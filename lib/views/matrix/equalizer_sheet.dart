import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tag_matrix_provider.dart';
import '../../theme/app_theme.dart';

class EqualizerSheet extends StatelessWidget {
  const EqualizerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final matrix = Provider.of<TagMatrixProvider>(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppTheme.borderSubtle, width: 0.8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderBright,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.tune_rounded, color: AppTheme.primaryAccent, size: 18),
                  SizedBox(width: 8),
                  Text(
                    "Parametric Equalizer",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => matrix.resetAllFilters(),
                child: const Text("Reset All", style: TextStyle(color: AppTheme.primaryAccent, fontSize: 12.5)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Duration Slider
          Text(
            "Episode Duration (${matrix.durationRange.start.round()}m - ${matrix.durationRange.end.round()}m)",
            style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
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
          const SizedBox(height: 10),

          // Resolution Quality Chips
          const Text(
            "Minimum Resolution",
            style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  backgroundColor: AppTheme.surfaceCard,
                  onSelected: (_) => matrix.setQuality(q),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Global Blacklist Shield Toggle
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderSubtle, width: 0.8),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_rounded, color: AppTheme.accentGreen, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Global Content Filter Shield", style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary, fontSize: 13)),
                      Text("Automatically hides filtered tags from all feeds", style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
                Switch(
                  value: matrix.blacklistShieldEnabled,
                  activeTrackColor: AppTheme.primaryNeon,
                  onChanged: (_) => matrix.toggleBlacklistShield(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
