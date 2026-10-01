import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/media_item.dart';
import '../../providers/extension_provider.dart';
import '../../providers/download_provider.dart';
import '../../theme/app_theme.dart';
import '../player/neo_player_view.dart';

class MediaDetailView extends StatefulWidget {
  final MediaItem item;
  final bool autoPlay;

  const MediaDetailView({
    super.key,
    required this.item,
    this.autoPlay = false,
  });

  @override
  State<MediaDetailView> createState() => _MediaDetailViewState();
}

class _MediaDetailViewState extends State<MediaDetailView> {
  MediaDetail? _detail;
  bool _isLoading = true;
  int _selectedEpisodeIndex = 0;
  final int _selectedSourceIndex = 0;
  bool _hasAutoPlayed = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final provider = Provider.of<ExtensionProvider>(context, listen: false);
    final detail = await provider.getDetail(widget.item.url);
    if (mounted) {
      setState(() {
        _detail = detail;
        _isLoading = false;
      });

      if (widget.autoPlay && !_hasAutoPlayed && detail.episodes.isNotEmpty) {
        _hasAutoPlayed = true;
        final activeEpisode = detail.episodes.first;
        final activeSource = activeEpisode.sources.isNotEmpty
            ? activeEpisode.sources.first
            : StreamSource(
                label: "1080p Master",
                url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
                protocol: StreamProtocol.directMp4,
              );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NeoPlayerView(
              media: widget.item,
              episode: activeEpisode,
              source: activeSource,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _detail == null) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryNeon),
        ),
      );
    }

    final detail = _detail!;
    final activeEpisode = detail.episodes.isNotEmpty
        ? detail.episodes[_selectedEpisodeIndex]
        : EpisodeItem(
            id: widget.item.id,
            episodeNumber: "Episode 1",
            title: widget.item.title,
            url: widget.item.url,
            sources: [
              StreamSource(
                label: "1080p Master",
                url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
                protocol: StreamProtocol.directMp4,
              )
            ],
          );

    final activeSource = activeEpisode.sources.isNotEmpty
        ? activeEpisode.sources[_selectedSourceIndex.clamp(0, activeEpisode.sources.length - 1)]
        : StreamSource(
            label: "1080p 60fps",
            url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
            protocol: StreamProtocol.directMp4,
          );

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // Collapsible Backdrop App Bar
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppTheme.surfaceElevated,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: detail.backdrop ?? detail.cover,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppTheme.background.withValues(alpha: 0.9),
                          AppTheme.background,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content Body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Meta Info
                  Text(
                    detail.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      height: 1.25,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.borderSubtle, width: 0.8),
                        ),
                        child: const Text(
                          "1080p 60FPS",
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppTheme.accentGold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        detail.studio ?? "Anime Studio",
                        style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "•  ${detail.releaseDate ?? '2024'}",
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Big Play Hero Button & Download
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryAccent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded, size: 24),
                          label: Text(
                            "Watch ${activeEpisode.episodeNumber}",
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: -0.2),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NeoPlayerView(
                                  media: widget.item,
                                  episode: activeEpisode,
                                  source: activeSource,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderSubtle, width: 0.8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.download_rounded, size: 20, color: AppTheme.textPrimary),
                          onPressed: () {
                            Provider.of<DownloadProvider>(context, listen: false).startDownload(
                              title: detail.title,
                              mediaId: widget.item.id,
                              episodeTitle: activeEpisode.episodeNumber,
                              coverUrl: detail.cover,
                              downloadUrl: activeSource.url,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppTheme.surfaceElevated,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                content: const Text("Added to Download Queue", style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Tag Cloud
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: detail.tags.map((t) => GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Provider.of<ExtensionProvider>(context, listen: false).search(t);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderSubtle, width: 0.8),
                        ),
                        child: Text(
                          "#$t",
                          style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                        ),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Synopsis Description
                  Text(
                    detail.description ?? "No synopsis available.",
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  // Episode List & Mirrors
                  const Text(
                    "Episodes & Mirrors",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, letterSpacing: -0.2),
                  ),
                  const SizedBox(height: 10),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: detail.episodes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final ep = detail.episodes[idx];
                      final isSelected = _selectedEpisodeIndex == idx;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedEpisodeIndex = idx;
                          });
                          final epSource = ep.sources.isNotEmpty ? ep.sources.first : activeSource;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NeoPlayerView(
                                media: widget.item,
                                episode: ep,
                                source: epSource,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryAccent.withValues(alpha: 0.12) : AppTheme.surfaceCard,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryAccent : AppTheme.borderSubtle,
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  ep.thumbnail ?? detail.cover,
                                  width: 60,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    width: 60,
                                    height: 40,
                                    color: AppTheme.surfaceElevated,
                                    child: const Icon(Icons.movie_outlined, size: 18, color: AppTheme.textMuted),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ep.episodeNumber,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected ? AppTheme.primaryAccent : AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      ep.title,
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.play_circle_outline_rounded,
                                size: 22,
                                color: isSelected ? AppTheme.primaryAccent : AppTheme.textMuted,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
