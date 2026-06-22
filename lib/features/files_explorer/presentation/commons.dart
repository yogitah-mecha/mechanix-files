import 'dart:io' as io;
import 'dart:ui' as ui;

import 'package:mechanix_files/core/widgets/toast/custom_app_toast.dart';
import 'package:mechanix_files/features/files_explorer/controllers/file_manager_controller.dart';
import 'package:mechanix_files/features/files_explorer/presentation/file_explorer.dart';
import 'package:mechanix_files/features/files_home/data/models/file_item.dart';
import 'package:mechanix_files/features/previews/presentation/audio.dart';
import 'package:mechanix_files/features/previews/presentation/code_preview.dart';
import 'package:mechanix_files/features/previews/presentation/docx_preview.dart';
import 'package:mechanix_files/features/previews/presentation/image.dart';
import 'package:mechanix_files/features/previews/presentation/pdf_preview.dart';
import 'package:mechanix_files/features/previews/presentation/video.dart';
import 'package:mechanix_files/features/recents/blocs/recent_file_event.dart';
import 'package:mechanix_files/features/recents/blocs/recent_files_bloc.dart';
import 'package:mechanix_files/features/recents/presentation/recent_files.dart';
import 'package:mechanix_files/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;

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
  final isDocx = docxFileTypes.contains(fileType);

  final isSupported =
      isText || isAudio || isVideo || isImage || isPdf || isDocx;

  if (isSupported) {
    // Add to recent once (only for supported types)
    context.read<RecentFilesBloc>().add(AddToRecentFiles(fullPath));
  } else {
    showUnsupportedFileToastMessage(context, fileType);
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

  if (isDocx) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => DocxPreview(
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
  final isDocx = docxFileTypes.contains(fileType);

  final isSupported =
      isText || isAudio || isVideo || isImage || isPdf || isDocx;

  if (isSupported) {
    // Add to recent once (only for supported types)
    context.read<RecentFilesBloc>().add(AddToRecentFiles(fullPath));
  } else {
    showUnsupportedFileToastMessage(context, fileType);
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

  if (isDocx) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocxPreview(rootContext: context, filePath: fullPath),
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

void showUnsupportedFileToastMessage(BuildContext context, String fileType) {
  CustomAppToast.show(
    context: context,
    type: ToastType.error,
    message:
        fileType.isEmpty
            ? AppLocalizations.of(context)!.unsupportedFileTypeErrorMessage
            : AppLocalizations.of(
              context,
            )!.unsupportedFileTypeErrorMessageWithType(fileType),
  );
}
