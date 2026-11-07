# Feature Specification: One UI Quick Snippet & Clipboard (Edge Panel)

**Feature Branch**: `main` (spec directory: `docs/`)

**Created**: 2026-11-07

**Status**: Draft

**Input**: User description: "One UI Quick Snippet & Clipboard with Samsung Edge Panel integration untuk Galaxy Store. Fitur wajib: 1-tap copy dengan haptic feedback & UI One UI / Material You; kategori snippet (Personal, Kerja, Rekening, Template Chat); variabel dinamis sederhana ({nama}, {tanggal}, {rekening}); integrasi Samsung Edge Panel (via Slook / Native RemoteViews Kotlin) + fallback Quick Settings Tile & Floating Overlay; arsitektur 100% offline (SQLite / drift lokal, zero telemetry); monetisasi In-App Purchase Galaxy Store (Free limit 10 snippet, Pro lifetime unlimited)."

## Ringkasan

Aplikasi Android untuk pengguna Samsung Galaxy yang sering mengetik teks berulang (nomor rekening, alamat, template balasan chat, salam kerja). Pengguna menyimpan teks sebagai *snippet*, mengelompokkannya per kategori, lalu menyalinnya ke clipboard dengan satu ketukan — dari dalam aplikasi, dari Edge Panel Samsung, dari Quick Settings Tile, atau dari tombol mengambang (floating overlay) — tanpa meninggalkan aplikasi yang sedang dipakai. Seluruh data tersimpan di perangkat, tanpa akun, tanpa jaringan, tanpa pelacakan.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Simpan & salin snippet dengan 1 ketukan (Priority: P1)

Pengguna membuka aplikasi, membuat snippet (judul + isi teks + kategori), lalu mengetuk kartu snippet tersebut. Isi teks langsung tersalin ke clipboard, perangkat bergetar singkat, dan muncul konfirmasi visual singkat "Disalin". Tampilan mengikuti gaya One UI (header besar, area sentuh di bagian bawah layar) dan warna dinamis Material You dari wallpaper.

**Why this priority**: Ini nilai inti produk. Tanpa simpan-dan-salin, fitur lain tidak berarti. Sudah layak dirilis sebagai MVP.

**Independent Test**: Instal aplikasi, buat 1 snippet, ketuk → tempel di aplikasi lain (mis. pesan) → teks identik muncul; getaran terasa.

**Acceptance Scenarios**:

1. **Given** daftar snippet kosong, **When** pengguna membuat snippet "Alamat Rumah" berisi teks alamat, **Then** snippet tampil di daftar dan tetap ada setelah aplikasi ditutup dan dibuka ulang.
2. **Given** ada snippet tersimpan, **When** pengguna mengetuk kartunya sekali, **Then** isi teks berada di clipboard, getaran haptic singkat terjadi, dan konfirmasi "Disalin" tampil ≤ 2 detik.
3. **Given** getaran sistem dimatikan pengguna di pengaturan perangkat, **When** snippet diketuk, **Then** teks tetap tersalin tanpa getaran dan konfirmasi visual tetap muncul.
4. **Given** ada snippet, **When** pengguna mengedit atau menghapusnya, **Then** perubahan langsung tercermin di semua permukaan akses (aplikasi, Edge Panel, tile, overlay).
5. **Given** perangkat memakai tema gelap atau warna wallpaper tertentu, **When** aplikasi dibuka, **Then** palet warna aplikasi mengikuti tema dan warna sistem.

---

### User Story 2 - Akses snippet dari Samsung Edge Panel (Priority: P1)

Pengguna menambahkan panel "Quick Snippet" ke Edge Panel Samsung. Saat sedang di aplikasi lain (mis. WhatsApp, m-banking), pengguna menggeser handle Edge Panel, melihat snippet favorit/terbaru, dan mengetuk satu snippet untuk menyalinnya — tanpa membuka aplikasi utama.

**Why this priority**: Pembeda utama produk di Galaxy Store; alasan pengguna memilih aplikasi ini dibanding clipboard manager biasa.

