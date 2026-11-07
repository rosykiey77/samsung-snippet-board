import 'package:drift/drift.dart';

import '../platform/native_bridge.dart';
import 'db.dart';

/// Insert ditolak: pengguna gratis sudah punya [SnippetRepo.freeLimit] snippet (FR-033).
class FreeLimitReached implements Exception {
  const FreeLimitReached();
}

/// Input tidak valid; [field] = 'title' | 'body'.
class SnippetInvalid implements Exception {
  const SnippetInvalid(this.field);
  final String field;
  @override
  String toString() => 'SnippetInvalid($field)';
}

/// Semua mutasi snippet lewat sini: validasi, batas gratis, undo, dan sinkron permukaan native.
class SnippetRepo {
  SnippetRepo(this.db, this.bridge);
  final AppDb db;
  final NativeBridge bridge;

  static const freeLimit = 10, maxTitle = 80, maxBody = 10000, autoTitleLength = 30;

  int get _now => DateTime.now().millisecondsSinceEpoch;

  Stream<List<Snippet>> watch({int? category, String? query}) =>
      db.watchSnippets(category: category, query: query);

  Future<int> create({required String title, required String body, int category = Category.personal}) async {
    final t = _validate(title, body, category);
    if (await db.getSetting('is_pro') != '1' && await db.countSnippets() >= freeLimit) {
      throw const FreeLimitReached();
    }
    final now = _now;
    final id = await db.into(db.snippets).insert(SnippetsCompanion.insert(
        title: t, body: body, category: Value(category), createdAt: now, updatedAt: now));
    await bridge.refreshSurfaces();
    return id;
  }

  /// Edit selalu diizinkan berapa pun jumlah snippet (refund tidak mengunci data, FR-038).
  Future<void> update(int id, {required String title, required String body, required int category}) async {
    final t = _validate(title, body, category);
    await (db.update(db.snippets)..where((s) => s.id.equals(id))).write(
        SnippetsCompanion(title: Value(t), body: Value(body), category: Value(category), updatedAt: Value(_now)));
    await bridge.refreshSurfaces();
  }

  Future<void> togglePin(int id) async {
    await db.customUpdate('UPDATE snippets SET pinned = 1 - pinned, updated_at = ? WHERE id = ?',
        variables: [Variable.withInt(_now), Variable.withInt(id)], updates: {db.snippets});
    await bridge.refreshSurfaces();
  }

  /// Mengembalikan baris yang dihapus untuk "Urungkan" (FR-005); null jika tidak ada.
  Future<Snippet?> delete(int id) async {
    final row = await (db.select(db.snippets)..where((s) => s.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    await (db.delete(db.snippets)..where((s) => s.id.equals(id))).go();
    await bridge.refreshSurfaces();
    return row;
  }

  /// Insert ulang dengan id & statistik yang sama; tanpa cek batas karena memulihkan.
  Future<void> restore(Snippet row) async {
    await db.into(db.snippets).insert(row);
    await bridge.refreshSurfaces();
  }

  Future<String?> getSetting(String key) => db.getSetting(key);

  Future<void> setSetting(String key, String value) async {
    await db.setSetting(key, value);
    await bridge.refreshSurfaces();
  }

  /// Mengembalikan judul final. Judul kosong → 30 karakter pertama isi.
  static String _validate(String title, String body, int category) {
    if (body.trim().isEmpty || body.length > maxBody) throw const SnippetInvalid('body');
    if (!Category.values.contains(category)) throw ArgumentError.value(category, 'category');
    var t = title.trim();
    // runes, bukan code unit: jangan memotong emoji di tengah surrogate pair.
    if (t.isEmpty) t = String.fromCharCodes(body.trim().runes.take(autoTitleLength)).trim();
    if (t.length > maxTitle) throw const SnippetInvalid('title');
    return t;
  }
}
