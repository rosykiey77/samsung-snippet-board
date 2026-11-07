package id.snippetboard.app.overlay

import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.PixelFormat
import android.graphics.drawable.Icon
import android.os.Build
import android.provider.Settings
import android.view.Gravity
import android.view.HapticFeedbackConstants
import android.view.MotionEvent
import android.view.View
import android.view.ViewConfiguration
import android.view.WindowManager
import android.widget.ImageView
import id.snippetboard.app.R
import id.snippetboard.app.core.SnippetStore
import id.snippetboard.app.picker.PickerActivity
import kotlin.math.hypot

/**
 * Gelembung mengambang (FR-022/023, ui-specs §8) untuk HP tanpa Edge Panel: foreground service
 * `specialUse` + view `TYPE_APPLICATION_OVERLAY`. Ketuk → picker; seret → snap ke tepi, posisi disimpan.
 * shortcut: tanpa target drag-to-close & animasi idle/spring; matikan lewat notifikasi atau Pengaturan.
 */
class SnippetOverlayService : Service() {
    private val wm by lazy { getSystemService(WindowManager::class.java) }
    private var bubble: View? = null

    override fun onBind(intent: Intent?) = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Aksi "Matikan" di notifikasi, atau izin dicabut saat aktif → berhenti aman & status nonaktif.
        if (intent?.action == ACTION_STOP || !Settings.canDrawOverlays(this)) {
            SnippetStore(this).putSetting(KEY_ENABLED, "0")
            stopSelf()
            return START_NOT_STICKY
        }
        startInForeground()
        if (bubble == null) bubble = showBubble()
        return START_STICKY
    }

    override fun onDestroy() {
        bubble?.let { wm.removeView(it) }
        bubble = null
        super.onDestroy()
    }

    private fun startInForeground() {
        val nm = getSystemService(NotificationManager::class.java)
        nm.createNotificationChannel(
            NotificationChannel(CHANNEL, getString(R.string.overlay_channel), NotificationManager.IMPORTANCE_MIN),
        )
        val stop = PendingIntent.getService(
            this, 1, Intent(this, SnippetOverlayService::class.java).setAction(ACTION_STOP), PendingIntent.FLAG_IMMUTABLE,
        )
        val n = Notification.Builder(this, CHANNEL)
            .setSmallIcon(R.drawable.ic_snippet)
            .setContentTitle(getString(R.string.overlay_notif_title))
            .setContentText(getString(R.string.overlay_notif_text))
            .setContentIntent(PendingIntent.getActivity(this, 0, PickerActivity.pickIntent(this), PendingIntent.FLAG_IMMUTABLE))
            .addAction(
                Notification.Action.Builder(
                    Icon.createWithResource(this, R.drawable.ic_snippet), getString(R.string.overlay_stop), stop,
                ).build(),
            )
            .setOngoing(true)
            .build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(NOTIF_ID, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(NOTIF_ID, n)
        }
    }

    @SuppressLint("ClickableViewAccessibility") // performClick() dipanggil saat ACTION_UP tanpa drag
    private fun showBubble(): View {
        val size = resources.getDimensionPixelSize(R.dimen.bubble_size)
        val saved = SnippetStore(this).settings()
        val screen = resources.displayMetrics
        val lp = WindowManager.LayoutParams(
            size, size,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = saved["overlay_x"]?.toIntOrNull() ?: (screen.widthPixels - size)
            y = saved["overlay_y"]?.toIntOrNull() ?: (screen.heightPixels / 3)
        }
        val v = ImageView(this).apply {
            setImageResource(R.drawable.ic_snippet)
            setBackgroundResource(R.drawable.bg_bubble)
            scaleType = ImageView.ScaleType.CENTER
            elevation = resources.displayMetrics.density * 6
            contentDescription = getString(R.string.overlay_cd)
            setOnClickListener { startActivity(PickerActivity.pickIntent(this@SnippetOverlayService)) }
        }
        val slop = ViewConfiguration.get(this).scaledTouchSlop
        var downX = 0f; var downY = 0f; var startX = 0; var startY = 0; var dragging = false
        v.setOnTouchListener { view, e ->
            when (e.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    downX = e.rawX; downY = e.rawY; startX = lp.x; startY = lp.y; dragging = false
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = e.rawX - downX; val dy = e.rawY - downY
                    if (!dragging && hypot(dx, dy) > slop) dragging = true
                    if (dragging) {
                        lp.x = startX + dx.toInt(); lp.y = startY + dy.toInt()
                        wm.updateViewLayout(view, lp)
                    }
                }
                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                    if (!dragging) {
                        if (e.actionMasked == MotionEvent.ACTION_UP) view.performClick()
                    } else {
                        val m = resources.displayMetrics // ulang: bisa sudah dirotasi
                        lp.x = snapX(lp.x, size, m.widthPixels)
                        lp.y = lp.y.coerceIn(0, (m.heightPixels - size).coerceAtLeast(0))
                        wm.updateViewLayout(view, lp)
                        view.performHapticFeedback(HapticFeedbackConstants.CLOCK_TICK)
                        SnippetStore(this).apply { putSetting("overlay_x", "${lp.x}"); putSetting("overlay_y", "${lp.y}") }
                    }
                }
            }
            true
        }
        wm.addView(v, lp)
        return v
    }

    companion object {
        const val KEY_ENABLED = "overlay_enabled"
        private const val CHANNEL = "overlay"
        private const val NOTIF_ID = 1
        private const val ACTION_STOP = "id.snippetboard.app.overlay.STOP"

        /** Tepi kiri/kanan terdekat dari pusat bubble. */
        fun snapX(x: Int, size: Int, screenW: Int): Int = if (x + size / 2 < screenW / 2) 0 else screenW - size

        fun start(ctx: Context) {
            ctx.startForegroundService(Intent(ctx, SnippetOverlayService::class.java))
        }

        fun stop(ctx: Context) {
            ctx.stopService(Intent(ctx, SnippetOverlayService::class.java))
        }
    }
}
