package id.snippetboard.app.core

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import java.io.File

/**
 * Akses Kotlin ke `snippets.db` milik drift. SQL & kolom dikunci oleh docs/contracts/db-schema.md:
 * tidak ada DDL, tidak ada INSERT/DELETE ke `snippets`, dan DB tidak pernah dibuat dari sini.
 */
class SnippetStore(private val dbFile: File) {
    constructor(context: Context) : this(context.getDatabasePath(DB_NAME))

    data class Snippet(val id: Long, val title: String, val body: String, val category: Int, val pinned: Boolean)

    private fun <T> withDb(empty: T, block: (SQLiteDatabase) -> T): T {
        if (!dbFile.exists()) return empty
        val db = SQLiteDatabase.openDatabase(dbFile.path, null, SQLiteDatabase.OPEN_READWRITE)
        return try {
            db.enableWriteAheadLogging()
            block(db)
        } finally {
            db.close()
        }
    }

    fun list(category: Int = -1, limit: Int = 100): List<Snippet> = withDb(emptyList()) { db ->
        db.rawQuery(
            """SELECT id, title, body, category, pinned FROM snippets
               WHERE (CAST(? AS INTEGER) = -1 OR category = ?)
               ORDER BY pinned DESC, COALESCE(last_copied_at, 0) DESC, created_at DESC
               LIMIT $limit""",
            // rawQuery mengikat argumen sebagai TEXT; tanpa CAST, '-1' = -1 bernilai false.
            arrayOf(category.toString(), category.toString()),
        ).use { c ->
            buildList {
                while (c.moveToNext()) {
                    add(Snippet(c.getLong(0), c.getString(1), c.getString(2), c.getInt(3), c.getInt(4) != 0))
                }
            }
        }
    }

    /** Hanya `body` & `category` (kontrak); `title` tidak dibutuhkan jalur salin. */
    fun get(id: Long): Pair<String, Int>? = withDb(null) { db ->
        db.rawQuery("SELECT body, category FROM snippets WHERE id = ?", arrayOf(id.toString())).use { c ->
            if (c.moveToFirst()) c.getString(0) to c.getInt(1) else null
        }
    }

    fun settings(): Map<String, String> = withDb(emptyMap()) { db ->
        db.rawQuery(
            "SELECT key, value FROM settings WHERE key IN " +
                "('var_nama','var_rekening','is_pro','overlay_enabled','overlay_x','overlay_y')",
            null,
        ).use { c -> buildMap { while (c.moveToNext()) put(c.getString(0), c.getString(1)) } }
    }

    fun markCopied(id: Long, now: Long) = withDb(Unit) { db ->
        db.execSQL(
            "UPDATE snippets SET last_copied_at = ?, copy_count = copy_count + 1 WHERE id = ?",
            arrayOf<Any>(now, id),
        )
    }

    fun putSetting(key: String, value: String) {
        require(key in WRITABLE_KEYS) { "Kotlin tidak boleh menulis setting '$key'" }
        withDb(Unit) { db ->
            db.execSQL("INSERT OR REPLACE INTO settings(key, value) VALUES (?, ?)", arrayOf<Any>(key, value))
        }
    }

    companion object {
        const val DB_NAME = "snippets.db"
        const val CATEGORY_REKENING = 2
        private val WRITABLE_KEYS = setOf("is_pro", "pro_verified_at", "overlay_enabled", "overlay_x", "overlay_y")
    }
}
