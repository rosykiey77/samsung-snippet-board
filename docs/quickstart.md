# Quickstart & Validation Guide

## Prasyarat

- Flutter stable 3.x, Android SDK 35, JDK 17.
- Perangkat Samsung Galaxy (One UI 2+, Edge Panel aktif) + satu perangkat/emulator non-Samsung (uji fallback).
- `android/app/libs/`: `slook_v1.4.0.jar`, `samsung-iap-6.x.aar` (unduh dari Samsung Developers; tidak di-commit jika lisensi melarang).
- Akun Seller Portal Galaxy Store dengan item `pro_lifetime` (non-consumable) + akun tester terdaftar.

## Build & test

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # kode drift
flutter test                                              # unit/widget Dart
(cd android && ./gradlew :app:testDebugUnitTest)          # VariableResolver, SnippetStore (JVM)
flutter run                                               # debug ke perangkat (IAP mode TEST)
flutter build apk --release                               # artefak Galaxy Store
```

## Skenario validasi (manual, di perangkat)

| # | Langkah | Hasil yang diharapkan | Spec |
|---|---|---|---|
| V1 | Buat snippet "Alamat" → ketuk kartu → tempel di aplikasi pesan | Teks identik, getar, toast "Disalin" | US1, FR-011/012 |
| V2 | Tutup paksa app → buka lagi | Snippet masih ada | FR-002 |
| V3 | Pengaturan → Edge panels → aktifkan "Quick Snippet" → buka WhatsApp → geser panel → ketuk snippet → tempel | Teks benar, app WhatsApp tetap di depan | US2 |
| V4 | Edit snippet di app → buka Edge Panel | Isi panel terbarui | FR-024 |
| V5 | Simpan `{nama}`=Budi di Pengaturan; snippet "Halo {nama}, {tanggal}" → salin | "Halo Budi, 7 November 2026" (tanggal hari ini) | US4 |
| V6 | Kosongkan `{rekening}`; salin snippet berisi `{rekening}` dari Edge Panel | Dialog isian muncul; batal → clipboard tidak berubah | FR-017 |
| V7 | Salin snippet kategori Rekening (Android 13+) | Pratinjau clipboard sistem disamarkan | FR-010 |
| V8 | Tambah tile Quick Snippet → ketuk → pilih snippet | Shade menutup, picker muncul, teks tersalin | US5 |
| V9 | Aktifkan overlay → tolak izin | Penjelasan tampil, overlay tetap nonaktif, tidak crash | FR-023 |
| V10 | Izinkan overlay → seret gelembung → restart app | Menempel tepi, posisi diingat | FR-022 |
| V11 | Perangkat non-Samsung: onboarding | Opsi Edge disembunyikan, tile & overlay ditawarkan | FR-025 |
| V12 | Akun gratis: buat 10 snippet → buat ke-11 | Layar upgrade dengan harga lokal; snippet ke-11 tidak dibuat | FR-033/034 |
| V13 | Beli (tester) | Pro aktif tanpa restart, buat ke-11 berhasil | FR-035 |
| V14 | Uninstall → install → Pulihkan pembelian | Pro kembali | FR-036 |
| V15 | Mode pesawat → buka app (Pro) | Tetap Pro | FR-037 |
| V16 | Pantau jaringan (mis. PCAPdroid, filter UID app) 10 menit pemakaian normal | 0 koneksi dari app (di luar alur beli) | SC-005 |
| V17 | `aapt dump permissions build/app/outputs/apk/release/app-release.apk` | Tidak ada izin di luar daftar di plan.md | FR-029 |
