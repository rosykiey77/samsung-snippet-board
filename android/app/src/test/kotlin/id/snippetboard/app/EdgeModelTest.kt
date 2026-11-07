package id.snippetboard.app

import id.snippetboard.app.core.SnippetStore.Snippet
import id.snippetboard.app.edge.EdgeModel
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class EdgeModelTest {
    @Test fun cycleOrderWrapsToAll() {
        val seen = generateSequence(EdgeModel.ALL) { EdgeModel.next(it) }.take(6).toList()
        assertEquals(listOf(-1, 0, 1, 2, 3, -1), seen)
    }

    @Test fun unknownCategoryResetsToAll() = assertEquals(EdgeModel.ALL, EdgeModel.next(42))

    @Test fun rekeningPreviewAlwaysMasked() =
        assertEquals("BCA •••• 7890 a.n. Budi", EdgeModel.preview("BCA 1234567890 a.n. Budi", 2))

    @Test fun otherCategoriesNotMasked() =
        assertEquals("Order 1234567890", EdgeModel.preview("Order 1234567890", 1))

    @Test fun searchMatchesTitleOrBodyIgnoringCase() {
        val s = Snippet(1, "Alamat Rumah", "Jl. Melati No. 12", 0, false)
        assertTrue(EdgeModel.matches(s, "  rumah "))
        assertTrue(EdgeModel.matches(s, "MELATI"))
        assertTrue(EdgeModel.matches(s, ""))
        assertFalse(EdgeModel.matches(s, "bca"))
    }
}
