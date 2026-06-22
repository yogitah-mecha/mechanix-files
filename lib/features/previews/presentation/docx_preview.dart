import 'package:docx_viewer/docx_viewer.dart';
import 'package:mechanix_files/core/theme/app_theme.dart';
import 'package:mechanix_files/features/files_explorer/presentation/file_explorer.dart';
import 'package:mechanix_files/features/previews/presentation/preview_action_bar.dart';
import 'package:flutter/material.dart';

class DocxPreview extends StatefulWidget {
  final String filePath;
  final FileExplorerPageState? state;
  final BuildContext rootContext;

  const DocxPreview({
    super.key,
    required this.filePath,
    required this.rootContext,
    this.state,
  });

  @override
  State<DocxPreview> createState() => _DocxPreviewState();
}

class _DocxPreviewState extends State<DocxPreview> {
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final fileName = widget.filePath.split('/').last;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          fileName,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),

      body: Column(
        children: [
          if (errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: Container(
              color: AppColors.surface,

              child: DocxView(
                filePath: widget.filePath,
                fontSize: 16,
                onError: (error) {
                  setState(() {
                    errorMessage = error.toString();
                  });
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(error.toString())));
                },
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: PreviewActionBar(
        path: widget.filePath,
        state: widget.state,
        rootContext: widget.rootContext,
      ),
    );
  }
}
