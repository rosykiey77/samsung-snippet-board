package id.snippetboard.app.picker

import android.app.Activity
import android.app.AlertDialog
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.text.Editable
import android.text.InputType
import android.text.TextWatcher
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.view.inputmethod.EditorInfo
import android.widget.AbsListView
import android.widget.ArrayAdapter
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.ListView
import android.widget.TextView
import id.snippetboard.app.R
import id.snippetboard.app.core.CopyFlow
import id.snippetboard.app.core.SnippetStore
import id.snippetboard.app.edge.EdgeModel

/**
 * Activity translucent untuk menyalin tanpa membuka Flutter (ui-specs §5.5, §6.2, §7).
 * - [ACTION_COPY] + [EXTRA_ID]: salin langsung; variabel kosong → dialog isian native.
 * - [ACTION_PICK]: daftar ringkas untuk Tile/Overlay (tanpa keyboard otomatis).
 * - [ACTION_SEARCH]: cari snippet (keyboard langsung terbuka) → ketuk → alur copy yang sama.
 */
class PickerActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (savedInstanceState != null) return finish() // jangan salin ulang setelah rotasi/recreate
        when (intent.action) {
            ACTION_SEARCH -> showSearch(autofocus = true)
            ACTION_PICK -> showSearch(autofocus = false)
            else -> intent.getLongExtra(EXTRA_ID, -1).let { if (it < 0) finish() else copy(it, emptyMap()) }
        }
    }

    private fun copy(id: Long, overrides: Map<String, String>) {
        // performHapticFeedback butuh view yang sudah ter-attach; post() menunda sampai itu terjadi.
        val decor = window.decorView
        decor.post {
            when (val s = CopyFlow.run(this, id, overrides, decor)) {
                CopyFlow.Status.Copied, CopyFlow.Status.NotFound -> finish()
                is CopyFlow.Status.NeedsInput -> askVariables(id, s.missing)
            }
        }
    }

    private fun askVariables(id: Long, missing: List<String>) {
        val pad = resources.getDimensionPixelSize(R.dimen.space_3)
        val box = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; setPadding(pad, pad / 2, pad, 0) }
        val fields = missing.map { name ->
            box.addView(TextView(this).apply {
                setText(if (name == "rekening") R.string.var_rekening else R.string.var_nama)
                setTextAppearance(R.style.TextAppearance_SnippetBoard_Label)
            })
            EditText(this).apply {
                minHeight = resources.getDimensionPixelSize(R.dimen.touch_min)
                inputType = if (name == "rekening") InputType.TYPE_CLASS_NUMBER
                else InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_CAP_WORDS
                isSingleLine = true
                box.addView(this)
            }
        }
        lateinit var dialog: AlertDialog
        fun submit() {
            if (fields.any { it.text.isBlank() }) return
            dialog.dismiss()
            copy(id, missing.zip(fields) { n, f -> n to f.text.toString().trim() }.toMap())
        }
        dialog = AlertDialog.Builder(this)
            .setTitle(R.string.var_title)
            .setView(box)
            .setPositiveButton(R.string.action_copy, null) // listener dipasang setelah show() agar tidak auto-dismiss
            .setNegativeButton(R.string.action_cancel) { _, _ -> finish() }
            .setOnCancelListener { finish() } // back / tap luar: tidak menyalin (FR-017)
            .create()
        dialog.window?.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_STATE_VISIBLE)
        dialog.show()
        val ok = dialog.getButton(AlertDialog.BUTTON_POSITIVE)
        ok.setOnClickListener { submit() }
        fun refresh() { ok.isEnabled = fields.none { it.text.isBlank() } }
        fields.forEach { it.onChange { refresh() } }
        fields.last().apply {
            imeOptions = EditorInfo.IME_ACTION_DONE
            setOnEditorActionListener { _, a, _ -> (a == EditorInfo.IME_ACTION_DONE).also { if (it) submit() } }
        }
        refresh()
        fields.first().requestFocus()
    }

    private fun showSearch(autofocus: Boolean) {
        val all = SnippetStore(this).list(limit = 500)
        val pad = resources.getDimensionPixelSize(R.dimen.space_3)
        val search = EditText(this).apply {
            hint = getString(R.string.search_hint)
            isSingleLine = true
            minHeight = resources.getDimensionPixelSize(R.dimen.touch_min)
        }
        val empty = TextView(this).apply {
            setText(R.string.empty_state)
            setPadding(0, pad, 0, pad)
            textAlignment = View.TEXT_ALIGNMENT_CENTER
        }
        val adapter = object : ArrayAdapter<SnippetStore.Snippet>(
            this, android.R.layout.simple_list_item_2, android.R.id.text1, all.toMutableList(),
        ) {
            override fun getView(position: Int, convertView: View?, parent: ViewGroup): View =
                super.getView(position, convertView, parent).apply {
                    val s = getItem(position)!!
                    findViewById<TextView>(android.R.id.text1).text = s.title
                    findViewById<TextView>(android.R.id.text2).apply {
                        text = EdgeModel.preview(s.body, s.category)
                        maxLines = 1
                    }
                }
        }
        val list = ListView(this).apply {
            this.adapter = adapter
            layoutParams = AbsListView.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        }
        val box = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(pad, pad / 2, pad, 0)
            addView(search)
            addView(empty)
            addView(list)
        }
        list.emptyView = empty

        val dialog = AlertDialog.Builder(this)
            .setTitle(R.string.pick_title)
            .setView(box)
            .setNegativeButton(R.string.action_cancel) { _, _ -> finish() }
            .setOnCancelListener { finish() }
            .create()
        search.onChange { q ->
            adapter.clear()
            adapter.addAll(all.filter { EdgeModel.matches(it, q) })
        }
        list.setOnItemClickListener { _, _, position, _ ->
            val s = adapter.getItem(position) ?: return@setOnItemClickListener
            dialog.dismiss()
            copy(s.id, emptyMap())
        }
        // ui-specs §7: keyboard otomatis HANYA di mode search (Edge); tile/overlay mulai dari daftar.
        dialog.window?.setSoftInputMode(
            if (autofocus) WindowManager.LayoutParams.SOFT_INPUT_STATE_ALWAYS_VISIBLE
            else WindowManager.LayoutParams.SOFT_INPUT_STATE_ALWAYS_HIDDEN,
        )
        dialog.show()
        if (autofocus) search.requestFocus()
    }

    private fun EditText.onChange(f: (String) -> Unit) = addTextChangedListener(object : TextWatcher {
        override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
        override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
        override fun afterTextChanged(s: Editable?) = f(s.toString())
    })

    companion object {
        const val ACTION_COPY = "id.snippetboard.app.picker.COPY"
        const val ACTION_SEARCH = "id.snippetboard.app.picker.SEARCH"
        const val ACTION_PICK = "id.snippetboard.app.picker.PICK"
        const val EXTRA_ID = "snippet_id"

        /** Picker ringkas untuk Tile & Overlay (dipanggil dari Service → butuh NEW_TASK). */
        fun pickIntent(ctx: Context): Intent = Intent(ctx, PickerActivity::class.java)
            .setAction(ACTION_PICK)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
    }
}
