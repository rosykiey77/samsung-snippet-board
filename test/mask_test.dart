import 'package:flutter_test/flutter_test.dart';
import 'package:snippetboard/data/mask.dart';

// Kasus sama dengan MaskerTest (Kotlin) agar kedua sisi tetap identik.
void main() {
  test('6 digit', () => expect(maskSensitive('123456'), '•••• 3456'));
  test('16 digit berspasi', () => expect(maskSensitive('1234 5678 9012 3456'), '•••• 3456'));
  test('dipisah strip, teks lain tetap', () =>
      expect(maskSensitive('BCA 0123-4567-8901 a.n. Budi'), 'BCA •••• 8901 a.n. Budi'));
  test('< 6 digit tidak dimasking', () => expect(maskSensitive('PIN 12345'), 'PIN 12345'));
  test('emoji/teks campuran', () => expect(maskSensitive('💳 1234567890 ✅'), '💳 •••• 7890 ✅'));
}
