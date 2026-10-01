import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../extensions/sources/rule34_extension.dart';
import '../../models/media_item.dart';
import '../../providers/download_provider.dart';
import '../../theme/app_theme.dart';

class InfinityReelsView extends StatefulWidget {
  const InfinityReelsView({super.key});

  @override
  State<InfinityReelsView> createState() => _InfinityReelsViewState();
}

class _InfinityReelsViewState extends State<InfinityReelsView> {
  final PageController _pageController = PageController();
  final List<MediaItem> _clips = [];
  bool _isLoading = true;
  final Set<String> _likedClips = {};

  @override
  void initState() {
    super.initState();
    _loadClips();
  }

  Future<void> _loadClips() async {
    final ext = Rule34Extension();
    final items = await ext.fetchTabFeed("top_rated", 1);
    if (mounted) {
      setState(() {
        _clips.addAll(items);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryNeon),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _clips.length,
        itemBuilder: (context, index) {
          final clip = _clips[index];
          final isLiked = _likedClips.contains(clip.id);

          return Stack(
            fit: StackFit.expand,
            children: [
              // Background Image / Video Player
              CachedNetworkImage(
                imageUrl: clip.cover,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(color: AppTheme.surface),
              ),

              // Ambient Dimmer Gradients
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // Top Bar Floating Badge
              Positioned(
                top: 48,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryNeon.withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.auto_awesome_motion_rounded, size: 14, color: AppTheme.primaryNeon),
                      SizedBox(width: 6),
                      Text("INFINITY REELS 3D", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ),

              // Right-Side Floating Action Stack
              Positioned(
                bottom: 110,
                right: 16,
                child: Column(
                  children: [
                    _buildActionButton(
                      icon: isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isLiked ? AppTheme.primaryNeon : Colors.white,
                      label: "${(clip.views ?? 85000) ~/ 1000}k",
                      onTap: () {
                        setState(() {
                          if (isLiked) {
                            _likedClips.remove(clip.id);
                          } else {
                            _likedClips.add(clip.id);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildActionButton(
                      icon: Icons.download_rounded,
                      color: AppTheme.secondaryNeon,
                      label: "Save",
                      onTap: () {
                        Provider.of<DownloadProvider>(context, listen: false).startDownload(
                          title: clip.title,
                          mediaId: clip.id,
                          episodeTitle: "3D Short Clip (4K 60FPS)",
                          coverUrl: clip.cover,
                          downloadUrl: clip.previewVideoUrl ?? "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: AppTheme.surfaceElevated,
                            content: Text("📥 Downloading 3D clip...", style: TextStyle(color: AppTheme.secondaryNeon)),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildActionButton(
                      icon: Icons.tag_rounded,
                      color: AppTheme.accentGold,
                      label: "Tags",
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              // Bottom Title & Tags Info
              Positioned(
                bottom: 90,
                left: 20,
                right: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clip.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: clip.tags.take(3).map((t) => Text(
                        "#$t",
                        style: const TextStyle(fontSize: 12, color: AppTheme.secondaryNeon, fontWeight: FontWeight.w600),
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
