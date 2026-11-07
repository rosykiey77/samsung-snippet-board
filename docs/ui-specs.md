# UI Specs — Samsung Snippet Board (One UI 6 / 7)

**Status**: Draft v1 · **Tanggal**: 2026-11-07
**Token**: semua nilai merujuk ke [design-system.md](design-system.md) (`§` = section di dokumen itu). **Requirement**: [spec.md](spec.md). **Task**: [tasks.md](tasks.md).

Notasi ukuran: dp untuk layout, sp untuk teks. "Light/Dark" = mode tema sistem.

---

## 1. Home (`lib/ui/home_page.dart` — T023, T034, T054)

### 1.1 Struktur

```
┌─────────────────────────────────────┐ ─┐
│                                     │  │
│                                     │  │  VIEWING AREA
│  Snippet                            │  │  clamp(33% tinggi, 200, 320) dp
│  7/10 snippet · Upgrade             │  │  judul headerLarge, kiri-bawah
│                          [🔍] [⋮]   │  │  baris aksi di DASAR area (terjangkau jempol)
├─────────────────────────────────────┤ ─┘
│ ( Cari snippet…                   ) │  search field (radiusField 18, tinggi 48)
│ [Semua][● Personal][● Kerja][● Rek… │  chip row — STICKY saat scroll
│ ┌─────────────────────────────────┐ │
│ │ [■] Alamat Rumah            📌  │ │  Quick Copy Card (§2)
│ │     Jl. Melati No. 12, RT 03…   │ │
│ └─────────────────────────────────┘ │  gap 8
│ ┌─────────────────────────────────┐ │
│ │ [■] BCA Pribadi          [👁]   │ │  kartu Rekening, termasking (§4)
│ │     •••• •••• 1234              │ │
│ └─────────────────────────────────┘ │
│                     ┌─────────────┐ │
│                     │ +  Tambah   │ │  FAB extended, 56 dp, kanan-bawah
│                     └─────────────┘ │  inset 16 + navigation bar
└─────────────────────────────────────┘
```

### 1.2 Perilaku header

| State | Tinggi | Isi |
|---|---|---|
| Expanded | viewing area (§4.2) | `headerLarge` "Snippet" + `headerSub` counter; aksi Search & Menu di baris dasar |
| Collapsing | interpolasi linear terhadap scroll | judul besar fade-out (opacity 1→0 pada 0–60% collapse), judul kecil fade-in (60–100%) |
| Collapsed | 64 dp | `titleBar` "Snippet" kiri, aksi kanan |

- Implementasi: `SliverAppBar(pinned: true, expandedHeight: viewingHeight, flexibleSpace: ...)`. **Jangan** pakai `SliverAppBar.large` (tinggi tetap 152 dp, bukan 1/3 layar) — ini mengubah detail T023.
- Snap: jika scroll berhenti di tengah collapse, animasikan ke state terdekat (`motionRelease`).
- Viewing area dinonaktifkan pada landscape / tinggi < 600 dp / pop-up / split / Flex mode (§4.2).
- Counter "x/10 snippet" hanya untuk pengguna gratis (FR-033); saat 10/10 teks counter berwarna `primary` dan menampilkan tautan "Upgrade". Pro: subjudul diganti jumlah total ("24 snippet").

### 1.3 Interaction area

- Margin horizontal 16, gap antar kartu 8, padding bawah daftar = tinggi FAB + 16 + inset nav bar (konten terakhir tidak tertutup FAB).
- Search field: tinggi 48, ikon `search` 20 kiri, tombol `close` 48×48 muncul saat ada teks. Filter real-time (debounce 150 ms), tidak peka huruf besar/kecil (FR-006).
- Chip row: lihat §3. Sticky di bawah toolbar collapsed (`SliverPersistentHeader(pinned: true)`).
- FAB: extended "Tambah" saat di puncak daftar, menyusut jadi FAB ikon 56×56 saat scroll ke bawah (`motionChip`), muncul lagi saat scroll ke atas. Saat batas gratis tercapai, FAB tetap aktif dan membuka Upgrade (T053).
- Font sistem 200%: `headerLarge` turun ke `titleLarge`, viewing area dibatasi 200 dp.

