---
description: "Task list: One UI Quick Snippet & Clipboard (Edge Panel)"
---

# Tasks: One UI Quick Snippet & Clipboard (Edge Panel)

**Input**: Design documents from `docs/` — [spec.md](spec.md), [plan.md](plan.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Hanya untuk logika non-trivial yang disebut di plan.md (VariableResolver, SnippetStore, SnippetRepo — batas gratis/undo/refund). Sisanya divalidasi manual lewat skenario V1–V17 di [quickstart.md](quickstart.md).

**Organization**: Dikelompokkan per user story agar tiap story bisa diimplementasi & diuji mandiri.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: bisa paralel (file berbeda, tidak bergantung task yang belum selesai)
- **[Story]**: US1–US6 sesuai spec.md
- Package Kotlin: `id.snippetboard.app` → path `android/app/src/main/kotlin/id/snippetboard/app/`

---

## Phase 1: Setup

**Purpose**: inisialisasi project Flutter + Android sesuai plan.md

- [X] T001 Jalankan `flutter create --org id.snippetboard --project-name snippetboard --platforms android .` di root repo (pertahankan README.md & docs/), pastikan applicationId `id.snippetboard.app` di android/app/build.gradle.kts
- [X] T002 Tambah dependencies di pubspec.yaml: `drift`, `drift_sqflite`, `sqflite`, `path`, `dynamic_color`, `intl`, `flutter_localizations` (sdk); dev: `drift_dev`, `build_runner`, `sqlite3` (untuk `NativeDatabase.memory()` di test host). Aktifkan `flutter: generate: true`
- [X] T003 [P] Konfigurasi android/app/build.gradle.kts: `minSdk = 29`, `targetSdk = 35`, JVM 17, `implementation(fileTree("libs") { include("*.jar", "*.aar") })`, JUnit 5 + `org.xerial:sqlite-jdbc` atau Robolectric untuk `testImplementation`
- [X] T004 [P] Buat folder android/app/libs/ dengan README.md yang menjelaskan cara mengunduh `slook_v1.4.0.jar` & Samsung IAP 6.x `.aar` dari Samsung Developers; tambahkan `android/app/libs/*.jar` & `*.aar` ke .gitignore jika lisensi melarang commit
- [X] T005 [P] Setup l10n: l10n.yaml (`arb-dir: lib/l10n`, `template-arb-file: app_en.arb`), lib/l10n/app_en.arb dan lib/l10n/app_id.arb dengan kunci awal (appTitle, copied, categoryPersonal, categoryWork, categoryAccount, categoryChatTemplate, emptyState); android/app/src/main/res/values/strings.xml & values-in/strings.xml untuk string native
- [X] T006 [P] Tulis android/app/src/main/AndroidManifest.xml dasar: `android:allowBackup="false"`, `android:fullBackupContent="false"`, izin `VIBRATE` saja dulu (izin lain ditambahkan di story masing-masing); pastikan TIDAK ada `INTERNET` di manifest main (hapus jika ditambahkan template debug hanya untuk debug/profile)

---

## Phase 2: Foundational (blocking)

**Purpose**: DB bersama, jalur salin Kotlin tunggal, bridge, theme. Wajib selesai sebelum story mana pun.

- [X] T007 Definisikan drift schema di lib/data/db.dart: tabel `Snippets` — `id` INTEGER PK autoincrement; `title` TEXT NOT NULL "1–80 char"; `body` TEXT NOT NULL "1–10.000 char, tidak boleh hanya spasi"; `category` INTEGER NOT NULL DEFAULT 0 "0=Personal, 1=Kerja, 2=Rekening, 3=Template Chat"; `pinned` INTEGER NOT NULL DEFAULT 0; `created_at`, `updated_at` INTEGER NOT NULL (epoch ms); `last_copied_at` INTEGER NULL; `copy_count` INTEGER NOT NULL DEFAULT 0. Tabel `Settings` (`key` TEXT PK, `value` TEXT NOT NULL). Nama tabel/kolom SQL harus persis seperti docs/contracts/db-schema.md (`snippets`, `settings`, snake_case). `schemaVersion = 1`; index `(pinned, last_copied_at)`
- [X] T008 Buka DB via `SqfliteQueryExecutor.inDatabaseFolder(path: 'snippets.db')` dengan `PRAGMA journal_mode=WAL` di `beforeOpen` di lib/data/db.dart; jalankan `dart run build_runner build` untuk menghasilkan lib/data/db.g.dart
- [X] T009 Tambah query di lib/data/db.dart: `watchSnippets({int? category, String? query})` dengan urutan `ORDER BY pinned DESC, COALESCE(last_copied_at,0) DESC, created_at DESC` dan pencarian `LIKE '%q%'` pada title OR body (case-insensitive); `countSnippets()`; `getSetting/setSetting`
- [X] T010 [P] Implementasi Kotlin `SnippetStore` di android/app/src/main/kotlin/id/snippetboard/app/core/SnippetStore.kt: buka `context.getDatabasePath("snippets.db")` dengan `SQLiteDatabase.openDatabase(..., OPEN_READWRITE)` + `enableWriteAheadLogging()`; jika file belum ada kembalikan list kosong (tidak membuat DB); method `list(category: Int = -1, limit = 100)`, `get(id)`, `settings(): Map<String,String>`, `markCopied(id, now)`, `putSetting(k, v)` — SQL persis dari docs/contracts/db-schema.md
- [X] T011 [P] Implementasi `VariableResolver` (fungsi murni) di android/app/src/main/kotlin/id/snippetboard/app/core/VariableResolver.kt: `resolve(body, values: Map<String,String>, overrides, locale, today: LocalDate): Result` → `Resolved(text)` atau `Missing(listOf("nama"|"rekening"))`. Token persis `{nama}`, `{tanggal}`, `{rekening}` (huruf kecil), lainnya literal; substitusi satu kali kiri-ke-kanan (nilai tidak diproses ulang); `{tanggal}` = `DateFormat.getDateInstance(DateFormat.LONG, locale)`; nilai kosong/blank dianggap missing
- [X] T012 [P] Test JUnit android/app/src/test/kotlin/id/snippetboard/app/VariableResolverTest.kt: substitusi 3 variabel; `{harga}` tetap literal; nilai berisi `{nama}` tidak diproses ulang; missing nama/rekening; tanggal id-ID "7 November 2026" & en-US "November 7, 2026"; emoji utuh
- [X] T013 Implementasi `Copier` di android/app/src/main/kotlin/id/snippetboard/app/core/Copier.kt: `copy(context, text, sensitive: Boolean, view: View?)` → `ClipData.newPlainText`, jika `sensitive` set `PersistableBundle` extra `"android.content.extra.IS_SENSITIVE"=true` di `clip.description.extras`; haptic `view?.performHapticFeedback(HapticFeedbackConstants.CONFIRM)` (API 30+, fallback `VIRTUAL_KEY`) atau tanpa view `Vibrator.vibrate(VibrationEffect.createPredefined(EFFECT_TICK))`; Toast "Disalin" hanya jika API < 33 (Android 13+ sudah menampilkan konfirmasi sistem)
- [X] T014 Implementasi `CopyFlow` di android/app/src/main/kotlin/id/snippetboard/app/core/CopyFlow.kt: `run(context, id, overrides, view): Status` — `SnippetStore.get` → `VariableResolver.resolve` dengan `settings()` var_nama/var_rekening → jika `Missing` kembalikan `NeedsInput(missing)` tanpa menyalin → selain itu `Copier.copy(sensitive = category == 2)` lalu `SnippetStore.markCopied(id, now)`; `NOT_FOUND` jika id tidak ada
- [X] T015 [P] Test android/app/src/test/kotlin/id/snippetboard/app/SnippetStoreTest.kt: buat DB SQLite dengan DDL yang sama dengan drift, verifikasi urutan list (pinned → last_copied_at → created_at), filter kategori, `markCopied` menaikkan `copy_count`, file DB tidak ada → list kosong
- [X] T016 Daftarkan MethodChannel `snippetboard/native` di android/app/src/main/kotlin/id/snippetboard/app/MainActivity.kt dengan method `copySnippet` (→ CopyFlow, kembalikan `{status:"copied"}` / `{status:"needsInput", missing:[...]}` / PlatformException `NOT_FOUND`) dan `refreshSurfaces` (no-op dulu); sesuai docs/contracts/method-channel.md
- [X] T017 [P] Wrapper Dart lib/platform/native_bridge.dart: `copySnippet(int id, {Map<String,String> overrides})` → sealed result `Copied | NeedsInput(List<String> missing)`; `refreshSurfaces()`; method lain ditambahkan per story
- [X] T018 Implementasi lib/data/snippet_repo.dart: `create(title, body, category)` — validasi body trim tidak kosong & ≤ 10.000 char, title kosong → 30 char pertama body (trim), title ≤ 80 char; tolak dengan `FreeLimitReached` jika `is_pro != "1"` DAN `count >= 10`; `update`, `togglePin`, `delete(id)` mengembalikan row, `restore(row)` insert ulang dengan id sama tanpa cek batas; setiap mutasi memanggil `NativeBridge.refreshSurfaces()`
- [X] T019 [P] Test test/snippet_repo_test.dart (drift `NativeDatabase.memory()`, bridge fake): snippet ke-11 ditolak saat free; diizinkan saat `is_pro=1`; dengan 12 snippet & `is_pro=0` (refund) edit/hapus tetap jalan, create ditolak, tidak ada data terhapus; body blank ditolak; title otomatis; restore setelah delete memulihkan id yang sama; urutan & search case-insensitive
- [X] T020 [P] Theme di lib/ui/theme.dart: `ThemeData(useMaterial3: true)` dari `ColorScheme` dinamis atau fallback seed `Color(0xFF3E91FF)`, light & dark, kartu radius 26 dp, typografi header besar
- [X] T021 lib/app_scope.dart (InheritedWidget memegang AppDb, SnippetRepo, NativeBridge) dan lib/main.dart: `DynamicColorBuilder` → `MaterialApp` (localizationsDelegates, supportedLocales id & en, themeMode system), `WidgetsBindingObserver` yang memicu re-query saat `AppLifecycleState.resumed`

- [X] T021a [P] Masking tampilan Rekening (ui-specs §4.1): lib/data/mask.dart `maskSensitive` + android/.../core/Masker.kt dengan regex identik; test test/mask_test.dart & `MaskerTest` (kasus sama)
- [X] T021b [P] Token native One UI (design-system §11): res/values{,-night,-v31,-night-v31}/colors.xml, values/dimens.xml, TextAppearance + `Theme.SnippetBoard.Picker` di values/styles.xml, drawable bg_card/bg_edge_card/bg_pill/bg_squircle, ui/Tokens.kt

**Catatan implementasi Phase 1–2**:
- Flutter 3.44: Material dipisah ke paket `material_ui` (dipakai `dynamic_color` 2.x). Kode app mengimpor `package:material_ui/material_ui.dart`, bukan `flutter/material.dart`.
- Test Kotlin memakai JUnit 4 + Robolectric 4.16 (opsi T003), satu runner untuk resolver murni & SQLite.
- Haptic `Copier` mengikuti design-system §8 (lebih baru dari T013): hanya `performHapticFeedback`, tanpa `Vibrator` langsung.
- `dataExtractionRules` ditambahkan: di Android 12+ `allowBackup=false` tidak mencegah transfer perangkat-ke-perangkat.
- Validasi lokal tanpa SDK terpasang: `docker run ghcr.io/cirruslabs/flutter:stable` dengan repo di-mount.
- Host dev saat ini aarch64: AAPT2 (Maven) hanya x86_64 dan Robolectric native SQLite tidak mendukung Linux aarch64 → `flutter build apk` & `SnippetStoreTest` **belum dijalankan**; jalankan `./gradlew :app:testDebugUnitTest` di mesin x86_64/macOS. Yang sudah diverifikasi: `flutter analyze` + `flutter test` (12), kompilasi semua Kotlin + `VariableResolverTest` (7) & `MaskerTest` (5) di proyek JVM terpisah, SQL `SnippetStore` dicek dengan sqlite3.

**Checkpoint**: `flutter test` dan `./gradlew :app:testDebugUnitTest` hijau.

---

## Phase 3: User Story 1 — Simpan & salin 1 ketukan (P1) 🎯 MVP

**Goal**: buat/edit/hapus snippet di app, ketuk kartu → tersalin + haptic + konfirmasi.

**Independent Test**: quickstart V1, V2.

- [X] T022 [P] [US1] Kartu snippet lib/ui/snippet_card.dart: judul + potongan isi `maxLines: 2`, ikon pin, `Semantics(label: title, hint: 'Ketuk untuk menyalin')`; `onTap` → `bridge.copySnippet`; `onLongPress` → bottom sheet Edit / Sematkan / Hapus (FR-013); konfirmasi "Disalin" sepenuhnya ditangani native `Copier` (Flutter tidak menampilkan SnackBar sendiri)
- [X] T023 [US1] Home lib/ui/home_page.dart: `CustomScrollView` dengan `SliverAppBar.large` (header One UI menyusut), `StreamBuilder` atas `watchSnippets()`, empty state "Belum ada snippet", FAB "Tambah" di bawah kanan; hapus → SnackBar "Urungkan" 5 detik memanggil `repo.restore` (FR-005)
- [X] T024 [US1] Editor lib/ui/editor_page.dart: field judul (maxLength 80), isi (maxLength 10000, multiline), simpan → `repo.create`/`repo.update`; tampilkan error validasi; tangkap `FreeLimitReached` → tampilkan dialog sementara "Batas 10 snippet tercapai" (diganti layar upgrade di US6)
- [X] T025 [US1] Tambahkan string US1 ke lib/l10n/app_en.arb & lib/l10n/app_id.arb (tambah, edit, hapus, urungkan, sematkan, validasi body kosong)

**Checkpoint**: MVP siap demo — V1, V2 lolos.

---

## Phase 4: User Story 2 — Samsung Edge Panel (P1)

**Goal**: panel Edge berisi daftar snippet; ketuk → tersalin tanpa membuka app.

**Independent Test**: quickstart V3, V4 di perangkat Galaxy.

- [X] T026 [P] [US2] Layout RemoteViews android/app/src/main/res/layout/edge_panel.xml (header + `ListView` id `edge_list` + empty view + tombol "Buka app"/"Tambah") dan android/app/src/main/res/layout/edge_item.xml (judul, potongan 2 baris)
- [X] T027 [P] [US2] android/app/src/main/res/xml/edge_panel_info.xml: metadata cocktail `category="1"`, `launchOnClick` ke MainActivity, `cocktailWidth` panel single-plus, label & ikon panel
- [X] T028 [US2] `EdgeListService` (`RemoteViewsService` + `RemoteViewsFactory`) di android/app/src/main/kotlin/id/snippetboard/app/edge/EdgeListService.kt: `onDataSetChanged` → `SnippetStore.list(category)` (kategori dari intent extra); tiap item `setOnClickFillInIntent` dengan `snippet_id`
- [X] T029 [US2] `SnippetEdgeProvider : SlookCocktailProvider` di android/app/src/main/kotlin/id/snippetboard/app/edge/SnippetEdgeProvider.kt: `onUpdate` → bangun RemoteViews `edge_panel`, `setRemoteAdapter(edge_list, EdgeListService intent)`, `setPendingIntentTemplate` → `PickerActivity` (`mode=copy`, `FLAG_IMMUTABLE` tidak boleh untuk template → pakai `FLAG_MUTABLE`), `setEmptyView`, tombol buka app; `SlookCocktailManager.updateCocktail`
- [X] T030 [US2] `PickerActivity` mode `copy` di android/app/src/main/kotlin/id/snippetboard/app/picker/PickerActivity.kt: tema translucent tanpa animasi (`Theme.Translucent.NoTitleBar`), `excludeFromRecents`, `noHistory`, `taskAffinity=""`; `onCreate` → `CopyFlow.run(id)`; `Copied` → `finish()`; `NeedsInput` → sementara (sampai T042) jangan salin, tampilkan Toast "Lengkapi variabel di Pengaturan" lalu `finish()` (diganti dialog di US4)
- [X] T031 [US2] Daftarkan di AndroidManifest.xml: receiver `SnippetEdgeProvider` (intent-filter `com.samsung.android.cocktail.v2.action.COCKTAIL_UPDATE`, meta-data `com.samsung.android.cocktail.provider` → `@xml/edge_panel_info`), service `EdgeListService` (`BIND_REMOTEVIEWS`), activity `PickerActivity`; tambahkan `<uses-permission android:name="com.samsung.android.providers.context.permission.WRITE_USE_APP_FEATURE_SURVEY"/>` HANYA jika diwajibkan versi Slook yang dipakai (cek dokumentasi; jika tidak wajib, jangan tambahkan)
- [X] T032 [US2] Implementasi `refreshSurfaces` dan `edgePanelSupported` di android/app/src/main/kotlin/id/snippetboard/app/MainActivity.kt: `Slook().initialize(ctx)` + `isFeatureEnabled(Slook.COCKTAIL_PANEL)` dalam try/catch (exception → false); refresh → `SlookCocktailManager.getInstance(ctx).getCocktailIds(ComponentName(provider))` lalu `notifyCocktailViewDataChanged(id, R.id.edge_list)`; tambah wrapper di lib/platform/native_bridge.dart
- [ ] T033 [US2] Uji manual V3 & V4 di perangkat Galaxy; catat versi One UI yang diuji di docs/quickstart.md

_Status US2: kode lengkap & terkompilasi (stub Slook). Build APK butuh `slook_v1.4.0.jar` di android/app/libs/. `EdgeModelTest` lulus; `EdgeListServiceTest` (Robolectric) belum dijalankan — host aarch64 tidak didukung. PickerActivity sudah punya mode `search` (dari search pill Edge); mode `pick` untuk Tile/Overlay (T043) belum._

**Checkpoint**: Edge Panel menyalin snippet tanpa membuka app.

---

## Phase 5: User Story 3 — Kategori & pencarian (P2)

**Goal**: filter per kategori (app & Edge), pencarian, Rekening sensitif.

**Independent Test**: spec US3 skenario 1–4; quickstart V7.

- [ ] T034 [P] [US3] Chip kategori + field pencarian di lib/ui/home_page.dart: `FilterChip` "Semua/Personal/Kerja/Rekening/Template Chat", search memanggil `watchSnippets(category, query)`; ikon kategori di lib/ui/snippet_card.dart — _chip selesai (lib/ui/category_chips.dart); field pencarian belum_
- [X] T035 [P] [US3] Selector kategori di lib/ui/editor_page.dart (`SegmentedButton`/dropdown, default Personal = 0)
- [X] T036 [US3] Filter kategori di Edge Panel: baris chip/ikon di android/app/src/main/res/layout/edge_panel.xml, klik → broadcast ke `SnippetEdgeProvider` yang menyimpan kategori aktif (SharedPreferences native sederhana `edge_category`) lalu `notifyCocktailViewDataChanged`; `EdgeListService` membaca kategori itu
- [ ] T037 [US3] Tambahkan label kategori & teks pencarian ke lib/l10n/app_en.arb, lib/l10n/app_id.arb, dan android/app/src/main/res/values{,-in}/strings.xml; verifikasi V7 (flag sensitif sudah diterapkan `Copier` dari T013)

---

## Phase 6: User Story 4 — Variabel dinamis (P2)

**Goal**: `{nama}`, `{tanggal}`, `{rekening}` terganti saat salin; dialog isian bila kosong.

**Independent Test**: quickstart V5, V6.

- [X] T038 [P] [US4] Bagian "Variabel" di lib/ui/settings_page.dart: field default `{nama}` & `{rekening}` disimpan ke settings `var_nama` / `var_rekening`, lalu `refreshSurfaces()`; tautkan dari menu Home
- [X] T039 [P] [US4] Dialog isian lib/ui/variable_dialog.dart: menerima `missing` list, satu TextField per variabel, kembalikan `Map<String,String>` atau `null` saat batal
- [X] T040 [US4] Hubungkan di lib/ui/snippet_card.dart: hasil `NeedsInput` → `variable_dialog` → panggil ulang `copySnippet(id, overrides)`; batal → tidak menyalin apa pun (FR-017)
- [ ] T041 [US4] Tombol sisip variabel di lib/ui/editor_page.dart: tiga `ActionChip` `{nama}` `{tanggal}` `{rekening}` yang menyisipkan token di posisi kursor `TextEditingController.selection`
- [X] T042 [US4] Dialog isian native di android/app/src/main/kotlin/id/snippetboard/app/picker/PickerActivity.kt: ganti perilaku sementara T030 — `NeedsInput` → `AlertDialog` (tema DeviceDefault.DayNight) dengan EditText per variabel; OK → `CopyFlow.run(id, overrides)`; Batal/dismiss → `finish()` tanpa menyalin

---

## Phase 7: User Story 5 — Fallback Tile & Overlay (P3)

**Goal**: pemilih snippet dari Quick Settings Tile dan gelembung mengambang.

**Independent Test**: quickstart V8–V11.

- [ ] T043 [P] [US5] Mode `pick` di android/app/src/main/kotlin/id/snippetboard/app/picker/PickerActivity.kt + android/app/src/main/res/layout/picker.xml & picker_item.xml: bottom sheet ringkas (RecyclerView `SnippetStore.list`, chip kategori, empty state + tombol buka app); ketuk → alur `copy` yang sama — _sebagian: `ACTION_PICK` memakai daftar+cari yang sama dengan mode search (tanpa keyboard otomatis); chip kategori & bottom sheet custom belum_
- [X] T044 [P] [US5] `SnippetTileService` di android/app/src/main/kotlin/id/snippetboard/app/tile/SnippetTileService.kt: `onClick` → API 34+ `startActivityAndCollapse(PendingIntent)` / lebih lama `startActivityAndCollapse(Intent)` ke `PickerActivity(mode=pick)`; daftarkan service di AndroidManifest.xml (`BIND_QUICK_SETTINGS_TILE`, ikon, label)
- [X] T045 [US5] `OverlayService` di android/app/src/main/kotlin/id/snippetboard/app/overlay/OverlayService.kt + android/app/src/main/res/layout/overlay_bubble.xml: foreground service (`specialUse`, notifikasi channel "Gelembung snippet" dengan aksi Matikan), bubble `TYPE_APPLICATION_OVERLAY` dapat diseret, snap ke tepi terdekat, simpan `overlay_x/overlay_y` via `SnippetStore.putSetting`; ketuk → `PickerActivity(mode=pick)`; seret ke zona "tutup" bawah → `overlay_enabled=0` & stopSelf; berhenti aman jika `canDrawOverlays()` false — _target drag-to-close & animasi idle/spring belum; matikan via notifikasi/Pengaturan (`overlay_enabled` ditambahkan ke key yang boleh ditulis Kotlin)_
- [X] T046 [US5] Manifest: izin `SYSTEM_ALERT_WINDOW`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_SPECIAL_USE`, `POST_NOTIFICATIONS`; service `OverlayService` dengan `foregroundServiceType="specialUse"` + `<property android:name="android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE" android:value="Floating snippet picker"/>` di android/app/src/main/AndroidManifest.xml
- [X] T047 [US5] Method channel `setOverlayEnabled`, `openOverlayPermission`, `requestAddTile` (API 33+ `StatusBarManager.requestAddTileService`) di MainActivity.kt + wrapper di lib/platform/native_bridge.dart
- [X] T048 [US5] Bagian "Akses cepat" di lib/ui/settings_page.dart: switch overlay (dialog penjelasan sebelum `openOverlayPermission`, FR-023; minta `POST_NOTIFICATIONS` di API 33+), tombol "Tambah tile" (fallback instruksi manual), status Edge Panel — _plus switch Edge/Tile (enable/disable komponen) dan Ekspor/Impor JSON via SAF (lib/data/settings_repo.dart); verifikasi di perangkat V8–V11 belum_
- [ ] T049 [US5] Onboarding lib/ui/onboarding_page.dart: 2–3 halaman; panggil `edgePanelSupported()` → jika true tampilkan cara mengaktifkan Edge Panel, jika false sembunyikan dan tawarkan tile & overlay (FR-025); simpan `onboarding_done=1`; arahkan dari lib/main.dart saat belum selesai

---

## Phase 8: User Story 6 — Upgrade Pro via Galaxy Store (P3)

**Goal**: batas 10 snippet free, Pro lifetime via Samsung IAP, restore, offline.

**Independent Test**: quickstart V12–V15 (OperationMode TEST, akun tester).

- [ ] T050 [US6] `IapBridge` di android/app/src/main/kotlin/id/snippetboard/app/iap/IapBridge.kt: `IapHelper.getInstance(ctx)` + `setOperationMode(if (BuildConfig.DEBUG) OPERATION_MODE_TEST else OPERATION_MODE_PRODUCTION)`; `product()` → `getProductsDetails("pro_lifetime")` harga lokal; `purchase(activity)` → `startPayment("pro_lifetime", ...)` sukses → `putSetting("is_pro","1")` + `pro_verified_at`; `restore()` → `getOwnedList(IapHelper.PRODUCT_TYPE_ITEM)` sukses → set `is_pro` sesuai ada/tidaknya item (refund → "0"), gagal → status tidak diubah; Galaxy Store tidak ada → error `IAP_UNAVAILABLE`. Tambahkan komentar `// shortcut: status Pro disimpan lokal tanpa verifikasi receipt, upgrade jika pembajakan signifikan`
- [ ] T051 [US6] Method channel `iapProduct`, `iapPurchase`, `iapRestore` di MainActivity.kt (sesuai docs/contracts/method-channel.md) + wrapper di lib/platform/native_bridge.dart; izin `com.samsung.android.iap.permission.BILLING` di AndroidManifest.xml
- [ ] T052 [US6] Layar lib/ui/upgrade_page.dart: manfaat Pro, harga dari `iapProduct` (loading/`IAP_UNAVAILABLE` → pesan "Pembelian memerlukan Galaxy Store"), tombol Beli → `iapPurchase`; `cancelled`/error → kembali dengan pesan, data tidak berubah; sukses → pop dengan hasil true
- [ ] T053 [US6] Ganti dialog sementara T024 di lib/ui/editor_page.dart & FAB di lib/ui/home_page.dart: `FreeLimitReached` → buka upgrade_page; sukses → lanjutkan simpan snippet tanpa restart
- [ ] T054 [US6] Penghitung "x/10 snippet" di header lib/ui/home_page.dart (sembunyi saat Pro), tombol "Pulihkan pembelian" di lib/ui/settings_page.dart; panggil `iapRestore` diam-diam saat start di lib/main.dart (abaikan error → status offline dipertahankan, FR-037)
- [ ] T055 [US6] Cek merged manifest (`android/app/build/intermediates/merged_manifest/release/AndroidManifest.xml`): catat izin yang ditambahkan aar IAP di bagian "Izin manifest" docs/plan.md

---

## Phase 9: Polish & Cross-Cutting

- [ ] T056 [P] Aksesibilitas: verifikasi TalkBack di Home/Editor/Picker/Edge, ukuran font sistem 200% tanpa overflow, kontras dark mode — perbaikan di lib/ui/*.dart dan layout XML native
- [ ] T057 [P] Halaman Tentang & Privasi di lib/ui/settings_page.dart (tanpa jaringan, tanpa pelacakan, data hanya di perangkat, tidak ada backup otomatis) + docs/privacy-policy.md untuk Galaxy Store
- [ ] T058 Audit privasi: jalankan quickstart V16 (PCAPdroid) & V17 (`aapt dump permissions`) pada build release; hasil dicatat di docs/quickstart.md
- [ ] T059 [P] Ikon adaptif, ikon panel Edge, screenshot Galaxy Store (id & en) di android/app/src/main/res/mipmap-*/ dan store-assets/
- [ ] T060 Release build: signing config di android/app/build.gradle.kts (keystore via `key.properties`, tidak di-commit), R8 rules untuk Slook & IAP di android/app/proguard-rules.pro (`-keep class com.samsung.android.sdk.** { *; }`), `flutter build apk --release`, uji V1–V15 di APK release
- [ ] T061 Jalankan seluruh skenario docs/quickstart.md V1–V17 di Galaxy + non-Samsung; submit ke Galaxy Store Seller Portal

---

## Dependencies & Execution Order

```text
Phase 1 Setup ─► Phase 2 Foundational ─► US1 (MVP)
                                         ├─► US2 Edge Panel ──► US3 (bagian Edge: T036)
                                         ├─► US3 Kategori (T034/T035/T037 tidak butuh US2)
                                         ├─► US4 Variabel (T042 butuh PickerActivity dari T030)
                                         ├─► US5 Fallback (T043 butuh PickerActivity dari T030)
                                         └─► US6 Pro (butuh T018 & T024 saja)
                                                      └─► Phase 9 Polish
```

- Dalam tiap story: layout/model → service/activity → wiring channel/manifest → UI Flutter → uji manual.
- File yang sering disentuh lintas story (berurutan, jangan paralel): `MainActivity.kt`, `AndroidManifest.xml`, `PickerActivity.kt`, `home_page.dart`, `settings_page.dart`, `native_bridge.dart`.

## Parallel Examples

- **Phase 2**: T010, T011, T012, T015 (Kotlin) paralel dengan T019, T020 (Dart) setelah T007–T009.
- **US2**: T026 + T027 paralel, lalu T028 → T029 → T030 → T031 → T032.
- **US3**: T034 + T035 paralel.
- **US4**: T038 + T039 paralel, lalu T040, T041; T042 terpisah (Kotlin).
- **US5**: T043 + T044 paralel, lalu T045 → T046 → T047 → T048 → T049.
- **Lintas story** (tim 2 orang setelah US1): Dev A = US2 → US5 (Kotlin), Dev B = US3/US4 Flutter → US6.

## Implementation Strategy

1. **MVP**: Phase 1 + 2 + US1 → APK internal, uji V1–V2.
2. **Pembeda produk**: US2 (Edge Panel) → uji di Galaxy nyata sebelum lanjut; ini risiko teknis terbesar.
3. **Increment**: US3 + US4 (nilai harian) → US5 (jangkauan perangkat) → US6 (pendapatan).
4. **Rilis**: Phase 9, submit Galaxy Store. Setiap checkpoint = build yang bisa didemokan.
