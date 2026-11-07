package id.snippetboard.app.ui

import android.view.animation.PathInterpolator
import id.snippetboard.app.R

/** Token gerak One UI untuk View native (docs/design-system.md §7, §11.5). */
object Motion {
    const val PRESS_MS = 100L
    const val COPIED_MS = 240L
    const val COPIED_HOLD_MS = 1200L
    const val SHEET_IN_MS = 300L
    const val SHEET_OUT_MS = 200L
    val standard = PathInterpolator(0.22f, 0.25f, 0f, 1f)
    val decelerate = PathInterpolator(0f, 0f, 0.2f, 1f)
    val accelerate = PathInterpolator(0.4f, 0f, 1f, 1f)
}

/** Warna kategori; index = key DB (data-model.md). Ikon ditambahkan bersama layout Edge/Picker (US2/US5). */
object CategoryTokens {
    val color = intArrayOf(R.color.cat_personal, R.color.cat_kerja, R.color.cat_rekening, R.color.cat_chat)
    val container = intArrayOf(
        R.color.cat_personal_container, R.color.cat_kerja_container,
        R.color.cat_rekening_container, R.color.cat_chat_container,
    )
}
