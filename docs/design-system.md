# Design System — Samsung Snippet Board (One UI 6 / 7)

**Status**: Draft v1 · **Tanggal**: 2026-11-07 · **Berlaku untuk**: app Flutter (`lib/ui/`) dan permukaan native Kotlin (Edge Panel, Picker, Tile, Overlay)
**Sumber**: [spec.md](spec.md) (FR-012, FR-026–FR-028), [plan.md](plan.md), [tasks.md](tasks.md) (T013, T020–T023, T026, T034, T036, T043, T045, T056). Spesifikasi layar & komponen ada di [ui-specs.md](ui-specs.md).

> Dokumen ini adalah **satu sumber kebenaran token**. Kode UI tidak boleh memakai hex, ukuran, atau durasi mentah. Semua nilai diambil dari token di bawah (Flutter: `lib/ui/theme.dart`; Kotlin: `res/values*/` + `ui/Tokens.kt`).

---

## 0. Prinsip desain

| # | Prinsip | Arti praktis |
|---|---|---|
| P1 | **Lihat di atas, sentuh di bawah** | Sepertiga atas layar adalah *viewing area* (judul besar, status), dua pertiga bawah adalah *interaction area* (search, chip, kartu, FAB). Aksi utama tidak pernah hanya ada di ujung atas. |
| P2 | **Satu ketuk = selesai** | Kartu adalah tombol salin. Tidak ada konfirmasi, tidak ada langkah tambahan kecuali variabel kosong (FR-017). |
| P3 | **Umpan balik berlapis** | Setiap salin memberi 3 sinyal: visual (kartu berubah), haptic (tick), dan teks ("Disalin") untuk pembaca layar. Tidak boleh bergantung pada satu sinyal saja. |
| P4 | **Privasi terlihat** | Data Rekening disamarkan secara default di semua permukaan (`•••• 1234`). Yang disalin tetap teks lengkap. |
| P5 | **Datar, tenang, AMOLED** | Kedalaman dari tonal surface, bukan bayangan tebal. Mode gelap memakai hitam murni sebagai latar. |
| P6 | **Native di mana-mana** | Edge Panel, Picker, Tile, dan Overlay memakai token yang sama walau dirender dengan View/RemoteViews, bukan Flutter. |

---

## 1. Arsitektur token

Tiga lapis. Komponen hanya membaca lapis **semantic** atau **component**.

```
primitive  (blue-600 = #0C66E4)
   └─ semantic  (color.primary.light = blue-600)
        └─ component  (card.copied.border = color.primary)
```

Penamaan lintas platform:

| Lapis | Flutter | Kotlin / XML |
|---|---|---|
| Primitive | `OneUiPalette.blue600` | `@color/p_blue_600` |
| Semantic | `ColorScheme.primary`, `OneUiColors.success` (ThemeExtension) | `@color/primary` (+ `values-night/`) |
| Component | `OneUiTokens.cardRadius` | `@dimen/card_radius` |

---

## 2. Warna

### 2.1 Primitive palette

| Token | Hex | Catatan |
|---|---|---|
| `black` | `#000000` | Latar AMOLED |
| `gray-950` | `#121212` | Kartu mode gelap |
| `gray-900` | `#1C1C1E` | Sheet/dialog mode gelap, chip gelap |
| `gray-850` | `#2C2C2E` | Pressed state gelap, divider kuat |
| `gray-800` | `#2A2B2E` | Divider gelap |
| `gray-500` | `#6B6F76` | Teks sekunder terang |
| `gray-400` | `#A6A9AF` | Teks sekunder gelap |
| `gray-200` | `#E2E4E8` | Divider terang (dekoratif) |
| `gray-100` | `#EEF0F3` | Chip terang, pressed terang |
| `gray-50` | `#F8F9FA` | Latar mode terang |
| `white` | `#FFFFFF` | Kartu mode terang |
| `ink-900` | `#111214` | Teks utama terang |
| `ink-50` | `#F2F3F5` | Teks utama gelap |
| `blue-600` | `#0C66E4` | **One UI Blue** — aksen terang |
| `blue-500` | `#2C74DE` | One UI Blue — isi tombol gelap |
| `blue-400` | `#3E91FF` | Aksen teks/ikon gelap (= seed T020) |
| `blue-100` | `#DCE9FC` | Primary container terang |
| `blue-900` | `#0F2C55` | Primary container gelap |
| `red-600` / `red-300` | `#D32F2F` / `#FF6B6B` | Error terang / gelap |
| `green-700` / `green-300` | `#1A7F37` / `#4CC38A` | Sukses (state "Disalin") |
| `teal-700` / `teal-300` | `#0F7B8A` / `#4FD1E0` | Kategori Personal |
| `violet-600` / `violet-300` | `#7A3FE0` / `#B794FF` | Kategori Kerja |
| `amber-700` / `amber-400` | `#B54708` / `#F5A524` | Kategori Rekening |
| `chatgreen-700` / `chatgreen-300` | `#1A7F37` / `#4CC38A` | Kategori Template Chat |

### 2.2 Semantic colors

