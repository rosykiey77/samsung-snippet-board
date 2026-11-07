package id.snippetboard.app

import id.snippetboard.app.overlay.SnippetOverlayService.Companion.snapX
import org.junit.Assert.assertEquals
import org.junit.Test

class OverlaySnapTest {
    @Test fun `pusat di kiri tengah layar menempel ke kiri`() = assertEquals(0, snapX(400, 150, 1080))
    @Test fun `pusat di kanan menempel ke kanan`() = assertEquals(930, snapX(500, 150, 1080))
    @Test fun `seret keluar layar tetap ke tepi terdekat`() {
        assertEquals(0, snapX(-300, 150, 1080))
        assertEquals(930, snapX(2000, 150, 1080))
    }
}
