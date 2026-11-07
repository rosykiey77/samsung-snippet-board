import 'package:drift/drift.dart' show TableUpdate;
import 'package:dynamic_color/dynamic_color.dart';
import 'package:material_ui/material_ui.dart';

import 'app_scope.dart';
import 'data/db.dart';
import 'data/settings_repo.dart';
import 'data/snippet_repo.dart';
import 'l10n/app_localizations.dart';
import 'platform/native_bridge.dart';
import 'ui/home_page.dart';
import 'ui/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDb();
  const bridge = NativeBridge();
  final settings = SettingsRepo(db, bridge);
  // Pulihkan diam-diam (refund → is_pro=0). Gagal/offline → status lokal dipertahankan (FR-037).
  settings.restorePro().ignore();
  runApp(AppScope(
      db: db,
      repo: SnippetRepo(db, bridge),
      bridge: bridge,
      settings: settings,
      child: const SnippetBoardApp()));
}

class SnippetBoardApp extends StatefulWidget {
  const SnippetBoardApp({super.key});

  @override
  State<SnippetBoardApp> createState() => _SnippetBoardAppState();
}

class _SnippetBoardAppState extends State<SnippetBoardApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // Kotlin (Edge Panel/picker) menulis statistik salin di luar drift → paksa stream re-query.
    final db = AppScope.of(context).db;
    db.notifyUpdates({TableUpdate.onTable(db.snippets), TableUpdate.onTable(db.settings)});
  }

  @override
  Widget build(BuildContext context) => DynamicColorBuilder(
        builder: (lightDyn, darkDyn) => MaterialApp(
          onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,
          theme: buildOneUiTheme(Brightness.light, dynamic: lightDyn),
          darkTheme: buildOneUiTheme(Brightness.dark, dynamic: darkDyn),
          themeMode: ThemeMode.system,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            // versi material_ui: GlobalCupertinoLocalizations dari cupertino_ui, bukan flutter_localizations.
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: const [Locale('id'), Locale('en')],
          home: const HomePage(),
        ),
      );
}