| Peran | Light | Dark (AMOLED) | Kontras terukur |
|---|---|---|---|
| `background` | `#F8F9FA` | `#000000` | — |
| `surface` (kartu) | `#FFFFFF` | `#121212` | — |
| `surfaceContainerHigh` (sheet, dialog, Edge Panel) | `#FFFFFF` | `#1C1C1E` | — |
| `surfacePressed` | `#EEF0F3` | `#2C2C2E` | — |
| `onSurface` (teks utama) | `#111214` | `#F2F3F5` | > 15:1 |
| `onSurfaceVariant` (teks sekunder, meta) | `#6B6F76` | `#A6A9AF` | 4.79:1 pada `#F8F9FA`; 7.22:1 pada `#1C1C1E` |
| `primary` (teks/ikon aksen, link) | `#0C66E4` | `#3E91FF` | 4.94:1 pada `#F8F9FA`; 5.98:1 pada `#121212` |
| `primaryFill` (isi tombol/chip terpilih) | `#0C66E4` | `#2C74DE` | — |
| `onPrimaryFill` | `#FFFFFF` | `#FFFFFF` | 5.2:1 / 4.51:1 |
| `primaryContainer` | `#DCE9FC` | `#0F2C55` | — |
| `onPrimaryContainer` | `#0A3D8F` | `#CFE0FF` | — |
| `outline` (divider dekoratif) | `#E2E4E8` | `#2A2B2E` | dekoratif saja, bukan batas kontrol |
| `outlineStrong` (batas kontrol, field) | `#8A8F98` | `#6B6F76` | ≥ 3:1 (non-text) |
| `error` | `#D32F2F` | `#FF6B6B` | 4.98:1 / 6.13:1 |
| `success` | `#1A7F37` | `#4CC38A` | 5.08:1 / 7.68:1 |
| `scrim` | `#000000` @ 40% | `#000000` @ 60% | — |

Rasio kontras dihitung dengan rumus WCAG 2.x pada pasangan yang tertulis. Teks normal ≥ 4.5:1; ikon/batas kontrol ≥ 3:1.

### 2.3 Warna kategori

Warna kategori hanya dipakai untuk **titik 8 dp, ikon squircle, dan aksen tepi**, tidak pernah untuk teks label (label chip tetap `onSurface`), sehingga tidak ada risiko kontras teks.

| Kategori | Key DB | Ikon (Material Symbols Rounded) | Light | Dark | Container light | Container dark |
|---|---|---|---|---|---|---|
| Personal | 0 | `person` | `#0F7B8A` | `#4FD1E0` | `#E0F2F4` | `#0E2A2E` |
| Kerja | 1 | `work` | `#7A3FE0` | `#B794FF` | `#EEE6FC` | `#251A3D` |
| Rekening | 2 | `account_balance` | `#B54708` | `#F5A524` | `#FCEBDD` | `#33240A` |
| Template Chat | 3 | `chat_bubble` | `#1A7F37` | `#4CC38A` | `#E3F2E7` | `#10291A` |

Label pendek untuk ruang sempit (Edge Panel): `Personal`, `Kerja`, `Rekening`, `Chat`.

### 2.4 Dynamic color (Material You) vs One UI Blue

FR-026 mewajibkan warna dinamis sistem bila tersedia. Aturannya:

1. **Netral selalu tetap**: `background`, `surface*`, `onSurface*`, `outline*` tidak pernah diambil dari wallpaper. Latar tetap `#F8F9FA` / `#000000` agar identitas One UI dan AMOLED terjaga.
2. **Hanya keluarga primary yang dinamis**: bila `DynamicColorBuilder` memberi skema, ambil `primary`, `primaryContainer`, `onPrimaryContainer` darinya; sisanya dari tabel 2.2.
3. **One UI Blue adalah default bawaan** dan dipakai saat dynamic color tidak tersedia (Android < 12, non-Samsung tanpa palette) atau saat pengguna mematikan "Warna dari wallpaper" di Pengaturan.
4. Warna kategori, `success`, `error` **tidak pernah** dinamis (makna harus stabil).
5. Permukaan native: pakai `@android:color/system_accent1_600` (light) / `system_accent1_200` (dark) di API 31+ lewat `values-v31/`, fallback `@color/p_blue_600` / `p_blue_400`.

---

## 3. Tipografi

### 3.1 Font family

| Peran | Pilihan 1 | Fallback | Catatan |
|---|---|---|---|
| Display / header besar | **Samsung Sharp Sans** | SamsungOne → Roboto | Hanya jika lisensi tersedia (lihat catatan) |
| UI / body | **SamsungOne** (font sistem One UI) | Roboto | Tidak dibundel; ikuti font sistem |
| Angka rekening | font UI + `tabular figures` | — | Lebar digit seragam agar `•••• 1234` rata |

**Catatan lisensi (penting):** Samsung Sharp Sans dan SamsungOne adalah font proprietary Samsung. **Jangan membundel file font tersebut ke APK** tanpa izin tertulis. Pendekatan v1:

- **Kotlin/XML**: pakai `android:fontFamily="sans-serif"` / `"sans-serif-medium"`. Di One UI ini di-resolve ke font sistem pilihan pengguna (default SamsungOne); di perangkat lain menjadi Roboto. Ini juga menghormati pilihan font pengguna di Pengaturan Galaxy.
- **Flutter**: biarkan `fontFamily` kosong di `TextTheme` (jangan hardcode `'Roboto'`). **Verifikasi di perangkat Galaxy** (task T056) apakah engine merender font sistem One UI; jika tidak, terima Roboto sebagai fallback yang sah daripada membundel font Samsung.
- Jika kelak lisensi Samsung Sharp Sans didapat, pakai **hanya** untuk `headerLarge` (judul viewing area) agar biaya ukuran APK minimal.

