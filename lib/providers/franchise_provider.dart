import 'package:flutter/material.dart';
import '../models/franchise_group.dart';
import '../models/media_item.dart';

class FranchiseProvider extends ChangeNotifier {
  final Map<String, FranchiseGroup> _cachedFranchises = {};
  bool _isLoading = false;

  Map<String, FranchiseGroup> get cachedFranchises => _cachedFranchises;
  bool get isLoading => _isLoading;

  Future<FranchiseGroup> getFranchiseHub(String queryOrId) async {
    _isLoading = true;
    notifyListeners();

    // Simulated cross-extension aggregator clustering
    await Future.delayed(const Duration(milliseconds: 300));

    final franchise = FranchiseGroup(
      id: "franchise_taimanin",
      canonicalTitle: "Taimanin: The Complete Multiverse Saga",
      cover: "https://picsum.photos/seed/taimanin_hub/640/360",
      banner: "https://picsum.photos/seed/taimanin_banner/1280/720",
      studio: "Lilith Soft / ZIZ",
      genres: ["Action", "Cyberpunk", "Dark Fantasy", "1080p 60fps", "Uncensored"],
      synopsis: "The definitive cross-platform master timeline combining all canon series, 3D CGI spin-offs, and English dubbed editions in one unified portal.",
      episodes: [
        AggregatedEpisode(
          episodeIndex: 1,
          title: "Episode 1: Infiltration into Roppongi",
          thumbnail: "https://picsum.photos/seed/tai_ep1/640/360",
          mirrors: [
            EpisodeMirror(
              sourceName: "Hanime.tv (1080p 60fps Master)",
              extensionId: "hanime_tv",
              episodeUrl: "https://hanime.tv/videos/hentai/taimanin-asagi-ep-1",
              qualityLabel: "1080p HLS",
              streamSources: [
                StreamSource(
                  label: "1080p 60fps",
                  url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
                  protocol: StreamProtocol.directMp4,
                )
              ],
            ),
            EpisodeMirror(
              sourceName: "HStream.moe (English Dubbed)",
              extensionId: "hstream_moe",
              episodeUrl: "https://hstream.moe/hentai/taimanin-ep-1-dub",
              qualityLabel: "1080p Dub",
              streamSources: [
                StreamSource(
                  label: "1080p Dubbed Audio",
                  url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
                  protocol: StreamProtocol.directMp4,
                )
              ],
            ),
            EpisodeMirror(
              sourceName: "Oppai.stream (4K AI Remaster)",
              extensionId: "oppai_stream",
              episodeUrl: "https://oppai.stream/watch?e=taimanin-4k-1",
              qualityLabel: "4K 60fps",
              streamSources: [
                StreamSource(
                  label: "4K Ultra-HD",
                  url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4",
                  protocol: StreamProtocol.directMp4,
                )
              ],
            ),
          ],
        ),
        AggregatedEpisode(
          episodeIndex: 2,
          title: "Episode 2: Shadow of the Syndicate",
          thumbnail: "https://picsum.photos/seed/tai_ep2/640/360",
          mirrors: [
            EpisodeMirror(
              sourceName: "Hanime.tv (1080p 60fps Master)",
              extensionId: "hanime_tv",
              episodeUrl: "https://hanime.tv/videos/hentai/taimanin-asagi-ep-2",
              qualityLabel: "1080p HLS",
              streamSources: [
                StreamSource(
                  label: "1080p 60fps",
                  url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
                  protocol: StreamProtocol.directMp4,
                )
              ],
            ),
            EpisodeMirror(
              sourceName: "HStream.moe (English Dubbed)",
              extensionId: "hstream_moe",
              episodeUrl: "https://hstream.moe/hentai/taimanin-ep-2-dub",
              qualityLabel: "1080p Dub",
              streamSources: [
                StreamSource(
                  label: "1080p Dubbed",
                  url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
                  protocol: StreamProtocol.directMp4,
                )
              ],
            ),
          ],
        ),
      ],
      related3DClips: [
        MediaItem(
          id: "r34_taimanin_1",
          title: "Asagi Taimanin Suit 3D Raytrace 60FPS",
          url: "https://rule34video.com/video/101",
          cover: "https://picsum.photos/seed/r34_tai1/450/600",
          duration: "03:45",
          extensionId: "rule34_video",
          type: MediaType.shortClip,
          tags: ["3D", "MMD", "Blender", "4K"],
          rating: 4.9,
          views: 95000,
          isUncensored: true,
          previewVideoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
        ),
        MediaItem(
          id: "hmv_taimanin_2",
          title: "Yukikaze Cyber Ninja Dance HMV",
          url: "https://hmvmania.com/hmv-102",
          cover: "https://picsum.photos/seed/hmv_tai2/450/600",
          duration: "04:15",
          extensionId: "hmv_mania",
          type: MediaType.mmd3D,
          tags: ["HMV", "MMD", "Music", "60fps"],
          rating: 5.0,
          views: 110000,
          isUncensored: true,
          previewVideoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ),
      ],
    );

    _cachedFranchises[franchise.id] = franchise;
    _isLoading = false;
    notifyListeners();
    return franchise;
  }
}
