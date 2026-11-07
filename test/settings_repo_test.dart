import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snippetboard/data/db.dart';
import 'package:snippetboard/data/settings_repo.dart';
import 'package:snippetboard/data/snippet_repo.dart';
import 'package:snippetboard/platform/native_bridge.dart';

class _FakeBridge extends Fake implements NativeBridge {
  int refreshes = 0;
  String overlayStatus = 'ok';
  final overlayCalls = <bool>[];
  @override
  Future<void> refreshSurfaces() async => refreshes++;
  @override
  Future<String> setOverlayEnabled(bool enabled) async {
    overlayCalls.add(enabled);
    return overlayStatus;
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDb db;
  late _FakeBridge bridge;
  late SnippetRepo snippets;
  late SettingsRepo repo;

  setUp(() {
    db = AppDb(NativeDatabase.memory());
    bridge = _FakeBridge();
    snippets = SnippetRepo(db, bridge);
    repo = SettingsRepo(db, bridge);
  });
  tearDown(() => db.close());

  test('setVariable menyimpan trim, refresh native, dan menolak key lain', () async {
    await repo.setVariable(SettingsRepo.varNama, '  Budi ');
    expect(await db.getSetting('var_nama'), 'Budi');
    expect(bridge.refreshes, 1);
    expect(repo.setVariable('is_pro', '1'), throwsArgumentError);
  });

  test('setOverlay hanya menulis status saat native ok', () async {
    bridge.overlayStatus = 'needsPermission';
    expect(await repo.setOverlay(true), isFalse);
    expect(await db.getSetting('overlay_enabled'), isNull);
    bridge.overlayStatus = 'ok';
    expect(await repo.setOverlay(true), isTrue);
    expect(await db.getSetting('overlay_enabled'), '1');
    await repo.setOverlay(false);
    expect(await db.getSetting('overlay_enabled'), '0');
  });

  test('ekspor → impor ke DB kosong memulihkan snippet & variabel, tanpa is_pro', () async {
    await snippets.create(title: 'Alamat', body: 'Jl. Melati 12');
    await snippets.create(title: 'BCA', body: '1234567890', category: Category.account);
    await repo.setVariable(SettingsRepo.varRekening, '999888777');
    await db.setSetting('is_pro', '1');
    final json = await repo.exportJson();
    expect(jsonDecode(json), isNot(contains('is_pro')));

    final db2 = AppDb(NativeDatabase.memory());
    addTearDown(db2.close);
    final repo2 = SettingsRepo(db2, bridge);
    expect(await repo2.importJson(json), 2);
    final rows = await db2.select(db2.snippets).get();
    expect(rows.map((r) => (r.title, r.category)), containsAll([('Alamat', 0), ('BCA', Category.account)]));
    expect(await db2.getSetting('var_rekening'), '999888777');
    expect(await db2.getSetting('is_pro'), isNull);
    // Impor ulang: semua duplikat dilewati.
    expect(await repo2.importJson(json), 0);
  });

  test('file invalid ditolak tanpa menulis apa pun', () async {
    expect(repo.importJson('bukan json'), throwsA(isA<ImportInvalid>()));
    expect(repo.importJson('{"format":"lain","version":1}'), throwsA(isA<ImportInvalid>()));
    final badBody = jsonEncode({
      'format': 'snippetboard',
      'version': 1,
      'snippets': [
        {'title': 'ok', 'body': 'isi'},
        {'title': 'x', 'body': '   '},
      ],
    });
    await expectLater(repo.importJson(badBody), throwsA(isA<ImportInvalid>()));
    expect(await db.countSnippets(), 0);
  });

  test('impor yang melewati batas gratis ditolak utuh', () async {
    for (var i = 0; i < 9; i++) {
      await snippets.create(title: 't$i', body: 'b$i');
    }
    final two = jsonEncode({
      'format': 'snippetboard',
      'version': 1,
      'snippets': [
        {'title': 'a', 'body': 'a'},
        {'title': 'b', 'body': 'b'},
      ],
    });
    await expectLater(repo.importJson(two), throwsA(isA<FreeLimitReached>()));
    expect(await db.countSnippets(), 9);
    await db.setSetting('is_pro', '1');
    expect(await repo.importJson(two), 2);
  });
}