### 3.2 Skala tipe

Satuan `sp` (mengikuti ukuran font sistem, FR-027). Line-height dalam sp.

| Token | Ukuran / LH | Bobot | Letter-spacing | Dipakai di |
|---|---|---|---|---|
| `headerLarge` | 34 / 40 | 700 | -0.4 | Judul viewing area (expanded) |
| `headerSub` | 15 / 20 | 400 | 0 | Subjudul viewing area ("7/10 snippet") |
| `titleBar` | 20 / 26 | 700 | -0.2 | Judul toolbar saat header menyusut |
| `titleLarge` | 22 / 28 | 700 | -0.2 | Judul layar sekunder, judul dialog |
| `titleMedium` | 17 / 22 | 600 | 0 | Judul kartu snippet |
| `bodyLarge` | 16 / 24 | 400 | 0 | Field editor, isi dialog |
| `bodyMedium` | 14 / 20 | 400 | 0 | Pratinjau isi kartu (maks 2 baris) |
| `labelLarge` | 15 / 20 | 600 | 0 | Tombol |
| `labelMedium` | 13 / 18 | 600 | 0.1 | Chip kategori |
| `labelSmall` | 12 / 16 | 500 | 0.2 | Meta (waktu disalin), counter, badge |
| `edgeTitle` | 14 / 18 | 600 | 0 | Judul mini-card Edge Panel |
| `edgeBody` | 12 / 16 | 400 | 0 | Pratinjau mini-card Edge Panel |

Aturan:
- Body minimum 14 sp di app, 12 sp hanya untuk meta & Edge Panel.
- Header besar dibatasi `maxLines: 1` + `ellipsis`; pada font 200% header mengecil ke `titleLarge` (lihat ui-specs §1.3).
- Jangan memakai bobot < 400 (font tipis jelek di AMOLED).

---

## 4. Spasi & layout (grid 8 dp)

### 4.1 Skala spasi

| Token | dp | Penggunaan |
|---|---|---|
| `space0_5` | 4 | **Hanya** jarak ikon↔teks dan antar baris teks dalam satu blok |
| `space1` | 8 | Gap antar kartu, gap antar chip, padding Edge mini-card vertikal |
| `space1_5` | 12 | Padding Edge mini-card (pengecualian untuk lebar sempit) |
| `space2` | 16 | Padding kartu, margin horizontal layar, inset FAB |
| `space3` | 24 | Padding horizontal header, padding dialog |
| `space4` | 32 | Jarak antar section |
| `space5` | 40 | Ukuran ikon squircle kartu |
| `space6` | 48 | Target sentuh minimum |
| `space7` | 56 | Tinggi FAB / tombol utama / bubble |
| `space8` | 64 | Tinggi toolbar collapsed |

Semua nilai kelipatan 8, kecuali 4 dan 12 sebagai setengah-langkah yang dibatasi pemakaiannya di atas.

### 4.2 Zona One UI

| Zona | Ukuran | Isi |
|---|---|---|
| Viewing area | `clamp(0.33 × tinggi layar, 200 dp, 320 dp)` | Judul besar, subjudul/counter, baris aksi di **dasar** area |
| Collapsed toolbar | 64 dp | Judul kecil + aksi |
| Interaction area | sisa layar | Search, chip (sticky), daftar kartu, FAB |
| Bottom safe inset | `max(16 dp, navigation bar inset)` | Jarak FAB / konten terakhir dari tepi bawah |

Viewing area **dinonaktifkan** (langsung 64 dp) jika: landscape, tinggi layar < 600 dp, mode jendela pop-up/split, atau Flex mode Galaxy Z Fold/Flip half-open.

### 4.3 Target sentuh

- Minimum **48 × 48 dp** di semua permukaan, termasuk Edge Panel. Elemen visual yang lebih kecil (ikon 20 dp, chip 36 dp) diperluas area ketuknya.
- Jarak antar target ≥ 8 dp.

---

## 5. Bentuk (radius & squircle)

| Token | Nilai | Komponen |
|---|---|---|
| `radiusCard` | **26 dp** | Kartu snippet, dialog, kartu settings group |
| `radiusSheet` | 26 dp (sudut atas saja) | Bottom sheet Picker |
| `radiusEdgeCard` | 18 dp | Mini-card Edge Panel (26 terlalu bulat pada lebar 120–160 dp) |
| `radiusField` | 18 dp | Search field, text field editor |
| `radiusFull` | 999 / `StadiumBorder` | Chip, tombol, FAB extended, search pill Edge |
| `squircle` | superellipse | Ikon kategori 40 dp, bubble overlay, ikon app |

**Tailwind (untuk mockup/prototipe HTML saja):** `rounded-3xl` = **24 px**, bukan 26. Gunakan `rounded-[26px]` agar sesuai token.

**Squircle:**
- Flutter: `ContinuousRectangleBorder(borderRadius: BorderRadius.circular(28))` untuk tile 40 dp (continuous curvature; nilai 28 ≈ visual sudut 13–14 dp — cek visual saat implementasi).
- Kotlin/RemoteViews: vector drawable `res/drawable/bg_squircle.xml` (viewport 24):

