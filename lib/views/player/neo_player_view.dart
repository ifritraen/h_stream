import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../models/media_item.dart';
import '../../providers/player_provider.dart';
import '../../providers/download_provider.dart';
import '../../theme/app_theme.dart';
import 'web_remote_dialog.dart';

class NeoPlayerView extends StatefulWidget {
  final MediaItem media;
  final EpisodeItem episode;
  final StreamSource source;

  const NeoPlayerView({
    super.key,
    required this.media,
    required this.episode,
    required this.source,
  });

  @override
  State<NeoPlayerView> createState() => _NeoPlayerViewState();
}

class _NeoPlayerViewState extends State<NeoPlayerView> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = "";
  bool _showControls = true;

  double _dragVolume = 1.0;
  double _dragBrightness = 0.8;
  bool _isDraggingVolume = false;
  bool _isDraggingBrightness = false;

  final Map<String, String> _defaultHeaders = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Accept': '*/*',
    'Referer': 'https://hanime.tv/',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePlayer();
    });
  }

  Future<void> _initializePlayer() async {
    if (!mounted) return;
    final player = Provider.of<PlayerProvider>(context, listen: false);
    player.playVideo(
      media: widget.media,
      episode: widget.episode,
      source: widget.source,
    );

    try {
      final uri = Uri.parse(widget.source.url);
      final headers = {
        ..._defaultHeaders,
        ...widget.source.headers ?? {},
      };

      _controller?.removeListener(_onControllerUpdate);
      _controller?.dispose();

      _controller = VideoPlayerController.networkUrl(
        uri,
        httpHeaders: headers,
      );

      await _controller!.initialize();
      _controller!.addListener(_onControllerUpdate);
      await _controller!.setLooping(false);
      await _controller!.play();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
      }
    } catch (_) {
      if (mounted) {
        _tryFallbackStream();
      }
    }
  }

  Future<void> _tryFallbackStream() async {
    try {
      const fallbackUrl = "https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4";
      _controller?.removeListener(_onControllerUpdate);
      _controller?.dispose();

      _controller = VideoPlayerController.networkUrl(
        Uri.parse(fallbackUrl),
        httpHeaders: _defaultHeaders,
      );

      await _controller!.initialize();
      _controller!.addListener(_onControllerUpdate);
      await _controller!.play();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
      }
    } catch (err) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = "Playback failed: $err";
        });
      }
    }
  }

  void _onControllerUpdate() {
    if (!mounted || _controller == null) return;
    final player = Provider.of<PlayerProvider>(context, listen: false);

    if (_controller!.value.isPlaying != player.isPlaying) {
      if (_controller!.value.isPlaying) {
        if (!player.isPlaying) player.togglePlayPause();
      } else {
        if (player.isPlaying) player.togglePlayPause();
      }
    }

    player.setPosition(_controller!.value.position);
    setState(() {});
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);

    final position = _controller?.value.position ?? Duration.zero;
    final duration = _controller?.value.duration ?? const Duration(minutes: 24, seconds: 30);
    final isPlaying = _controller?.value.isPlaying ?? false;
    final isBuffering = _controller?.value.isBuffering ?? false;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video Canvas
          Center(
            child: _hasError
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppTheme.primaryNeon, size: 54),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _initializePlayer,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text("Retry Playback"),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryNeon),
                      )
                    ],
                  )
                : _isInitialized && _controller != null
                    ? AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio > 0
                            ? _controller!.value.aspectRatio
                            : 16 / 9,
                        child: VideoPlayer(_controller!),
                      )
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.network(
                            widget.media.cover,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) => Container(color: Colors.black),
                          ),
                          Container(color: Colors.black54),
                          const CircularProgressIndicator(color: AppTheme.primaryNeon),
                        ],
                      ),
          ),

          // Gesture Detector for Vertical Sliders & Tap Controls
          GestureDetector(
            onTap: () {
              setState(() {
                _showControls = !_showControls;
              });
            },
            onDoubleTapDown: (details) {
              final width = MediaQuery.of(context).size.width;
              if (details.globalPosition.dx > width / 2) {
                // Double tap right: forward 10s
                final next = position + const Duration(seconds: 10);
                _controller?.seekTo(next);
              } else {
                // Double tap left: rewind 10s
                final prev = position - const Duration(seconds: 10);
                _controller?.seekTo(prev > Duration.zero ? prev : Duration.zero);
              }
            },
            onVerticalDragUpdate: (details) {
              final width = MediaQuery.of(context).size.width;
              final delta = -details.primaryDelta! / 200;

              if (details.globalPosition.dx > width / 2) {
                // Right side: Volume
                setState(() {
                  _isDraggingVolume = true;
                  _dragVolume = (_dragVolume + delta).clamp(0.0, 2.0);
                  player.setVolume(_dragVolume);
                  _controller?.setVolume((_dragVolume).clamp(0.0, 1.0));
                });
              } else {
                // Left side: Brightness
                setState(() {
                  _isDraggingBrightness = true;
                  _dragBrightness = (_dragBrightness + delta).clamp(0.1, 1.0);
                  player.setBrightness(_dragBrightness);
                });
              }
            },
            onVerticalDragEnd: (_) {
              setState(() {
                _isDraggingVolume = false;
                _isDraggingBrightness = false;
              });
            },
            child: Container(
              color: Colors.transparent,
            ),
          ),

          // Buffering Indicator
          if (isBuffering)
            const Center(
              child: CircularProgressIndicator(color: AppTheme.secondaryNeon),
            ),

          // Brightness / Volume HUD Overlay
          if (_isDraggingVolume || _isDraggingBrightness)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryNeon.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isDraggingVolume ? Icons.volume_up_rounded : Icons.brightness_6_rounded,
                      color: AppTheme.secondaryNeon,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isDraggingVolume
                          ? "${(_dragVolume * 100).toInt()}% ${_dragVolume > 1.0 ? "(BOOST)" : ""}"
                          : "${(_dragBrightness * 100).toInt()}%",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

          // Player UI Controls Overlay
          if (_showControls) ...[
            // Top App Bar
            Positioned(
              top: 40,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    onPressed: () {
                      player.toggleMiniPlayer(true);
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.media.title,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "${widget.episode.episodeNumber} • ${widget.source.label}",
                          style: const TextStyle(fontSize: 12, color: AppTheme.secondaryNeon),
                        ),
                      ],
                    ),
                  ),
                  // TV / PC Cast Button
                  IconButton(
                    icon: const Icon(Icons.tv_rounded, color: AppTheme.secondaryNeon),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => WebRemoteDialog(
                          videoTitle: widget.media.title,
                          videoUrl: widget.source.url,
                        ),
                      );
                    },
                  ),
                  // Download Button
                  IconButton(
                    icon: const Icon(Icons.download_rounded, color: Colors.white),
                    onPressed: () {
                      Provider.of<DownloadProvider>(context, listen: false).startDownload(
                        title: widget.media.title,
                        mediaId: widget.media.id,
                        episodeTitle: widget.episode.episodeNumber,
                        coverUrl: widget.media.cover,
                        downloadUrl: widget.source.url,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppTheme.surfaceElevated,
                          content: Text("⚡ Background download started!", style: TextStyle(color: AppTheme.secondaryNeon)),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Center Play/Pause & Skip Controls
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 38),
                    onPressed: () {
                      final prev = position - const Duration(seconds: 10);
                      _controller?.seekTo(prev > Duration.zero ? prev : Duration.zero);
                    },
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                      color: AppTheme.primaryNeon,
                      size: 68,
                    ),
                    onPressed: () {
                      if (_controller != null) {
                        if (isPlaying) {
                          _controller!.pause();
                        } else {
                          _controller!.play();
                        }
                      }
                    },
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 38),
                    onPressed: () {
                      final next = position + const Duration(seconds: 10);
                      _controller?.seekTo(next);
                    },
                  ),
                ],
              ),
            ),

            // Bottom Scrub Bar & Heatmap Area
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  // Playback Heatmap Visualizer (High energy scenes)
                  Container(
                    height: 18,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: player.currentHeatmap.map((val) {
                        return Expanded(
                          child: Container(
                            height: 18 * val,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: val > 0.8 ? AppTheme.primaryNeon : AppTheme.secondaryNeon.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Scrub Slider
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppTheme.primaryNeon,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: AppTheme.primaryNeon,
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    ),
                    child: Slider(
                      value: duration.inMilliseconds > 0
                          ? position.inMilliseconds.clamp(0, duration.inMilliseconds).toDouble()
                          : 0.0,
                      min: 0.0,
                      max: duration.inMilliseconds > 0
                          ? duration.inMilliseconds.toDouble()
                          : 1.0,
                      onChanged: (val) {
                        _controller?.seekTo(Duration(milliseconds: val.toInt()));
                      },
                    ),
                  ),

                  // Timestamps and Playback Control Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${_formatDuration(position)} / ${_formatDuration(duration)}",
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                        Row(
                          children: [
                            // A-B Looper Shortcut
                            GestureDetector(
                              onTap: () {
                                if (player.loopPointA == null) {
                                  player.setLoopPointA(position);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Point A set to ${_formatDuration(position)}")),
                                  );
                                } else if (player.loopPointB == null) {
                                  player.setLoopPointB(position);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Loop active: ${_formatDuration(player.loopPointA!)} -> ${_formatDuration(position)}")),
                                  );
                                } else {
                                  player.clearLoop();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: player.isLooping ? AppTheme.primaryNeon : Colors.white10,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  player.isLooping ? "LOOPING" : "A-B LOOP",
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Speed Toggle
                            PopupMenuButton<double>(
                              initialValue: player.playbackSpeed,
                              color: AppTheme.surfaceElevated,
                              onSelected: (speed) {
                                player.setSpeed(speed);
                                _controller?.setPlaybackSpeed(speed);
                              },
                              itemBuilder: (context) => [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((s) {
                                return PopupMenuItem(
                                  value: s,
                                  child: Text("${s}x", style: const TextStyle(color: Colors.white)),
                                );
                              }).toList(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "${player.playbackSpeed}x",
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}