**Independent Test**: Di perangkat Galaxy yang mendukung Edge Panel, aktifkan panel, buka aplikasi lain, geser panel, ketuk snippet → tempel → teks benar.

**Acceptance Scenarios**:

1. **Given** perangkat mendukung Edge Panel dan panel sudah diaktifkan, **When** pengguna membuka panel, **Then** tampil daftar snippet (disematkan dulu, lalu yang paling sering/terakhir dipakai) dengan filter kategori.
2. **Given** panel terbuka, **When** pengguna mengetuk snippet, **Then** teks tersalin, ada getaran haptic, dan konfirmasi singkat tampil; aplikasi yang sedang dipakai tetap di depan.
3. **Given** snippet mengandung variabel yang belum punya nilai, **When** diketuk dari panel, **Then** muncul dialog isian ringkas di atas aplikasi aktif; setelah diisi teks final tersalin.
4. **Given** pengguna menambah/mengubah snippet di aplikasi, **When** panel dibuka berikutnya, **Then** isinya sudah terbarui.

---

### User Story 3 - Kategori snippet (Priority: P2)

Snippet dikelompokkan ke kategori bawaan: **Personal**, **Kerja**, **Rekening**, **Template Chat**. Pengguna memfilter daftar berdasarkan kategori dan mencari snippet berdasarkan judul/isi.

**Why this priority**: Saat jumlah snippet bertambah, pengelompokan dan pencarian menjaga akses tetap cepat; kategori Rekening juga menentukan perlakuan data sensitif.

**Independent Test**: Buat snippet di 4 kategori, pilih filter "Rekening" → hanya snippet rekening tampil; cari kata kunci → hasil sesuai.

**Acceptance Scenarios**:

1. **Given** snippet di beberapa kategori, **When** pengguna memilih satu kategori, **Then** hanya snippet kategori itu yang tampil, di aplikasi maupun di Edge Panel.
2. **Given** snippet berkategori Rekening disalin, **When** sistem menampilkan pratinjau clipboard, **Then** isinya ditandai sensitif sehingga disamarkan di pratinjau sistem (pada versi Android yang mendukung).
3. **Given** pengguna mengetik kata kunci di pencarian, **When** hasil tampil, **Then** snippet yang judul atau isinya mengandung kata kunci (tanpa membedakan huruf besar/kecil) tampil.
4. **Given** snippet dibuat tanpa memilih kategori, **Then** snippet masuk ke kategori Personal.

---

### User Story 4 - Variabel dinamis (Priority: P2)

Isi snippet dapat memuat variabel `{nama}`, `{tanggal}`, dan `{rekening}`. Saat disalin, variabel diganti nilai sebenarnya: `{tanggal}` otomatis tanggal hari ini; `{nama}` dan `{rekening}` diambil dari nilai default yang disimpan pengguna di Pengaturan, atau ditanyakan saat menyalin jika belum diisi.

**Why this priority**: Membuat template chat dan pesan transfer benar-benar siap kirim tanpa edit manual; nilai tambah besar dengan cakupan kecil.

**Independent Test**: Buat snippet "Halo {nama}, mohon transfer ke {rekening} sebelum {tanggal}", isi nilai default, ketuk → teks tertempel dengan semua variabel terganti.

**Acceptance Scenarios**:

1. **Given** snippet berisi `{tanggal}`, **When** disalin pada 7 November 2026 dengan bahasa perangkat Indonesia, **Then** teks hasil berisi "7 November 2026" (format tanggal panjang sesuai bahasa perangkat).
2. **Given** nilai default `{nama}` dan `{rekening}` sudah diisi di Pengaturan, **When** snippet disalin, **Then** variabel diganti tanpa dialog tambahan.
3. **Given** nilai default `{nama}` kosong, **When** snippet berisi `{nama}` disalin, **Then** muncul dialog isian; pengguna bisa mengisi lalu menyalin, atau membatalkan (tidak ada yang disalin).
4. **Given** teks berisi kurung kurawal yang bukan variabel dikenal (mis. `{harga}`), **When** disalin, **Then** teks tersebut dibiarkan apa adanya.
5. **Given** editor snippet terbuka, **When** pengguna mengetuk tombol sisip variabel, **Then** variabel tersisip di posisi kursor.

