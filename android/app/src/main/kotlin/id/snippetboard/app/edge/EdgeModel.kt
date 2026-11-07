package id.snippetboard.app.edge

import id.snippetboard.app.core.Masker
import id.snippetboard.app.core.SnippetStore

/** Logika murni Edge Panel (tanpa Android) supaya bisa diuji JVM biasa. */
object EdgeModel {
    const val ALL = -1
    const val LIMIT = 50 // ui-specs §5.3: 50 teratas, sisanya lewat search pill

    /** Urutan cycle chip (ui-specs §5.4): Semua → Personal → Kerja → Rekening → Chat → Semua. */
    private val CYCLE = intArrayOf(ALL, 0, 1, 2, 3)

    /** Kategori tak dikenal (mis. pref rusak) kembali ke Semua. */
    fun next(category: Int): Int = CYCLE[(CYCLE.indexOf(category) + 1) % CYCLE.size]

    fun isSensitive(category: Int) = category == SnippetStore.CATEGORY_REKENING

    /** Edge/Picker selalu termasking untuk Rekening, tanpa reveal (ui-specs §4.2). */
    fun preview(body: String, category: Int): String = if (isSensitive(category)) Masker.mask(body) else body

    /** Filter pencarian Picker: judul atau isi, tanpa beda huruf besar/kecil. */
    fun matches(s: SnippetStore.Snippet, query: String): Boolean =
        query.isBlank() || s.title.contains(query.trim(), true) || s.body.contains(query.trim(), true)
}