### 1.4 State kosong & hasil kosong

| Kondisi | Tampilan |
|---|---|
| Belum ada snippet | Ilustrasi squircle 96 dp (ikon `content_paste` 40 dp, `primaryContainer`), judul `titleLarge` "Belum ada snippet", body "Simpan teks yang sering kamu ketik, lalu salin dengan sekali ketuk.", tombol isi "Buat snippet pertama" (posisi di 2/3 bawah layar) |
| Filter/pencarian tanpa hasil | Teks `bodyMedium` "Tidak ada snippet untuk “{query}”" + tombol teks "Hapus filter" |

### 1.5 Hapus & urungkan (FR-005)

Snackbar floating (stadium, di atas FAB): "Snippet dihapus" + aksi "Urungkan", durasi 5 s. FAB naik mengikuti snackbar.

---

## 2. Quick Copy Card (`lib/ui/snippet_card.dart` — T022, T040)

### 2.1 Anatomi

```
┌──────────────────────────────────────────────┐  radius 26, surface, padding 16
│ ┌────┐  Judul snippet (titleMedium, 1 baris)  📌│  pin: iconSm 16 fill, primary
│ │ ■  │  Pratinjau isi, bodyMedium, maks 2     │
│ └────┘  baris, ellipsis…                [👁] │  tombol mata 48×48 (hanya Rekening)
│ 40dp    Disalin 2 jam lalu (labelSmall)       │  meta opsional
└──────────────────────────────────────────────┘
min-height 80 dp · gap ikon↔teks 16 · gap judul↔pratinjau 4
```

- Ikon kiri: squircle 40 dp, container kategori + ikon kategori 20 dp (§2.3, §5).
- Seluruh kartu adalah satu target ketuk (`InkWell` dengan `customBorder: OneUiRadius.cardShape`).
- Pratinjau menampilkan **teks mentah** (variabel tetap `{nama}`) dengan token variabel diberi warna `primary` agar terlihat sebagai placeholder.
- Pin: ikon `push_pin` fill hanya jika disematkan.

### 2.2 State & animasi salin

| # | State | Pemicu | Visual | Durasi |
|---|---|---|---|---|
| S0 | Idle | — | surface, skala 1 | — |
| S1 | Pressed | pointer down | skala 0.97, warna `surfacePressed` | `motionPress` 100 ms |
| S2 | Copying | tap up → `bridge.copySnippet` | kembali ke skala 1 (`oneUiSpring`); tidak ada spinner (operasi < 300 ms, SC-002) | `motionRelease` |
| S3 | **Copied** | hasil `copied` dari native | ikon squircle cross-fade → `check` di container `success` 16% ; baris pratinjau diganti teks `success` "Disalin" (labelLarge); border 2 dp `success` fade-in | `motionCopied` 240 ms |
| S4 | Hold | — | tetap S3 | `motionCopiedHold` 1200 ms |
| S5 | Revert | timer | kembali ke S0 | `motionRevert` 300 ms |
| SX | NeedsInput | hasil `needsInput` | kartu kembali S0, buka dialog variabel (§6) | — |
| SE | Error | exception native | snackbar "Gagal menyalin. Coba lagi." | — |

Aturan:
- **Haptic dipicu oleh native `Copier`** saat clipboard berhasil ditulis (design-system §8). Flutter tidak menambahkan haptic.
- **Tanpa snackbar/toast "Disalin" di dalam app**: umpan balik inline di kartu sudah cukup dan tidak menutupi FAB. Di Android 13+ sistem juga menampilkan overlay clipboard sendiri — itu perilaku sistem, tidak diduplikasi.
- Tap beruntun saat S3/S4: menyalin ulang, timer hold di-reset, haptic berbunyi lagi.
- Reduced motion: S1 tanpa skala (hanya warna), S3 langsung tanpa cross-fade.
- Aksesibilitas: setelah salin, panggil `SemanticsService.announce('Disalin: {judul}', textDirection)` (pada Rekening: "Disalin: {judul}, nomor disamarkan").

