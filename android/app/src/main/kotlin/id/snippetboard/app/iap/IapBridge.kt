package id.snippetboard.app.iap

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import com.samsung.android.sdk.iap.lib.constants.HelperDefine
import com.samsung.android.sdk.iap.lib.helper.IapHelper
import id.snippetboard.app.core.SnippetStore
import io.flutter.plugin.common.MethodChannel

/**
 * Samsung IAP 6.x untuk `pro_lifetime` (non-consumable) — channel `iapProduct/iapPurchase/iapRestore`
 * (docs/contracts/method-channel.md). Jaringan hanya lewat aplikasi Galaxy Store (FR-030).
 */
// shortcut: status Pro disimpan lokal tanpa verifikasi receipt, upgrade jika pembajakan signifikan
class IapBridge(private val context: Context) {
    private val store = SnippetStore(context)

    private fun helper(): IapHelper? {
        if (!storeInstalled()) return null
        return IapHelper.getInstance(context).apply {
            setOperationMode(
                // AGP 8 tidak membuat BuildConfig secara default; debuggable = build debug.
                if ((context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0) HelperDefine.OperationMode.OPERATION_MODE_TEST
                else HelperDefine.OperationMode.OPERATION_MODE_PRODUCTION,
            )
        }
    }

    private fun storeInstalled() = try {
        context.packageManager.getPackageInfo(GALAXY_STORE, 0)
        true
    } catch (_: PackageManager.NameNotFoundException) {
        false
    }

    private fun unavailable(r: MethodChannel.Result) = r.error("IAP_UNAVAILABLE", "Galaxy Store tidak tersedia", null)

    private fun setPro(pro: Boolean) {
        store.putSetting("is_pro", if (pro) "1" else "0")
        store.putSetting("pro_verified_at", System.currentTimeMillis().toString())
    }

    fun product(r: MethodChannel.Result) {
        val h = helper() ?: return unavailable(r)
        h.getProductsDetails(PRODUCT_ID) { error, products ->
            val p = products?.firstOrNull { it.itemId == PRODUCT_ID }
            if (error.errorCode != HelperDefine.IAP_ERROR_NONE || p == null) {
                r.error("IAP_UNAVAILABLE", error.errorString, null)
            } else {
                r.success(mapOf("price" to p.itemPriceString))
            }
        }
    }

    fun purchase(r: MethodChannel.Result) {
        val h = helper() ?: return unavailable(r)
        val started = h.startPayment(PRODUCT_ID, "", { error, purchase ->
            when {
                error.errorCode == HelperDefine.IAP_PAYMENT_IS_CANCELED -> r.success(mapOf("status" to "cancelled"))
                error.errorCode != HelperDefine.IAP_ERROR_NONE || purchase == null ->
                    r.error("IAP_FAILED", error.errorString, null) // status Pro tidak diubah
                else -> {
                    setPro(true)
                    r.success(mapOf("status" to "purchased"))
                }
            }
        })
        if (!started) r.error("IAP_FAILED", "startPayment ditolak (pembayaran lain sedang berjalan)", null)
    }

    /** Sukses → `is_pro` mengikuti daftar milik (refund → "0"); gagal → status lokal dipertahankan (FR-037). */
    fun restore(r: MethodChannel.Result) {
        val h = helper() ?: return unavailable(r)
        h.getOwnedList(HelperDefine.PRODUCT_TYPE_ITEM) { error, owned ->
            if (error.errorCode != HelperDefine.IAP_ERROR_NONE || owned == null) {
                r.error("IAP_FAILED", error.errorString, null)
            } else {
                val pro = owned.any { it.itemId == PRODUCT_ID }
                setPro(pro)
                r.success(mapOf("isPro" to pro))
            }
        }
    }

    companion object {
        const val PRODUCT_ID = "pro_lifetime"
        const val GALAXY_STORE = "com.sec.android.app.samsungapps"
    }
}
