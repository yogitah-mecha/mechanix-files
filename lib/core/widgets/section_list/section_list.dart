import 'package:mechanix_files/core/widgets/section_list/section_item.dart';
import 'package:flutter/material.dart';

class SectionList extends StatelessWidget {
  final String? title;
  final List<SectionItem> items;

  const SectionList({super.key, this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Section Title
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title!,
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        /// Items
        Column(
          children: items.map((item) => SectionListItem(item: item)).toList(),
        ),
      ],
    );
  }
}

class SectionListItem extends StatelessWidget {
  final SectionItem item;

  const SectionListItem({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.disabled ? null : item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (item.leading != null) ...[
              item.leading!,
              const SizedBox(width: 16),
            ],

            Expanded(
              child: Text(
                item.title,
                style:
                    item.titleStyle ??
                    Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: item.disabled ? Colors.grey : Colors.white,
                    ),
              ),
            ),

            /// Default chevron if no trailing
            item.trailing ??
                const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
