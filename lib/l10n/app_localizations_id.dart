// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Snippet Board';

  @override
  String get copied => 'Disalin';

  @override
  String get categoryPersonal => 'Personal';

  @override
  String get categoryWork => 'Kerja';

  @override
  String get categoryAccount => 'Rekening';

  @override
  String get categoryChatTemplate => 'Template Chat';

  @override
  String get emptyState => 'Belum ada snippet';
}
