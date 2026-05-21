// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get filesHomeTitle => 'Locations';

  @override
  String get downloads => 'Downloads';

  @override
  String get homeDirectory => 'Home directory';

  @override
  String get home => 'Home';

  @override
  String get documents => 'Documents';

  @override
  String get recent => 'Recent';

  @override
  String get hardDriveTitle => 'Hard Drive';

  @override
  String get root => 'Root ( / )';

  @override
  String get fileInfo => 'Info';

  @override
  String get rename => 'Rename';

  @override
  String get select => 'Select';

  @override
  String get newFolder => 'New Folder';

  @override
  String get hideFiles => 'Hide hidden files';

  @override
  String get showFiles => 'Show hidden files';

  @override
  String get type => 'Type';

  @override
  String get size => 'Size';

  @override
  String get modified => 'Modified';

  @override
  String get accessed => 'Accessed';

  @override
  String get changed => 'Changed';

  @override
  String get readable => 'Readable';

  @override
  String get writable => 'Writable';

  @override
  String get hidden => 'Hidden';

  @override
  String get emptySearchResultsMessage => 'No matching results found';

  @override
  String get emptyFolderMessage => 'This folder is empty';

  @override
  String get selectAll => 'Select all';

  @override
  String get copyTo => 'Copy to';

  @override
  String get moveTo => 'Move to';

  @override
  String get moveToTrash => 'Move to trash';

  @override
  String get newFolderWithSingleItem => 'New folder with this item';

  @override
  String get paste => 'Paste here';

  @override
  String get cancel => 'Cancel';

  @override
  String get replace => 'Replace';

  @override
  String get skip => 'Skip';

  @override
  String get skipAll => 'Skip all';

  @override
  String moveItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Move $count items',
      one: 'Move 1 item',
    );
    return '$_temp0';
  }

  @override
  String copyItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Copy $count items',
      one: 'Copy 1 item',
    );
    return '$_temp0';
  }

  @override
  String pasteInNewFolder(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'New folder with \'$count items\'',
      one: 'New folder with \'1 item\'',
    );
    return '$_temp0';
  }

  @override
  String get trash => 'Trash';

  @override
  String get enterPdfPassword => 'Enter PDF password';

  @override
  String get enterPassword => 'Enter password';

  @override
  String get passwordError => 'Password can not be empty';

  @override
  String get fileLoadError => 'Failed to load file';

  @override
  String get emptyRecentFolderMessage => 'No recent files';

  @override
  String get unsupportedFileTypeErrorMessage => 'Unsupported file type';

  @override
  String unsupportedFileTypeErrorMessageWithType(String fileType) {
    return 'Files of type \"$fileType\" are not supported';
  }
}
