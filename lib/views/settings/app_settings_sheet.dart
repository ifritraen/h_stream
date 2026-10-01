import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tag_matrix_provider.dart';
import '../../providers/extension_provider.dart';
import '../../providers/stealth_provider.dart';
import '../../models/tag_filter_state.dart';
import '../../theme/app_theme.dart';

class AppSettingsSheet extends StatefulWidget {
  const AppSettingsSheet({super.key});

  @override
  State<AppSettingsSheet> createState() => _AppSettingsSheetState();
}

class _AppSettingsSheetState extends State<AppSettingsSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _tagSearchController = TextEditingController();
  String _tagSearch = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tagSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matrix = Provider.of<TagMatrixProvider>(context);
    final extProvider = Provider.of<ExtensionProvider>(context, listen: false);
    final stealth = Provider.of<StealthProvider>(context, listen: false);

    final filteredTags = matrix.allTags
        .where((t) => t.name.toLowerCase().contains(_tagSearch.toLowerCase()))
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppTheme.borderSubtle, width: 0.8)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderSubtle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune_rounded, color: AppTheme.primaryAccent, size: 20),
                    SizedBox(width: 10),
                    Text(
                      "Settings & Filter Equalizer",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    matrix.resetAllFilters();
                    extProvider.fetchFeed(refresh: true);
                  },
                  child: const Text(
                    "Reset Filters",
                    style: TextStyle(color: AppTheme.primaryAccent, fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Settings Sub-Tabs
          TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.primaryAccent,
            indicatorWeight: 2.5,
            dividerColor: AppTheme.borderSubtle,
            labelColor: AppTheme.textPrimary,
            unselectedLabelColor: AppTheme.textMuted,
            labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            tabs: const [
              Tab(text: "3-State Matrix"),
              Tab(text: "Equalizer"),
              Tab(text: "Security & Shield"),
            ],
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Relocated 3-State Tag Matrix
                _buildTagMatrixTab(matrix, extProvider, filteredTags),

                // 2. Parametric Equalizer
                _buildEqualizerTab(matrix),

                // 3. Security, Blacklist Shield & Stealth
                _buildSecurityTab(matrix, stealth),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagMatrixTab(
    TagMatrixProvider matrix,
    ExtensionProvider extProvider,
    List<TagModel> filteredTags,
  ) {
    return Column(
      children: [
        // Legend
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderSubtle, width: 0.8),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MatrixLegendDot(color: AppTheme.textMuted, label: "Neutral"),
              _MatrixLegendDot(color: AppTheme.accentGreen, label: "+ Whitelist"),
              _MatrixLegendDot(color: AppTheme.primaryAccent, label: "- Blacklist"),
            ],
          ),
        ),

        // Search tags inside matrix
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            controller: _tagSearchController,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: "Search tags in matrix (${matrix.allTags.length} tags)...",
              hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12.5),
              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 18),
              filled: true,
              fillColor: AppTheme.surfaceCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.borderSubtle, width: 0.8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.borderSubtle, width: 0.8),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
            ),
            onChanged: (val) {
              setState(() {
                _tagSearch = val.trim();
              });
            },
          ),
        ),

        // Tag matrix wrap
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
                    extProvider.fetchFeed(
                      refresh: true,
                      whitelistedTags: matrix.whitelistedTags,
                      blacklistedTags: matrix.blacklistedTags,
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "$prefix${tag.name}",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: (isInc || isExc) ? FontWeight.bold : FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                        if (tag.count > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            "(${tag.count})",
                            style: const TextStyle(fontSize: 9.5, color: AppTheme.textMuted),
                          ),
                        ]
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEqualizerTab(TagMatrixProvider matrix) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Duration
          Text(
            "Episode Duration: ${matrix.durationRange.start.round()}m - ${matrix.durationRange.end.round()}m",
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
          ),
          RangeSlider(
            values: matrix.durationRange,
            min: 0,
            max: 60,
            divisions: 12,
            activeColor: AppTheme.primaryAccent,
            inactiveColor: AppTheme.surfaceCard,
            labels: RangeLabels(
              "${matrix.durationRange.start.round()}m",
              "${matrix.durationRange.end.round()}m",
            ),
            onChanged: (values) => matrix.setDurationRange(values),
          ),
          const SizedBox(height: 16),

          // Release Year
          Text(
            "Release Year: ${matrix.yearRange.start.round()} - ${matrix.yearRange.end.round()}",
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
          ),
          RangeSlider(
            values: matrix.yearRange,
            min: 2000,
            max: 2026,
            divisions: 26,
            activeColor: AppTheme.secondaryAccent,
            inactiveColor: AppTheme.surfaceCard,
            labels: RangeLabels(
              "${matrix.yearRange.start.round()}",
              "${matrix.yearRange.end.round()}",
            ),
            onChanged: (values) => matrix.setYearRange(values),
          ),
          const SizedBox(height: 16),

          // Resolution
          const Text(
            "Preferred Resolution",
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: ["All", "1080p HD", "4K Ultra"].map((q) {
              final isSel = matrix.selectedQuality == q;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(q),
                  selected: isSel,
                  selectedColor: AppTheme.primaryAccent,
                  labelStyle: TextStyle(
                    color: isSel ? Colors.white : AppTheme.textSecondary,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: isSel ? AppTheme.primaryAccent : AppTheme.borderSubtle,
                    width: 0.8,
                  ),
                  backgroundColor: AppTheme.surfaceCard,
                  onSelected: (_) => matrix.setQuality(q),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Censorship Preference
          const Text(
            "Censorship Preference",
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: ["All", "Uncensored", "Decensored"].map((c) {
              final isSel = matrix.selectedCensorship == c;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(c),
                  selected: isSel,
                  selectedColor: AppTheme.primaryAccent,
                  labelStyle: TextStyle(
                    color: isSel ? Colors.white : AppTheme.textSecondary,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: isSel ? AppTheme.primaryAccent : AppTheme.borderSubtle,
                    width: 0.8,
                  ),
                  backgroundColor: AppTheme.surfaceCard,
                  onSelected: (_) => matrix.setCensorship(c),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTab(TagMatrixProvider matrix, StealthProvider stealth) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        // Blacklist Shield
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderSubtle, width: 0.8),
          ),
          child: Row(
            children: [
              const Icon(Icons.shield_rounded, color: AppTheme.accentGreen, size: 24),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Global Blacklist Shield", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 13.5)),
                    SizedBox(height: 2),
                    Text("Filters out extreme & blacklisted tags across feeds", style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  ],
                ),
              ),
              Switch(
                value: matrix.blacklistShieldEnabled,
                activeThumbColor: AppTheme.primaryAccent,
                onChanged: (_) => matrix.toggleBlacklistShield(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Global Blacklist Tags
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderSubtle, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Permanently Blacklisted Tags", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 13.5)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: matrix.globalBlacklist.map((tag) {
                  return Chip(
                    label: Text(tag, style: const TextStyle(fontSize: 11.5, color: AppTheme.primaryAccent)),
                    backgroundColor: AppTheme.primaryAccent.withValues(alpha: 0.1),
                    side: const BorderSide(color: AppTheme.primaryAccent, width: 0.6),
                    deleteIcon: const Icon(Icons.close_rounded, size: 14, color: AppTheme.primaryAccent),
                    onDeleted: () => matrix.removeGlobalBlacklist(tag),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Calculator Decoy Stealth Mode
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderSubtle, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.calculate_rounded, color: AppTheme.secondaryAccent, size: 22),
                  SizedBox(width: 10),
                  Text("Stealth Calculator Decoy", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 13.5)),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                "Instantly transforms app into a fully functional calculator. Unlock by entering PIN '7777' followed by '='.",
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  stealth.activateCalculatorDecoy();
                },
                icon: const Icon(Icons.shield_outlined, size: 16),
                label: const Text("Activate Calculator Decoy Now"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.secondaryAccent,
                  side: const BorderSide(color: AppTheme.secondaryAccent, width: 0.8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MatrixLegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _MatrixLegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
