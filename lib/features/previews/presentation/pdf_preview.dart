import 'package:mechanix_files/core/constants/icons.dart';
import 'package:mechanix_files/core/constants/path_constants.dart';
import 'package:mechanix_files/core/widgets/custom_icon_button.dart';
import 'package:mechanix_files/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import 'package:mechanix_files/core/theme/app_theme.dart';
import 'package:mechanix_files/features/files_explorer/presentation/file_explorer.dart';
import 'package:mechanix_files/features/previews/presentation/preview_action_bar.dart';

class PdfPreview extends StatefulWidget {
  final String filePath;
  final FileExplorerPageState? state;
  final BuildContext rootContext;

  const PdfPreview({
    super.key,
    required this.filePath,
    required this.rootContext,
    this.state,
  });

  @override
  State<PdfPreview> createState() => _PdfPreviewState();
}

class _PdfPreviewState extends State<PdfPreview> {
  final PdfViewerController _controller = PdfViewerController();
  bool showError = false;

  @override
  void initState() {
    super.initState();

    Pdfrx.pdfiumModulePath = AppPaths.pdfiumModulePath;
  }

  Future<String?> showPasswordSheet() async {
    final TextEditingController controllerText = TextEditingController();
    final FocusNode focusNode = FocusNode();

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final text = controllerText.text.trim();
            final isEmpty = text.isEmpty;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.backgroundVariantDark,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(
                      height: 1,
                      color: AppColors.backgroundVariant,
                    ),

                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.enterPdfPassword,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        CustomIconButton.icon(
                          iconData: Icons.close,
                          onPressed: () {
                            Navigator.pop(ctx, null);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    const Divider(
                      height: 1,
                      color: AppColors.backgroundVariant,
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: controllerText,
                      focusNode: focusNode,
                      autofocus: true,
                      obscureText: true,
                      onChanged:
                          (_) => setState(() {
                            showError = true;
                          }),
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.enterPassword,
                        errorText:
                            showError && isEmpty
                                ? AppLocalizations.of(context)!.passwordError
                                : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        suffixIcon: CustomIconButton.asset(
                          assetPath: FileIcons.clear,
                          onPressed: controllerText.clear,
                        ),
                      ),
                      onSubmitted: (_) {
                        Navigator.pop(ctx, controllerText.text.trim());
                      },
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(widget.filePath.split('/').last),
      ),
      body: PdfViewer.file(
        widget.filePath,
        controller: _controller,

        passwordProvider: () async {
          final result = await showPasswordSheet();

          if (result == null) {
            if (mounted) Navigator.pop(context);
            return null;
          }

          return result;
        },

        firstAttemptByEmptyPassword: true,
        params: PdfViewerParams(
          backgroundColor: AppColors.surface,
          errorBannerBuilder: (context, error, stack, document) {
            return const SizedBox.shrink();
          },
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
