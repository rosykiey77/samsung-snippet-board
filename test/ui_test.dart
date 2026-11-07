import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:snippetboard/app_scope.dart';
import 'package:snippetboard/data/db.dart';
import 'package:snippetboard/data/settings_repo.dart';
import 'package:snippetboard/data/snippet_repo.dart';
import 'package:snippetboard/l10n/app_localizations.dart';
import 'package:snippetboard/platform/native_bridge.dart';
import 'package:snippetboard/ui/home_page.dart';
import 'package:snippetboard/ui/theme.dart';

class _FakeBridge extends Fake implements NativeBridge {
  final calls = <(int, Map<String, String>)>[];
  List<String> missing = const [];
  bool fail = false;

  @override
  Future<void> refreshSurfaces() async {}

  @override
  Future<CopyResult> copySnippet(int id, {Map<String, String> overrides = const {}}) async {
    calls.add((id, overrides));
    if (fail) throw Exception('native');
    return overrides.isEmpty && missing.isNotEmpty ? NeedsInput(missing) : const Copied();
  }
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

  Future<void> pumpHome(WidgetTester t) async {
    await t.pumpWidget(AppScope(
      db: db,
      repo: repo,
      bridge: bridge,
      settings: SettingsRepo(db, bridge),
      child: MaterialApp(
        locale: const Locale('id'),
        theme: buildOneUiTheme(Brightness.light),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          // versi material_ui: GlobalCupertinoLocalizations dari cupertino_ui, bukan flutter_localizations.
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: const [Locale('id'), Locale('en')],
        home: const HomePage(),
      ),
    ));
    await settle(t);
  }

  // drift menjalankan query di isolate/IO nyata → beri waktu riil, lalu pump frame.
  Future<void> run(WidgetTester t, Future<void> Function() f) async {
    await t.runAsync(f);
    await settle(t);
  }

  tearDown(() async {
    await db.close();
  });

  testWidgets('empty state lalu kartu muncul setelah create', (t) async {
    await pumpHome(t);
    expect(find.text('Snippet Board'), findsOneWidget);
    expect(find.text('Belum ada snippet'), findsOneWidget);
    await run(t, () => repo.create(title: 'Alamat', body: 'Jl. Melati 12'));
    expect(find.text('Alamat'), findsOneWidget);
    await disposeTree(t);
  });

  testWidgets('ketuk kartu → copySnippet, state Disalin lalu kembali', (t) async {
    await t.runAsync(() => repo.create(title: 'Alamat', body: 'Jl. Melati 12'));
    await pumpHome(t);
    await t.tap(find.text('Alamat'));
    await t.pump();
    await t.pump();
    expect(bridge.calls.single.$2, isEmpty);
    expect(find.text('Disalin'), findsOneWidget);
    await t.pump(OneUiMotion.copiedHold + const Duration(milliseconds: 400));
    expect(find.text('Disalin'), findsNothing);
    await disposeTree(t);
  });

  testWidgets('copy gagal → snackbar error', (t) async {
    await t.runAsync(() => repo.create(title: 'A', body: 'b'));
    bridge.fail = true;
    await pumpHome(t);
    await t.tap(find.text('A'));
    await t.pump();
    await t.pump();
    expect(find.text('Gagal menyalin. Coba lagi.'), findsOneWidget);
    await disposeTree(t);
  });

  testWidgets('NeedsInput → dialog; Salin nonaktif sampai terisi; overrides dikirim', (t) async {
    await t.runAsync(() => repo.create(title: 'Salam', body: 'Halo {nama} {rekening}'));
    bridge.missing = ['nama', 'rekening'];
    await pumpHome(t);
    await t.tap(find.text('Salam'));
    await t.pumpAndSettle();
    expect(find.text('Lengkapi variabel'), findsOneWidget);
    TextButton salin() => t.widget<TextButton>(find.widgetWithText(TextButton, 'Salin'));
    expect(salin().onPressed, isNull);
    await t.enterText(find.byType(TextField).at(0), 'Budi');
    await t.pump();
    expect(salin().onPressed, isNull);
    await t.enterText(find.byType(TextField).at(1), '1234567890');
    await t.pump();
    await t.tap(find.text('Salin'));
    await t.pumpAndSettle();
    expect(bridge.calls.last.$2, {'nama': 'Budi', 'rekening': '1234567890'});
    expect(find.text('Disalin'), findsOneWidget);
    await disposeTree(t);
  });

