import 'package:ellipsized_text/ellipsized_text.dart';
import 'package:file/memory.dart';
import 'package:mechanix_files/core/constants/icons.dart';
import 'package:mechanix_files/core/constants/path_constants.dart';
import 'package:mechanix_files/core/utils/app_file_system.dart';
import 'package:mechanix_files/core/widgets/custom_icon_button.dart';
import 'package:mechanix_files/features/files_explorer/presentation/file_explorer.dart';
import 'package:mechanix_files/features/files_explorer/presentation/single_select_action_menu.dart';
import 'package:mechanix_files/features/files_explorer/presentation/file_details_dialog.dart';
import 'package:mechanix_files/features/files_home/presentation/files_home.dart';
import 'package:mechanix_files/l10n/app_localizations.dart';
import 'package:mechanix_files/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MemoryFileSystem fs;

  const testItemName = 'single_test_item';

  late String srcPath;
  late String destPath;

  Finder findCustomIconButtonByAsset(String assetPath) {
    return find.byWidgetPredicate((widget) {
      if (widget is! CustomIconButton) return false;

      final icon = widget.icon;

      return icon is Image &&
          icon.image is AssetImage &&
          (icon.image as AssetImage).assetName == assetPath;
    });
  }

  Finder findItem(String name) {
    return find.byWidgetPredicate(
      (widget) =>
          (widget is EllipsizedText && widget.text == name) ||
          (widget is Text && widget.data == name),
    );
  }

  Finder findItemTile(String name) {
    return find.ancestor(of: findItem(name), matching: find.byType(ListTile));
  }

  setUp(() {
    fs = MemoryFileSystem();

    AppFileSystem.instance = fs;

    srcPath = '${AppPaths.documentsDir}/$testItemName';
    destPath = '${AppPaths.downloadsDir}/$testItemName';

    fs.directory(AppPaths.homeDir).createSync(recursive: true);
    fs.directory(AppPaths.downloadsDir).createSync(recursive: true);
    fs.directory(AppPaths.documentsDir).createSync(recursive: true);
    fs.directory(AppPaths.trashDir).createSync(recursive: true);

    fs.directory(srcPath).createSync(recursive: true);
  });

  group('Single Select Actions Integration Test', () {
    testWidgets(
      'Verify all single-item selection actions (Copy, Move, Rename, Trash, Info, New Folder)',
      (WidgetTester tester) async {
        app.main();

        await tester.pumpAndSettle();

        final BuildContext context = tester.element(find.byType(FileHomePage));

        final localizations = AppLocalizations.of(context)!;

        // 1. Copy To Flow
        // Navigate to Documents
        await tester.tap(find.text(localizations.documents));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 1000));

        expect(find.byType(FileExplorerPage), findsOneWidget);

        // Verify item
        expect(findItemTile(testItemName), findsOneWidget);

        // Long press item
        await tester.longPress(findItemTile(testItemName));
        await tester.pumpAndSettle();

        expect(find.byType(SingleSelectActionsMenu), findsOneWidget);

        // Copy To
        await tester.tap(find.text(localizations.copyTo));
        await tester.pumpAndSettle();

        // Back to home (pop all explorer pages to return to FileHomePage)
        while (find.byType(FileExplorerPage).evaluate().isNotEmpty) {
          final backButton = findCustomIconButtonByAsset(FileIcons.back);
          expect(backButton, findsWidgets);
          await tester.tap(backButton.last);
          await tester.pumpAndSettle();
        }

        expect(find.text(localizations.copyItems(1)), findsOneWidget);

        // Navigate to Downloads
        await tester.tap(find.text(localizations.downloads));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 1000));

        // Confirm paste
        final checkButton = findCustomIconButtonByAsset(FileIcons.check);
        expect(checkButton, findsWidgets);
        await tester.tap(checkButton.last);
        await tester.pumpAndSettle();

        // Verify copy
        expect(fs.directory(destPath).existsSync(), isTrue);

        // Back home (pop all explorer pages to return to FileHomePage)
        while (find.byType(FileExplorerPage).evaluate().isNotEmpty) {
          final backButton = findCustomIconButtonByAsset(FileIcons.back);
          expect(backButton, findsWidgets);
          await tester.tap(backButton.last);
          await tester.pumpAndSettle();
        }

        expect(find.text(localizations.filesHomeTitle), findsOneWidget);

        // Reset filesystem state: clean up destPath, ensure srcPath exists
        if (fs.directory(destPath).existsSync()) {
          fs.directory(destPath).deleteSync(recursive: true);
        }
        if (!fs.directory(srcPath).existsSync()) {
          fs.directory(srcPath).createSync(recursive: true);
        }

        // 2. Move To Flow
        // Navigate to Documents
        await tester.tap(find.text(localizations.documents));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 1000));

        // Long press item
        await tester.longPress(findItemTile(testItemName));
        await tester.pumpAndSettle();

        // Move To
        await tester.tap(find.text(localizations.moveTo));
        await tester.pumpAndSettle();

        // Back home (pop all explorer pages to return to FileHomePage)
        while (find.byType(FileExplorerPage).evaluate().isNotEmpty) {
          final backButton = findCustomIconButtonByAsset(FileIcons.back);
          await tester.tap(backButton.last);
          await tester.pumpAndSettle();
        }

        expect(find.text(localizations.moveItems(1)), findsOneWidget);

        // Navigate to Downloads
        await tester.tap(find.text(localizations.downloads));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 1000));

        // Confirm paste
        final checkButton2 = findCustomIconButtonByAsset(FileIcons.check);
        expect(checkButton2, findsWidgets);
        await tester.tap(checkButton2.last);
        await tester.pumpAndSettle();

        // Verify move
        expect(fs.directory(destPath).existsSync(), isTrue);
        expect(fs.directory(srcPath).existsSync(), isFalse);

        // Back home (pop all explorer pages to return to FileHomePage)
        while (find.byType(FileExplorerPage).evaluate().isNotEmpty) {
          final backButton = findCustomIconButtonByAsset(FileIcons.back);
          await tester.tap(backButton.last);
          await tester.pumpAndSettle();
        }

        // Reset filesystem state
        if (fs.directory(destPath).existsSync()) {
          fs.directory(destPath).deleteSync(recursive: true);
        }
        if (!fs.directory(srcPath).existsSync()) {
          fs.directory(srcPath).createSync(recursive: true);
        }

        // 3. Rename Flow
        // Navigate to Documents
        await tester.tap(find.text(localizations.documents));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 1000));

        // Long press item
        await tester.longPress(findItemTile(testItemName));
        await tester.pumpAndSettle();

        // Rename
        await tester.tap(find.text(localizations.rename));
        await tester.pumpAndSettle();

        // Enter new name and submit
        const newName = 'single_test_item_renamed';
        final renamedPath = '${AppPaths.documentsDir}/$newName';

        await tester.enterText(find.byType(TextField), newName);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 1000));

        // Verify renamed item exists and old one is gone in filesystem
        expect(fs.directory(renamedPath).existsSync(), isTrue);
        expect(fs.directory(srcPath).existsSync(), isFalse);

        // Verify renamed item is visible in explorer
        expect(findItemTile(newName), findsOneWidget);

        // Reset filesystem state
        if (fs.directory(renamedPath).existsSync()) {
          fs.directory(renamedPath).deleteSync(recursive: true);
        }
        if (!fs.directory(srcPath).existsSync()) {
          fs.directory(srcPath).createSync(recursive: true);
        }

        // Back home to clean stack
        while (find.byType(FileExplorerPage).evaluate().isNotEmpty) {
          final backButton = findCustomIconButtonByAsset(FileIcons.back);
          await tester.tap(backButton.last);
          await tester.pumpAndSettle();
        }

        // 4. File Info Flow
        // Navigate to Documents
        await tester.tap(find.text(localizations.documents));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 1000));

        // Long press item
        await tester.longPress(findItemTile(testItemName));
        await tester.pumpAndSettle();

        // Info
        await tester.tap(find.text(localizations.fileInfo));
        await tester.pumpAndSettle();

        // Verify FileDetailsDialog is displayed
        expect(find.byType(FileDetailsDialog), findsOneWidget);

        // Close details dialog
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
        expect(find.byType(FileDetailsDialog), findsNothing);

        // Back home
        while (find.byType(FileExplorerPage).evaluate().isNotEmpty) {
          final backButton = findCustomIconButtonByAsset(FileIcons.back);
          await tester.tap(backButton.last);
          await tester.pumpAndSettle();
        }

        // 5. New Folder with Single Item Flow
        // Navigate to Documents
        await tester.tap(find.text(localizations.documents));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 1000));

        // Long press item
        await tester.longPress(findItemTile(testItemName));
        await tester.pumpAndSettle();

        // New folder with single item
        await tester.tap(find.text(localizations.newFolderWithSingleItem));
        await tester.pumpAndSettle();

        // Dialog / Sheet shows up to name the new folder. Enter name and submit.
        const newFolderName = 'single_item_folder';
        await tester.enterText(find.byType(TextField), newFolderName);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 1000));

        // Verify folder is created in filesystem containing the moved item
        final folderPath = '${AppPaths.documentsDir}/$newFolderName';
        expect(fs.directory(folderPath).existsSync(), isTrue);
        expect(fs.directory('$folderPath/$testItemName').existsSync(), isTrue);

        // Verify original item is no longer directly in documents root
        expect(fs.directory(srcPath).existsSync(), isFalse);

        // Verify new folder tile is visible in explorer
        expect(findItemTile(newFolderName), findsOneWidget);

        // Reset filesystem state
        if (fs.directory(folderPath).existsSync()) {
          fs.directory(folderPath).deleteSync(recursive: true);
        }
        if (!fs.directory(srcPath).existsSync()) {
          fs.directory(srcPath).createSync(recursive: true);
        }

        // Back home
        while (find.byType(FileExplorerPage).evaluate().isNotEmpty) {
          final backButton = findCustomIconButtonByAsset(FileIcons.back);
          await tester.tap(backButton.last);
          await tester.pumpAndSettle();
        }

        // 6. Move to Trash Flow
        // Navigate to Documents
        await tester.tap(find.text(localizations.documents));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 1000));

        // Long press item
        await tester.longPress(findItemTile(testItemName));
        await tester.pumpAndSettle();

        // Move to Trash
        await tester.tap(find.text(localizations.moveToTrash));
        await tester.pumpAndSettle();

        // Confirm Move to Trash inside Dialog
        await tester.tap(find.text(localizations.moveToTrash).last);
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 1000));

        // Verify item deleted from documents and is in trash
        expect(fs.directory(srcPath).existsSync(), isFalse);
        expect(
          fs.directory('${AppPaths.trashDir}/$testItemName').existsSync(),
          isTrue,
        );

        // Verify item is no longer visible in explorer
        expect(findItemTile(testItemName), findsNothing);

        // Reset filesystem state
        if (fs.directory('${AppPaths.trashDir}/$testItemName').existsSync()) {
          fs
              .directory('${AppPaths.trashDir}/$testItemName')
              .deleteSync(recursive: true);
        }
        if (!fs.directory(srcPath).existsSync()) {
          fs.directory(srcPath).createSync(recursive: true);
        }

        // Back home
        while (find.byType(FileExplorerPage).evaluate().isNotEmpty) {
          final backButton = findCustomIconButtonByAsset(FileIcons.back);
          await tester.tap(backButton.last);
          await tester.pumpAndSettle();
        }

        expect(find.text(localizations.filesHomeTitle), findsOneWidget);
      },
    );
  });
}
