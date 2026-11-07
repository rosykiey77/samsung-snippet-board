# Research: One UI Quick Snippet & Clipboard

Phase 0 output for [plan.md](plan.md). Each item: Decision / Rationale / Alternatives.

## R1. Satu database dibaca Flutter dan Kotlin

- **Decision**: drift dengan executor **`drift_sqflite`** (SQLite bawaan Android lewat sqflite). Kode Kotlin (Edge Panel, tile, overlay, picker) membuka **file DB yang sama** lewat `android.database.sqlite.SQLiteDatabase`. Mode WAL aktif. drift pemilik skema & migrasi; Kotlin hanya memakai kolom yang dikunci di [contracts/db-schema.md](contracts/db-schema.md).
- **Rationale**: Edge Panel/tile harus bisa jalan tanpa Flutter engine (SC-002, edge case "aplikasi dihentikan sistem"). Jika drift memakai `NativeDatabase` (sqlite3 yang dibundel) sementara Kotlin memakai SQLite framework, ada **dua salinan library SQLite dalam satu proses** → POSIX lock saling melepas → risiko korupsi DB. Dengan sqflite, keduanya memakai library SQLite yang sama sehingga locking aman.
- **Alternatives**: (a) `NativeDatabase` + snapshot JSON untuk native — dua sumber kebenaran, sinkronisasi statistik salin rumit. (b) Kotlin memanggil Dart via headless engine — cold start lambat (> 300 ms), melanggar SC-002. (c) Room di Kotlin + channel ke Flutter — membalik kepemilikan, lebih banyak kode channel.

## R2. Lokasi logika salin (clipboard, haptic, sensitif, variabel)

- **Decision**: Satu implementasi di Kotlin: `VariableResolver` + `Copier`. Flutter memanggil `copySnippet(id, overrides)` via MethodChannel; semua permukaan (app, Edge, tile, overlay) memakai jalur yang sama.
- **Rationale**: `Clipboard.setData` Flutter tidak bisa memberi flag `ClipDescription.EXTRA_IS_SENSITIVE` (FR-010). Resolver tunggal = tidak ada dua implementasi yang bisa berbeda (SC-006).
- **Alternatives**: resolver di Dart + Kotlin dengan fixture bersama — duplikasi tanpa manfaat.

## R3. Samsung Edge Panel

- **Decision**: Slook SDK (`slook_v1.4.0.jar` atau terbaru dari Samsung Developers), `SlookCocktailProvider` + panel tipe list (`edge_single_plus`) dengan `RemoteViews` + `RemoteViewsService` untuk `ListView`. Klik item memakai `setPendingIntentTemplate` → **`PickerActivity`** translucent (mode `copy`, extra `snippet_id`). Refresh panel lewat `SlookCocktailManager.notifyCocktailViewDataChanged` yang dipicu channel `refreshSurfaces` setelah setiap mutasi.
- **Rationale**: RemoteViews ListView hanya boleh satu PendingIntent template. Activity translucent bisa menyalin langsung (punya fokus, jadi clipboard pasti boleh ditulis) **dan** menampilkan dialog variabel bila perlu (FR-017) — satu target untuk dua kasus.
- **Deteksi dukungan**: `Slook().initialize(context)` + `isFeatureEnabled(Slook.COCKTAIL_PANEL)`; gagal/exception → Edge tidak didukung (FR-025).
- **Alternatives**: BroadcastReceiver langsung — tidak bisa menampilkan dialog variabel; harus dua jalur.
- **Risiko**: panel Edge pihak ketiga perlu terdaftar di manifest dengan meta-data `com.samsung.android.cocktail.provider`; Galaxy Store mewajibkan app tetap jalan di perangkat tanpa Slook → semua pemanggilan Slook di-guard try/catch.

## R4. Quick Settings Tile & Floating Overlay

- **Decision**: `TileService` → `startActivityAndCollapse(PendingIntent)` (API 34+) / `startActivityAndCollapse(Intent)` (API < 34) ke `PickerActivity` mode `pick`. Overlay = `OverlayService` foreground service (`foregroundServiceType="specialUse"`) yang menggambar gelembung `TYPE_APPLICATION_OVERLAY`; ketuk → `PickerActivity` mode `pick`.
- **Rationale**: Picker native (bukan Flutter) → muncul instan. Tile dan overlay memakai picker yang sama.
- **Alternatives**: Picker berbasis Flutter activity kedua — cold start engine ±1 detik.

## R5. Samsung IAP

- **Decision**: Samsung IAP SDK 6.x (`.aar`) di Kotlin, `IapBridge` di belakang MethodChannel. Item `pro_lifetime` tipe *non-consumable (Item)*. `getOwnedList(ITEM)` saat start (jika online) dan di "Pulihkan pembelian"; `startPayment` untuk beli; `getProductsDetails` untuk harga lokal. `OperationMode.OPERATION_MODE_TEST` di debug, `PRODUCTION` di release.
- **Hasil disimpan** di tabel `settings` (`is_pro`, `pro_verified_at`) → berlaku offline (FR-037). Bila `getOwnedList` sukses & item tidak ada → `is_pro=0` (refund, FR-038 menjaga data). Bila gagal (offline/Galaxy Store tidak ada) → status lama dipertahankan.
- **Rationale**: Tidak ada plugin Flutter resmi; bridge kecil cukup (3 method).
- **Alternatives**: verifikasi server-side — melanggar zero-network/zero-backend.
- **Catatan**: shortcut — status Pro di DB lokal bisa diubah di perangkat root; upgrade ke verifikasi tanda tangan receipt jika pembajakan terlihat signifikan.
- **Izin**: aplikasi sendiri tidak memakai `INTERNET`. Cek *merged manifest*: jika `.aar` IAP menambahkan `INTERNET`, biarkan (dipakai SDK/Galaxy Store), dan dokumentasikan di halaman privasi Store. Diverifikasi di task.

## R6. UI One UI + Material You

- **Decision**: Material 3 (`useMaterial3`) + paket `dynamic_color` (warna wallpaper, fallback seed biru One UI). Pola One UI: `SliverAppBar.large` (header besar menyusut), FAB & search di bawah, kartu sudut membulat 26 dp.
- **Haptic**: di native `Copier` → `View.performHapticFeedback(CONFIRM)` saat ada view, selain itu `Vibrator.vibrate(VibrationEffect.createPredefined(EFFECT_TICK))`; keduanya menghormati pengaturan getaran sistem. Butuh izin normal `VIBRATE`.
- **Alternatives**: One UI design kit pihak ketiga — tidak resmi untuk Flutter.

## R7. Format `{tanggal}`

- **Decision**: `DateFormat.getDateInstance(DateFormat.LONG, Locale.getDefault())` → "7 November 2026" (id) / "November 7, 2026" (en).

## R8. Versi Android & build

- **Decision**: `minSdk 29` (Android 10 / One UI 2), `targetSdk 35`, Flutter stable 3.x, Kotlin 2.x, Java 17. `android:allowBackup="false"`.
- **Rationale**: Galaxy aktif mayoritas ≥ Android 10; `EXTRA_IS_SENSITIVE` (API 33) diberikan sebagai extra string di semua versi — diabaikan di versi lama.

## R9. State management Flutter

- **Decision**: Tanpa library state management. drift `watch()` stream + `StreamBuilder`; satu `AppScope` (InheritedWidget) memegang DB, repo, bridge. Saat `AppLifecycleState.resumed` → refresh (native bisa menulis statistik salin yang tidak terlihat oleh stream drift).
- **Alternatives**: Riverpod/Bloc — tidak perlu untuk ±5 layar.
