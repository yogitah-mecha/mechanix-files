import 'package:mechanix_files/core/theme/app_theme.dart';
import 'package:mechanix_files/core/widgets/custom_button.dart';
import 'package:mechanix_files/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

Future<bool?> showMoveToTrashConfirmationSheet({
  required BuildContext context,
  required int itemCount,
}) async {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Container(
        decoration: const BoxDecoration(color: AppColors.backgroundVariant),
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 16,
          top: 16,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                itemCount > 1
                    ? AppLocalizations.of(context)!.moveItemsToTrashConfirmation
                    : AppLocalizations.of(context)!.moveItemToTrashConfirmation,
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      label: AppLocalizations.of(context)!.cancel,
                      backgroundColor: AppColors.onSurfaceVariantDark,
                      textColor: AppColors.onSurface,
                      borderRadius: 0,
                      onPressed: () {
                        Navigator.pop(sheetContext, false);
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: CustomButton(
                      label: AppLocalizations.of(context)!.moveToTrash,
                      backgroundColor: AppColors.onSurface,
                      textColor: AppColors.surface,
                      borderRadius: 0,
                      onPressed: () {
                        Navigator.pop(sheetContext, true);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