---

### User Story 5 - Fallback: Quick Settings Tile & Floating Overlay (Priority: P3)

Untuk perangkat tanpa Edge Panel (atau pengguna yang mematikannya), pengguna dapat (a) menambahkan tile "Quick Snippet" di panel notifikasi yang membuka pemilih snippet ringkas, dan/atau (b) mengaktifkan tombol mengambang yang dapat diseret di atas aplikasi lain dan membuka daftar snippet mini saat diketuk.

**Why this priority**: Memperluas jangkauan ke perangkat Galaxy lama/murah dan non-Samsung, tetapi bukan pembeda utama.

**Independent Test**: Tambahkan tile → ketuk tile → pilih snippet → tempel di aplikasi lain. Aktifkan overlay → beri izin tampil di atas aplikasi → ketuk gelembung → pilih snippet → tempel.

**Acceptance Scenarios**:

1. **Given** tile sudah ditambahkan, **When** pengguna mengetuknya, **Then** panel notifikasi menutup dan pemilih snippet ringkas tampil; mengetuk snippet menyalin teks dan menutup pemilih.
2. **Given** pengguna mengaktifkan overlay pertama kali, **When** izin tampil di atas aplikasi belum diberikan, **Then** aplikasi menjelaskan alasan izin dan mengarahkan ke halaman izin sistem; jika ditolak, overlay tetap nonaktif tanpa crash.
3. **Given** overlay aktif, **When** pengguna menyeret gelembung, **Then** gelembung menempel ke tepi layar terdekat dan posisinya diingat.
4. **Given** overlay aktif, **When** pengguna menyeret gelembung ke area "tutup", **Then** overlay mati sampai diaktifkan lagi.
5. **Given** perangkat tidak mendukung Edge Panel, **When** onboarding berjalan, **Then** pengguna ditawari tile dan overlay sebagai gantinya.

---

### User Story 6 - Upgrade ke Pro via Galaxy Store (Priority: P3)

Versi gratis menyimpan maksimal 10 snippet. Saat batas tercapai, pengguna ditawari upgrade **Pro (lifetime, sekali bayar)** lewat In-App Purchase Galaxy Store, yang membuka batas menjadi tak terbatas. Pembelian dapat dipulihkan setelah instal ulang atau di perangkat lain dengan akun Samsung yang sama.

**Why this priority**: Sumber pendapatan; namun aplikasi sudah bermanfaat tanpa ini, sehingga diimplementasi setelah fitur inti stabil.

**Independent Test**: Buat 10 snippet → coba buat ke-11 → layar upgrade tampil → beli (mode uji) → snippet ke-11 tersimpan. Instal ulang → "Pulihkan pembelian" → status Pro kembali.

**Acceptance Scenarios**:

1. **Given** pengguna gratis punya 10 snippet, **When** mencoba membuat snippet baru, **Then** layar upgrade tampil berisi harga lokal dari Galaxy Store, dan snippet tidak dibuat sampai upgrade berhasil.
2. **Given** pembelian berhasil, **Then** status Pro aktif seketika, tanpa restart, dan batas snippet hilang.
3. **Given** pembelian dibatalkan atau gagal, **Then** pengguna kembali ke layar sebelumnya dengan pesan yang jelas dan data tidak berubah.
4. **Given** pengguna Pro menginstal ulang aplikasi, **When** memilih "Pulihkan pembelian", **Then** status Pro kembali.
5. **Given** perangkat sedang offline, **When** pengguna Pro membuka aplikasi, **Then** status Pro tetap berlaku (disimpan di perangkat dari verifikasi terakhir).
6. **Given** pengguna gratis, **Then** penghitung "x/10 snippet" terlihat di layar utama.

---

### Edge Cases

