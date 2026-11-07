import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:snippetboard/app_scope.dart';
import 'package:snippetboard/data/db.dart';
import 'package:snippetboard/data/settings_repo.dart';
import 'package:snippetboard/data/snippet_repo.dart';
import 'package:snippetboard/l10n/app_localizations.dart';
import 'package:snippetboard/platform/native_bridge.dart';
import 'package:snippetboard/ui/theme.dart';
import 'package:snippetboard/ui/upgrade_page.dart';

import 'ui_test.dart' show disposeTree, settle;

class _FakeBridge extends Fake implements NativeBridge {
  PlatformException? productError;
  bool purchased = false;
  bool owned = false;
  int purchases = 0;

  @override
  Future<void> refreshSurfaces() async {}
  @override
  Future<String> iapProduct() async => productError != null ? throw productError! : 'Rp49.000';
  @override
  Future<bool> iapPurchase() async {
    purchases++;
    return purchased;
  }

  @override
  Future<bool> iapRestore() async => owned;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDb db;
  late _FakeBridge bridge;
  bool? result;

  setUp(() {
    db = AppDb(NativeDatabase.memory());
    bridge = _FakeBridge();
    result = null;
  });
  tearDown(() => db.close());

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
        home: Builder(
          builder: (c) => TextButton(
              onPressed: () async => result = await UpgradePage.open(c), child: const Text('buka')),
        ),
      ),
    ));
    await t.tap(find.text('buka'));
    await settle(t);
  }

  testWidgets('harga lokal tampil, beli sukses → pop true', (t) async {
    bridge.purchased = true;
    await pump(t);
    expect(find.text('Snippet tanpa batas'), findsOneWidget);
    await t.tap(find.text('Beli Rp49.000'));
    await settle(t);
    expect(result, isTrue);
    expect(find.text('buka'), findsOneWidget);
    await disposeTree(t);
  });

  testWidgets('beli dibatalkan → tetap di layar dengan pesan', (t) async {
    await pump(t);
    await t.tap(find.text('Beli Rp49.000'));
    await settle(t);
    expect(result, isNull);
    expect(find.text('Pembelian dibatalkan'), findsOneWidget);
    await disposeTree(t);
  });

  testWidgets('tanpa Galaxy Store → tombol beli nonaktif + pesan', (t) async {
    bridge.productError = PlatformException(code: 'IAP_UNAVAILABLE');
    await pump(t);
    expect(find.text('Pembelian memerlukan Galaxy Store'), findsOneWidget);
    await t.tap(find.text('Upgrade ke Pro'));
    await settle(t);
    expect(bridge.purchases, 0);
    await disposeTree(t);
  });

  testWidgets('pulihkan pembelian: ada item → pop true', (t) async {
    bridge.owned = true;
    await pump(t);
    await t.tap(find.text('Pulihkan pembelian'));
    await settle(t);
    expect(result, isTrue);
    await disposeTree(t);
  });
}