```xml
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="40dp" android:height="40dp"
    android:viewportWidth="24" android:viewportHeight="24">
  <path android:fillColor="@color/category_container"
      android:pathData="M12,0 C20.5,0 24,3.5 24,12 C24,20.5 20.5,24 12,24 C3.5,24 0,20.5 0,12 C0,3.5 3.5,0 12,0 Z"/>
</vector>
```

- Ikon launcher: adaptive icon (`mipmap-anydpi-v26`); bentuk squircle diberikan oleh mask One UI, jangan digambar sendiri.

---

## 6. Elevasi & bayangan

One UI datar. Kedalaman di mode gelap **hanya** dari tonal surface; bayangan hanya di mode terang dan tipis.

| Level | Komponen | Light | Dark |
|---|---|---|---|
| `e0` | Latar, kartu di daftar | tanpa bayangan; kartu putih di atas `#F8F9FA` | `#121212` di atas `#000000` |
| `e1` | Chip terpilih, search field | tanpa bayangan | — |
| `e2` | FAB, bubble overlay | `0 4 12 rgba(0,0,0,0.16)` | tanpa bayangan; isi `primaryFill` |
| `e3` | Bottom sheet, dialog, Edge Panel | `0 8 24 rgba(0,0,0,0.20)` + scrim | surface `#1C1C1E` + scrim 60% |

Flutter: set `surfaceTintColor: Colors.transparent` di `CardTheme`, `DialogTheme`, `BottomSheetTheme`, `AppBarTheme` agar M3 tidak menambahkan tint biru ke kartu.

---

## 7. Gerak (motion)

### 7.1 Durasi & kurva

| Token | Durasi | Kurva | Penggunaan |
|---|---|---|---|
| `motionPress` | 100 ms | `easeOut` | Kartu mengecil saat ditekan (scale 0.97) |
| `motionRelease` | 200 ms | `oneUiSpring` | Kartu kembali ke skala 1 |
| `motionCopied` | 240 ms | `oneUiStandard` | Ikon → centang, label → "Disalin" |
| `motionCopiedHold` | 1200 ms | — | Lama state "Disalin" sebelum kembali |
| `motionRevert` | 300 ms | `oneUiStandard` | Kembali ke state normal |
| `motionChip` | 150 ms | `oneUiStandard` | Ganti chip terpilih |
| `motionSheetIn` | 300 ms | `oneUiDecelerate` | Bottom sheet / dialog masuk |
| `motionSheetOut` | 200 ms | `oneUiAccelerate` | Keluar (lebih cepat dari masuk) |
| `motionReveal` | 180 ms | `oneUiStandard` | Masking → teks asli (cross-fade) |

Kurva (pendekatan gaya One UI, bukan nilai resmi Samsung):

| Kurva | Flutter | Android |
|---|---|---|
| `oneUiStandard` | `Cubic(0.22, 0.25, 0.0, 1.0)` | `PathInterpolator(0.22f, 0.25f, 0f, 1f)` |
| `oneUiDecelerate` | `Cubic(0.0, 0.0, 0.2, 1.0)` | `PathInterpolator(0f, 0f, 0.2f, 1f)` |
| `oneUiAccelerate` | `Cubic(0.4, 0.0, 1.0, 1.0)` | `PathInterpolator(0.4f, 0f, 1f, 1f)` |
| `oneUiSpring` | `SpringDescription(mass: 1, stiffness: 600, damping: 30)` | `SpringForce(1f).setStiffness(600f).setDampingRatio(0.6f)` |

### 7.2 Reduced motion

Jika `MediaQuery.disableAnimationsOf(context)` (Flutter) atau `Settings.Global.ANIMATOR_DURATION_SCALE == 0` (Kotlin): tanpa scale, tanpa morph; state berganti langsung. Label "Disalin" dan haptic **tetap** ada.

---

## 8. Haptic

Prinsip: haptic hanya untuk peristiwa bermakna, selalu menghormati pengaturan getaran sistem (FR-012). **Jangan** memakai `FLAG_IGNORE_GLOBAL_SETTING` dan **jangan** memakai `Vibrator` langsung.

| Peristiwa | Pemilik | API Android | Fallback |
|---|---|---|---|
| **Salin berhasil** (semua permukaan) | Native `Copier` (T013) | `view.performHapticFeedback(HapticFeedbackConstants.CONFIRM)` (API 30+) | API 29: `KEYBOARD_TAP` |
| Salin gagal / dialog variabel dibatalkan | Native | `REJECT` (API 30+) | tanpa haptic |
| Pilih chip kategori | Flutter | `HapticFeedback.selectionClick()` (→ `CLOCK_TICK`) | — |
| Tekan lama kartu (menu aksi) | Flutter | bawaan `InkWell.onLongPress` (`LONG_PRESS`) | — |
| Bubble menempel ke tepi | Native | `CLOCK_TICK` | — |
| Bubble masuk zona "tutup" | Native | `LONG_PRESS` | — |

Haptic salin **hanya** dipicu oleh `Copier` (keputusan arsitektur: konfirmasi salin dimiliki native). Flutter tidak boleh memanggil `HapticFeedback` untuk salin, agar tidak ada getaran ganda. Di One UI, `CONFIRM` terasa sebagai *tick* pendek dan halus.

---

## 9. Ikonografi

