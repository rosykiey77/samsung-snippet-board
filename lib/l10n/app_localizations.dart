import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// App name shown in the header and task switcher
  ///
  /// In en, this message translates to:
  /// **'Snippet Board'**
  String get appTitle;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @categoryPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get categoryPersonal;

  /// No description provided for @categoryWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get categoryWork;

  /// No description provided for @categoryAccount.
  ///
  /// In en, this message translates to:
  /// **'Bank account'**
  String get categoryAccount;

  /// No description provided for @categoryChatTemplate.
  ///
  /// In en, this message translates to:
  /// **'Chat templates'**
  String get categoryChatTemplate;

  /// No description provided for @emptyState.
  ///
  /// In en, this message translates to:
  /// **'No snippets yet'**
  String get emptyState;

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @pin.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get pin;

  /// No description provided for @unpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get unpin;

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'Snippet deleted'**
  String get deleted;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @copyFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t copy. Try again.'**
  String get copyFailed;

  /// No description provided for @copiedAnnounce.
  ///
  /// In en, this message translates to:
  /// **'Copied: {title}'**
  String copiedAnnounce(String title);

  /// No description provided for @tapToCopy.
  ///
  /// In en, this message translates to:
  /// **'Double tap to copy'**
  String get tapToCopy;

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// No description provided for @pinned.
  ///
  /// In en, this message translates to:
  /// **'pinned'**
  String get pinned;

  /// No description provided for @showNumber.
  ///
  /// In en, this message translates to:
  /// **'Show number'**
  String get showNumber;

  /// No description provided for @hideNumber.
  ///
  /// In en, this message translates to:
  /// **'Hide number'**
  String get hideNumber;

  /// No description provided for @emptyBody.
  ///
  /// In en, this message translates to:
  /// **'Save text you type often, then copy it with one tap.'**
  String get emptyBody;

  /// No description provided for @createFirst.
  ///
  /// In en, this message translates to:
  /// **'Create first snippet'**
  String get createFirst;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No snippets in this category'**
  String get noResults;

  /// No description provided for @clearFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear filter'**
  String get clearFilter;

  /// No description provided for @newSnippet.
  ///
  /// In en, this message translates to:
  /// **'New snippet'**
  String get newSnippet;

  /// No description provided for @editSnippet.
  ///
  /// In en, this message translates to:
  /// **'Edit snippet'**
  String get editSnippet;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @titleHint.
  ///
  /// In en, this message translates to:
  /// **'Auto from the first 30 characters'**
  String get titleHint;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @bodyLabel.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get bodyLabel;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @bodyEmpty.
  ///
  /// In en, this message translates to:
  /// **'Content can\'t be empty'**
  String get bodyEmpty;

  /// No description provided for @titleTooLong.
  ///
  /// In en, this message translates to:
  /// **'Title is too long'**
  String get titleTooLong;

  /// No description provided for @freeLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Limit reached'**
  String get freeLimitTitle;

  /// No description provided for @freeLimitBody.
  ///
  /// In en, this message translates to:
  /// **'The free version holds up to 10 snippets.'**
  String get freeLimitBody;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @discardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get discardTitle;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get keepEditing;

  /// No description provided for @fillVariables.
  ///
  /// In en, this message translates to:
  /// **'Fill in variables'**
  String get fillVariables;

  /// No description provided for @varNama.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get varNama;

  /// No description provided for @varRekening.
  ///
  /// In en, this message translates to:
  /// **'Account number'**
  String get varRekening;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @variablesGroup.
  ///
  /// In en, this message translates to:
  /// **'Variables'**
  String get variablesGroup;

  /// No description provided for @defaultNama.
  ///
  /// In en, this message translates to:
  /// **'Default name'**
  String get defaultNama;

  /// No description provided for @defaultRekening.
  ///
  /// In en, this message translates to:
  /// **'Default account number'**
  String get defaultRekening;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set — asked when copying'**
  String get notSet;

  /// No description provided for @quickAccessGroup.
  ///
  /// In en, this message translates to:
  /// **'Quick access'**
  String get quickAccessGroup;

  /// No description provided for @edgePanel.
  ///
  /// In en, this message translates to:
  /// **'Edge Panel'**
  String get edgePanel;

  /// No description provided for @edgePanelHint.
  ///
  /// In en, this message translates to:
  /// **'Show the snippet panel in the Edge Panel list'**
  String get edgePanelHint;

  /// No description provided for @quickTile.
  ///
  /// In en, this message translates to:
  /// **'Quick Settings tile'**
  String get quickTile;

  /// No description provided for @quickTileHint.
  ///
  /// In en, this message translates to:
  /// **'Open snippets from the notification panel'**
  String get quickTileHint;

  /// No description provided for @addTile.
  ///
  /// In en, this message translates to:
  /// **'Add tile to Quick Settings'**
  String get addTile;

  /// No description provided for @tileManual.
  ///
  /// In en, this message translates to:
  /// **'Swipe down the notification panel, tap Edit, then drag \"Quick Snippet\" in.'**
  String get tileManual;

  /// No description provided for @overlay.
  ///
  /// In en, this message translates to:
  /// **'Floating button'**
  String get overlay;

  /// No description provided for @overlayHint.
  ///
  /// In en, this message translates to:
  /// **'A draggable bubble over other apps'**
  String get overlayHint;

  /// No description provided for @overlayPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow display over other apps'**
  String get overlayPermissionTitle;

  /// No description provided for @overlayPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'The floating button needs permission to appear over other apps. It only opens your snippet list; nothing is read from the screen.'**
  String get overlayPermissionBody;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @dataGroup.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get dataGroup;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get exportData;

  /// No description provided for @exportHint.
  ///
  /// In en, this message translates to:
  /// **'Saved as JSON. Account numbers are not masked in the file.'**
  String get exportHint;

  /// No description provided for @importData.
  ///
  /// In en, this message translates to:
  /// **'Import data'**
  String get importData;

  /// No description provided for @exportDone.
  ///
  /// In en, this message translates to:
  /// **'Data exported'**
  String get exportDone;

  /// No description provided for @importDone.
  ///
  /// In en, this message translates to:
  /// **'{count} snippets imported'**
  String importDone(int count);

  /// No description provided for @importInvalid.
  ///
  /// In en, this message translates to:
  /// **'This file is not a Snippet Board backup'**
  String get importInvalid;

  /// No description provided for @fileError.
  ///
  /// In en, this message translates to:
  /// **'Could not read or write the file'**
  String get fileError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
