package id.snippetboard.app.core

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.os.Build
import android.os.PersistableBundle
import android.view.HapticFeedbackConstants
import android.view.View
import android.widget.Toast
import id.snippetboard.app.R

/** Satu-satunya pemilik konfirmasi salin (clipboard + haptic + teks) untuk semua permukaan. */
object Copier {
    private const val EXTRA_IS_SENSITIVE = "android.content.extra.IS_SENSITIVE"

    fun copy(context: Context, text: String, sensitive: Boolean, view: View?) {
        val clip = ClipData.newPlainText(context.getString(R.string.clip_label), text)
        if (sensitive) {
            clip.description.extras = PersistableBundle().apply { putBoolean(EXTRA_IS_SENSITIVE, true) }
        }
        context.getSystemService(ClipboardManager::class.java).setPrimaryClip(clip)

        // design-system §8: hanya performHapticFeedback (menghormati setelan getaran), tanpa Vibrator langsung.
        view?.performHapticFeedback(
            if (Build.VERSION.SDK_INT >= 30) HapticFeedbackConstants.CONFIRM
            else HapticFeedbackConstants.KEYBOARD_TAP,
        )
        // Android 13+ sudah menampilkan konfirmasi clipboard sistem.
        if (Build.VERSION.SDK_INT < 33) {
            Toast.makeText(context, R.string.copied, Toast.LENGTH_SHORT).show()
        }
    }
}
