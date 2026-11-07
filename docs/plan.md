# Implementation Plan: One UI Quick Snippet & Clipboard (Edge Panel)

**Branch**: `main` | **Date**: 2026-11-07 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `docs/spec.md`

## Summary

Aplikasi Android (Galaxy Store) untuk menyimpan snippet teks dan menyalinnya dengan 1 ketukan dari aplikasi, Samsung Edge Panel, Quick Settings Tile, atau gelembung mengambang. App utama ditulis dengan **Flutter + drift**; semua permukaan sistem ditulis **native Kotlin** agar tampil instan tanpa Flutter engine. Kunci arsitektur: **satu file SQLite** yang dibaca Flutter (drift via `drift_sqflite`) dan Kotlin (SQLite framework) — library SQLite yang sama sehingga aman dipakai bersamaan (lihat [research.md R1](research.md)). Logika salin (variabel, clipboard sensitif, haptic) hanya ada **satu** implementasi di Kotlin, dipakai semua permukaan. Monetisasi via Samsung IAP non-consumable `pro_lifetime`; tidak ada backend, tidak ada telemetri.

## Technical Context

**Language/Version**: Dart 3.x (Flutter stable 3.x); Kotlin 2.x (JVM 17)

**Primary Dependencies**: Flutter: `drift`, `drift_sqflite`, `sqflite`, `dynamic_color`, `flutter_localizations` + `intl`. Dev: `drift_dev`, `build_runner`. Android: Samsung Slook SDK (jar), Samsung IAP SDK 6.x (aar). Tanpa library state management, DI, atau analytics.

**Storage**: SQLite lokal (`snippets.db`, WAL) — skema di [data-model.md](data-model.md)

**Testing**: `flutter_test` (repo & widget, drift in-memory via `NativeDatabase.memory()` hanya di test host); JUnit 5 untuk Kotlin (`VariableResolver` murni, `SnippetStore` dengan SQLite JDBC/Robolectric); validasi manual perangkat di [quickstart.md](quickstart.md)

**Target Platform**: Android 10+ (`minSdk 29`, `targetSdk 35`); dioptimalkan untuk Samsung One UI dengan Edge Panel; fallback berfungsi di Android non-Samsung

**Project Type**: mobile-app (Flutter + modul native Android di project yang sama)

**Performance Goals**: ketuk → clipboard + haptic ≤ 300 ms (SC-002); cold start app ≤ 1,5 s (SC-003); picker/Edge Panel tampil tanpa start Flutter engine

**Constraints**: 100% offline; tanpa izin `INTERNET` dari kode app (lihat R5); `allowBackup=false`; tidak membaca clipboard; data private app-only

**Scale/Scope**: ±6 layar Flutter (Home, Editor, Settings, Upgrade, Onboarding, Search inline), 4 komponen native (Edge Panel, Tile, Overlay, Picker); ≤ ribuan snippet per pengguna

**Izin manifest (lengkap)**: `VIBRATE`, `SYSTEM_ALERT_WINDOW`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_SPECIAL_USE`, `POST_NOTIFICATIONS` (notifikasi wajib foreground service overlay), `com.samsung.android.iap.permission.BILLING`, plus apa pun yang di-merge dari aar IAP (diverifikasi & didokumentasikan).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` masih berupa template kosong (belum diratifikasi) → **tidak ada gate formal**. Prinsip yang diturunkan dari spec dipakai sebagai gate pengganti:

| Gate | Status pra-desain | Status pasca-desain |
|---|---|---|
| Zero network/telemetry (FR-029/030) | ✅ tidak ada dependency jaringan/analytics | ✅ hanya IAP via Galaxy Store; V16/V17 memverifikasi |
| Satu sumber kebenaran data | ✅ | ✅ satu DB, kontrak kolom Kotlin di [contracts/db-schema.md](contracts/db-schema.md) |
| Tanpa duplikasi logika salin | ✅ | ✅ resolver + copier hanya di Kotlin |
| Kesederhanaan (YAGNI) | ✅ | ✅ tanpa state-mgmt lib/DI/backend; 1 MethodChannel |

