enum MediaType { animeSeries, shortClip, mmd3D }

enum StreamProtocol { hlsM3u8, directMp4, embedIframe }

class StreamSource {
  final String label; // e.g. "1080p 60fps", "720p", "Server 1"
  final String url;
  final StreamProtocol protocol;
  final Map<String, String>? headers;
  final String? format; // "mp4", "m3u8"

  StreamSource({
    required this.label,
    required this.url,
    this.protocol = StreamProtocol.hlsM3u8,
    this.headers,
    this.format,
  });

  factory StreamSource.fromJson(Map<String, dynamic> json) {
    return StreamSource(
      label: json['label'] ?? 'Standard',
      url: json['url'] ?? '',
      protocol: json['protocol'] == 'directMp4'
          ? StreamProtocol.directMp4
          : json['protocol'] == 'embedIframe'
              ? StreamProtocol.embedIframe
              : StreamProtocol.hlsM3u8,
      headers: (json['headers'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, v.toString()),
      ),
      format: json['format'],
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'url': url,
        'protocol': protocol.name,
        'headers': headers,
        'format': format,
      };
}

class MediaItem {
  final String id;
  final String title;
  final String url; // Relative or absolute target URL
  final String cover;
  final String? duration;
  final String? releaseDate;
  final String? studio;
  final String? extensionId;
  final MediaType type;
  final List<String> tags;
  final double? rating;
  final int? views;
  final bool isUncensored;
  final String? previewVideoUrl; // Short hover micro-clip if available

  MediaItem({
    required this.id,
    required this.title,
    required this.url,
    required this.cover,
    this.duration,
    this.releaseDate,
    this.studio,
    this.extensionId,
    this.type = MediaType.animeSeries,
    this.tags = const [],
    this.rating,
    this.views,
    this.isUncensored = false,
    this.previewVideoUrl,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      url: json['url'] ?? '',
      cover: json['cover'] ?? '',
      duration: json['duration'],
      releaseDate: json['releaseDate'],
      studio: json['studio'],
      extensionId: json['extensionId'],
      type: json['type'] == 'shortClip'
          ? MediaType.shortClip
          : json['type'] == 'mmd3D'
              ? MediaType.mmd3D
              : MediaType.animeSeries,
      tags: List<String>.from(json['tags'] ?? []),
      rating: (json['rating'] as num?)?.toDouble(),
      views: json['views'] as int?,
      isUncensored: json['isUncensored'] ?? false,
      previewVideoUrl: json['previewVideoUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'url': url,
        'cover': cover,
        'duration': duration,
        'releaseDate': releaseDate,
        'studio': studio,
        'extensionId': extensionId,
        'type': type.name,
        'tags': tags,
        'rating': rating,
        'views': views,
        'isUncensored': isUncensored,
        'previewVideoUrl': previewVideoUrl,
      };
}

class EpisodeItem {
  final String id;
  final String episodeNumber; // e.g. "Episode 1", "OVA 2"
  final String title;
  final String url;
  final String? thumbnail;
  final String? duration;
  final List<StreamSource> sources;

  EpisodeItem({
    required this.id,
    required this.episodeNumber,
    required this.title,
    required this.url,
    this.thumbnail,
    this.duration,
    this.sources = const [],
  });
}

class SceneMarker {
  final String title;
  final double timestampSeconds;
  final String? thumbnail;

  SceneMarker({
    required this.title,
    required this.timestampSeconds,
    this.thumbnail,
  });
}

class MediaDetail {
  final String id;
  final String title;
  final String cover;
  final String? backdrop;
  final String? description;
  final String? studio;
  final String? releaseDate;
  final List<String> tags;
  final List<EpisodeItem> episodes;
  final List<MediaItem> related;
  final List<SceneMarker> sceneMarkers;
  final List<double> playbackHeatmap; // Normalized 0.0 - 1.0 energy waveform
  final String? franchiseId;

  MediaDetail({
    required this.id,
    required this.title,
    required this.cover,
    this.backdrop,
    this.description,
    this.studio,
    this.releaseDate,
    this.tags = const [],
    this.episodes = const [],
    this.related = const [],
    this.sceneMarkers = const [],
    this.playbackHeatmap = const [],
    this.franchiseId,
  });
}
