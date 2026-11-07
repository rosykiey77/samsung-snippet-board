import 'dart:convert';

import 'package:drift/drift.dart';

import '../platform/native_bridge.dart';
import 'db.dart';
import 'snippet_repo.dart';

/// File impor bukan backup Snippet Board, atau isinya tidak valid.
class ImportInvalid implements Exception {
  const ImportInvalid(this.reason);
  final String reason;
  @override
  String toString() => 'ImportInvalid($reason)';
}

/// Pengaturan (tabel `settings`, dibaca juga oleh Kotlin) + akses cepat + ekspor/impor.
class SettingsRepo {
  SettingsRepo(this.db, this.bridge);
  final AppDb db;
  final NativeBridge bridge;

  static const varNama = 'var_nama', varRekening = 'var_rekening', overlayEnabled = 'overlay_enabled';
  static const _format = 'snippetboard', _version = 1;

  Stream<String?> watch(String key) =>
      (db.select(db.settings)..where((t) => t.key.equals(key))).watchSingleOrNull().map((r) => r?.value);

  /// Kosong = tanyakan saat menyalin (VariableResolver menganggap blank sebagai "tidak ada").
  Future<void> setVariable(String key, String value) async {
    if (key != varNama && key != varRekening) throw ArgumentError.value(key, 'key');
    await db.setSetting(key, value.trim());
    await bridge.refreshSurfaces();
  }

  /// false = izin overlay belum diberikan; status tidak berubah.
  Future<bool> setOverlay(bool enabled) async {
    if (await bridge.setOverlayEnabled(enabled) != 'ok') return false;
    await db.setSetting(overlayEnabled, enabled ? '1' : '0');
    return true;
  }

  /// JSON berisi snippet + nilai default variabel. Status Pro sengaja tidak ikut.
  Future<String> exportJson() async {
    final rows = await (db.select(db.snippets)..orderBy([(s) => OrderingTerm.asc(s.id)])).get();
    return const JsonEncoder.withIndent('  ').convert({
      'format': _format,
      'version': _version,
      'settings': {for (final k in [varNama, varRekening]) k: ?await db.getSetting(k)},
      'snippets': [
        for (final s in rows)
          {'title': s.title, 'body': s.body, 'category': s.category, 'pinned': s.pinned, 'createdAt': s.createdAt},
      ],
    });
  }

  /// Menambah snippet dari [text] (duplikat judul+isi dilewati) dan menimpa default variabel.
  /// Semua-atau-tidak-sama-sekali: input invalid / melewati batas gratis → tidak ada yang ditulis.
  /// Mengembalikan jumlah snippet baru.
  Future<int> importJson(String text) async {
    final Object? root;
    try {
      root = jsonDecode(text);
    } on FormatException {
      throw const ImportInvalid('json');
    }
    if (root is! Map || root['format'] != _format || root['version'] != _version) {
      throw const ImportInvalid('format');
    }
    final list = root['snippets'], vars = root['settings'] ?? const {};
    if (list is! List || vars is! Map) throw const ImportInvalid('format');

    final now = DateTime.now().millisecondsSinceEpoch;
    final incoming = <SnippetsCompanion>[];
    for (final e in list) {
      if (e is! Map || e['title'] is! String || e['body'] is! String) throw const ImportInvalid('snippet');
      final category = e['category'] is int ? e['category'] as int : Category.personal;
      final String title;
      try {
        title = SnippetRepo.validate(e['title'] as String, e['body'] as String, category);
      } on Object {
        throw const ImportInvalid('snippet');
      }
      incoming.add(SnippetsCompanion.insert(
        title: title,
        body: e['body'] as String,
        category: Value(category),
        pinned: Value(e['pinned'] == true),
        createdAt: e['createdAt'] is int ? e['createdAt'] as int : now,
        updatedAt: now,
      ));
    }

    final added = await db.transaction(() async {
      final existing = {for (final s in await db.select(db.snippets).get()) (s.title, s.body)};
      final fresh = [
        for (final c in incoming)
          if (existing.add((c.title.value, c.body.value))) c, // add() false = duplikat (juga di dalam file)
      ];
      if (await db.getSetting('is_pro') != '1' && existing.length > SnippetRepo.freeLimit && fresh.isNotEmpty) {
        throw const FreeLimitReached();
      }
      await db.batch((b) => b.insertAll(db.snippets, fresh));
      for (final k in [varNama, varRekening]) {
        if (vars[k] is String) await db.setSetting(k, (vars[k] as String).trim());
      }
      return fresh.length;
    });
    await bridge.refreshSurfaces();
    return added;
  }
}
