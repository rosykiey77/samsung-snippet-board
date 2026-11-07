package id.snippetboard.app.edge

import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import id.snippetboard.app.R
import id.snippetboard.app.core.SnippetStore
import id.snippetboard.app.picker.PickerActivity
import id.snippetboard.app.ui.CategoryTokens

/** Isi `edge_list` di Edge Panel. Kategori aktif dibaca dari [SnippetEdgeProvider.category]. */
class EdgeListService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory = Factory(applicationContext)

    class Factory(private val ctx: Context) : RemoteViewsFactory {
        private var items = emptyList<SnippetStore.Snippet>()

        override fun onCreate() {}
        override fun onDestroy() {}

        override fun onDataSetChanged() {
            items = SnippetStore(ctx).list(SnippetEdgeProvider.category(ctx), EdgeModel.LIMIT)
        }

        override fun getCount() = items.size
        override fun getItemId(position: Int) = items.getOrNull(position)?.id ?: position.toLong()
        override fun hasStableIds() = true
        override fun getViewTypeCount() = 1
        override fun getLoadingView(): RemoteViews? = null

        override fun getViewAt(position: Int): RemoteViews {
            val rv = RemoteViews(ctx.packageName, R.layout.edge_item)
            // Daftar bisa berubah di antara getCount dan getViewAt.
            val s = items.getOrNull(position) ?: return rv
            rv.setTextViewText(R.id.edge_item_title, s.title)
            rv.setTextViewText(R.id.edge_item_body, EdgeModel.preview(s.body, s.category))
            CategoryTokens.color.getOrNull(s.category)?.let {
                rv.setInt(R.id.edge_item_dot, "setColorFilter", ctx.getColor(it))
            }
            rv.setViewVisibility(R.id.edge_item_pin, if (s.pinned) View.VISIBLE else View.GONE)
            rv.setContentDescription(
                R.id.edge_item,
                ctx.getString(if (EdgeModel.isSensitive(s.category)) R.string.cd_copy_masked else R.string.cd_copy, s.title),
            )
            rv.setOnClickFillInIntent(R.id.edge_item, Intent().putExtra(PickerActivity.EXTRA_ID, s.id))
            return rv
        }
    }
}