> Disarankan menjalankan `/speckit-constitution` untuk meratifikasi prinsip di atas.

## Arsitektur

```text
┌──────────────── Flutter (lib/) ────────────────┐
│ UI (M3 + dynamic_color, SliverAppBar.large)    │
│   │                                            │
│ SnippetRepo ──(batas 10, undo)── drift AppDb   │──┐
│   │                                            │  │  snippets.db (WAL)
│ NativeBridge (MethodChannel snippetboard/native)│  │  library SQLite framework
└───┼────────────────────────────────────────────┘  │  yang sama
    ▼                                               │
┌──────────── Kotlin (android/app/src/main/kotlin) ─┤
│ MainActivity: channel handler                     │
│ core/SnippetStore ── baca daftar, tulis statistik ┘
│ core/VariableResolver (murni) → core/Copier (clipboard+sensitif+haptic)
│ picker/PickerActivity (translucent; mode copy|pick; dialog variabel)
│ edge/SnippetEdgeProvider + EdgeListService (Slook, RemoteViews ListView)
│ tile/SnippetTileService ─────────► PickerActivity(pick)
│ overlay/OverlayService (bubble) ─► PickerActivity(pick)
│ iap/IapBridge (Samsung IAP) → settings.is_pro
└───────────────────────────────────────────────────
```

**Alur salin dari Edge Panel**: ketuk item → PendingIntent template → `PickerActivity(mode=copy, id)` → `SnippetStore.get(id)` + `settings` → `VariableResolver.resolve(body, values, locale, today)` → jika ada `missing` → dialog isian → `Copier.copy(text, sensitive=category==Rekening)` → haptic + toast → update statistik → `finish()`.

**Alur salin dari app**: `NativeBridge.copySnippet(id)` → jalur Kotlin yang sama; jika `needsInput` Flutter menampilkan dialog isian lalu memanggil ulang dengan `overrides`.

**Sinkronisasi permukaan (FR-024)**: setiap mutasi di `SnippetRepo` → `NativeBridge.refreshSurfaces()` → `notifyCocktailViewDataChanged`. Tile & picker selalu query saat dibuka. Flutter re-query saat `resumed`.

## Project Structure

### Documentation (this feature)

```text
docs/
├── spec.md              # /speckit-specify
├── plan.md              # this file
├── research.md          # Phase 0
├── data-model.md        # Phase 1
├── quickstart.md        # Phase 1
├── contracts/
│   ├── method-channel.md
│   └── db-schema.md
├── checklists/requirements.md
└── tasks.md             # /speckit-tasks
```

### Source Code (repository root)

```text
pubspec.yaml
l10n.yaml
lib/
├── main.dart                 # runApp, DynamicColorBuilder, AppScope, lifecycle refresh
├── app_scope.dart            # InheritedWidget: AppDb, SnippetRepo, NativeBridge
├── data/
│   ├── db.dart               # drift tables Snippets, Settings + queries (schemaVersion 1)
│   └── snippet_repo.dart     # CRUD, batas gratis, undo, search, settings, refreshSurfaces
├── platform/
│   └── native_bridge.dart    # wrapper MethodChannel (contracts/method-channel.md)
├── ui/
│   ├── theme.dart            # M3 theme One UI-ish (radius, typografi), fallback seed
│   ├── home_page.dart        # SliverAppBar.large, chip kategori, search, kartu, counter x/10
│   ├── snippet_card.dart
│   ├── editor_page.dart      # form + tombol sisip variabel
│   ├── variable_dialog.dart  # isian {nama}/{rekening}
│   ├── settings_page.dart    # nilai variabel, tile, overlay, restore, tentang/privasi
│   ├── upgrade_page.dart
│   └── onboarding_page.dart  # deteksi Edge Panel → tawarkan permukaan
└── l10n/
    ├── app_id.arb
    └── app_en.arb

test/
├── snippet_repo_test.dart    # batas 10, undo, urutan, search, refund
└── widget/home_page_test.dart

android/app/
├── build.gradle.kts          # minSdk 29, libs/*.jar|aar
├── libs/                     # slook jar, samsung iap aar
└── src/
    ├── main/
    │   ├── AndroidManifest.xml
    │   ├── kotlin/id/snippetboard/app/
    │   │   ├── MainActivity.kt
    │   │   ├── core/{SnippetStore,VariableResolver,Copier}.kt
    │   │   ├── picker/PickerActivity.kt
    │   │   ├── edge/{SnippetEdgeProvider,EdgeListService}.kt
    │   │   ├── tile/SnippetTileService.kt
    │   │   ├── overlay/OverlayService.kt
    │   │   └── iap/IapBridge.kt
    │   └── res/
    │       ├── xml/edge_panel_info.xml
    │       ├── layout/{edge_panel,edge_item,picker,picker_item,overlay_bubble}.xml
    │       └── values{,-in}/strings.xml
    └── test/kotlin/id/snippetboard/app/
        ├── VariableResolverTest.kt
        └── SnippetStoreTest.kt
```

