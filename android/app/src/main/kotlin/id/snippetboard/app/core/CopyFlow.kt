package id.snippetboard.app.core

import android.content.Context
import android.view.View
import java.time.LocalDate

/** Alur salin bersama: store → resolver → Copier → statistik. Dipakai MainActivity & PickerActivity. */
object CopyFlow {
    sealed interface Status {
        data object Copied : Status
        data object NotFound : Status
        data class NeedsInput(val missing: List<String>) : Status
    }

    fun run(context: Context, id: Long, overrides: Map<String, String>, view: View?): Status {
        val store = SnippetStore(context)
        val (body, category) = store.get(id) ?: return Status.NotFound
        val s = store.settings()
        val values = buildMap {
            s["var_nama"]?.let { put("nama", it) }
            s["var_rekening"]?.let { put("rekening", it) }
        }
        val locale = context.resources.configuration.locales[0]
        return when (val r = VariableResolver.resolve(body, values, overrides, locale, LocalDate.now())) {
            is VariableResolver.Result.Missing -> Status.NeedsInput(r.names)
            is VariableResolver.Result.Resolved -> {
                Copier.copy(context, r.text, sensitive = category == SnippetStore.CATEGORY_REKENING, view = view)
                store.markCopied(id, System.currentTimeMillis())
                Status.Copied
            }
        }
    }
}
