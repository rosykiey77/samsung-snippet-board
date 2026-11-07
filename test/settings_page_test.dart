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
import 'package:snippetboard/ui/settings_page.dart';
import 'package:snippetboard/ui/theme.dart';

import 'ui_test.dart' show disposeTree, settle;

class _FakeBridge extends Fake implements NativeBridge {
  var status = {'edgeSupported': false, 'edge': true, 'tile': true, 'overlayPermission': false};
  final surfaces = <(String, bool)>[];
  int permissionOpened = 0;

  @override
  Future<void> refreshSurfaces() async {}
  @override
  Future<Map<String, bool>> surfaceStatus() async => status;
  @override
  Future<void> setSurfaceEnabled(String surface, bool enabled) async => surfaces.add((surface, enabled));
  @override
  Future<bool> requestAddTile() async => true;
  @override
  Future<String> setOverlayEnabled(bool enabled) async =>
      status['overlayPermission']! || !enabled ? 'ok' : 'needsPermission';
  @override
  Future<void> openOverlayPermission() async => permissionOpened++;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDb db;
  late _FakeBridge bridge;

  setUp(() {
    db = AppDb(NativeDatabase.memory());
    bridge = _FakeBridge();
  });

  Future<void> pump(WidgetTester t) async {
    await t.pumpWidget(AppScope(
      db: db,
      repo: SnippetRepo(db, bridge),
      bridge: bridge,
      settings: SettingsRepo(db, bridge),
      child: MaterialApp(
        locale: const Locale('id'),
        theme: buildOneUiTheme(Brightness.light),
        localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
        supportedLocales: const [Locale('id'), Locale('en')],
        home: const SettingsPage(),
      ),
    ));
    await settle(t);
  }

  Future<void> tearDownDb(WidgetTester t) async {
    await disposeTree(t);
    await t.runAsync(db.close);
  }

  testWidgets('nama default disimpan ke settings; rekening ditampilkan termasking', (t) async {
    await t.runAsync(() => db.setSetting('var_rekening', '1234567890'));
    await pump(t);
    expect(find.text('•••• 7890'), findsOneWidget);
    expect(find.text('1234567890'), findsNothing);

    await t.tap(find.text('Nama default'));
    await settle(t);
    await t.enterText(find.byType(TextField), 'Budi');
    await t.tap(find.widgetWithText(TextButton, 'Simpan'));
    await settle(t);
    expect(await t.runAsync(() => db.getSetting('var_nama')), 'Budi');
    expect(find.text('Budi'), findsOneWidget);
    await tearDownDb(t);
  });

  testWidgets('Edge disembunyikan bila tidak didukung; switch tile memanggil native', (t) async {
    await pump(t);
    expect(find.text('Edge Panel'), findsNothing);
    await t.tap(find.widgetWithText(SwitchListTile, 'Tile Quick Settings'));
    await settle(t);
    expect(bridge.surfaces, [('tile', false)]);
    await tearDownDb(t);
  });

  testWidgets('overlay tanpa izin: dialog penjelasan dulu, lalu buka izin; status tetap off', (t) async {
    await pump(t);
    await t.tap(find.widgetWithText(SwitchListTile, 'Tombol mengambang'));
    await settle(t);
    expect(find.text('Izinkan tampil di atas aplikasi lain'), findsOneWidget);
    expect(bridge.permissionOpened, 0);
    await t.tap(find.text('Buka pengaturan'));
    await settle(t);
    expect(bridge.permissionOpened, 1);
    expect(await t.runAsync(() => db.getSetting('overlay_enabled')), isNull);
    await tearDownDb(t);
  });
}