### 2.3 Tekan lama (FR-013)

Haptic `LONG_PRESS` → bottom sheet aksi (radius atas 26): "Edit", "Sematkan"/"Lepas sematan", "Hapus" (warna `error`). Setiap baris 56 dp, ikon 24 kiri. Hapus tidak meminta konfirmasi (ada Urungkan).

### 2.4 Semantics

```dart
Semantics(
  button: true,
  label: '$title. ${maskedOrPreview}. Kategori $categoryLabel${pinned ? ', disematkan' : ''}',
  hint: 'Ketuk dua kali untuk menyalin',
  onLongPressHint: 'Opsi lainnya',
  child: ...,
)
```

---

## 3. Category Pills (T034, T035, T036)

### 3.1 Anatomi

```
 ┌────────┐ ┌────────────┐ ┌─────────┐ ┌────────────┐ ┌────────────────┐
 │ Semua  │ │ ● Personal │ │ ● Kerja │ │ ● Rekening │ │ ● Template Chat│ →
 └────────┘ └────────────┘ └─────────┘ └────────────┘ └────────────────┘
 tinggi visual 36 · target 48 · padding-h 12 (16 tanpa dot) · gap 8 · StadiumBorder
```

| State | Latar | Teks | Leading |
|---|---|---|---|
| Unselected | `chip_bg` (`#EEF0F3` / `#1C1C1E`) | `onSurface`, labelMedium 600 | titik 8 dp warna kategori |
| Selected | `primaryFill` | `onPrimaryFill` | ikon `check` 18 dp menggantikan titik (status tidak hanya lewat warna) |
| Pressed | overlay `surfacePressed` / ripple | — | — |

- Single-select; "Semua" default. Ketuk chip terpilih (selain Semua) → kembali ke Semua.
- Horizontal scroll (`ListView(scrollDirection: Axis.horizontal)`), padding kiri 16 sehingga chip pertama sejajar kartu; fade-edge 16 dp di kanan sebagai petunjuk scroll.
- Saat dipilih: `HapticFeedback.selectionClick()`, chip auto-scroll ke tampak penuh (`Scrollable.ensureVisible`, `motionChip`).
- Label: ID "Semua, Personal, Kerja, Rekening, Template Chat"; EN "All, Personal, Work, Bank account, Chat templates".
- Semantics: `selected: true/false`, label "Filter {kategori}".

### 3.2 Pemilih kategori di Editor (T035)

Pills yang sama (tanpa "Semua"), dalam `Wrap` (bukan scroll) agar keempatnya terlihat. Default Personal (FR-009).

---

## 4. Sensitive Data Masking (kategori Rekening)

> Tambahan UI di atas FR-010. Masking **hanya tampilan**; isi yang disalin tetap teks final lengkap, dan clipboard tetap diberi flag sensitif oleh `Copier`. Bukan enkripsi (PIN/biometrik di luar cakupan v1).

### 4.1 Aturan masking

| Aturan | Detail |
|---|---|
| Berlaku untuk | `body` snippet kategori Rekening (key 2) dan nilai default `{rekening}` di Pengaturan |
| Pola yang dimasking | Deret digit (boleh dipisah spasi/`-`/`.`) berisi **≥ 6 digit** |
| Format | `•••• ` + 4 digit terakhir. Contoh: `1234567890` → `•••• 7890`; `0123-4567-8901` → `•••• 8901` |
| Teks lain | Tetap tampil (nama bank, "a.n. Budi") agar kartu tetap bisa dikenali |
| Judul | Tidak dimasking (pengguna yang menentukan judul) |
| Variabel `{rekening}` di pratinjau | Tetap tampil sebagai token `{rekening}` (nilai tidak diresolusi di pratinjau) |
| Angka | `FontFeature.tabularFigures()` / `android:fontFeatureSettings="tnum"`; titik `•` U+2022 |

Fungsi tunggal `maskSensitive(String body) → String` di Dart (dipakai Home/Editor) dan padanannya di Kotlin `core/Masker.kt` (dipakai Edge/Picker), keduanya dengan regex yang sama:

