package id.snippetboard.app

import id.snippetboard.app.core.CopyFlow
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** Handler channel `snippetboard/native` — docs/contracts/method-channel.md. */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
                "refreshSurfaces" -> result.success(null) // diisi di T032 (Edge Panel)
                else -> result.notImplemented()
            }
        }
    }

    private companion object {
        const val CHANNEL = "snippetboard/native"
    }
}
