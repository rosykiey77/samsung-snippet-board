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

  @override
  String get settings => 'Settings';

  @override
  String get variablesGroup => 'Variables';

  @override
  String get defaultNama => 'Default name';

  @override
  String get defaultRekening => 'Default account number';

  @override
  String get notSet => 'Not set — asked when copying';

  @override
  String get quickAccessGroup => 'Quick access';

  @override
  String get edgePanel => 'Edge Panel';

  @override
  String get edgePanelHint => 'Show the snippet panel in the Edge Panel list';

  @override
  String get quickTile => 'Quick Settings tile';

  @override
  String get quickTileHint => 'Open snippets from the notification panel';

  @override
  String get addTile => 'Add tile to Quick Settings';

  @override
  String get tileManual =>
      'Swipe down the notification panel, tap Edit, then drag \"Quick Snippet\" in.';

  @override
  String get overlay => 'Floating button';

  @override
  String get overlayHint => 'A draggable bubble over other apps';

  @override
  String get overlayPermissionTitle => 'Allow display over other apps';

  @override
  String get overlayPermissionBody =>
      'The floating button needs permission to appear over other apps. It only opens your snippet list; nothing is read from the screen.';

  @override
  String get openSettings => 'Open settings';

  @override
  String get dataGroup => 'Data';

  @override
  String get exportData => 'Export data';

  @override
  String get exportHint =>
      'Saved as JSON. Account numbers are not masked in the file.';

  @override
  String get importData => 'Import data';

  @override
  String get exportDone => 'Data exported';

  @override
  String importDone(int count) {
    return '$count snippets imported';
  }

  @override
  String get importInvalid => 'This file is not a Snippet Board backup';

  @override
  String get fileError => 'Could not read or write the file';

  @override
  String get proGroup => 'Pro';

  @override
  String get proActive => 'Pro active — unlimited snippets';

  @override
  String get upgradeToPro => 'Upgrade to Pro';

  @override
  String get restorePurchase => 'Restore purchase';

  @override
  String get restoreNone => 'No Pro purchase found';

  @override
  String get restoreDone => 'Pro restored';

  @override
  String get proTitle => 'Snippet Pro';

  @override
  String get proUnlimited => 'Unlimited snippets';

  @override
  String get proLifetime => 'Pay once, yours forever';

  @override
  String get proOffline => 'Still 100% offline';

  @override
  String buyFor(String price) {
    return 'Buy $price';
  }

  @override
  String get iapUnavailable => 'Purchases require Galaxy Store';

  @override
  String get iapCancelled => 'Purchase cancelled';

  @override
  String get iapFailed => 'Purchase failed, nothing was changed';

  @override
  String snippetCount(int count) {
    return '$count/10 snippets';
  }

  @override
  String get upgrade => 'Upgrade';

  @override
  String get aboutGroup => 'About';

  @override
  String get privacy => 'Privacy';

  @override
  String get privacyBody => '100% offline: no internet access, no tracking or analytics. Snippets stay on this device and are not backed up automatically. The only external connection is the Galaxy Store purchase flow.';
}