- Set: **Material Symbols Rounded**, weight 400, grade 0, optical size 24, *outline* untuk ikon netral, *fill* hanya untuk state aktif (pin aktif, chip terpilih).
- Ukuran token: `iconSm` 16 dp (meta), `iconMd` 20 dp (Edge, chip), `iconLg` 24 dp (toolbar, kartu).
- Tanpa emoji sebagai ikon struktural.
- Ikon kategori di dalam squircle 40 dp: ikon 20 dp warna kategori di atas container kategori.
- Ikon dekoratif di samping teks: `excludeSemantics` / `importantForAccessibility="no"`. Ikon-tombol wajib punya label (`tooltip` / `contentDescription`).

---

## 10. Token Flutter (`lib/ui/theme.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class OneUiPalette {
  static const black = Color(0xFF000000);
  static const gray950 = Color(0xFF121212);
  static const gray900 = Color(0xFF1C1C1E);
  static const gray850 = Color(0xFF2C2C2E);
  static const gray800 = Color(0xFF2A2B2E);
  static const gray500 = Color(0xFF6B6F76);
  static const gray400 = Color(0xFFA6A9AF);
  static const gray200 = Color(0xFFE2E4E8);
  static const gray100 = Color(0xFFEEF0F3);
  static const gray50 = Color(0xFFF8F9FA);
  static const ink900 = Color(0xFF111214);
  static const ink50 = Color(0xFFF2F3F5);
  static const blue600 = Color(0xFF0C66E4);
  static const blue500 = Color(0xFF2C74DE);
  static const blue400 = Color(0xFF3E91FF);
  static const blue100 = Color(0xFFDCE9FC);
  static const blue900 = Color(0xFF0F2C55);
}

abstract final class OneUiSpace {
  static const half = 4.0, s1 = 8.0, s1_5 = 12.0, s2 = 16.0, s3 = 24.0,
      s4 = 32.0, s5 = 40.0, s6 = 48.0, s7 = 56.0, s8 = 64.0;
}

abstract final class OneUiRadius {
  static const card = 26.0, edgeCard = 18.0, field = 18.0;
  static const cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(card)));
  static const squircle = ContinuousRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(28)));
}

abstract final class OneUiMotion {
  static const press = Duration(milliseconds: 100);
  static const release = Duration(milliseconds: 200);
  static const copied = Duration(milliseconds: 240);
  static const copiedHold = Duration(milliseconds: 1200);
  static const revert = Duration(milliseconds: 300);
  static const chip = Duration(milliseconds: 150);
  static const sheetIn = Duration(milliseconds: 300);
  static const sheetOut = Duration(milliseconds: 200);
  static const reveal = Duration(milliseconds: 180);
  static const standard = Cubic(0.22, 0.25, 0.0, 1.0);
  static const decelerate = Cubic(0.0, 0.0, 0.2, 1.0);
  static const accelerate = Cubic(0.4, 0.0, 1.0, 1.0);
}

/// Warna non-M3: sukses + kategori. Tidak pernah dinamis.
@immutable
class OneUiColors extends ThemeExtension<OneUiColors> {
  const OneUiColors({
    required this.success,
    required this.surfacePressed,
    required this.outlineStrong,
    required this.category,
    required this.categoryContainer,
  });
  final Color success, surfacePressed, outlineStrong;
  final List<Color> category; // index = key DB kategori 0..3
  final List<Color> categoryContainer;

  static const light = OneUiColors(
    success: Color(0xFF1A7F37),
    surfacePressed: OneUiPalette.gray100,
    outlineStrong: Color(0xFF8A8F98),
    category: [Color(0xFF0F7B8A), Color(0xFF7A3FE0), Color(0xFFB54708), Color(0xFF1A7F37)],
    categoryContainer: [Color(0xFFE0F2F4), Color(0xFFEEE6FC), Color(0xFFFCEBDD), Color(0xFFE3F2E7)],
  );
  static const dark = OneUiColors(
    success: Color(0xFF4CC38A),
    surfacePressed: OneUiPalette.gray850,
    outlineStrong: OneUiPalette.gray500,
    category: [Color(0xFF4FD1E0), Color(0xFFB794FF), Color(0xFFF5A524), Color(0xFF4CC38A)],
    categoryContainer: [Color(0xFF0E2A2E), Color(0xFF251A3D), Color(0xFF33240A), Color(0xFF10291A)],
  );

  @override
  OneUiColors copyWith() => this;
  @override
  OneUiColors lerp(OneUiColors? other, double t) => t < 0.5 ? this : (other ?? this);
}

