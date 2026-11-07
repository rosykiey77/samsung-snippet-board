/// Masking tampilan nomor rekening (ui-specs §4.1). Regex identik dengan Kotlin `core/Masker.kt`.
/// Hanya tampilan: teks yang disalin tetap lengkap.
final _digits = RegExp(r'(?<!\d)\d(?:[ .\-]?\d){5,}(?!\d)');

String maskSensitive(String body) => body.replaceAllMapped(_digits, (m) {
      final d = m[0]!.replaceAll(RegExp(r'\D'), '');
      return '•••• ${d.substring(d.length - 4)}';
    });
