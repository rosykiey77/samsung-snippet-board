package id.snippetboard.app

import android.Manifest
import android.app.StatusBarManager
import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.drawable.Icon
import android.net.Uri
import android.os.Build
import android.provider.Settings
import id.snippetboard.app.core.CopyFlow
import id.snippetboard.app.core.SnippetStore
import id.snippetboard.app.edge.SnippetEdgeProvider
import id.snippetboard.app.iap.IapBridge
import id.snippetboard.app.overlay.SnippetOverlayService
import id.snippetboard.app.tile.SnippetTileService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** Handler channel `snippetboard/native` — docs/contracts/method-channel.md. */
class MainActivity : FlutterActivity() {
    private val iap by lazy { IapBridge(this) }
    private var pendingDoc: Pair<MethodChannel.Result, String?>? = null // (result, isi yang akan ditulis)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Service tidak hidup lagi setelah reboot; app dibuka → pulihkan gelembung jika masih aktif.
        if (SnippetStore(this).settings()[SnippetOverlayService.KEY_ENABLED] == "1" && Settings.canDrawOverlays(this)) {
            SnippetOverlayService.start(this)
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "copySnippet" -> {
                    val id = call.argument<Number>("id")?.toLong()
                        ?: return@setMethodCallHandler result.error("BAD_ARGS", "id wajib", null)
                    val overrides = call.argument<Map<String, String>>("overrides").orEmpty()
                    when (val s = CopyFlow.run(this, id, overrides, window.decorView)) {
                        CopyFlow.Status.Copied -> result.success(mapOf("status" to "copied"))
                        CopyFlow.Status.NotFound -> result.error("NOT_FOUND", "Snippet $id tidak ada", null)
                        is CopyFlow.Status.NeedsInput ->
                            result.success(mapOf("status" to "needsInput", "missing" to s.missing))
                    }
                }
                "refreshSurfaces" -> {
                    SnippetEdgeProvider.update(this)
                    result.success(null)
                }
                "edgePanelSupported" -> result.success(SnippetEdgeProvider.supported(this))
                "surfaceStatus" -> result.success(
                    mapOf(
                        "edgeSupported" to SnippetEdgeProvider.supported(this),
                        "edge" to isEnabled(EDGE),
                        "tile" to isEnabled(TILE),
                        "overlayPermission" to Settings.canDrawOverlays(this),
                    ),
                )
                "setSurfaceEnabled" -> {
                    val c = when (call.argument<String>("surface")) {
                        "edge" -> EDGE
                        "tile" -> TILE
                        else -> return@setMethodCallHandler result.error("BAD_ARGS", "surface: edge|tile", null)
                    }
                    val on = call.argument<Boolean>("enabled") == true
                    // Komponen nonaktif = panel hilang dari daftar Edge / tile hilang dari Quick Settings.
                    packageManager.setComponentEnabledSetting(
                        ComponentName(this, c),
                        if (on) PackageManager.COMPONENT_ENABLED_STATE_DEFAULT else PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                        PackageManager.DONT_KILL_APP,
                    )
                    result.success(null)
                }
                "setOverlayEnabled" -> {
                    if (call.argument<Boolean>("enabled") != true) {
                        SnippetOverlayService.stop(this)
                        result.success(mapOf("status" to "ok"))
                    } else if (!Settings.canDrawOverlays(this)) {
                        result.success(mapOf("status" to "needsPermission"))
                    } else {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
                            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
                        ) {
                            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 0) // ditolak pun service tetap jalan
                        }
                        SnippetOverlayService.start(this)
                        result.success(mapOf("status" to "ok"))
                    }
                }
                "openOverlayPermission" -> {
                    startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName")))
                    result.success(null)
                }
                "requestAddTile" -> {
                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return@setMethodCallHandler result.success(false)
                    getSystemService(StatusBarManager::class.java).requestAddTileService(
                        ComponentName(this, TILE), getString(R.string.tile_label),
                        Icon.createWithResource(this, R.drawable.ic_snippet), mainExecutor,
                    ) {}
                    result.success(true)
                }
                "saveDocument" -> openDoc(
                    result, call.argument<String>("content") ?: "",
                    Intent(Intent.ACTION_CREATE_DOCUMENT).setType(JSON).putExtra(Intent.EXTRA_TITLE, call.argument<String>("name")),
                )
                "openDocument" -> openDoc(result, null, Intent(Intent.ACTION_OPEN_DOCUMENT).setType("*/*"))
                "iapProduct" -> iap.product(result)
                "iapPurchase" -> iap.purchase(result)
                "iapRestore" -> iap.restore(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun isEnabled(c: Class<*>) =
        packageManager.getComponentEnabledSetting(ComponentName(this, c)) != PackageManager.COMPONENT_ENABLED_STATE_DISABLED

    /** SAF: pengguna memilih lokasi file sendiri → tanpa izin storage & tanpa jaringan. */
    private fun openDoc(result: MethodChannel.Result, content: String?, intent: Intent) {
        pendingDoc?.first?.error("BUSY", "Dialog file lain masih terbuka", null)
        pendingDoc = result to content
        @Suppress("DEPRECATION")
        startActivityForResult(intent.addCategory(Intent.CATEGORY_OPENABLE), REQ_DOC)
    }

    @Deprecated("FlutterActivity masih memakai onActivityResult")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQ_DOC) return
        val (result, content) = pendingDoc ?: return
        pendingDoc = null
        val uri = data?.data.takeIf { resultCode == RESULT_OK } ?: return result.success(null) // batal
        try {
            if (content != null) {
                contentResolver.openOutputStream(uri, "wt")!!.bufferedWriter().use { it.write(content) }
                result.success(true)
            } else {
                // shortcut: file dibaca utuh ke memori, batasi ukuran jika ada laporan OOM dari backup raksasa.
                result.success(contentResolver.openInputStream(uri)!!.bufferedReader().use { it.readText() })
            }
        } catch (e: Exception) {
            result.error("IO", e.message, null)
        }
    }

    private companion object {
        const val CHANNEL = "snippetboard/native"
        const val REQ_DOC = 41
        const val JSON = "application/json"
        val EDGE = SnippetEdgeProvider::class.java
        val TILE = SnippetTileService::class.java
    }
}
