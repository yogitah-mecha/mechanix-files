import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mechanix_files/core/constants/icons.dart';
import 'package:mechanix_files/core/constants/path_constants.dart';
import 'package:mechanix_files/core/widgets/custom_icon_button.dart';
import 'package:mechanix_files/features/files_explorer/presentation/file_explorer.dart';
import 'package:mechanix_files/features/files_explorer/presentation/file_details_dialog.dart';
import 'package:mechanix_files/features/files_explorer/presentation/folder_actions_menu.dart';
import 'package:mechanix_files/features/files_home/presentation/files_home.dart';
import 'package:mechanix_files/l10n/app_localizations.dart';
import 'package:file/memory.dart';
import 'package:mechanix_files/core/utils/app_file_system.dart';
import 'package:mechanix_files/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Folder Actions Integration Test', () {
    late MemoryFileSystem fs;

    // Helper to find CustomIconButton by asset path
    Finder findCustomIconButtonByAsset(String assetPath) {
      return find.byWidgetPredicate((widget) {
        if (widget is! CustomIconButton) return false;
        final icon = widget.icon;
        return icon is Image &&
            icon.image is AssetImage &&
            (icon.image as AssetImage).assetName == assetPath;
      }).last;
    }

    setUp(() {
      fs = MemoryFileSystem();
      fs.directory(AppPaths.homeDir).createSync(recursive: true);
      fs.directory(AppPaths.downloadsDir).createSync(recursive: true);
      fs.directory(AppPaths.documentsDir).createSync(recursive: true);
      fs.directory(AppPaths.trashDir).createSync(recursive: true);
      AppFileSystem.instance = fs;
    });

    testWidgets('Verify folder-level actions menu items and actions', (
      WidgetTester tester,
    ) async {
      // Start the application
      app.main();
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(FileHomePage));
      final localizations = AppLocalizations.of(context)!;

      // Navigate to Home directory
      await tester.tap(find.text(localizations.documents));
      await tester.pumpAndSettle();
      // Allow time for async directory loading and keyboard focus callbacks to settle
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.byType(FileExplorerPage), findsOneWidget);

      final state = tester.state<FileExplorerPageState>(
        find.byType(FileExplorerPage),
      );

      // --- Action 1: Toggle Hidden Files ---
      // Tap more actions menu button
      await tester.tap(findCustomIconButtonByAsset(FileIcons.moreVert));
      await tester.pumpAndSettle();
      expect(find.byType(FolderActionsMenu), findsOneWidget);

      // Determine initial show/hide state and tap to toggle
      final hasShowFiles = tester.any(find.text(localizations.showFiles));
      final toggleText =
          hasShowFiles ? localizations.showFiles : localizations.hideFiles;
      final expectedOppositeText =
          hasShowFiles ? localizations.hideFiles : localizations.showFiles;

      await tester.tap(find.text(toggleText));
      await tester.pumpAndSettle();
      // Allow time for reload async I/O operation
      await tester.pump(const Duration(milliseconds: 1000));

      // Verify toggled state by opening menu again
      await tester.tap(findCustomIconButtonByAsset(FileIcons.moreVert));
      await tester.pumpAndSettle();
      expect(find.text(expectedOppositeText), findsOneWidget);

      // Close the menu sheet
      await tester.tap(find.byIcon(Icons.close).last);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));

      // --- Action 2: Select ---
      await tester.tap(findCustomIconButtonByAsset(FileIcons.moreVert));
      await tester.pumpAndSettle();
      await tester.tap(find.text(localizations.select));
      await tester.pumpAndSettle(); // Selection mode active

      // Check for the presence of the selection bottom bar
      expect(
        find.byKey(const ValueKey('selection_bottom_bar')),
        findsOneWidget,
      );

      // Close/cancel selection mode
      await tester.tap(find.byIcon(Icons.close).last);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const ValueKey('normal_bottom_bar')), findsOneWidget);

      // --- Action 3: New Folder ---
      await tester.tap(findCustomIconButtonByAsset(FileIcons.moreVert));
      await tester.pumpAndSettle();
      await tester.tap(find.text(localizations.newFolder));
      await tester.pumpAndSettle();
      // Allow time for async directory operations and sheet pop-up animation
      await tester.pump(const Duration(milliseconds: 1000));

      // Detect newly created folder directly from the controller to make sure it was created in memory
      final newFolderPath = state.controller.newFolderPath;
      expect(newFolderPath, isNotNull);
      expect(fs.directory(newFolderPath!).existsSync(), isTrue);

      // Close/cancel the folder creation rename sheet
      await tester.tap(find.byIcon(Icons.close).last);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 1000));

      // --- Action 4: Info ---
      await tester.tap(findCustomIconButtonByAsset(FileIcons.moreVert));
      await tester.pumpAndSettle();
      await tester.tap(find.text(localizations.fileInfo));
      await tester.pumpAndSettle();
      // Allow time for async file details fetch and modal pop-up animation
      await tester.pump(const Duration(milliseconds: 1000));

      // Verify Info dialog is shown
      expect(find.byType(FileDetailsDialog), findsOneWidget);
      expect(find.text(localizations.fileInfo), findsOneWidget);

      // Close info dialog
      await tester.tap(find.byIcon(Icons.close).last);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));

      // Navigate back to Locations home screen
      await tester.tap(findCustomIconButtonByAsset(FileIcons.back));
      await tester.pumpAndSettle();
      expect(find.text(localizations.filesHomeTitle), findsOneWidget);
    });
  });
}
