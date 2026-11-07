import 'package:drift/drift.dart' show TableUpdate, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snippetboard/data/db.dart';
import 'package:snippetboard/data/snippet_repo.dart';
import 'package:snippetboard/platform/native_bridge.dart';

class _FakeBridge extends Fake implements NativeBridge {
  int refreshes = 0;
  @override
  Future<void> refreshSurfaces() async => refreshes++;
  @override
  Future<CopyResult> copySnippet(int id, {Map<String, String> overrides = const {}}) async => const Copied();
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDb db;
  late _FakeBridge bridge;
  late SnippetRepo repo;

  setUp(() {
    db = AppDb(NativeDatabase.memory());
    bridge = _FakeBridge();
    repo = SnippetRepo(db, bridge);
  });
  tearDown(() => db.close());

  Future<void> fill(int n) async {
    for (var i = 0; i < n; i++) {
      await repo.create(title: 't$i', body: 'b$i');
    }
  }

  Future<List<Snippet>> all({int? category, String? query}) =>
      repo.watch(category: category, query: query).first;

  test('snippet ke-11 ditolak saat free, diizinkan saat Pro', () async {
    await fill(10);
    expect(repo.create(title: 'x', body: 'y'), throwsA(isA<FreeLimitReached>()));
    await db.setSetting('is_pro', '1');
    await repo.create(title: 'x', body: 'y');
    expect(await db.countSnippets(), 11);
  });

  test('refund (12 snippet, is_pro=0): edit/hapus jalan, create ditolak, data utuh', () async {
    await db.setSetting('is_pro', '1');
    await fill(12);
    await db.setSetting('is_pro', '0');
    final first = (await all()).last;
    await repo.update(first.id, title: 'baru', body: 'isi baru', category: Category.work);
    expect((await all()).firstWhere((s) => s.id == first.id).title, 'baru');
    await repo.delete(first.id);
    expect(await db.countSnippets(), 11);
    expect(repo.create(title: 'x', body: 'y'), throwsA(isA<FreeLimitReached>()));
    expect(await db.countSnippets(), 11);
  });

  test('validasi body & judul otomatis', () async {
    expect(repo.create(title: 'x', body: '   \n '), throwsA(isA<SnippetInvalid>()));
    expect(repo.create(title: 'x', body: 'a' * 10001), throwsA(isA<SnippetInvalid>()));
    expect(repo.create(title: 'x' * 81, body: 'b'), throwsA(isA<SnippetInvalid>()));
    final id = await repo.create(title: '  ', body: '  Halo 👋 ini isi yang panjang sekali lebih dari tiga puluh');
    final s = (await all()).single;
    expect(s.id, id);
    expect(s.title, 'Halo 👋 ini isi yang panjang se');
    expect(s.title.runes.length, 30);
  });

  test('restore setelah delete memulihkan id dan statistik yang sama', () async {
    await fill(2);
    final victim = (await all()).first;
    final row = await repo.delete(victim.id);
    expect(await all(), hasLength(1));
    await repo.restore(row!);
    final back = (await all()).firstWhere((s) => s.id == victim.id);
    expect(back, victim);
    expect(await repo.delete(999), isNull);
  });

  test('urutan: pinned → last_copied_at → created_at', () async {
    await repo.create(title: 'a', body: 'a'); // id 1
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await repo.create(title: 'b', body: 'b'); // id 2
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await repo.create(title: 'c', body: 'c'); // id 3
    expect((await all()).map((s) => s.id), [3, 2, 1]);
    // Meniru tulisan Kotlin: drift tidak tahu, jadi beri tahu seperti main.dart saat resumed.
    await db.customUpdate('UPDATE snippets SET last_copied_at = 99 WHERE id = 1');
    db.notifyUpdates({TableUpdate.onTable(db.snippets)});
    expect((await all()).map((s) => s.id), [1, 3, 2]);
    await repo.togglePin(2);
    expect((await all()).map((s) => s.id), [2, 1, 3]);
    await repo.togglePin(2);
    expect((await all()).first.id, 1);
  });

  test('pencarian case-insensitive di judul/isi, filter kategori, wildcard literal', () async {
    await repo.create(title: 'Alamat Rumah', body: 'Jl. Merdeka');
    await repo.create(title: 'BCA', body: 'Rekening 1234567890', category: Category.account);
    await repo.create(title: 'Diskon', body: 'potongan 50% hari ini');
    expect((await all(query: 'alamat')).map((s) => s.title), ['Alamat Rumah']);
    expect((await all(query: 'MERDEKA')).map((s) => s.title), ['Alamat Rumah']);
    expect((await all(category: Category.account)).map((s) => s.title), ['BCA']);
    expect((await all(query: '%')).map((s) => s.title), ['Diskon']);
    expect(await all(query: '_'), isEmpty);
  });

  test('setiap mutasi memanggil refreshSurfaces', () async {
    final id = await repo.create(title: 'a', body: 'a');
    await repo.update(id, title: 'b', body: 'b', category: 0);
    await repo.togglePin(id);
    final row = await repo.delete(id);
    await repo.restore(row!);
    await repo.setSetting('var_nama', 'Budi');
    expect(bridge.refreshes, 6);
  });

  test('atFreeLimit & watchCount mengikuti jumlah snippet dan status Pro', () async {
    await fill(9);
    expect(await repo.atFreeLimit(), isFalse);
    await fill(1);
    expect(await repo.watchCount().first, 10);
    expect(await repo.atFreeLimit(), isTrue);
    await db.setSetting('is_pro', '1');
    expect(await repo.atFreeLimit(), isFalse);
    await db.setSetting('is_pro', '0'); // refund
    expect(await repo.atFreeLimit(), isTrue);
  });
}