- **Snippet kosong**: isi teks kosong/hanya spasi tidak boleh disimpan; judul kosong diisi otomatis dari 30 karakter pertama isi.
- **Teks sangat panjang**: snippet hingga 10.000 karakter didukung; kartu dan Edge Panel menampilkan potongan 2 baris.
- **Emoji & karakter non-Latin**: tersalin utuh tanpa kerusakan karakter.
- **Status Pro dicabut** (refund) saat pengguna punya > 10 snippet: semua snippet tetap tersimpan dan bisa disalin/diedit/dihapus, tetapi snippet baru tidak bisa dibuat sampai jumlah < 10 atau upgrade lagi. Data tidak pernah dihapus otomatis.
- **Galaxy Store tidak terpasang / tidak tersedia** (mis. perangkat non-Samsung): tombol upgrade menampilkan pesan bahwa pembelian memerlukan Galaxy Store; fitur gratis tetap berfungsi penuh.
- **Edge Panel tidak didukung** (perangkat non-Samsung atau One UI lama): opsi Edge Panel disembunyikan; tile dan overlay ditawarkan.
- **Daftar kosong** di Edge Panel/tile/overlay: tampil pesan "Belum ada snippet" dengan aksi membuka aplikasi untuk membuat snippet.
- **Izin overlay dicabut** saat overlay aktif: overlay berhenti dengan aman; pengaturan menampilkan status nonaktif.
- **Hapus tidak sengaja**: setelah menghapus, tersedia aksi "Urungkan" selama ±5 detik.
- **Mode hemat daya / aplikasi dihentikan sistem**: Edge Panel dan tile tetap dapat menyalin tanpa aplikasi utama berjalan.
- **Variabel dengan nilai berisi kurung kurawal**: nilai dimasukkan apa adanya dan tidak diproses ulang sebagai variabel.

## Requirements *(mandatory)*

### Functional Requirements

**Manajemen snippet**

- **FR-001**: Pengguna MUST dapat membuat, melihat, mengedit, dan menghapus snippet berisi judul, isi teks (maks. 10.000 karakter), dan satu kategori.
- **FR-002**: Sistem MUST menyimpan snippet secara permanen di perangkat sehingga tetap ada setelah aplikasi ditutup, perangkat di-restart, atau aplikasi diperbarui.
- **FR-003**: Pengguna MUST dapat menyematkan (pin) snippet agar tampil paling atas di semua permukaan akses.
- **FR-004**: Sistem MUST mengurutkan snippet: disematkan dulu, lalu berdasarkan waktu terakhir disalin (terbaru dulu), lalu waktu dibuat.
- **FR-005**: Sistem MUST menyediakan aksi "Urungkan" setelah penghapusan snippet selama ±5 detik.
- **FR-006**: Pengguna MUST dapat mencari snippet berdasarkan judul atau isi (tanpa membedakan huruf besar/kecil).

**Kategori**

- **FR-007**: Sistem MUST menyediakan tepat empat kategori bawaan: Personal, Kerja, Rekening, Template Chat. Kategori kustom di luar cakupan v1.
- **FR-008**: Pengguna MUST dapat memfilter daftar snippet per kategori di aplikasi dan di Edge Panel.
- **FR-009**: Snippet tanpa kategori pilihan MUST masuk ke Personal.
- **FR-010**: Saat snippet berkategori Rekening disalin, sistem MUST menandai isi clipboard sebagai sensitif agar disamarkan di pratinjau clipboard sistem (pada versi Android yang mendukung penanda ini).

**Salin 1-ketuk & umpan balik**

- **FR-011**: Satu ketukan pada snippet di permukaan mana pun MUST menyalin teks final ke clipboard sistem.
- **FR-012**: Setiap penyalinan berhasil MUST disertai getaran haptic singkat (menghormati pengaturan getaran sistem) dan konfirmasi visual singkat.
- **FR-013**: Tekan lama pada snippet di aplikasi MUST membuka aksi tambahan (edit, sematkan, hapus).

**Variabel dinamis**

