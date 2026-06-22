import 'package:ellipsized_text/ellipsized_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mechanix_files/core/constants/icons.dart';
import 'package:mechanix_files/core/constants/path_constants.dart';
import 'package:mechanix_files/core/widgets/custom_icon_button.dart';
import 'package:mechanix_files/features/files_explorer/presentation/file_explorer.dart';
import 'package:mechanix_files/features/previews/presentation/audio.dart';
import 'package:mechanix_files/features/previews/presentation/code_preview.dart';
import 'package:mechanix_files/features/previews/presentation/image.dart';
import 'package:mechanix_files/features/previews/presentation/pdf_preview.dart';
import 'package:mechanix_files/features/previews/presentation/video.dart';
import 'package:mechanix_files/features/files_home/presentation/files_home.dart';
import 'package:mechanix_files/l10n/app_localizations.dart';
import 'package:file/memory.dart';
import 'package:mechanix_files/core/utils/app_file_system.dart';
import 'package:mechanix_files/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Preview Pages Integration Test', () {
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
      fs.directory(AppPaths.homeDir).createSync(recursive: true);
      fs.directory(AppPaths.downloadsDir).createSync(recursive: true);
      fs.directory(AppPaths.documentsDir).createSync(recursive: true);
      fs.directory(AppPaths.trashDir).createSync(recursive: true);

      // Create test files of various types inside Documents folder
      fs.file('${AppPaths.documentsDir}/test.txt')
        ..createSync(recursive: true)
        ..writeAsStringSync('Hello, code preview world!');
      fs.file('${AppPaths.documentsDir}/test.png').createSync(recursive: true);
      fs.file('${AppPaths.documentsDir}/test.pdf').createSync(recursive: true);
      fs.file('${AppPaths.documentsDir}/test.mp3').createSync(recursive: true);
      fs.file('${AppPaths.documentsDir}/test.mp4').createSync(recursive: true);

      AppFileSystem.instance = fs;
    });

    testWidgets(
      'Verify opening previews for text, image, audio, video and pdf files',
      (WidgetTester tester) async {
        // Start the application
        app.main();
        await tester.pumpAndSettle();

        final BuildContext context = tester.element(find.byType(FileHomePage));
        final localizations = AppLocalizations.of(context)!;

        // Navigate to Documents directory
        await tester.tap(find.text(localizations.documents));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 1000));
        expect(find.byType(FileExplorerPage), findsOneWidget);

        // Verify the files exist in lists
        expect(findItemTile('test.txt'), findsOneWidget);
        expect(findItemTile('test.png'), findsOneWidget);
        expect(findItemTile('test.pdf'), findsOneWidget);
        expect(findItemTile('test.mp3'), findsOneWidget);
        expect(findItemTile('test.mp4'), findsOneWidget);

        // 1. Verify Code Preview
        await tester.tap(findItemTile('test.txt'));
        await tester.pumpAndSettle();
        // Allow time to read file from memory filesystem
        await tester.pump(const Duration(milliseconds: 1000));
        expect(find.byType(CodePreview), findsOneWidget);
        expect(
          find.textContaining('Hello, code preview world!'),
          findsAtLeastNWidgets(1),
        );

        // Go back using PreviewActionBar's back button
        await tester.tap(findCustomIconButtonByAsset(FileIcons.back));
        await tester.pumpAndSettle();
        expect(find.byType(FileExplorerPage), findsOneWidget);

        // 2. Verify Image Preview
        await tester.tap(findItemTile('test.png'));
        await tester.pumpAndSettle();
        expect(find.byType(ImagePreview), findsOneWidget);

        await tester.tap(findCustomIconButtonByAsset(FileIcons.back));
        await tester.pumpAndSettle();
        expect(find.byType(FileExplorerPage), findsOneWidget);

        // 3. Verify Audio Preview
        await tester.tap(findItemTile('test.mp3'));
        await tester.pumpAndSettle();
        expect(find.byType(AudioPreview), findsOneWidget);

        await tester.tap(findCustomIconButtonByAsset(FileIcons.back));
        await tester.pumpAndSettle();
        expect(find.byType(FileExplorerPage), findsOneWidget);

        // 4. Verify Video Preview
        await tester.tap(findItemTile('test.mp4'));
        await tester.pumpAndSettle();
        // VideoPlayer might be loading, but check that VideoPreview widget is visible
        expect(find.byType(VideoPreview), findsOneWidget);

        await tester.tap(findCustomIconButtonByAsset(FileIcons.back));
        await tester.pumpAndSettle();
        expect(find.byType(FileExplorerPage), findsOneWidget);

        // 5. Verify PDF Preview
        await tester.tap(findItemTile('test.pdf'));
        await tester.pumpAndSettle();
        expect(find.byType(PdfPreview), findsOneWidget);

        await tester.tap(findCustomIconButtonByAsset(FileIcons.back));
        await tester.pumpAndSettle();
        expect(find.byType(FileExplorerPage), findsOneWidget);
      },
    );
  });
}