```
(?<!\d)\d(?:[ .\-]?\d){5,}(?!\d)
```

Wajib ada unit test di kedua sisi untuk: 6 digit, 16 digit berspasi, angka < 6 digit tidak dimasking, emoji/teks campuran.

### 4.2 Reveal

```
│ [■] BCA Pribadi                    [👁]  │   idle: termasking, ikon visibility
│     BCA •••• 7890 a.n. Budi              │
        ↓ ketuk mata (bukan kartu)
│ [■] BCA Pribadi                    [🚫👁]│   revealed: teks asli, ikon visibility_off
│     BCA 1234567890 a.n. Budi             │
```

- Tombol mata 48×48 di kanan kartu, terpisah dari area salin (kartu = salin, mata = lihat).
- Reveal per kartu, cross-fade `motionReveal`. Auto re-mask setelah **10 detik**, saat scroll keluar layar, atau saat app ke background (`AppLifecycleState.paused`).
- Menyalin **tidak** membuka masking; state "Disalin" tetap menampilkan versi termasking.
- Edge Panel, Picker, Overlay: **selalu termasking, tanpa tombol reveal** (ruang sempit, sering dipakai di depan orang lain).
- Semantics: label termasking dibacakan "nomor rekening disamarkan, berakhiran 7 8 9 0" (bukan "titik titik titik"); tombol mata: "Tampilkan nomor" / "Sembunyikan nomor".

---

## 5. Samsung Edge Panel (`res/layout/edge_panel.xml`, `edge_item.xml` — T026–T029, T036)

### 5.1 Batasan teknis yang membentuk desain

- Edge Panel dirender lewat **RemoteViews**: hanya `LinearLayout/FrameLayout/RelativeLayout`, `TextView`, `ImageView`, `ImageButton`, `ListView/GridView` (via `RemoteViewsService`). **Tidak ada `EditText`, `HorizontalScrollView`, animasi kustom, atau font kustom.**
- Lebar panel ditentukan sistem (One UI, `cocktailWidth`); desain harus **fluid 120–160 dp**, nominal 144 dp.
- Konsekuensi:
  - **Quick search** = *search pill* yang membuka `PickerActivity` mode `search` (keyboard langsung terbuka) di atas app aktif.
  - **Filter kategori** = satu *cycle chip* (bukan baris chip horizontal, yang tidak muat dan tidak bisa di-scroll di RemoteViews).
  - Umpan balik salin = haptic + konfirmasi dari `PickerActivity`/`Copier`, bukan animasi kartu.

### 5.2 Layout (lebar 144 dp)

```
┌────────────────────┐  bg surface_container_high, padding 8
│ Snippet        [+] │  header: edgeTitle 14sp 600 + ImageButton 48×48 "Tambah"
│ ┌────────────────┐ │
│ │ 🔍 Cari        │ │  SEARCH PILL — tinggi 40 (target 48), bg_pill
│ └────────────────┘ │   → PickerActivity(mode=search)
│ ┌────────────────┐ │
│ │ ● Semua      ⟳ │ │  CYCLE CHIP — tinggi 40 (target 48), bg_pill
│ └────────────────┘ │   ketuk → kategori berikutnya (§5.4)
│ ┌────────────────┐ │
│ │ ■ Alamat Rumah │ │  MINI-CARD — ListView 1 kolom, gap 8
│ │ Jl. Melati No. │ │   radius 18, padding 12
│ │ 12, RT 03…     │ │
│ └────────────────┘ │
│ ┌────────────────┐ │
│ │ ■ BCA Pribadi  │ │
│ │ BCA •••• 7890  │ │  Rekening: selalu termasking
│ └────────────────┘ │
│        ⋮           │
│ ┌────────────────┐ │
│ │   Buka app     │ │  footer: tombol teks primary, tinggi 48
│ └────────────────┘ │
└────────────────────┘
```

### 5.3 Mini-card (`edge_item.xml`)

