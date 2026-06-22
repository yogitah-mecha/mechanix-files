import 'package:ellipsized_text/ellipsized_text.dart';
import 'package:mechanix_files/core/theme/app_theme.dart';
import 'package:mechanix_files/core/utils/commons.dart';
import 'package:mechanix_files/core/widgets/custom_icon_button.dart';
import 'package:mechanix_files/features/files_explorer/blocs/file_boc.dart';
import 'package:mechanix_files/features/files_explorer/blocs/file_state.dart';
import 'package:mechanix_files/features/files_home/data/models/file_item.dart';
import 'package:mechanix_files/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;

class FileDetailsDialog extends StatelessWidget {
  final String path;
  final VoidCallback onClose;

  const FileDetailsDialog({
    super.key,
    required this.path,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<FilesBloc>();

    final fileItem = FileItem(
      name: p.basename(path),
      type: p.extension(path).isEmpty ? 'dir' : p.extension(path),
      modified: DateTime.now(),
    );

    return BlocProvider.value(
      value: bloc,
      child: BlocBuilder<FilesBloc, FilesState>(
        builder: (context, state) {
          final details = state.fileDetails;

          if (details == null) {
            return const SizedBox.shrink();
          }

          final hidden = p.basename(path).startsWith('.') ? 'Yes' : 'No';
          final readable = (details.mode & 0x100) != 0 ? 'Yes' : 'No';
          final writable = (details.mode & 0x80) != 0 ? 'Yes' : 'No';

          return Material(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: CustomIconButton.icon(
                        iconData: Icons.close,
                        onPressed: () => onClose(),
                      ),
                    ),

                    const Divider(
                      height: 1,
                      color: AppColors.backgroundVariant,
                    ),

                    const SizedBox(height: 8),

                    /// HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.fileInfo,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(color: AppColors.onSurface),
                        ),

                        Row(
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 180),
                              child: EllipsizedText(
                                fileItem.name,
                                type: EllipsisType.middle,
                                textAlign: TextAlign.right,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),

                            const SizedBox(width: 10),

                            Image.asset(
                              fileItem.iconPath,
                              width: 22,
                              height: 22,
                              color: Colors.white70,
                            ),
                          ],
                        ),
                      ],
                    ),

                    DetailRow(
                      title: AppLocalizations.of(context)!.type,
                      value: details.type.toString(),
                    ),

                    DetailRow(
                      title: AppLocalizations.of(context)!.size,
                      value: formatBytesDecimal(details.size),
                    ),

                    DetailRow(
                      title: AppLocalizations.of(context)!.modified,
                      value: formatDateTime(details.modified),
                    ),

                    DetailRow(
                      title: AppLocalizations.of(context)!.accessed,
                      value: formatDateTime(details.accessed),
                    ),

                    DetailRow(
                      title: AppLocalizations.of(context)!.changed,
                      value: formatDateTime(details.changed),
                    ),

                    DetailRow(
                      title: AppLocalizations.of(context)!.readable,
                      value: readable,
                    ),

                    DetailRow(
                      title: AppLocalizations.of(context)!.writable,
                      value: writable,
                    ),

                    DetailRow(
                      title: AppLocalizations.of(context)!.hidden,
                      value: hidden,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  final String title;
  final String value;

  const DetailRow({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),

          const SizedBox(width: 16),

          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