- **FR-014**: Sistem MUST mengenali tepat tiga variabel: `{nama}`, `{tanggal}`, `{rekening}`; teks dalam kurung kurawal lain dibiarkan apa adanya.
- **FR-015**: `{tanggal}` MUST diganti tanggal hari ini dalam format tanggal panjang sesuai bahasa perangkat.
- **FR-016**: Pengguna MUST dapat menyimpan nilai default `{nama}` dan `{rekening}` di Pengaturan.
- **FR-017**: Jika variabel yang dipakai tidak punya nilai default, sistem MUST menampilkan dialog isian sebelum menyalin (juga saat dipicu dari Edge Panel/tile/overlay); membatalkan dialog MUST tidak menyalin apa pun.
- **FR-018**: Editor snippet MUST menyediakan tombol sisip variabel pada posisi kursor.

**Permukaan akses**

- **FR-019**: Pada perangkat Samsung yang mendukung Edge Panel, sistem MUST menyediakan panel Edge berisi daftar snippet yang dapat disalin dengan 1 ketukan tanpa membuka aplikasi utama.
- **FR-020**: Edge Panel MUST menampilkan filter kategori dan tombol untuk membuka aplikasi/menambah snippet.
- **FR-021**: Sistem MUST menyediakan Quick Settings Tile yang membuka pemilih snippet ringkas di atas aplikasi aktif.
- **FR-022**: Sistem MUST menyediakan tombol mengambang opsional (nonaktif secara default) yang dapat diseret, menempel ke tepi, mengingat posisinya, dan membuka daftar snippet mini.
- **FR-023**: Sebelum meminta izin tampil di atas aplikasi lain, sistem MUST menjelaskan alasannya; penolakan izin MUST ditangani tanpa crash.
- **FR-024**: Perubahan data snippet MUST tercermin di semua permukaan akses paling lambat saat permukaan itu dibuka berikutnya.
- **FR-025**: Onboarding MUST mendeteksi dukungan Edge Panel dan menawarkan permukaan yang sesuai.

**Tampilan**

- **FR-026**: UI MUST mengikuti pola One UI (header besar yang menyusut saat di-scroll, kontrol utama di separuh bawah layar) dan memakai warna dinamis sistem bila tersedia, dengan palet bawaan sebagai cadangan.
- **FR-027**: UI MUST mendukung tema terang dan gelap mengikuti sistem, ukuran font sistem, serta pembaca layar (setiap snippet punya label yang dapat dibacakan).
- **FR-028**: Bahasa UI MUST tersedia dalam Bahasa Indonesia dan Inggris, mengikuti bahasa perangkat.

**Privasi & offline**

- **FR-029**: Aplikasi MUST berfungsi penuh tanpa koneksi internet dan MUST NOT mengirim data apa pun ke server (tanpa analitik, crash reporting jarak jauh, iklan, atau akun).
- **FR-030**: Satu-satunya komunikasi eksternal yang diizinkan adalah alur pembelian/verifikasi yang ditangani aplikasi Galaxy Store di perangkat.
- **FR-031**: Sistem MUST NOT membaca atau memantau clipboard; aplikasi hanya menulis ke clipboard saat pengguna mengetuk snippet.
- **FR-032**: Data snippet MUST tidak dapat diakses aplikasi lain.

**Monetisasi**

- **FR-033**: Pengguna gratis MUST dibatasi maksimal 10 snippet tersimpan; penghitung "x/10" MUST terlihat.
- **FR-034**: Saat batas tercapai dan pengguna mencoba menambah snippet, sistem MUST menampilkan layar upgrade dengan harga lokal dari Galaxy Store.
- **FR-035**: Pembelian Pro (lifetime, non-consumable, sekali bayar) MUST membuka jumlah snippet tak terbatas seketika.
- **FR-036**: Pengguna MUST dapat memulihkan pembelian Pro.
- **FR-037**: Status Pro MUST tetap berlaku saat offline berdasarkan verifikasi terakhir yang berhasil.
- **FR-038**: Jika status Pro dicabut, sistem MUST NOT menghapus snippet apa pun; hanya pembuatan snippet baru di atas batas yang diblokir.
- **FR-039**: Semua fitur selain batas jumlah snippet (kategori, variabel, Edge Panel, tile, overlay) MUST tersedia di versi gratis.