  testWidgets('NeedsInput dibatalkan → tidak menyalin', (t) async {
    await t.runAsync(() => repo.create(title: 'Salam', body: 'Halo {nama}'));
    bridge.missing = ['nama'];
    await pumpHome(t);
    await t.tap(find.text('Salam'));
    await t.pumpAndSettle();
    await t.tap(find.text('Batal'));
    await t.pumpAndSettle();
    expect(bridge.calls, hasLength(1));
    expect(find.text('Disalin'), findsNothing);
    await disposeTree(t);
  });

  testWidgets('Rekening termasking; tombol mata membuka 10 detik', (t) async {
    await t.runAsync(() => repo.create(title: 'BCA', body: 'BCA 1234567890', category: Category.account));
    await pumpHome(t);
    expect(find.text('BCA •••• 7890'), findsOneWidget);
    await t.tap(find.byTooltip('Tampilkan nomor'));
    await t.pumpAndSettle();
    expect(find.text('BCA 1234567890'), findsOneWidget);
    await t.pump(const Duration(seconds: 10));
    await t.pumpAndSettle();
    expect(find.text('BCA •••• 7890'), findsOneWidget);
    await disposeTree(t);
  });

  testWidgets('chip kategori memfilter; ketuk lagi → Semua', (t) async {
    await t.runAsync(() async {
      await repo.create(title: 'Pribadi', body: 'a');
      await repo.create(title: 'Kantor', body: 'b', category: Category.work);
    });
    await pumpHome(t);
    await t.tap(find.text('Kerja'));
    await settle(t);
    expect(find.text('Kantor'), findsOneWidget);
    expect(find.text('Pribadi'), findsNothing);
    await t.tap(find.text('Kerja'));
    await settle(t);
    expect(find.text('Pribadi'), findsOneWidget);
    await disposeTree(t);
  });

  testWidgets('editor: validasi isi kosong, lalu simpan dengan kategori', (t) async {
    await pumpHome(t);
    await t.tap(find.text('Tambah'));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(TextButton, 'Simpan'));
    await settle(t);
    expect(find.text('Isi tidak boleh kosong'), findsOneWidget);
    await t.enterText(find.byType(TextField).at(0), 'Kantor');
    await t.tap(find.text('Kerja'));
    await t.enterText(find.byType(TextField).at(1), 'Jl. Sudirman');
    await t.pump();
    expect(find.text('Pratinjau'), findsOneWidget);
    await t.tap(find.widgetWithText(TextButton, 'Simpan'));
    await settle(t);
    final rows = (await t.runAsync(() => repo.watch().first))!;
    expect(rows.single.category, Category.work);
    expect(find.text('Kantor'), findsOneWidget); // kembali ke Home
    await disposeTree(t);
  });

  testWidgets('tekan lama → Hapus → Urungkan memulihkan', (t) async {
    await t.runAsync(() => repo.create(title: 'Alamat', body: 'x'));
    await pumpHome(t);
    await t.longPress(find.text('Alamat'));
    await t.pumpAndSettle();
    await t.tap(find.text('Hapus'));
    await settle(t);
    expect(find.text('Alamat'), findsNothing);
    expect(find.text('Snippet dihapus'), findsOneWidget);
    await t.tap(find.text('Urungkan'));
    await settle(t);
    expect(find.text('Alamat'), findsOneWidget);
    await disposeTree(t);
  });
}

/// Bolak-balik antara waktu riil (drift) dan frame sampai UI stabil.
Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 5; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await t.pump(const Duration(milliseconds: 350));
  }
}

/// Lepas stream drift sebelum db ditutup agar tidak ada timer menggantung.
Future<void> disposeTree(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
  await t.pump(const Duration(seconds: 1));
}
