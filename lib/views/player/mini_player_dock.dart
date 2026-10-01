import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/player_provider.dart';
import '../../theme/app_theme.dart';
import 'neo_player_view.dart';

class MiniPlayerDock extends StatelessWidget {
  const MiniPlayerDock({super.key});

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    if (!player.isMiniPlayerActive || player.activeMedia == null) {
      return const SizedBox.shrink();
    }

    final media = player.activeMedia!;

    return Positioned(
      bottom: 84,
      left: 16,
      right: 16,
      child: GestureDetector(
        onTap: () {
          player.toggleMiniPlayer(false);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NeoPlayerView(
                media: media,
                episode: player.activeEpisode!,
                source: player.activeStreamSource!,
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderSubtle, width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Row(
                children: [
                  // Thumbnail Icon
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      media.cover,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title & Meta
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          media.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                "1080p",
                                style: TextStyle(fontSize: 8.5, color: AppTheme.primaryAccent, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              player.activeEpisode?.episodeNumber ?? "Ep 1",
                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Play/Pause Button
                  IconButton(
                    icon: Icon(
                      player.isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                      color: AppTheme.primaryAccent,
                      size: 32,
                    ),
                    onPressed: () => player.togglePlayPause(),
                  ),

                  // Close Button
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted, size: 18),
                    onPressed: () => player.closePlayer(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