| Elemen | Spesifikasi |
|---|---|
| Container | `match_parent` × wrap, min-height 64, `bg_edge_card` (radius 18, ripple), padding 12 |
| Baris 1 | titik kategori 8 dp (`ImageView` tint warna kategori) + gap 4 + judul `EdgeTitle` 14sp, `maxLines=1`, ellipsize end; ikon pin 12 dp jika disematkan |
| Baris 2 | pratinjau `EdgeBody` 12sp, `maxLines=2` (spec edge case "potongan 2 baris"), sudah melalui `Masker` |
| Klik | `setOnClickFillInIntent` → template `PickerActivity(mode=copy, id)` |
| Urutan | pinned → terakhir disalin → dibuat (FR-004) |
| Batas item | 50 teratas; sisanya lewat search pill |
| contentDescription | "{judul}. Ketuk untuk menyalin" (+ ", nomor disamarkan" untuk Rekening) |

Pada lebar 120 dp: titik kategori disembunyikan jika judul < 6 karakter terlihat (cukup tetap ditampilkan; ellipsis menangani). Tidak ada perubahan layout per lebar selain wrap teks.

### 5.4 Cycle chip kategori (T036)

- Urutan: Semua → Personal → Kerja → Rekening → Chat → Semua.
- Label = kategori aktif (label pendek §2.3 design-system) + titik warna kategori; ikon `swap_vert` 16 dp di kanan sebagai petunjuk "ketuk untuk ganti".
- Klik → broadcast ke `SnippetEdgeProvider` → simpan kategori aktif → `notifyCocktailViewDataChanged`.
- contentDescription: "Filter: {kategori}. Ketuk untuk kategori berikutnya".

### 5.5 Alur salin dari Edge Panel

```
ketuk mini-card ──► PickerActivity(copy, id)  [translucent, tanpa UI jika tidak perlu]
                     ├─ tanpa variabel kosong ─► Copier: clipboard + flag sensitif + haptic CONFIRM
                     │                            ├─ API ≤ 32: Toast "Disalin" 
                     │                            └─ API ≥ 33: andalkan konfirmasi clipboard sistem
                     │                           ► finish()  (app aktif tetap di depan)
                     └─ ada variabel kosong ──► Dialog variabel native (§6.2) ─► Copier ─► finish()
```

Target SC-001: ≤ 2 ketukan (buka panel + ketuk kartu), ≤ 3 detik.

### 5.6 State khusus

| State | Tampilan |
|---|---|
| Kosong | Ikon squircle 40 dp + teks `EdgeBody` "Belum ada snippet" + tombol "Buat" 48 dp → MainActivity |
| Filter kosong | "Tidak ada di {kategori}" + cycle chip tetap aktif |
| Dark | warna dari `values-night` otomatis; panel memakai `#1C1C1E`, kartu `#121212` |

---

## 6. Dialog isian variabel (FR-017 — T039, T042)

### 6.1 Flutter (`variable_dialog.dart`)

```
┌──────────────────────────────────┐  dialog One UI: di BAGIAN BAWAH layar (thumb zone)
│ Lengkapi variabel                │  titleLarge, padding 24
│                                  │
│ Nama                             │  label terlihat di atas field (bukan placeholder-only)
│ ( Budi                         ) │  field 48, radius 18, autofocus field pertama
│ Nomor rekening                   │
│ ( 1234567890                   ) │  keyboardType number
│ ☐ Simpan sebagai nilai default   │  checkbox 48 dp target
│                                  │
│   Batal      │      Salin        │  2 tombol teks sama lebar, primary utk "Salin"
└──────────────────────────────────┘
```

- Posisi: `showModalBottomSheet`-style dialog melayang di bawah (margin 16 kiri/kanan/bawah + inset keyboard), radius 26 semua sudut.
- "Salin" nonaktif selama ada field kosong. Enter di field terakhir = Salin.
- Batal / back / tap scrim → tidak menyalin (haptic `REJECT` dari native tidak diperlukan di app; cukup tutup).
- Field `{rekening}` termasking saat tidak fokus (§4.1).
- Opsi "Simpan sebagai nilai default" adalah tambahan opsional UI; jika tidak dibangun di v1, hilangkan barisnya tanpa mengubah layout lain.

