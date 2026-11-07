// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Snippet Board';

  @override
  String get copied => 'Copied';

  @override
  String get categoryPersonal => 'Personal';

  @override
  String get categoryWork => 'Work';

  @override
  String get categoryAccount => 'Account';

  @override
  String get categoryChatTemplate => 'Chat template';

  @override
  String get emptyState => 'No snippets yet';
}