ColorScheme _scheme(Brightness b, ColorScheme? dynamic, bool useDynamic) {
  final light = b == Brightness.light;
  var s = ColorScheme(
    brightness: b,
    primary: light ? OneUiPalette.blue600 : OneUiPalette.blue400,
    onPrimary: light ? Colors.white : OneUiPalette.black,
    primaryContainer: light ? OneUiPalette.blue100 : OneUiPalette.blue900,
    onPrimaryContainer: light ? const Color(0xFF0A3D8F) : const Color(0xFFCFE0FF),
    secondary: light ? OneUiPalette.blue600 : OneUiPalette.blue400,
    onSecondary: light ? Colors.white : OneUiPalette.black,
    error: light ? const Color(0xFFD32F2F) : const Color(0xFFFF6B6B),
    onError: light ? Colors.white : OneUiPalette.black,
    surface: light ? Colors.white : OneUiPalette.gray950,
    onSurface: light ? OneUiPalette.ink900 : OneUiPalette.ink50,
    onSurfaceVariant: light ? OneUiPalette.gray500 : OneUiPalette.gray400,
    surfaceContainerHigh: light ? Colors.white : OneUiPalette.gray900,
    outline: light ? const Color(0xFF8A8F98) : OneUiPalette.gray500,
    outlineVariant: light ? OneUiPalette.gray200 : OneUiPalette.gray800,
    scrim: OneUiPalette.black,
  );
  if (useDynamic && dynamic != null) {
    // Hanya keluarga primary yang ikut wallpaper (design-system §2.4).
    s = s.copyWith(
      primary: dynamic.primary,
      primaryContainer: dynamic.primaryContainer,
      onPrimaryContainer: dynamic.onPrimaryContainer,
    );
  }
  return s;
}

ThemeData buildOneUiTheme(Brightness b, {ColorScheme? dynamic, bool useDynamic = true}) {
  final light = b == Brightness.light;
  final scheme = _scheme(b, dynamic, useDynamic);
  final text = TextTheme(
    displaySmall: const TextStyle(fontSize: 34, height: 40 / 34, fontWeight: FontWeight.w700, letterSpacing: -0.4), // headerLarge
    titleLarge: const TextStyle(fontSize: 22, height: 28 / 22, fontWeight: FontWeight.w700, letterSpacing: -0.2),
    titleMedium: const TextStyle(fontSize: 17, height: 22 / 17, fontWeight: FontWeight.w600),
    bodyLarge: const TextStyle(fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w400),
    bodyMedium: const TextStyle(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w400),
    labelLarge: const TextStyle(fontSize: 15, height: 20 / 15, fontWeight: FontWeight.w600),
    labelMedium: const TextStyle(fontSize: 13, height: 18 / 13, fontWeight: FontWeight.w600, letterSpacing: 0.1),
    labelSmall: const TextStyle(fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w500, letterSpacing: 0.2),
  ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
  // fontFamily sengaja tidak di-set: ikut font sistem One UI (§3.1).

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    textTheme: text,
    scaffoldBackgroundColor: light ? OneUiPalette.gray50 : OneUiPalette.black,
    extensions: [light ? OneUiColors.light : OneUiColors.dark],
    splashFactory: InkSparkle.splashFactory,
    cardTheme: CardThemeData(
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: OneUiRadius.cardShape,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: light ? OneUiPalette.gray50 : OneUiPalette.black,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      systemOverlayStyle: light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: BorderSide.none,
      backgroundColor: light ? OneUiPalette.gray100 : OneUiPalette.gray900,
      selectedColor: light ? OneUiPalette.blue600 : OneUiPalette.blue500,
      labelStyle: text.labelMedium,
      padding: const EdgeInsets.symmetric(horizontal: OneUiSpace.s1_5),
      materialTapTargetSize: MaterialTapTargetSize.padded, // area ketuk 48 dp
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: light ? OneUiPalette.blue600 : OneUiPalette.blue500,
      foregroundColor: Colors.white,
      shape: const StadiumBorder(),
      elevation: light ? 4 : 0,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      shape: OneUiRadius.cardShape,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(OneUiRadius.card))),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: light ? OneUiPalette.gray100 : OneUiPalette.gray900,
      border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(OneUiRadius.field)),
          borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(OneUiRadius.field)),
          borderSide: BorderSide(color: scheme.primary, width: 2)),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: StadiumBorder(),
    ),
  );
}
```

Pemakaian di `main.dart` (T021):

```dart
DynamicColorBuilder(builder: (lightDyn, darkDyn) => MaterialApp(
  theme: buildOneUiTheme(Brightness.light, dynamic: lightDyn, useDynamic: useWallpaperColor),
  darkTheme: buildOneUiTheme(Brightness.dark, dynamic: darkDyn, useDynamic: useWallpaperColor),
  themeMode: ThemeMode.system,
  ...
));
```

Akses di widget: `Theme.of(context).extension<OneUiColors>()!.category[snippet.category]`.

---

## 11. Token Kotlin / Android (`res/values*/`)

Permukaan native memakai **View + XML** (RemoteViews untuk Edge Panel tidak mendukung Compose), jadi token disimpan sebagai resource.

### 11.1 `res/values/colors.xml` (light) dan `res/values-night/colors.xml` (dark)

```xml
<!-- res/values/colors.xml -->
<resources>
  <!-- primitive -->
  <color name="p_blue_600">#0C66E4</color>
  <color name="p_blue_500">#2C74DE</color>
  <color name="p_blue_400">#3E91FF</color>
  <!-- semantic (light) -->
  <color name="background">#F8F9FA</color>
  <color name="surface">#FFFFFF</color>
  <color name="surface_container_high">#FFFFFF</color>
  <color name="surface_pressed">#EEF0F3</color>
  <color name="on_surface">#111214</color>
  <color name="on_surface_variant">#6B6F76</color>
  <color name="primary">@color/p_blue_600</color>
  <color name="primary_fill">@color/p_blue_600</color>
  <color name="on_primary_fill">#FFFFFF</color>
  <color name="outline">#E2E4E8</color>
  <color name="outline_strong">#8A8F98</color>
  <color name="chip_bg">#EEF0F3</color>
  <color name="error">#D32F2F</color>
  <color name="success">#1A7F37</color>
  <color name="scrim">#66000000</color>
  <!-- kategori -->
  <color name="cat_personal">#0F7B8A</color>
  <color name="cat_kerja">#7A3FE0</color>
  <color name="cat_rekening">#B54708</color>
  <color name="cat_chat">#1A7F37</color>
  <color name="cat_personal_container">#E0F2F4</color>
  <color name="cat_kerja_container">#EEE6FC</color>
  <color name="cat_rekening_container">#FCEBDD</color>
  <color name="cat_chat_container">#E3F2E7</color>
