package id.snippetboard.app

import id.snippetboard.app.core.VariableResolver
import id.snippetboard.app.core.VariableResolver.Result.Missing
import id.snippetboard.app.core.VariableResolver.Result.Resolved
import org.junit.Assert.assertEquals
import org.junit.Test
import java.time.LocalDate
import java.util.Locale

class VariableResolverTest {
    private val day = LocalDate.of(2026, 11, 7)
    private val id = Locale.forLanguageTag("id-ID")
    private val vals = mapOf("nama" to "Budi", "rekening" to "1234567890")

    private fun r(body: String, values: Map<String, String> = vals, over: Map<String, String> = emptyMap(), loc: Locale = id) =
        VariableResolver.resolve(body, values, over, loc, day)

    @Test fun substitutesAllThree() =
        assertEquals(Resolved("Halo Budi, 7 November 2026, rek 1234567890"), r("Halo {nama}, {tanggal}, rek {rekening}"))

    @Test fun unknownTokenStaysLiteral() = assertEquals(Resolved("{harga} {Nama}"), r("{harga} {Nama}"))

    @Test fun valuesAreNotReprocessed() =
        assertEquals(Resolved("x {rekening} y"), r("x {nama} y", mapOf("nama" to "{rekening}")))

    @Test fun missingReportedOnceInOrder() =
        assertEquals(Missing(listOf("rekening", "nama")), r("{rekening} {nama} {rekening}", mapOf("nama" to "  ")))

    @Test fun overridesFillMissing() =
        assertEquals(Resolved("Ani"), r("{nama}", emptyMap(), mapOf("nama" to "Ani")))

    @Test fun dateEnUs() = assertEquals(Resolved("November 7, 2026"), r("{tanggal}", loc = Locale.US))

    @Test fun emojiIntact() = assertEquals(Resolved("👋🏽 Budi 🙏"), r("👋🏽 {nama} 🙏"))
}
