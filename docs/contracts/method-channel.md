# Contract: Flutter ↔ Kotlin MethodChannel

Channel: `snippetboard/native` (satu channel). Implementasi: `MainActivity.kt` (Kotlin), `lib/platform/native_bridge.dart` (Dart).
Error dikembalikan sebagai `PlatformException(code, message)`.

| Method | Args | Return | Catatan |
|---|---|---|---|
| `copySnippet` | `{id: int, overrides: {nama?: String, rekening?: String}}` | `{status: "copied"}` atau `{status: "needsInput", missing: ["nama"\|"rekening", ...]}` | Resolve variabel → clipboard (flag sensitif jika kategori Rekening) → haptic → update `last_copied_at`/`copy_count`. Tidak menyalin apa pun jika `needsInput`. Error: `NOT_FOUND`. |
| `refreshSurfaces` | – | `null` | Dipanggil Dart setelah setiap insert/update/delete/settings. Kotlin: notify Edge Panel (jika didukung). |
| `edgePanelSupported` | – | `bool` | Slook init + `COCKTAIL_PANEL`; exception → `false`. |
| `setOverlayEnabled` | `{enabled: bool}` | `{status: "ok"\|"needsPermission"}` | `needsPermission` jika `Settings.canDrawOverlays` false; Dart menampilkan penjelasan lalu memanggil `openOverlayPermission`. |
| `openOverlayPermission` | – | `null` | Buka `ACTION_MANAGE_OVERLAY_PERMISSION` untuk paket ini. |
| `requestAddTile` | – | `bool` | API 33+: `StatusBarManager.requestAddTileService` → `true`; lebih lama: `false` (UI menampilkan instruksi manual). |
| `surfaceStatus` | – | `{edgeSupported, edge, tile, overlayPermission: bool}` | `edge`/`tile` = komponen tidak dinonaktifkan. |
| `setSurfaceEnabled` | `{surface: "edge"\|"tile", enabled: bool}` | `null` | `PackageManager.setComponentEnabledSetting` pada `SnippetEdgeProvider` / `SnippetTileService`. |
| `saveDocument` | `{name: String, content: String}` | `true` atau `null` (batal) | SAF `ACTION_CREATE_DOCUMENT` (ekspor JSON). Error: `IO`. |
| `openDocument` | – | `String` atau `null` (batal) | SAF `ACTION_OPEN_DOCUMENT` (impor). Error: `IO`. |
| `iapProduct` | – | `{price: String}` atau error `IAP_UNAVAILABLE` | `getProductsDetails("pro_lifetime")`. |
| `iapPurchase` | – | `{status: "purchased"\|"cancelled"}` atau error `IAP_UNAVAILABLE`/`IAP_FAILED` | Saat `purchased`, Kotlin sudah menulis `is_pro=1` ke `settings`. |
| `iapRestore` | – | `{isPro: bool}` atau error `IAP_UNAVAILABLE` | `getOwnedList(ITEM)`; menulis hasil ke `settings`. |

Native → Dart: tidak ada callback. Dart me-refresh query saat `AppLifecycleState.resumed`.

## Intent ke `PickerActivity` (internal native)

| Extra | Nilai | Perilaku |
|---|---|---|
| `mode` | `"copy"` | wajib `snippet_id: Long`. Salin langsung; jika `needsInput` tampilkan dialog isian; selesai → `finish()`. |
| `mode` | `"pick"` | tampilkan daftar snippet ringkas + chip kategori; ketuk → sama dengan `copy`. |
