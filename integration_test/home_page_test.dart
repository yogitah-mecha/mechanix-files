import 'package:mechanix_files/core/utils/app_file_system.dart';
import 'package:mechanix_files/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mechanix_files/core/constants/icons.dart';
import 'package:mechanix_files/core/constants/path_constants.dart';
import 'package:mechanix_files/core/widgets/custom_icon_button.dart';
import 'package:mechanix_files/features/files_explorer/presentation/file_explorer.dart';
import 'package:mechanix_files/features/recents/presentation/recent_files.dart';
import 'package:mechanix_files/features/trash/presentation/trash.dart';
import 'package:mechanix_files/features/files_home/presentation/files_home.dart';
import 'package:mechanix_files/l10n/app_localizations.dart';
import 'package:file/memory.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Files App Navigation Integration Test', () {
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
      final fs = MemoryFileSystem();

      fs.directory(AppPaths.homeDir).createSync(recursive: true);
      fs.directory(AppPaths.downloadsDir).createSync(recursive: true);
      fs.directory(AppPaths.documentsDir).createSync(recursive: true);
      fs.directory(AppPaths.trashDir).createSync(recursive: true);
      AppFileSystem.instance = fs;
    });

    testWidgets('Verify locations home screen and navigate to all sections', (
      WidgetTester tester,
    ) async {
      // Start the application (parameterless)
      app.main();
      await tester.pumpAndSettle();

      // Retrieve localized strings
      final BuildContext context = tester.element(find.byType(FileHomePage));
      final localizations = AppLocalizations.of(context)!;

      // Verify the application title is displayed
      expect(find.text(localizations.filesHomeTitle), findsOneWidget);

      // Verify the essential directory options on the home screen
      expect(find.text(localizations.homeDirectory), findsOneWidget);
      expect(find.text(localizations.recent), findsOneWidget);
      expect(find.text(localizations.downloads), findsOneWidget);
      expect(find.text(localizations.documents), findsOneWidget);
      expect(find.text(localizations.trash), findsOneWidget);
      expect(find.text(localizations.root), findsOneWidget);

      // 1. Test navigation to Home directory
      await tester.tap(find.text(localizations.homeDirectory));
      await tester.pumpAndSettle();
      expect(find.byType(FileExplorerPage), findsOneWidget);
      await tester.tap(findCustomIconButtonByAsset(FileIcons.back));
      await tester.pumpAndSettle();
      expect(find.text(localizations.filesHomeTitle), findsOneWidget);

      // 2. Test navigation to Recent files screen
      await tester.tap(find.text(localizations.recent));
      await tester.pumpAndSettle();
      expect(find.byType(RecentFilesExplorerPage), findsOneWidget);
      await tester.tap(findCustomIconButtonByAsset(FileIcons.back));
      await tester.pumpAndSettle();
      expect(find.text(localizations.filesHomeTitle), findsOneWidget);

      // 3. Test navigation to Downloads screen
      await tester.tap(find.text(localizations.downloads));
      await tester.pumpAndSettle();
      expect(find.byType(FileExplorerPage), findsOneWidget);
      await tester.tap(findCustomIconButtonByAsset(FileIcons.back));
      await tester.pumpAndSettle();
      expect(find.text(localizations.filesHomeTitle), findsOneWidget);

      // 4. Test navigation to Documents screen
      await tester.tap(find.text(localizations.documents));
      await tester.pumpAndSettle();
      expect(find.byType(FileExplorerPage), findsOneWidget);
      await tester.tap(findCustomIconButtonByAsset(FileIcons.back));
      await tester.pumpAndSettle();
      expect(find.text(localizations.filesHomeTitle), findsOneWidget);

      // 5. Test navigation to Trash screen
      await tester.tap(find.text(localizations.trash));
      await tester.pumpAndSettle();
      expect(find.byType(TrashPage), findsOneWidget);
      await tester.tap(findCustomIconButtonByAsset(FileIcons.back));
      await tester.pumpAndSettle();
      expect(find.text(localizations.filesHomeTitle), findsOneWidget);

      // 6. Test navigation to Root ( / ) screen
      await tester.tap(find.text(localizations.root));
      await tester.pumpAndSettle();
      expect(find.byType(FileExplorerPage), findsOneWidget);
      await tester.tap(findCustomIconButtonByAsset(FileIcons.back));
      await tester.pumpAndSettle();
      expect(find.text(localizations.filesHomeTitle), findsOneWidget);
    });
  });
}
