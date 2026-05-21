import 'dart:convert';
import 'dart:io';

import 'package:files/core/theme/app_theme.dart';
import 'package:files/features/files_explorer/presentation/file_explorer.dart';
import 'package:files/features/previews/presentation/preview_action_bar.dart';
import 'package:files/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';

class CodePreview extends StatefulWidget {
  final String filePath;
  final FileExplorerPageState? state;
  final BuildContext rootContext;

  const CodePreview({
    super.key,
    required this.filePath,
    required this.rootContext,
    this.state,
  });

  @override
  State<CodePreview> createState() => _CodePreviewState();
}

class _CodePreviewState extends State<CodePreview> {
  CodeController? _controller;

  bool isLoading = true;
  bool hasError = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  Future<void> _loadFile() async {
    try {
      final file = File(widget.filePath);

      final buffer = StringBuffer();
      bool controllerCreated = false;

      await for (final line in file
          .openRead()
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        buffer.writeln(line);

        if (!controllerCreated && buffer.length > 5000) {
          _controller = CodeController(text: buffer.toString());
          controllerCreated = true;

          if (mounted) {
            setState(() => isLoading = false);
          }
        }
      }

      if (!mounted) return;

      // update if controller was never created
      if (!controllerCreated) {
        _controller = CodeController(text: buffer.toString());
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(widget.filePath.split('/').last),
      ),

      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : hasError
              ? Center(
                child: Text(
                  AppLocalizations.of(context)!.fileLoadError,
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 16,
                  ),
                ),
              )
              : SingleChildScrollView(
                controller: _scrollController,
                child: Stack(
                  children: [
                    CodeField(
                      controller: _controller!,
                      enabled: false,
                      readOnly: true,
                      background: AppColors.surface,
                    ),
                  ],
                ),
              ),
      bottomNavigationBar: PreviewActionBar(
        path: widget.filePath,
        state: widget.state,
        rootContext: widget.rootContext,
      ),
    );
  }
}
