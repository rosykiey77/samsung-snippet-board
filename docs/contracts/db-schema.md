# Contract: Skema DB yang dibaca/ditulis Kotlin

drift adalah pemilik skema. Kotlin (`core/SnippetStore.kt`) **hanya** boleh memakai kolom berikut. Mengubah salah satunya = perubahan kontrak: update file ini + `SnippetStore.kt` + test keduanya.

File: `getDatabasePath("snippets.db")`, dibuka `SQLiteDatabase.openDatabase(path, null, OPEN_READWRITE)` dengan `enableWriteAheadLogging()`.

## Read

```sql
-- daftar (Edge Panel, picker); :cat = -1 untuk semua
SELECT id, title, body, category, pinned FROM snippets
 WHERE (:cat = -1 OR category = :cat)
 ORDER BY pinned DESC, COALESCE(last_copied_at, 0) DESC, created_at DESC
 LIMIT 100;

SELECT body, category FROM snippets WHERE id = :id;

SELECT key, value FROM settings WHERE key IN ('var_nama','var_rekening','is_pro','overlay_enabled','overlay_x','overlay_y');
```

> Catatan Kotlin: `rawQuery` mengikat argumen sebagai TEXT, jadi `:cat = -1` ditulis `CAST(? AS INTEGER) = -1`.

## Write

```sql
UPDATE snippets SET last_copied_at = :now, copy_count = copy_count + 1 WHERE id = :id;
INSERT OR REPLACE INTO settings(key, value) VALUES (:k, :v);  -- hanya is_pro, pro_verified_at, overlay_x, overlay_y
```

Kotlin tidak pernah INSERT/DELETE ke `snippets` dan tidak menjalankan DDL.

## Jika DB belum ada

Edge Panel/picker dibuka sebelum aplikasi pernah dijalankan → file belum ada → tampilkan state kosong "Belum ada snippet" + tombol buka aplikasi. Kotlin **tidak** membuat DB.
