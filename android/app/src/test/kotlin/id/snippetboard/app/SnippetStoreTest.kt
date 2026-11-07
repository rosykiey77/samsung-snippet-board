package id.snippetboard.app

import android.database.sqlite.SQLiteDatabase
import id.snippetboard.app.core.Masker
import id.snippetboard.app.core.SnippetStore
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import java.io.File

@RunWith(RobolectricTestRunner::class)
class SnippetStoreTest {
    @get:Rule val tmp = TemporaryFolder()

    private fun seed(): File = File(tmp.root, "snippets.db").also(::seedSnippetsDb)

    @Test fun listOrderPinnedThenCopiedThenCreated() =
        assertEquals(listOf(3L, 4L, 2L, 1L), SnippetStore(seed()).list().map { it.id })

    @Test fun listFiltersCategory() = assertEquals(listOf(2L), SnippetStore(seed()).list(category = 2).map { it.id })

    @Test fun markCopiedBumpsCountAndOrder() {
        val f = seed()
        val store = SnippetStore(f)
        store.markCopied(1, 5000)
        store.markCopied(1, 6000)
        assertEquals(listOf(3L, 1L, 4L, 2L), store.list().map { it.id })
        SQLiteDatabase.openDatabase(f.path, null, SQLiteDatabase.OPEN_READONLY).use { db ->
            db.rawQuery("SELECT copy_count, last_copied_at FROM snippets WHERE id=1", null).use {
                it.moveToFirst(); assertEquals(2, it.getInt(0)); assertEquals(6000L, it.getLong(1))
            }
        }
    }

    @Test fun getAndSettingsUseContractColumnsOnly() {
        val store = SnippetStore(seed())
        assertEquals("b2" to 2, store.get(2))
        assertNull(store.get(42))
        assertEquals(mapOf("var_nama" to "Budi"), store.settings()) // onboarding_done bukan bagian kontrak
        store.putSetting("is_pro", "1")
        assertEquals("1", store.settings()["is_pro"])
    }

    @Test(expected = IllegalArgumentException::class)
    fun putSettingRejectsKeysOutsideContract() = SnippetStore(seed()).putSetting("var_nama", "x")

    @Test fun missingDbFileYieldsEmptyAndIsNotCreated() {
        val f = File(tmp.root, "none.db")
        val store = SnippetStore(f)
        assertTrue(store.list().isEmpty())
        assertNull(store.get(1))
        assertTrue(store.settings().isEmpty())
        assertTrue(!f.exists())
    }
}

// DDL harus sama dengan yang dihasilkan drift dari lib/data/db.dart (lihat docs/contracts/db-schema.md).
// Dipakai juga oleh EdgeListServiceTest.
internal fun seedSnippetsDb(f: File) {
    SQLiteDatabase.openOrCreateDatabase(f, null).use { db ->
        db.execSQL(
            """CREATE TABLE snippets (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL,
               body TEXT NOT NULL, category INTEGER NOT NULL DEFAULT 0, pinned INTEGER NOT NULL DEFAULT 0 CHECK (pinned IN (0, 1)),
               created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, last_copied_at INTEGER NULL,
               copy_count INTEGER NOT NULL DEFAULT 0)""",
        )
        db.execSQL("CREATE TABLE settings (key TEXT NOT NULL PRIMARY KEY, value TEXT NOT NULL)")
        // id, category, pinned, created_at, last_copied_at
        listOf(
            arrayOf<Any?>(1, 0, 0, 100, null),
            arrayOf<Any?>(2, 2, 0, 200, null),
            arrayOf<Any?>(3, 0, 1, 50, null),
            arrayOf<Any?>(4, 0, 0, 10, 999),
        ).forEach { (id, cat, pin, created, copied) ->
            db.execSQL(
                "INSERT INTO snippets(id,title,body,category,pinned,created_at,updated_at,last_copied_at) VALUES (?,?,?,?,?,?,?,?)",
                arrayOf(id, "t$id", "b$id", cat, pin, created, created, copied),
            )
        }
        db.execSQL("INSERT INTO settings VALUES ('var_nama','Budi'),('onboarding_done','1')")
    }
}

class MaskerTest {
    @Test fun sixDigits() = assertEquals("•••• 3456", Masker.mask("123456"))
    @Test fun sixteenDigitsSpaced() = assertEquals("•••• 3456", Masker.mask("1234 5678 9012 3456"))
    @Test fun dashed() = assertEquals("BCA •••• 8901 a.n. Budi", Masker.mask("BCA 0123-4567-8901 a.n. Budi"))
    @Test fun underSixUntouched() = assertEquals("PIN 12345", Masker.mask("PIN 12345"))
    @Test fun emojiMixed() = assertEquals("💳 •••• 7890 ✅", Masker.mask("💳 1234567890 ✅"))
}
