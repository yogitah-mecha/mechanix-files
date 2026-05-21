import 'dart:io' as io;
import 'dart:ui' as ui;

import 'package:files/core/theme/app_theme.dart';
import 'package:files/core/widgets/notification/custom_notification.dart';
import 'package:files/features/files_explorer/controllers/file_manager_controller.dart';
import 'package:files/features/files_explorer/presentation/file_explorer.dart';
import 'package:files/features/files_home/data/models/file_item.dart';
import 'package:files/features/previews/presentation/audio.dart';
import 'package:files/features/previews/presentation/code_preview.dart';
import 'package:files/features/previews/presentation/image.dart';
import 'package:files/features/previews/presentation/pdf_preview.dart';
import 'package:files/features/previews/presentation/video.dart';
import 'package:files/features/recents/blocs/recent_file_event.dart';
import 'package:files/features/recents/blocs/recent_files_bloc.dart';
import 'package:files/features/recents/presentation/recent_files.dart';
import 'package:files/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;

TextStyle confirmationDialogRegularStyle(BuildContext context) =>
    const TextStyle(
      color: AppColors.onSurface,
      fontSize: 24,
      fontWeight: FontWeight.w400,
    );

TextStyle confirmationDialogBoldStyle(BuildContext context) => const TextStyle(
  color: AppColors.onSurface,
  fontSize: 24,
  fontWeight: FontWeight.w600,
);

double textWidth(String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    maxLines: 1,
    textDirection: ui.TextDirection.ltr,
  )..layout();

  return painter.width;
}

void handleFileTap(
  BuildContext context,
  io.FileSystemEntity file,
  String fullPath,
  bool isSelectionMode,
  FileExplorerPageState? state,
  FileManagerController controller,
) {
  final fileType = p.extension(fullPath).toLowerCase();

  if (isSelectionMode) {
    state?.toggleSelection(fullPath);
    return;
  }

  if (state?.isSearching == true) {
    state?.clearSearch(); // will reset and remove overlay
  }

  // Determine supported type
  final isText = textFileTypes.contains(fileType);
  final isAudio = audioFileTypes.contains(fileType);
  final isVideo = videoFileTypes.contains(fileType);
  final isImage = imageFileTypes.contains(fileType);
  final isPdf = fileType == '.pdf';

  final isSupported = isText || isAudio || isVideo || isImage || isPdf;

  if (isSupported) {
    // Add to recent once (only for supported types)
    context.read<RecentFilesBloc>().add(AddToRecentFiles(fullPath));
  } else {
    showUnsupportedFileNotification(context, fileType);
    return;
  }

  if (isText) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => CodePreview(
              rootContext: context,
              filePath: fullPath,
              state: state,
            ),
      ),
    );
    return;
  }

  if (isAudio) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AudioPreview(filePath: fullPath, state: state),
      ),
    );
    return;
  }

  if (isVideo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => VideoPreview(
              filePath: fullPath,
              rootContext: context,
              state: state,
            ),
      ),
    );
    return;
  }

  if (isPdf) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PdfPreview(
              rootContext: context,
              filePath: fullPath,
              state: state,
            ),
      ),
    );
    return;
  }

  if (isImage) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImagePreview(imagePath: fullPath, state: state),
      ),
    );
    return;
  }
}

void handleTap(
  BuildContext context,
  String fullPath,
  RecentFilesExplorerPageState? state,
) {
  final fileType = p.extension(fullPath).toLowerCase();

  // Determine supported type
  final isText = textFileTypes.contains(fileType);
  final isAudio = audioFileTypes.contains(fileType);
  final isVideo = videoFileTypes.contains(fileType);
  final isImage = imageFileTypes.contains(fileType);
  final isPdf = fileType == '.pdf';

  final isSupported = isText || isAudio || isVideo || isImage || isPdf;

  if (isSupported) {
    // Add to recent once (only for supported types)
    context.read<RecentFilesBloc>().add(AddToRecentFiles(fullPath));
  } else {
    showUnsupportedFileNotification(context, fileType);
    return;
  }
  if (isText) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CodePreview(rootContext: context, filePath: fullPath),
      ),
    );
    return;
  }

  if (isAudio) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AudioPreview(filePath: fullPath)),
    );
    return;
  }

  if (isVideo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPreview(filePath: fullPath, rootContext: context),
      ),
    );
    return;
  }

  if (isPdf) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreview(rootContext: context, filePath: fullPath),
      ),
    );
    return;
  }

  if (isImage) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ImagePreview(imagePath: fullPath)),
    );
    return;
  }
}

void showUnsupportedFileNotification(BuildContext context, String fileType) {
  CustomNotification.show(
    context: context,
    type: NotificationType.error,
    message:
        fileType.isEmpty
            ? AppLocalizations.of(context)!.unsupportedFileTypeErrorMessage
            : AppLocalizations.of(
              context,
            )!.unsupportedFileTypeErrorMessageWithType(fileType),
  );
}
