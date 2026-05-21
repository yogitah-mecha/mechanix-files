import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @filesHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Locations'**
  String get filesHomeTitle;

  /// No description provided for @downloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// No description provided for @homeDirectory.
  ///
  /// In en, this message translates to:
  /// **'Home directory'**
  String get homeDirectory;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @hardDriveTitle.
  ///
  /// In en, this message translates to:
  /// **'Hard Drive'**
  String get hardDriveTitle;

  /// No description provided for @root.
  ///
  /// In en, this message translates to:
  /// **'Root ( / )'**
  String get root;

  /// No description provided for @fileInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get fileInfo;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @newFolder.
  ///
  /// In en, this message translates to:
  /// **'New Folder'**
  String get newFolder;

  /// No description provided for @hideFiles.
  ///
  /// In en, this message translates to:
  /// **'Hide hidden files'**
  String get hideFiles;

  /// No description provided for @showFiles.
  ///
  /// In en, this message translates to:
  /// **'Show hidden files'**
  String get showFiles;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// No description provided for @modified.
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get modified;

  /// No description provided for @accessed.
  ///
  /// In en, this message translates to:
  /// **'Accessed'**
  String get accessed;

  /// No description provided for @changed.
  ///
  /// In en, this message translates to:
  /// **'Changed'**
  String get changed;

  /// No description provided for @readable.
  ///
  /// In en, this message translates to:
  /// **'Readable'**
  String get readable;

  /// No description provided for @writable.
  ///
  /// In en, this message translates to:
  /// **'Writable'**
  String get writable;

  /// No description provided for @hidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get hidden;

  /// No description provided for @emptySearchResultsMessage.
  ///
  /// In en, this message translates to:
  /// **'No matching results found'**
  String get emptySearchResultsMessage;

  /// No description provided for @emptyFolderMessage.
  ///
  /// In en, this message translates to:
  /// **'This folder is empty'**
  String get emptyFolderMessage;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @copyTo.
  ///
  /// In en, this message translates to:
  /// **'Copy to'**
  String get copyTo;

  /// No description provided for @moveTo.
  ///
  /// In en, this message translates to:
  /// **'Move to'**
  String get moveTo;

  /// No description provided for @moveToTrash.
  ///
  /// In en, this message translates to:
  /// **'Move to trash'**
  String get moveToTrash;

  /// No description provided for @newFolderWithSingleItem.
  ///
  /// In en, this message translates to:
  /// **'New folder with this item'**
  String get newFolderWithSingleItem;

  /// No description provided for @paste.
  ///
  /// In en, this message translates to:
  /// **'Paste here'**
  String get paste;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @replace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @skipAll.
  ///
  /// In en, this message translates to:
  /// **'Skip all'**
  String get skipAll;

  /// No description provided for @moveItems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Move 1 item} other{Move {count} items}}'**
  String moveItems(int count);

  /// No description provided for @copyItems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Copy 1 item} other{Copy {count} items}}'**
  String copyItems(int count);

  /// No description provided for @pasteInNewFolder.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{New folder with \'1 item\'} other{New folder with \'{count} items\'}}'**
  String pasteInNewFolder(int count);

  /// No description provided for @trash.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get trash;

  /// No description provided for @enterPdfPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter PDF password'**
  String get enterPdfPassword;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get enterPassword;

  /// No description provided for @passwordError.
  ///
  /// In en, this message translates to:
  /// **'Password can not be empty'**
  String get passwordError;

  /// No description provided for @fileLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load file'**
  String get fileLoadError;

  /// No description provided for @emptyRecentFolderMessage.
  ///
  /// In en, this message translates to:
  /// **'No recent files'**
  String get emptyRecentFolderMessage;

  /// No description provided for @unsupportedFileTypeErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Unsupported file type'**
  String get unsupportedFileTypeErrorMessage;

  /// No description provided for @unsupportedFileTypeErrorMessageWithType.
  ///
  /// In en, this message translates to:
  /// **'Files of type \"{fileType}\" are not supported'**
  String unsupportedFileTypeErrorMessageWithType(String fileType);
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
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
