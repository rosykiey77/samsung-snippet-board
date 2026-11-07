package id.snippetboard.app.core

import java.text.DateFormat
import java.time.LocalDate
import java.time.ZoneId
import java.util.Date
import java.util.Locale

/** Resolusi token `{nama}`, `{tanggal}`, `{rekening}` — fungsi murni (data-model.md §Variabel). */
object VariableResolver {
    sealed interface Result {
        data class Resolved(val text: String) : Result
        data class Missing(val names: List<String>) : Result
    }

    private val TOKEN = Regex("\\{(nama|tanggal|rekening)\\}")

    /**
     * @param values nilai default dari settings, key `nama` / `rekening`.
     * @param overrides isian pengguna dari dialog; menang atas [values].
     */
    fun resolve(
        body: String,
        values: Map<String, String>,
        overrides: Map<String, String>,
        locale: Locale,
        today: LocalDate,
    ): Result {
        fun valueOf(name: String) = (overrides[name] ?: values[name])?.takeIf { it.isNotBlank() }

        val missing = TOKEN.findAll(body).map { it.groupValues[1] }
            .filter { it != "tanggal" && valueOf(it) == null }
            .distinct().toList()
        if (missing.isNotEmpty()) return Result.Missing(missing)

        val date by lazy {
            val d = Date.from(today.atStartOfDay(ZoneId.systemDefault()).toInstant())
            DateFormat.getDateInstance(DateFormat.LONG, locale).format(d)
        }
        // Regex.replace memindai sekali kiri-ke-kanan; nilai pengganti tidak dipindai ulang.
        return Result.Resolved(TOKEN.replace(body) { m ->
            if (m.groupValues[1] == "tanggal") date else valueOf(m.groupValues[1])!!
        })
    }
}