### Key Entities

- **Snippet**: satu teks yang dapat disalin. Atribut: judul, isi teks (boleh mengandung variabel), kategori, status disematkan, waktu dibuat, waktu diubah, waktu terakhir disalin, jumlah disalin.
- **Kategori**: salah satu dari empat nilai tetap (Personal, Kerja, Rekening, Template Chat). Rekening menandai isi sebagai sensitif.
- **Nilai Variabel**: nilai default milik pengguna untuk `{nama}` dan `{rekening}`. `{tanggal}` tidak disimpan (dihitung saat menyalin).
- **Status Kepemilikan (Entitlement)**: gratis atau Pro, beserta waktu verifikasi terakhir.
- **Preferensi Permukaan**: status overlay aktif/nonaktif, posisi gelembung terakhir, onboarding selesai.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Pengguna dapat menyalin snippet dari Edge Panel saat berada di aplikasi lain dalam ≤ 2 ketukan dan ≤ 3 detik total.
- **SC-002**: Waktu dari ketukan sampai teks tersedia di clipboard dan getaran terasa ≤ 300 ms pada perangkat Galaxy kelas menengah.
- **SC-003**: Aplikasi terbuka ke daftar snippet siap pakai dalam ≤ 1,5 detik (cold start) pada perangkat Galaxy kelas menengah.
- **SC-004**: Pengguna baru dapat membuat dan menyalin snippet pertama dalam ≤ 60 detik tanpa panduan eksternal.
- **SC-005**: 0 permintaan jaringan dihasilkan aplikasi selama penggunaan normal (diverifikasi dengan pemantauan lalu lintas), selain alur pembelian Galaxy Store.
- **SC-006**: 100% teks tersalin identik dengan teks yang diharapkan (termasuk emoji dan substitusi variabel) dalam uji regresi.
- **SC-007**: Tingkat crash-free sessions ≥ 99,5% (diukur via laporan Galaxy Store / uji internal, bukan telemetri aplikasi).
- **SC-008**: Lolos review Galaxy Store pada pengajuan pertama atau kedua.
- **SC-009**: ≥ 3% pengguna aktif gratis melakukan upgrade Pro dalam 90 hari setelah rilis.
- **SC-010**: Rating rata-rata Galaxy Store ≥ 4,3 setelah 100 ulasan.

## Assumptions

- Target utama: perangkat Samsung Galaxy dengan One UI yang mendukung Edge Panel; aplikasi tetap terpasang dan berguna di perangkat Android lain lewat tile dan overlay.
- Versi Android minimum mengikuti batas yang wajar untuk perangkat Galaxy yang masih aktif dipakai (ditetapkan di plan).
- Distribusi hanya via Galaxy Store pada v1; Google Play di luar cakupan.
- Harga Pro ditetapkan di Seller Portal Galaxy Store; spec tidak mengikat nominal.
- Pemulihan pembelian bergantung pada akun Samsung yang sama di Galaxy Store.
- Format `{tanggal}` memakai format tanggal panjang bahasa perangkat; format kustom di luar cakupan v1.
- Riwayat clipboard (menangkap teks yang disalin dari aplikasi lain) **tidak** termasuk cakupan; produk ini hanya pustaka snippet milik pengguna. Ini disengaja demi privasi dan pembatasan akses clipboard Android modern.
- Di luar cakupan v1: sinkronisasi cloud, akun, ekspor/impor, kategori kustom, variabel kustom, widget layar utama, enkripsi berbasis PIN/biometrik.
- Pencadangan data otomatis oleh sistem operasi (backup perangkat) tidak diaktifkan pada v1 agar data tidak keluar perangkat tanpa sepengetahuan pengguna; ekspor/impor manual bisa ditambahkan di versi berikut.