**Structure Decision**: satu project Flutter di root repo; kode native tinggal di `android/app` standar Flutter (bukan plugin terpisah) karena hanya dipakai app ini.

## Roadmap Implementasi

| Fase | Isi | Deliverable / exit criteria | Spec |
|---|---|---|---|
| **M0 Setup** | `flutter create`, deps, manifest, minSdk, l10n, theme, CI lokal (`flutter test` + gradle test) | App kosong jalan, test hijau | – |
| **M1 Fondasi data + salin** | drift schema, `SnippetRepo`, `SnippetStore`, `VariableResolver`, `Copier`, channel `copySnippet` | Unit test resolver & repo hijau | FR-001..006, 011..014 |
| **M2 MVP app (US1)** | Home, Editor, Card, haptic/toast, undo | V1, V2 lolos | US1 |
| **M3 Edge Panel (US2)** | Slook provider, ListView RemoteViews, PickerActivity mode copy, refreshSurfaces | V3, V4 lolos di Galaxy | US2 |
| **M4 Kategori + variabel (US3, US4)** | chip filter app & Edge, search, flag sensitif, editor sisip variabel, settings variabel, dialog isian | V5–V7 | US3, US4 |
| **M5 Fallback (US5)** | PickerActivity mode pick, TileService, OverlayService, onboarding | V8–V11 | US5 |
| **M6 Monetisasi (US6)** | IapBridge, upgrade page, counter, restore, refund rule | V12–V15 di mode TEST | US6 |
| **M7 Rilis** | audit privasi (V16, V17), a11y, ikon/screenshot, kebijakan privasi, submit Galaxy Store (OperationMode PRODUCTION) | Lolos review | SC-005, SC-008 |

M3–M5 dapat dikerjakan paralel setelah M2. M6 bergantung hanya pada M1.

## Risiko

| Risiko | Mitigasi |
|---|---|
| Slook SDK tidak berfungsi / berubah di One UI terbaru | Guard semua pemanggilan; fallback tile/overlay selalu tersedia; uji di ≥2 versi One UI |
| aar IAP menambahkan izin `INTERNET` | Terima & dokumentasikan; kode app tetap tanpa jaringan (V16) |
| Galaxy Store menolak foreground service overlay | Overlay opsional & nonaktif default; notifikasi jelas; bisa dihapus tanpa memengaruhi fitur lain |
| Status Pro bisa dimanipulasi di perangkat root | Diterima untuk v1 (`shortcut:` di IapBridge) |
| Drift stream tidak melihat tulisan Kotlin | Re-query saat `resumed`; statistik salin bukan data kritis |

## Complexity Tracking

Tidak ada pelanggaran yang perlu dijustifikasi. Dua bahasa (Dart + Kotlin) adalah syarat dari spec (Edge Panel/tile/overlay native), bukan pilihan tambahan.
