# Data Model

Satu file SQLite: `<app data>/databases/snippets.db` (lokasi default sqflite `getDatabasesPath()`), mode WAL. Pemilik skema: drift (`lib/data/db.dart`). Kolom yang juga dipakai Kotlin dikunci di [contracts/db-schema.md](contracts/db-schema.md).

## Tabel `snippets`

| Kolom | Tipe | Aturan |
|---|---|---|
| `id` | INTEGER PK autoincrement | |
| `title` | TEXT NOT NULL | 1–80 char. Jika kosong saat simpan → 30 char pertama `body` (trim). |
| `body` | TEXT NOT NULL | 1–10.000 char, tidak boleh hanya spasi (FR-001). |
| `category` | INTEGER NOT NULL DEFAULT 0 | 0=Personal, 1=Kerja, 2=Rekening, 3=Template Chat (FR-007, FR-009). |
| `pinned` | INTEGER NOT NULL DEFAULT 0 | 0/1 (FR-003). |
| `created_at` | INTEGER NOT NULL | epoch ms. |
| `updated_at` | INTEGER NOT NULL | epoch ms. |
| `last_copied_at` | INTEGER NULL | epoch ms; ditulis oleh Kotlin `Copier`. |
| `copy_count` | INTEGER NOT NULL DEFAULT 0 | ditulis oleh Kotlin `Copier`. |

**Urutan tampil (FR-004)**: `ORDER BY pinned DESC, last_copied_at DESC NULLS LAST, created_at DESC`.
(SQLite Android < 3.30 tidak kenal `NULLS LAST` → pakai `COALESCE(last_copied_at, 0) DESC`.)

**Index**: `(pinned, last_copied_at)`; tidak perlu FTS — pencarian `LIKE '%q%'` (case-insensitive ASCII default; untuk ≤ ribuan baris cukup).

## Tabel `settings` (key–value)

| key | value | Keterangan |
|---|---|---|
| `var_nama` | TEXT | default `{nama}` (FR-016) |
| `var_rekening` | TEXT | default `{rekening}` |
| `is_pro` | `"0"`/`"1"` | entitlement (FR-035, FR-037) |
| `pro_verified_at` | epoch ms | verifikasi IAP sukses terakhir |
| `overlay_enabled` | `"0"`/`"1"` | default 0 (FR-022) |
| `overlay_x`, `overlay_y` | int px | posisi gelembung terakhir |
| `onboarding_done` | `"0"`/`"1"` | |

Kolom: `key TEXT PK`, `value TEXT NOT NULL`.

## Kategori (enum, bukan tabel)

Tetap 4 nilai; label dari l10n. `Rekening (2)` ⇒ salin dengan flag sensitif (FR-010).

## Aturan bisnis

- **Batas gratis (FR-033/038)**: insert diizinkan jika `is_pro = 1` **atau** `COUNT(snippets) < 10`. Edit/hapus/salin selalu diizinkan, berapa pun jumlahnya. Tidak ada penghapusan otomatis.
- **Undo hapus (FR-005)**: repo mengembalikan baris yang dihapus; "Urungkan" meng-insert ulang dengan `id` yang sama (bypass cek batas karena memulihkan).
- **Variabel (FR-014..017)**: token dikenali persis `{nama}`, `{tanggal}`, `{rekening}` (huruf kecil). Lainnya literal. Substitusi satu kali, kiri-ke-kanan, nilai tidak diproses ulang.

## State entitlement

```
FREE --startPayment OK--> PRO
FREE --getOwnedList has item--> PRO      (restore)
PRO  --getOwnedList OK, item absent--> FREE   (refund; data utuh)
PRO/FREE --getOwnedList gagal/offline--> (tidak berubah)
```

## Migrasi

`schemaVersion = 1`. Setiap perubahan skema: naikkan versi di drift, tambah langkah `onUpgrade`, dan perbarui [contracts/db-schema.md](contracts/db-schema.md) jika kolom yang dipakai Kotlin berubah.