</resources>

<!-- res/values-night/colors.xml -->
<resources>
  <color name="background">#000000</color>
  <color name="surface">#121212</color>
  <color name="surface_container_high">#1C1C1E</color>
  <color name="surface_pressed">#2C2C2E</color>
  <color name="on_surface">#F2F3F5</color>
  <color name="on_surface_variant">#A6A9AF</color>
  <color name="primary">@color/p_blue_400</color>
  <color name="primary_fill">@color/p_blue_500</color>
  <color name="on_primary_fill">#FFFFFF</color>
  <color name="outline">#2A2B2E</color>
  <color name="outline_strong">#6B6F76</color>
  <color name="chip_bg">#1C1C1E</color>
  <color name="error">#FF6B6B</color>
  <color name="success">#4CC38A</color>
  <color name="scrim">#99000000</color>
  <color name="cat_personal">#4FD1E0</color>
  <color name="cat_kerja">#B794FF</color>
  <color name="cat_rekening">#F5A524</color>
  <color name="cat_chat">#4CC38A</color>
  <color name="cat_personal_container">#0E2A2E</color>
  <color name="cat_kerja_container">#251A3D</color>
  <color name="cat_rekening_container">#33240A</color>
  <color name="cat_chat_container">#10291A</color>
</resources>
```

`res/values-v31/colors.xml` dan `res/values-night-v31/colors.xml` (opsional, dynamic color native):

```xml
<!-- values-v31 -->       <color name="primary">@android:color/system_accent1_600</color>
<!-- values-night-v31 --> <color name="primary">@android:color/system_accent1_200</color>
```

### 11.2 `res/values/dimens.xml`

```xml
<resources>
  <!-- spasi 8dp grid -->
  <dimen name="space_half">4dp</dimen>
  <dimen name="space_1">8dp</dimen>
  <dimen name="space_1_5">12dp</dimen>
  <dimen name="space_2">16dp</dimen>
  <dimen name="space_3">24dp</dimen>
  <dimen name="space_4">32dp</dimen>
  <dimen name="touch_min">48dp</dimen>
  <dimen name="fab_size">56dp</dimen>
  <!-- radius -->
  <dimen name="radius_card">26dp</dimen>
  <dimen name="radius_edge_card">18dp</dimen>
  <dimen name="radius_field">18dp</dimen>
  <dimen name="radius_full">999dp</dimen>
  <!-- ikon -->
  <dimen name="icon_sm">16dp</dimen>
  <dimen name="icon_md">20dp</dimen>
  <dimen name="icon_lg">24dp</dimen>
  <dimen name="squircle_tile">40dp</dimen>
  <!-- Edge Panel -->
  <dimen name="edge_width_min">120dp</dimen>
  <dimen name="edge_width_max">160dp</dimen>
  <dimen name="edge_padding">8dp</dimen>
  <dimen name="edge_card_padding">12dp</dimen>
  <!-- tipe (sp) -->
  <dimen name="text_header_large">34sp</dimen>
  <dimen name="text_title_large">22sp</dimen>
  <dimen name="text_title_medium">17sp</dimen>
  <dimen name="text_body_large">16sp</dimen>
  <dimen name="text_body_medium">14sp</dimen>
  <dimen name="text_label_large">15sp</dimen>
  <dimen name="text_label_medium">13sp</dimen>
  <dimen name="text_label_small">12sp</dimen>
  <dimen name="text_edge_title">14sp</dimen>
  <dimen name="text_edge_body">12sp</dimen>
</resources>
```

### 11.3 `res/values/styles.xml` (TextAppearance)

```xml
<resources>
  <style name="TextAppearance.SnippetBoard.TitleMedium" parent="">
    <item name="android:fontFamily">sans-serif-medium</item>
    <item name="android:textSize">@dimen/text_title_medium</item>
    <item name="android:textColor">@color/on_surface</item>
    <item name="android:lineHeight">22sp</item>
  </style>
  <style name="TextAppearance.SnippetBoard.BodyMedium" parent="">
    <item name="android:fontFamily">sans-serif</item>
    <item name="android:textSize">@dimen/text_body_medium</item>
    <item name="android:textColor">@color/on_surface_variant</item>
    <item name="android:lineHeight">20sp</item>
  </style>
  <style name="TextAppearance.SnippetBoard.EdgeTitle" parent="">
    <item name="android:fontFamily">sans-serif-medium</item>
    <item name="android:textSize">@dimen/text_edge_title</item>
    <item name="android:textColor">@color/on_surface</item>
  </style>
  <style name="TextAppearance.SnippetBoard.EdgeBody" parent="">
    <item name="android:fontFamily">sans-serif</item>
    <item name="android:textSize">@dimen/text_edge_body</item>
    <item name="android:textColor">@color/on_surface_variant</item>
  </style>
  <style name="TextAppearance.SnippetBoard.Label" parent="">
    <item name="android:fontFamily">sans-serif-medium</item>
    <item name="android:textSize">@dimen/text_label_medium</item>
    <item name="android:textColor">@color/on_surface</item>
  </style>

  <!-- Picker: Activity translucent + bottom sheet (T030/T043) -->
  <style name="Theme.SnippetBoard.Picker" parent="Theme.DeviceDefault.DayNight.Dialog.NoActionBar">
    <item name="android:windowIsTranslucent">true</item>
    <item name="android:windowBackground">@android:color/transparent</item>
    <item name="android:backgroundDimEnabled">true</item>
    <item name="android:colorAccent">@color/primary</item>
  </style>
