// Jaminan zero-network / zero-telemetry (FR-029/030, SC-005) secara statis.
// Pelengkap, bukan pengganti, audit perangkat quickstart V16 (PCAPdroid) & V17 (aapt).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Iterable<File> _sources(String dir, String ext) => Directory(dir)
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith(ext) && !f.path.endsWith('.g.dart'));

void main() {
  test('manifest main tidak meminta izin jaringan', () {
    final m = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    for (final p in ['android.permission.INTERNET', 'android.permission.ACCESS_NETWORK_STATE', 'AD_ID']) {
      expect(m, isNot(contains(p)), reason: p);
    }
  });

  test('dependency runtime hanya dari allowlist (tanpa http/analytics/crash reporter)', () {
    const allowed = {
      'flutter', 'flutter_localizations', 'drift', 'drift_sqflite', 'dynamic_color', 'intl', 'path', 'sqflite',
      'material_ui',
    };
    final pubspec = File('pubspec.yaml').readAsLinesSync();
    final start = pubspec.indexOf('dependencies:');
    final deps = pubspec
        .skip(start + 1)
        .takeWhile((l) => l.isEmpty || l.startsWith(' '))
        .map((l) => RegExp(r'^  ([a-z0-9_]+):').firstMatch(l)?.group(1))
        .whereType<String>()
        .toSet();
    expect(deps, isNotEmpty);
    expect(deps.difference(allowed), isEmpty, reason: 'dependency baru wajib diaudit jaringan/telemetri dulu');
  });

  test('kode Dart tidak memakai API jaringan', () {
    // Pola kode/import, bukan kata biasa: teks privasi di l10n memang menyebut "analytics".
    final banned = RegExp(r'''HttpClient|WebSocket|Socket\.connect|import\s+'package:(http|dio|firebase\w*|sentry\w*|\w*analytics\w*)/''');
    for (final f in _sources('lib', '.dart')) {
      expect(banned.hasMatch(f.readAsStringSync()), isFalse, reason: f.path);
    }
  });

  test('kode Kotlin tidak memakai API jaringan', () {
    final banned = RegExp(r'HttpURLConnection|Socket\(|^import (java\.net\.|okhttp3|retrofit2|com\.google\.firebase)', multiLine: true);
    for (final f in _sources('android/app/src/main/kotlin', '.kt')) {
      expect(banned.hasMatch(f.readAsStringSync()), isFalse, reason: f.path);
    }
  });

  test('backup otomatis dimatikan (data hanya di perangkat)', () {
    final m = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(m, contains('android:allowBackup="false"'));
  });
}
