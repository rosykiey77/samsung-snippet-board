# SDK Samsung (tidak di-commit)

Lisensi Samsung SDK tidak mengizinkan redistribusi, jadi file di folder ini di-ignore git
(`android/app/libs/*.jar`, `*.aar`). `build.gradle.kts` otomatis memuat semua `*.jar`/`*.aar` di sini.

| File | Sumber | Dipakai di |
|---|---|---|
| `slook_v1.4.0.jar` | Samsung Developers → *Galaxy Edge* → Download "Samsung Look SDK" | Edge Panel (US2, T029) |
| `samsung-iap-6.x.x.aar` | Samsung Developers → *In-App Purchase* → Download "IAP SDK 6.x" (Android) | Pro upgrade (US6, T050) |

Langkah:
1. Login ke https://developer.samsung.com, unduh kedua SDK di atas.
2. Salin `.jar` / `.aar` ke `android/app/libs/`.
3. `flutter build apk` — tidak perlu mengubah Gradle.

Build tanpa file ini tetap berhasil sampai task yang memakai Slook/IAP diimplementasikan.
