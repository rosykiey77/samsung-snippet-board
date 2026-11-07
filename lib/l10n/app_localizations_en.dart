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
  String get categoryAccount => 'Bank account';

  @override
  String get categoryChatTemplate => 'Chat templates';

  @override
  String get emptyState => 'No snippets yet';

  @override
  String get categoryAll => 'All';

  @override
  String get add => 'Add';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get pin => 'Pin';

  @override
  String get unpin => 'Unpin';

  @override
  String get deleted => 'Snippet deleted';

  @override
  String get undo => 'Undo';

  @override
  String get copyFailed => 'Couldn\'t copy. Try again.';

  @override
  String copiedAnnounce(String title) {
    return 'Copied: $title';
  }

  @override
  String get tapToCopy => 'Double tap to copy';

  @override
  String get moreOptions => 'More options';

  @override
  String get pinned => 'pinned';

  @override
  String get showNumber => 'Show number';

  @override
  String get hideNumber => 'Hide number';

  @override
  String get emptyBody =>
      'Save text you type often, then copy it with one tap.';

  @override
  String get createFirst => 'Create first snippet';

  @override
  String get noResults => 'No snippets in this category';

  @override
  String get clearFilter => 'Clear filter';

  @override
  String get newSnippet => 'New snippet';

  @override
  String get editSnippet => 'Edit snippet';

  @override
  String get save => 'Save';

  @override
  String get titleLabel => 'Title';

  @override
  String get titleHint => 'Auto from the first 30 characters';

  @override
  String get categoryLabel => 'Category';

  @override
  String get bodyLabel => 'Content';

  @override
  String get preview => 'Preview';

  @override
  String get bodyEmpty => 'Content can\'t be empty';

  @override
  String get titleTooLong => 'Title is too long';

  @override
  String get freeLimitTitle => 'Limit reached';

  @override
  String get freeLimitBody => 'The free version holds up to 10 snippets.';

  @override
  String get ok => 'OK';

  @override
  String get discardTitle => 'Discard changes?';

  @override
  String get discard => 'Discard';

  @override
  String get keepEditing => 'Keep editing';

  @override
  String get fillVariables => 'Fill in variables';

  @override
  String get varNama => 'Name';

  @override
  String get varRekening => 'Account number';

  @override
  String get cancel => 'Cancel';

  @override
  String get copy => 'Copy';
}