### 6.2 Native (`PickerActivity`, T042)

`AlertDialog` dengan `Theme.DeviceDefault.DayNight.Dialog` (otomatis gaya dialog One UI: posisi bawah, tombol teks). Isi sama seperti 6.1; tanpa checkbox default.

---

## 7. Picker sheet (Tile & Overlay — T043; mode search dari Edge)

```
┌─────────────────────────────────────┐ ← scrim 40/60%
│              ───                    │ drag handle 32×4
│  Pilih snippet                   ✕  │ titleLarge + close 48
│ ( 🔍 Cari snippet…                ) │ EditText 48, autofocus HANYA di mode search
│ [Semua][● Personal][● Kerja]…  →    │ chip row (RecyclerView horizontal — boleh di Activity)
│ ┌─────────────────────────────────┐ │
│ │ ■ Alamat Rumah                  │ │ kartu ringkas: radius 26, min-height 72
│ │   Jl. Melati No. 12…            │ │ pratinjau 1 baris
│ └─────────────────────────────────┘ │
│              …                      │
└─────────────────────────────────────┘
tinggi: wrap, maks 70% layar · radius atas 26 · masuk 300 ms decelerate dari bawah
```

- Ketuk kartu → `Copier` → haptic → sheet keluar (`motionSheetOut` 200 ms) → `finish()`.
- Rekening selalu termasking, tanpa reveal.
- Back / swipe-down / tap scrim → tutup tanpa menyalin.
- Kosong: sama seperti §5.6 dengan tombol "Buka app".

---

## 8. Floating overlay bubble (T045)

| Elemen | Spesifikasi |
|---|---|
| Bubble | squircle 56 dp, `primaryFill`, ikon app glyph 24 dp putih, bayangan `e2` (light) |
| Idle | setelah 3 s tanpa interaksi: opacity 0.6 dan bergeser setengah ke luar tepi (setengah terlihat) |
| Drag | opacity 1, skala 1.05; saat dilepas snap ke tepi kiri/kanan terdekat (`oneUiSpring`) + haptic `CLOCK_TICK`; posisi Y disimpan |
| Tutup | saat drag dimulai, target "tutup" muncul di tengah bawah: lingkaran 64 dp `surface_container_high` + ikon `close`; bubble masuk radius 80 dp → target membesar 1.2 + haptic `LONG_PRESS`; lepas → overlay mati |
| Tap | buka Picker sheet (§7) |
| contentDescription | "Quick Snippet. Ketuk untuk membuka daftar snippet" |

Hindari area: status bar, navigation bar/gesture, dan display cutout (`WindowInsets`).

---

## 9. Editor (`editor_page.dart` — T024, T035, T041)

```
 ← Snippet baru                        Simpan    toolbar 64 (aksi "Simpan" juga di bawah)
 Judul
 ( Alamat Rumah                          12/80 )  field 48+, counter labelSmall
 Kategori
 [● Personal][● Kerja][● Rekening][● Template Chat]   Wrap pills (§3.2)
 Isi
 ┌───────────────────────────────────────────┐
 │ Halo {nama}, alamat saya …                │  multiline, min 6 baris, radius 18
 └───────────────────────────────────────────┘
                                    120/10.000
 Sisipkan variabel                                labelMedium, onSurfaceVariant
 [ {nama} ] [ {tanggal} ] [ {rekening} ]          ActionChip, sisip di kursor (FR-018)
 ┌───────────────────────────────────────────┐
 │                 Simpan                     │  tombol isi 56, stadium, sticky di atas keyboard
 └───────────────────────────────────────────┘
```

- Validasi inline di bawah field (warna `error`, ikon `error` 16): isi kosong/spasi → "Isi tidak boleh kosong". Judul kosong → otomatis dari 30 karakter pertama (tampilkan sebagai hint).
- Token variabel di field isi disorot `primaryContainer` (Flutter: `TextEditingController.buildTextSpan` override).
- Back dengan perubahan belum disimpan → dialog "Buang perubahan?" (Buang / Lanjut edit).

---

