import 'media_item.dart';

class EpisodeMirror {
  final String sourceName; // e.g. "Hanime (1080p HLS)", "HStream (Dubbed)", "WatchHentai (Mirror 2)"
  final String extensionId;
  final String episodeUrl;
  final String qualityLabel;
  final List<StreamSource> streamSources;

  EpisodeMirror({
    required this.sourceName,
    required this.extensionId,
    required this.episodeUrl,
    required this.qualityLabel,
    this.streamSources = const [],
  });
}

class AggregatedEpisode {
  final int episodeIndex;
  final String title;
  final String? thumbnail;
  final List<EpisodeMirror> mirrors;

  AggregatedEpisode({
    required this.episodeIndex,
    required this.title,
    this.thumbnail,
    this.mirrors = const [],
  });
}

class FranchiseGroup {
  final String id;
  final String canonicalTitle;
  final String cover;
  final String? banner;
  final String? synopsis;
  final String? studio;
  final List<String> genres;
  final List<AggregatedEpisode> episodes;
  final List<MediaItem> related3DClips;

  FranchiseGroup({
    required this.id,
    required this.canonicalTitle,
    required this.cover,
    this.banner,
    this.synopsis,
    this.studio,
    this.genres = const [],
    this.episodes = const [],
    this.related3DClips = const [],
  });
}
