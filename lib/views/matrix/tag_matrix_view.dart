import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tag_matrix_provider.dart';
import '../../providers/extension_provider.dart';
import '../../models/tag_filter_state.dart';
import '../../theme/app_theme.dart';
import 'equalizer_sheet.dart';

class TagMatrixView extends StatefulWidget {
  const TagMatrixView({super.key});

  @override
  State<TagMatrixView> createState() => _TagMatrixViewState();
}

class _TagMatrixViewState extends State<TagMatrixView> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final matrix = Provider.of<TagMatrixProvider>(context);
    final extProvider = Provider.of<ExtensionProvider>(context);

    final filteredTags = matrix.allTags
        .where((t) => t.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("3-State Tag Matrix"),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppTheme.secondaryNeon),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (_) => const EqualizerSheet(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => matrix.resetAllFilters(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 3-State Legend & Guide
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderSubtle, width: 0.8),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _LegendItem(color: AppTheme.textMuted, label: "Neutral"),
                _LegendItem(color: AppTheme.accentGreen, label: "+ Whitelist"),
                _LegendItem(color: AppTheme.primaryAccent, label: "- Blacklist"),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: "Search tags & genres...",
                hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 18),
                filled: true,
                fillColor: AppTheme.surfaceCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderSubtle, width: 0.8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderSubtle, width: 0.8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderBright, width: 1.0),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),

          // Tag Cloud Grid
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
              child: Wrap(
                spacing: 6,
                runSpacing: 8,
                children: filteredTags.map((tag) {
                  final state = matrix.getTagState(tag.name);
                  final isInc = state == TagFilterState.included;
                  final isExc = state == TagFilterState.excluded;

                  Color bgColor = AppTheme.surfaceCard;
                  Color borderColor = AppTheme.borderSubtle;
                  Color textColor = AppTheme.textSecondary;
                  String prefix = "";

                  if (isInc) {
                    bgColor = AppTheme.accentGreen.withValues(alpha: 0.15);
                    borderColor = AppTheme.accentGreen;
                    textColor = AppTheme.accentGreen;
                    prefix = "+ ";
                  } else if (isExc) {
                    bgColor = AppTheme.primaryAccent.withValues(alpha: 0.15);
                    borderColor = AppTheme.primaryAccent;
                    textColor = AppTheme.primaryAccent;
                    prefix = "- ";
                  }

                  return InkWell(
                    onTap: () {
                      matrix.cycleTagState(tag.name);
                      // Apply to active feed
                      extProvider.fetchFeed(
                        refresh: true,
                        whitelistedTags: matrix.whitelistedTags,
                        blacklistedTags: matrix.blacklistedTags,
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "$prefix${tag.name}",
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: (isInc || isExc) ? FontWeight.bold : FontWeight.w500,
                              color: textColor,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "(${tag.count})",
                            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
