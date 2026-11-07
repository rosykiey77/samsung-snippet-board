package id.snippetboard.app.core

/** Masking tampilan nomor rekening (ui-specs §4.1). Regex identik dengan `lib/data/mask.dart`. */
object Masker {
    private val DIGITS = Regex("""(?<!\d)\d(?:[ .\-]?\d){5,}(?!\d)""")

    fun mask(body: String): String = DIGITS.replace(body) { m ->
        "•••• " + m.value.filter(Char::isDigit).takeLast(4)
    }
}
