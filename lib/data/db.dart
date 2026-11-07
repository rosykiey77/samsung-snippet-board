import 'package:drift/drift.dart';
import 'package:drift_sqflite/drift_sqflite.dart';

part 'db.g.dart';

/// Kategori snippet (key DB, data-model.md). Rekening ⇒ clipboard sensitif.
abstract final class Category {
  static const personal = 0, work = 1, account = 2, chatTemplate = 3;
  static const values = [personal, work, account, chatTemplate];
}

/// Pemilik skema `snippets.db`. Kolom yang dibaca Kotlin dikunci oleh docs/contracts/db-schema.md.
@TableIndex(name: 'idx_snippets_pinned_copied', columns: {#pinned, #lastCopiedAt})
class Snippets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()(); // 1–80, divalidasi SnippetRepo
  TextColumn get body => text()(); // 1–10.000, tidak blank
  IntColumn get category => integer().withDefault(const Constant(Category.personal))();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
  // epoch ms (bukan DateTimeColumn: drift menyimpan detik, kontrak Kotlin memakai ms).
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get lastCopiedAt => integer().nullable()();
  IntColumn get copyCount => integer().withDefault(const Constant(0))();
}

@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(tables: [Snippets, Settings])
class AppDb extends _$AppDb {
  AppDb([QueryExecutor? executor])
      : super(executor ?? SqfliteQueryExecutor.inDatabaseFolder(path: 'snippets.db'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          // PRAGMA ini mengembalikan baris → harus lewat select (execute gagal di Android).
          await customSelect('PRAGMA journal_mode=WAL').get();
        },
      );

  /// Urutan FR-004: disematkan → terakhir disalin → terbaru dibuat.
  /// Pencarian case-insensitive (ASCII, perilaku LIKE SQLite) pada judul atau isi.
  Stream<List<Snippet>> watchSnippets({int? category, String? query}) {
    final q = query?.trim() ?? '';
    final s = select(snippets);
    s.where((t) {
      Expression<bool> e = const Constant(true);
      if (category != null) e = e & t.category.equals(category);
      if (q.isNotEmpty) {
        final pattern = '%${_escapeLike(q)}%';
        e = e & (t.title.like(pattern, escapeChar: r'\') | t.body.like(pattern, escapeChar: r'\'));
      }
      return e;
    });
    s.orderBy([
      (t) => OrderingTerm.desc(t.pinned),
      (t) => OrderingTerm.desc(coalesce([t.lastCopiedAt, const Constant(0)])),
      (t) => OrderingTerm.desc(t.createdAt),
    ]);
    return s.watch();
  }

  Future<int> countSnippets() async {
    final c = countAll();
    final row = await (selectOnly(snippets)..addColumns([c])).getSingle();
    return row.read(c)!;
  }

  Future<String?> getSetting(String key) async =>
      (await (select(settings)..where((t) => t.key.equals(key))).getSingleOrNull())?.value;

  Future<void> setSetting(String key, String value) =>
      into(settings).insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));
}

/// `%` dan `_` dari input pengguna dicari literal, bukan wildcard.
String _escapeLike(String s) => s.replaceAllMapped(RegExp(r'[\\%_]'), (m) => '\\${m[0]}');