## 10. Layar sekunder

### 10.1 Pengaturan (T038, T048, T054, T057)

Pola One UI: header besar (viewing area sama dengan Home), lalu **grup kartu** radius 26 berisi baris 64 dp dengan divider inset 16 (`outline`).

| Grup | Baris |
|---|---|
| Variabel | Nama default · Nomor rekening default (termasking) |
| Tampilan | Warna dari wallpaper (switch, default on — design-system §2.4) |
| Akses cepat | Edge Panel (status + cara aktifkan, disembunyikan bila tidak didukung) · Tambah Quick Settings tile · Tombol mengambang (switch + dialog penjelasan izin, FR-023) |
| Pro | Status Pro / Upgrade · Pulihkan pembelian |
| Tentang | Privasi (offline, tanpa pelacakan) · Versi |

### 10.2 Upgrade (T052)

- Viewing area: ikon squircle 72 dp `primaryContainer` + `headerLarge` "Snippet Pro".
- Interaction area: 3 baris manfaat (ikon 24 + `bodyLarge`): "Snippet tanpa batas", "Sekali bayar, selamanya", "Tetap 100% offline".
- Tombol isi 56 stadium "Beli {harga lokal}" di dasar layar; di bawahnya tombol teks "Pulihkan pembelian".
- Loading harga: skeleton pill 120×20 di tombol; Galaxy Store tidak ada: tombol nonaktif + pesan "Pembelian memerlukan Galaxy Store".

### 10.3 Onboarding (T049)

2–3 halaman, ilustrasi di 1/3 atas, teks + tombol di 2/3 bawah, indikator titik, tombol "Lewati" kanan atas dan "Lanjut" stadium 56 di bawah. Halaman akses cepat bercabang: Edge Panel didukung → panduan aktifkan panel; tidak → kartu Tile & Overlay (FR-025).

---

## 11. Aksesibilitas & kualitas (wajib sebelum rilis — T056)

- [ ] TalkBack: urutan fokus = urutan visual; setiap kartu punya label + hint salin; masking dibacakan sebagai "berakhiran …".
- [ ] Pengumuman "Disalin" via `SemanticsService.announce` (Flutter) / `announceForAccessibility` (native, termasuk Picker).
- [ ] Target sentuh ≥ 48 dp di semua permukaan, termasuk tombol mata, cycle chip, dan tombol "+" Edge.
- [ ] Font sistem 200%: header turun ke `titleLarge`, kartu tumbuh vertikal, tidak ada teks terpotong kecuali pratinjau yang memang `maxLines`.
- [ ] Kontras sesuai tabel design-system §2.2 di light & dark; status terpilih tidak hanya lewat warna (ikon check di chip).
- [ ] Reduced motion dihormati; haptic mengikuti setelan getaran sistem (spec US1 skenario 3).
- [ ] Safe area: FAB, snackbar, dialog bawah, dan bubble tidak bertabrakan dengan navigation bar / gesture / keyboard.
- [ ] Edge Panel diuji pada lebar 120, 144, dan 160 dp, light & dark.
- [ ] Data Rekening tidak pernah tampil tanpa masking di Edge Panel, Picker, Overlay.

---

## 12. Dampak ke tasks.md

Spesifikasi ini mengubah/menambah detail pada task yang ada (tanpa task baru kecuali masking):

| Task | Perubahan |
|---|---|
| T020 | Fallback seed bukan satu warna: pakai `buildOneUiTheme` (design-system §10); netral tetap, hanya primary dinamis |
| T022 | State salin S0–S5 (§2.2), tombol mata untuk Rekening, semantics §2.4 |
| T023 | `SliverAppBar` kustom dengan viewing area 1/3 layar, **bukan** `SliverAppBar.large` |
| T026 / T036 | Search pill + cycle chip (§5.2–5.4) karena batasan RemoteViews |
| T013 | Haptic `CONFIRM`/`KEYBOARD_TAP`; toast hanya API ≤ 32 |
| Baru | `maskSensitive` (Dart) + `Masker.kt` (Kotlin) + unit test kedua sisi (§4.1) |
