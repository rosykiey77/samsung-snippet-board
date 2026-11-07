package id.snippetboard.app

import android.content.Intent
import android.widget.FrameLayout
import android.widget.TextView
import id.snippetboard.app.core.SnippetStore
import id.snippetboard.app.edge.EdgeListService
import id.snippetboard.app.edge.SnippetEdgeProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment

@RunWith(RobolectricTestRunner::class)
class EdgeListServiceTest {
    private val app get() = RuntimeEnvironment.getApplication()

    @Before fun seed() {
        app.getDatabasePath(SnippetStore.DB_NAME).apply { parentFile!!.mkdirs(); delete() }.also(::seedSnippetsDb)
    }

    private fun factory() = EdgeListService.Factory(app).apply { onDataSetChanged() }
    private fun cycle() = SnippetEdgeProvider().onReceive(app, Intent(SnippetEdgeProvider.ACTION_CYCLE))

    @Test fun allCategoriesInStoreOrder() {
        val f = factory()
        assertEquals(listOf(3L, 4L, 2L, 1L), (0 until f.count).map(f::getItemId))
        val v = f.getViewAt(0).apply(app, FrameLayout(app))
        assertEquals("t3", v.findViewById<TextView>(R.id.edge_item_title).text.toString())
    }

    @Test fun cycleChipFiltersList() {
        repeat(3) { cycle() } // Semua → Personal → Kerja → Rekening
        assertEquals(2, SnippetEdgeProvider.category(app))
        val f = factory()
        assertEquals(listOf(2L), (0 until f.count).map(f::getItemId))
        repeat(2) { cycle() } // → Chat → Semua
        assertEquals(4, factory().count)
    }

    @Test fun staleIndexDoesNotCrash() {
        factory().getViewAt(99)
    }

    @Test fun edgeUnsupportedOffSamsung() = assertFalse(SnippetEdgeProvider.supported(app))
}
