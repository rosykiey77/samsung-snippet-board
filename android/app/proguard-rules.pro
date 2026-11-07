# Dimuat otomatis oleh Flutter Gradle Plugin untuk build release (R8).
# Samsung Slook (Edge Panel) & IAP dipanggil lewat refleksi/AIDL — jangan di-shrink/rename.
-keep class com.samsung.android.sdk.** { *; }
-keep interface com.samsung.android.sdk.** { *; }
-keep class com.samsung.android.iap.** { *; }
-dontwarn com.samsung.android.sdk.**
