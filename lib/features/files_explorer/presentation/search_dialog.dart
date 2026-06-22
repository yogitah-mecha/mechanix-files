import 'package:mechanix_files/core/constants/icons.dart';
import 'package:mechanix_files/core/theme/app_theme.dart';
import 'package:mechanix_files/core/widgets/custom_icon_button.dart';
import 'package:mechanix_files/features/files_explorer/presentation/file_explorer.dart';
import 'package:mechanix_files/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class SearchOverlayController {
  OverlayEntry? _searchOverlayEntry;

  final FocusNode _focusNode = FocusNode();

  final ValueNotifier<bool> isTextInputOpened = ValueNotifier(false);

  SearchOverlayController() {
    _focusNode.addListener(focusChange);
  }

  bool get isVisible => _searchOverlayEntry != null;

  void show(
    BuildContext context, {
    required ValueNotifier<String> searchQuery,
    required VoidCallback onClear,
    required Function(String) onSearch,
  }) {
    final overlay = Overlay.of(context);
    final controllerText = TextEditingController(text: searchQuery.value);
    final state = context.findAncestorStateOfType<FileExplorerPageState>();

    hide();

    _searchOverlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Material(
            color: Colors.transparent,
            child: Container(
              color: AppColors.backgroundVariant,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CustomIconButton.asset(
                        assetPath: FileIcons.arrowDown,
                        iconSize: 20,
                        onPressed: () {
                          controllerText.clear();
                          searchQuery.value = '';
                          onClear();
                          state?.clearSearch();
                        },
                      ),
                    ],
                  ),

                  const Divider(height: 1, color: AppColors.background),

                  const SizedBox(height: 8),
                  TextField(
                    controller: controllerText,
                    focusNode: _focusNode,
                    autofocus: false,
                    onChanged: (query) {
                      searchQuery.value = query;
                      onSearch(query);
                    },
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.searchHint,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,

                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(
                          right: 8,
                          left: 8,
                          bottom: 8,
                        ),
                        child: Image.asset(
                          FileIcons.search,
                          width: 24,
                          height: 24,
                        ),
                      ),

                      suffixIcon: CustomIconButton.asset(
                        assetPath: FileIcons.clear,
                        onPressed: () {
                          controllerText.clear();
                          searchQuery.value = '';
                          onSearch('');
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_searchOverlayEntry!);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_focusNode.canRequestFocus) {
          _focusNode.requestFocus();
        }
      });
    });
  }

  void hide() {
    _searchOverlayEntry?.remove();
    _searchOverlayEntry = null;

    _focusNode.unfocus();
  }

  void dispose() {
    hide();

    _focusNode.removeListener(focusChange);
    _focusNode.dispose();

    isTextInputOpened.dispose();
  }

  Future<void> focusChange() async {
    isTextInputOpened.value = _focusNode.hasFocus;
  }
}
