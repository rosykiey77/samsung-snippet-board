package id.snippetboard.app.edge

import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.samsung.android.sdk.look.Slook
import com.samsung.android.sdk.look.cocktailbar.SlookCocktailManager
import com.samsung.android.sdk.look.cocktailbar.SlookCocktailProvider
import id.snippetboard.app.MainActivity
import id.snippetboard.app.R
import id.snippetboard.app.picker.PickerActivity
import id.snippetboard.app.ui.CategoryTokens

/** Samsung Edge Panel (ui-specs §5). Data list dari [EdgeListService]; salin lewat [PickerActivity]. */
class SnippetEdgeProvider : SlookCocktailProvider() {

    override fun onUpdate(context: Context, manager: SlookCocktailManager, cocktailIds: IntArray) {
        val panel = panel(context)
        cocktailIds.forEach { manager.updateCocktail(it, panel) }
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_CYCLE) {
            prefs(context).edit().putInt(KEY_CATEGORY, EdgeModel.next(category(context))).apply()
            update(context, rebuild = true)
        } else {
            super.onReceive(context, intent)
        }
    }

    companion object {
        internal const val ACTION_CYCLE = "id.snippetboard.app.edge.CYCLE_CATEGORY"
        private const val PREFS = "edge"
        private const val KEY_CATEGORY = "edge_category"

        private fun prefs(ctx: Context) = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

        /** Kategori aktif panel; [EdgeModel.ALL] = Semua. */
        fun category(ctx: Context): Int = prefs(ctx).getInt(KEY_CATEGORY, EdgeModel.ALL)

        /** `edgePanelSupported` (method-channel.md): perangkat non-Samsung melempar exception → false. */
        fun supported(ctx: Context): Boolean = try {
            Slook().run { initialize(ctx); isFeatureEnabled(Slook.COCKTAIL_PANEL) }
        } catch (e: Exception) {
            false
        }

        /** `refreshSurfaces`: muat ulang list; [rebuild] juga menggambar ulang header (label kategori). */
        fun update(ctx: Context, rebuild: Boolean = false) {
            if (!supported(ctx)) return
            val m = SlookCocktailManager.getInstance(ctx)
            val ids = m.getCocktailIds(ComponentName(ctx, SnippetEdgeProvider::class.java)) ?: return
            val panel = if (rebuild) panel(ctx) else null
            ids.forEach { id ->
                panel?.let { m.updateCocktail(id, it) }
                m.notifyCocktailViewDataChanged(id, R.id.edge_list)
            }
        }

        private fun panel(ctx: Context): RemoteViews {
            val cat = category(ctx)
            val label = ctx.getString(
                when (cat) {
                    0 -> R.string.category_personal
                    1 -> R.string.category_work
                    2 -> R.string.category_account
                    3 -> R.string.category_chat
                    else -> R.string.category_all
                },
            )
            val openApp = PendingIntent.getActivity(
                ctx, 0, Intent(ctx, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                PendingIntent.FLAG_IMMUTABLE,
            )
            fun picker(action: String, flags: Int) = PendingIntent.getActivity(
                ctx, 0, Intent(ctx, PickerActivity::class.java).setAction(action),
                PendingIntent.FLAG_UPDATE_CURRENT or flags,
            )
            val cycle = PendingIntent.getBroadcast(
                ctx, 0, Intent(ctx, SnippetEdgeProvider::class.java).setAction(ACTION_CYCLE),
                PendingIntent.FLAG_IMMUTABLE,
            )

            return RemoteViews(ctx.packageName, R.layout.edge_panel).apply {
                setRemoteAdapter(R.id.edge_list, Intent(ctx, EdgeListService::class.java))
                setEmptyView(R.id.edge_list, R.id.edge_empty)
                // Template harus MUTABLE agar fill-in intent (snippet_id) bisa digabung.
                setPendingIntentTemplate(R.id.edge_list, picker(PickerActivity.ACTION_COPY, PendingIntent.FLAG_MUTABLE))
                setOnClickPendingIntent(R.id.edge_search, picker(PickerActivity.ACTION_SEARCH, PendingIntent.FLAG_IMMUTABLE))
                setOnClickPendingIntent(R.id.edge_cycle, cycle)
                setOnClickPendingIntent(R.id.edge_add, openApp)
                setOnClickPendingIntent(R.id.edge_open, openApp)
                setTextViewText(R.id.edge_cycle_label, label)
                setContentDescription(R.id.edge_cycle, ctx.getString(R.string.cd_filter, label))
                setInt(
                    R.id.edge_cycle_dot, "setColorFilter",
                    ctx.getColor(CategoryTokens.color.getOrNull(cat) ?: R.color.primary),
                )
                setTextViewText(
                    R.id.edge_empty_text,
                    if (cat == EdgeModel.ALL) ctx.getString(R.string.empty_state) else ctx.getString(R.string.filter_empty, label),
                )
            }
        }
    }
}