</resources>
```

> `Theme.DeviceDefault.*` di perangkat Samsung otomatis mewarisi gaya One UI (dialog, tombol, switch). Pakai ini untuk dialog native, bukan tema Material Components, agar terlihat seperti dialog sistem Galaxy.

### 11.4 Drawable dasar

```xml
<!-- res/drawable/bg_card.xml : kartu Picker/Overlay -->
<ripple xmlns:android="http://schemas.android.com/apk/res/android" android:color="@color/surface_pressed">
  <item><shape><solid android:color="@color/surface"/><corners android:radius="@dimen/radius_card"/></shape></item>
</ripple>

<!-- res/drawable/bg_edge_card.xml : mini-card Edge (RemoteViews mendukung ripple/selector) -->
<ripple xmlns:android="http://schemas.android.com/apk/res/android" android:color="@color/surface_pressed">
  <item><shape><solid android:color="@color/surface"/><corners android:radius="@dimen/radius_edge_card"/></shape></item>
</ripple>

<!-- res/drawable/bg_pill.xml : chip & search pill -->
<ripple xmlns:android="http://schemas.android.com/apk/res/android" android:color="@color/surface_pressed">
  <item><shape><solid android:color="@color/chip_bg"/><corners android:radius="@dimen/radius_full"/></shape></item>
</ripple>
```

### 11.5 `ui/Tokens.kt` (nilai yang dipakai dari kode)

```kotlin
package id.snippetboard.app.ui

import android.view.animation.PathInterpolator

object Motion {
    const val PRESS_MS = 100L
    const val COPIED_MS = 240L
    const val COPIED_HOLD_MS = 1200L
    const val SHEET_IN_MS = 300L
    const val SHEET_OUT_MS = 200L
    val standard = PathInterpolator(0.22f, 0.25f, 0f, 1f)
    val decelerate = PathInterpolator(0f, 0f, 0.2f, 1f)
    val accelerate = PathInterpolator(0.4f, 0f, 1f, 1f)
}

object Category {
    // index = key DB kategori (data-model.md)
    val color = intArrayOf(R.color.cat_personal, R.color.cat_kerja, R.color.cat_rekening, R.color.cat_chat)
    val container = intArrayOf(R.color.cat_personal_container, R.color.cat_kerja_container,
        R.color.cat_rekening_container, R.color.cat_chat_container)
    val icon = intArrayOf(R.drawable.ic_person, R.drawable.ic_work, R.drawable.ic_account_balance, R.drawable.ic_chat_bubble)
    const val REKENING = 2
}
```

Haptic di `Copier` (T013):

```kotlin
val effect = if (Build.VERSION.SDK_INT >= 30) HapticFeedbackConstants.CONFIRM
             else HapticFeedbackConstants.KEYBOARD_TAP
view?.performHapticFeedback(effect) // tanpa FLAG_IGNORE_GLOBAL_SETTING → hormati setelan getaran
```

---

## 12. Referensi cepat Tailwind (mockup/prototipe saja)

Untuk mockup HTML/Figma-to-code di luar app (screenshot Galaxy Store, halaman privasi), token dipetakan:

| Token | Tailwind |
|---|---|
| `radiusCard` 26 | `rounded-[26px]` (bukan `rounded-3xl` = 24px) |
| `radiusEdgeCard` 18 | `rounded-[18px]` |
| `radiusFull` | `rounded-full` |
| background light/dark | `bg-[#F8F9FA] dark:bg-black` |
| surface | `bg-white dark:bg-[#121212]` |
| primary | `text-[#0C66E4] dark:text-[#3E91FF]` |
| space 8-grid | `p-2 / p-4 / p-6 / gap-2` (= 8/16/24/8 px) |

---

## 13. Checklist kepatuhan

- [ ] Tidak ada hex/ukuran/durasi mentah di `lib/ui/*.dart` dan layout XML (grep `Color(0x` hanya di `theme.dart`).
- [ ] Teks normal ≥ 4.5:1, ikon/batas kontrol ≥ 3:1 di light & dark (tabel §2.2).
- [ ] Semua target sentuh ≥ 48 dp, termasuk Edge Panel.
- [ ] Haptic salin hanya dari `Copier`; tidak ada `Vibrator` langsung; menghormati setelan sistem.
- [ ] Reduced motion: animasi mati, label "Disalin" tetap tampil.
- [ ] Font 200%: tidak ada teks terpotong di Home, Editor, Picker (T056).
- [ ] Font Samsung tidak dibundel ke APK tanpa lisensi.
- [ ] `surfaceTintColor` transparan di semua surface M3.
