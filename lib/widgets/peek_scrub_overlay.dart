import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/media_item.dart';
import '../theme/app_theme.dart';

class PeekScrubOverlay extends StatefulWidget {
  final MediaItem item;
  final VoidCallback onOpenFull;
  final VoidCallback onQuickDownload;

  const PeekScrubOverlay({
    super.key,
    required this.item,
    required this.onOpenFull,
    required this.onQuickDownload,
  });

  @override
  State<PeekScrubOverlay> createState() => _PeekScrubOverlayState();
}

class _PeekScrubOverlayState extends State<PeekScrubOverlay> {
  double _scrubPosition = 0.5; // 0.0 to 1.0

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.88,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: AppTheme.glassBox(
            radius: 24,
            color: AppTheme.surfaceElevated.withValues(alpha: 0.95),
            border: Border.all(color: AppTheme.primaryNeon.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Media Header with Live Preview Badge
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: CachedNetworkImage(
                        imageUrl: widget.item.cover,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => Container(color: AppTheme.surface),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryNeon,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_circle_fill_rounded, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              "LIVE SCRUB PREVIEW",
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.item.duration ?? "24:00",
                          style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Interactive Scrub Slider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Scrub Bar
                    Row(
                      children: [
                        const Text("00:00", style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        Expanded(
                          child: Slider(
                            value: _scrubPosition,
                            activeColor: AppTheme.secondaryNeon,
                            inactiveColor: AppTheme.surface,
                            onChanged: (val) {
                              setState(() {
                                _scrubPosition = val;
                              });
                            },
                          ),
                        ),
                        Text(widget.item.duration ?? "24:00", style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),

              // Quick Action Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryNeon,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text("Watch Full", style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: widget.onOpenFull,
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.surfaceCard,
                        foregroundColor: AppTheme.secondaryNeon,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.all(12),
                      ),
                      icon: const Icon(Icons.download_rounded),
                      onPressed: widget.onQuickDownload,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
