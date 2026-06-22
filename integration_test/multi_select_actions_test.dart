import 'package:ellipsized_text/ellipsized_text.dart';
import 'package:file/memory.dart';
import 'package:mechanix_files/core/constants/icons.dart';
import 'package:mechanix_files/core/constants/path_constants.dart';
import 'package:mechanix_files/core/utils/app_file_system.dart';
import 'package:mechanix_files/core/widgets/custom_icon_button.dart';
import 'package:mechanix_files/features/files_explorer/presentation/file_explorer.dart';
import 'package:mechanix_files/features/files_explorer/presentation/multiselect_actions_menu.dart';
import 'package:mechanix_files/features/files_home/presentation/files_home.dart';
import 'package:mechanix_files/l10n/app_localizations.dart';
import 'package:mechanix_files/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Multi Select Actions Integration Test', () {
    late MemoryFileSystem fs;

    final testItemName1 = 'multi_test_item1';
    final srcPath1 = '${AppPaths.documentsDir}/$testItemName1';
    final destPath1 = '${AppPaths.downloadsDir}/$testItemName1';

    final testItemName2 = 'multi_test_item2';
    final srcPath2 = '${AppPaths.documentsDir}/$testItemName2';
    final destPath2 = '${AppPaths.downloadsDir}/$testItemName2';

    // Find CustomIconButton by asset
    Finder findCustomIconButtonByAsset(String assetPath) {
      return find.byWidgetPredicate((widget) {
        if (widget is! CustomIconButton) return false;

        final icon = widget.icon;

        return icon is Image &&
            icon.image is AssetImage &&
            (icon.image as AssetImage).assetName == assetPath;
      }).last;
    }

    // Find clickable ListTile using EllipsizedText
    Finder itemTileFinder(String name) {
      return find.ancestor(
        of: find.byWidgetPredicate(
          (widget) => widget is EllipsizedText && widget.text == name,
        ),
        matching: find.byType(ListTile),
      );
    }

    // Wait until widget appears
    Future<void> waitUntilVisible(
      WidgetTester tester,
      Finder finder, {
      Duration timeout = const Duration(seconds: 10),
    }) async {
      final end = DateTime.now().add(timeout);

      while (DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 100));

        if (finder.evaluate().isNotEmpty) {
          return;
        }
      }

      debugDumpApp();
      fail('Widget not found: $finder');
    }

    // Setup filesystem
    setUp(() {
      fs = MemoryFileSystem();

      fs.directory(AppPaths.homeDir).createSync(recursive: true);
      fs.directory(AppPaths.downloadsDir).createSync(recursive: true);
      fs.directory(AppPaths.documentsDir).createSync(recursive: true);
      fs.directory(AppPaths.trashDir).createSync(recursive: true);

      fs.directory(srcPath1).createSync(recursive: true);
      fs.directory(srcPath2).createSync(recursive: true);

      AppFileSystem.instance = fs;
    });

    // Test

    testWidgets(
      'Verify all multi-select selection actions (Move, Copy, Select All, Trash)',
      (WidgetTester tester) async {
        // Start app
        app.main();

        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(FileHomePage), findsOneWidget);

        final BuildContext context = tester.element(find.byType(FileHomePage));

        final localizations = AppLocalizations.of(context)!;

        // 1. Move To Flow
        // Open Documents
        await tester.tap(find.text(localizations.documents));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(FileExplorerPage), findsOneWidget);

        // Wait for list
        await waitUntilVisible(tester, find.byType(ListTile));

        // Find item tiles
        final item1Tile = itemTileFinder(testItemName1);
        final item2Tile = itemTileFinder(testItemName2);

        await waitUntilVisible(tester, item1Tile);
        await waitUntilVisible(tester, item2Tile);

        expect(item1Tile, findsOneWidget);
        expect(item2Tile, findsOneWidget);

        // Enable selection mode
        await tester.tap(findCustomIconButtonByAsset(FileIcons.moreVert));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        await tester.tap(find.text(localizations.select));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Select first item
        await tester.ensureVisible(item1Tile);
        await tester.tap(item1Tile);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Select second item
        await tester.ensureVisible(item2Tile);
        await tester.tap(item2Tile);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Open multiselect actions
        await tester.tap(findCustomIconButtonByAsset(FileIcons.moreVert));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(MultiselectActionsMenu), findsOneWidget);

        // Tap Move To
        await tester.tap(find.text(localizations.moveTo));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Navigate back to home
        while (find.byType(FileExplorerPage).evaluate().isNotEmpty) {
          final backButton = findCustomIconButtonByAsset(FileIcons.back);
          await tester.tap(backButton.last);
          await tester.pumpAndSettle();
        }

        await tester.pump(const Duration(milliseconds: 500));

        // Open Downloads
        await tester.tap(find.text(localizations.downloads));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 1000));
        expect(find.byType(FileExplorerPage), findsOneWidget);

        // Confirm Move
        await tester.tap(findCustomIconButtonByAsset(FileIcons.check));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // Verify move completed
        expect(fs.directory(destPath1).existsSync(), isTrue);
        expect(fs.directory(destPath2).existsSync(), isTrue);
        expect(fs.directory(srcPath1).existsSync(), isFalse);
        expect(fs.directory(srcPath2).existsSync(), isFalse);

        // Reset filesystem state: delete dest folders, re-create src folders
        if (fs.directory(destPath1).existsSync()) {
          fs.directory(destPath1).deleteSync(recursive: true);
        }
        if (fs.directory(destPath2).existsSync()) {
          fs.directory(destPath2).deleteSync(recursive: true);
        }
        if (!fs.directory(srcPath1).existsSync()) {
          fs.directory(srcPath1).createSync(recursive: true);
        }
        if (!fs.directory(srcPath2).existsSync()) {
          fs.directory(srcPath2).createSync(recursive: true);
        }

        // Back to home
        while (find.byType(FileExplorerPage).evaluate().isNotEmpty) {
          final backButton = findCustomIconButtonByAsset(FileIcons.back);
          await tester.tap(backButton.last);
          await tester.pumpAndSettle();
        }

        // 2. Copy To Flow
        // Open Documents
        await tester.tap(find.text(localizations.documents));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 1000));

        // Enable selection mode
        await tester.tap(findCustomIconButtonByAsset(FileIcons.moreVert));
        await tester.pumpAndSettle();
        await tester.tap(find.text(localizations.select));
        await tester.pumpAndSettle();

        // Select first item
        await tester.tap(itemTileFinder(testItemName1));
        await tester.pumpAndSettle();

        // Select second item
        await tester.tap(itemTileFinder(testItemName2));
        await tester.pumpAndSettle();

        // Open multiselect actions
        await tester.tap(findCustomIconButtonByAsset(FileIcons.moreVert));
        await tester.pumpAndSettle();

        // Tap Copy To
        await tester.tap(find.text(localizations.copyTo));
        await tester.pumpAndSettle();

        // Navigate back to home
        while (find.byType(FileExplorerPage).evaluate().isNotEmpty) {
          final backButton = findCustomIconButtonByAsset(FileIcons.back);
          await tester.tap(backButton.last);
          await tester.pumpAndSettle();
        }

        // Open Downloads
        await tester.tap(find.text(localizations.downloads));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 1000));

        // Confirm Copy
        await tester.tap(findCustomIconButtonByAsset(FileIcons.check));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 1));

        // Verify copy completed (src folders still exist, dest folders exist)
        expect(fs.directory(destPath1).existsSync(), isTrue);
        expect(fs.directory(destPath2).existsSync(), isTrue);
        expect(fs.directory(srcPath1).existsSync(), isTrue);
        expect(fs.directory(srcPath2).existsSync(), isTrue);

        // Reset filesystem state
        if (fs.directory(destPath1).existsSync()) {
          fs.directory(destPath1).deleteSync(recursive: true);
        }
        if (fs.directory(destPath2).existsSync()) {
          fs.directory(destPath2).deleteSync(recursive: true);
        }

        // Back to home
        while (find.byType(FileExplorerPage).evaluate().isNotEmpty) {
          final backButton = findCustomIconButtonByAsset(FileIcons.back);
          await tester.tap(backButton.last);
          await tester.pumpAndSettle();
        }

        // 3. Select All Flow
        // Open Documents
        await tester.tap(find.text(localizations.documents));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 1000));

        // Enable selection mode
        await tester.tap(findCustomIconButtonByAsset(FileIcons.moreVert));
        await tester.pumpAndSettle();
        await tester.tap(find.text(localizations.select));
        await tester.pumpAndSettle();

        // Open multiselect actions
        await tester.tap(findCustomIconButtonByAsset(FileIcons.moreVert));
        await tester.pumpAndSettle();

        // Tap Select All
        await tester.tap(find.text(localizations.selectAll));
        await tester.pumpAndSettle();

        // Verify selection bottom bar text indicates 2 Selected
        expect(find.text(localizations.selectedItems(2)), findsOneWidget);

        // Clear selection to exit selection mode
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Back to home
        while (find.byType(FileExplorerPage).evaluate().isNotEmpty) {
          final backButton = findCustomIconButtonByAsset(FileIcons.back);
          await tester.tap(backButton.last);
          await tester.pumpAndSettle();
        }

        // 4. Move to Trash Flow
        // Open Documents
        await tester.tap(find.text(localizations.documents));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 1000));

        // Enable selection mode
        await tester.tap(findCustomIconButtonByAsset(FileIcons.moreVert));
        await tester.pumpAndSettle();
        await tester.tap(find.text(localizations.select));
        await tester.pumpAndSettle();

        // Select items
        await tester.tap(itemTileFinder(testItemName1));
        await tester.pumpAndSettle();
        await tester.tap(itemTileFinder(testItemName2));
        await tester.pumpAndSettle();

        // Open multiselect actions
        await tester.tap(findCustomIconButtonByAsset(FileIcons.moreVert));
        await tester.pumpAndSettle();

        // Move to Trash
        await tester.tap(find.text(localizations.moveToTrash));
        await tester.pumpAndSettle();

        // Confirm inside confirmation sheet
        await tester.tap(find.text(localizations.moveToTrash).last);
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 1));

        // Verify items deleted from documents and are in trash
        expect(fs.directory(srcPath1).existsSync(), isFalse);
        expect(fs.directory(srcPath2).existsSync(), isFalse);
        expect(
          fs.directory('${AppPaths.trashDir}/$testItemName1').existsSync(),
          isTrue,
        );
        expect(
          fs.directory('${AppPaths.trashDir}/$testItemName2').existsSync(),
          isTrue,
        );

        // Reset filesystem state
        if (fs.directory('${AppPaths.trashDir}/$testItemName1').existsSync()) {
          fs
              .directory('${AppPaths.trashDir}/$testItemName1')
              .deleteSync(recursive: true);
        }
        if (fs.directory('${AppPaths.trashDir}/$testItemName2').existsSync()) {
          fs
              .directory('${AppPaths.trashDir}/$testItemName2')
              .deleteSync(recursive: true);
        }
        if (!fs.directory(srcPath1).existsSync()) {
          fs.directory(srcPath1).createSync(recursive: true);
        }
        if (!fs.directory(srcPath2).existsSync()) {
          fs.directory(srcPath2).createSync(recursive: true);
        }

        // Back to home
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
