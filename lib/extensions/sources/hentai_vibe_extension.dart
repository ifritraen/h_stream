import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../base_extension.dart';
import '../../models/media_item.dart';
import '../../models/extension_manifest.dart';
import '../../models/catalog_model.dart';
import '../taxonomies/hentai_vibe_taxonomy.dart';

/// HentaiVibe extension for HStream Neo.
/// Scrapes ambient mood playlists and curated HD streaming from hentaivibe.com.
class HentaiVibeExtension extends HentaiExtension {
  @override
  String get id => "hentai_vibe";

  @override
  String get name => "HentaiVibe";

  @override
  String get baseUrl => "https://hentaivibe.com";

  @override
  String get iconUrl => "https://hentaivibe.com/favicon.ico";

  @override
  String get description =>
      "Ambient mood playlists, late-night anime streaming, and high-definition series.";

  @override
  ViewLayoutType get defaultLayout => ViewLayoutType.widescreen16x9;

  @override
  bool get supportsShorts => false;

  @override
  List<ExtensionTab> get tabs => [
        ExtensionTab(
            id: "latest",
            title: "Vibe Latest",
            icon: Icons.fiber_new_rounded),
        ExtensionTab(
            id: "popular",
            title: "Top Vibe",
            icon: Icons.whatshot_rounded),
        ExtensionTab(
            id: "uncensored",
            title: "Uncensored Vibe",
            icon: Icons.lock_open_rounded),
        ExtensionTab(
            id: "3d",
            title: "Cyber / 3D",
            icon: Icons.view_in_ar_rounded),
        ExtensionTab(
            id: "romance",
            title: "Pure Romance",
            icon: Icons.favorite_rounded),
      ];

  @override
  List<FilterGroup> get filters => [];

  final Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaivibe.com/',
  };

  final List<String> _candidateDomains = [
    'https://hentaivibe.org',
    'https://hentaivibe.net',
    'https://hentaivibe.com',
    'https://hentaivibe.tv',
  ];

  @override
  Future<List<MediaItem>> fetchTabFeed(
    String tabId,
    int page, {
    Map<String, dynamic>? activeFilters,
    List<String>? whitelistedTags,
    List<String>? blacklistedTags,
  }) async {
    String path;
    switch (tabId) {
      case 'popular':
        path = '/best.html';
        break;
      case 'uncensored':
        path = '/tags/uncensored/';
        break;
      case '3d':
        path = '/tags/3d/';
        break;
      case 'romance':
        path = '/tags/romance/';
        break;
      case 'latest':
      default:
        path = '/lastnews/';
        break;
    }

    for (final domain in _candidateDomains) {
      try {
        final String targetUrl;
        if (path == '/best.html') {
          targetUrl = '$domain/best.html';
        } else {
          final cleanPath = path.startsWith('/') ? path : '/$path';
          final normalized = cleanPath.endsWith('/') ? cleanPath : '$cleanPath/';
          targetUrl = page == 1
              ? '$domain$normalized'
              : '$domain${normalized}page/$page/';
        }

        final response = await http
            .get(Uri.parse(targetUrl), headers: _headers)
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final items =
              _parseCardsFromHtml(response.body, domain, tabId: tabId);
          if (items.isNotEmpty) return items;
        }
      } catch (_) {}
    }

    return _generateSampleList(tabId, page);
  }

  @override
  Future<List<MediaItem>> search(
    String query,
    int page, {
    Map<String, dynamic>? activeFilters,
    List<String>? whitelistedTags,
    List<String>? blacklistedTags,
  }) async {
    for (final domain in _candidateDomains) {
      try {
        final searchUrls = [
          Uri.parse(
              "$domain/?do=search&subaction=search&story=${Uri.encodeComponent(query)}"),
          Uri.parse(
              "$domain/?s=${Uri.encodeComponent(query)}&page=$page"),
        ];

        for (final searchUrl in searchUrls) {
          try {
            final response = await http
                .get(searchUrl, headers: _headers)
                .timeout(const Duration(seconds: 4));

            if (response.statusCode == 200) {
              final items =
                  _parseCardsFromHtml(response.body, domain, tabId: 'latest');
              if (items.isNotEmpty) return items;
            }
          } catch (_) {}
        }
      } catch (_) {}
    }

    return fetchTabFeed("latest", page);
  }

  List<MediaItem> _parseCardsFromHtml(String html, String domain,
      {String tabId = 'latest'}) {
    final doc = html_parser.parse(html);
    final articles = doc.querySelectorAll(
        'article, .post, .item, .vibe-item, a.poster, .poster, .grid-item');
    final List<MediaItem> items = [];
    final Set<String> seenHrefs = {};

    for (final art in articles) {
      final a = art.localName == 'a' ? art : art.querySelector('a');
      var href = a?.attributes['href'] ?? '';
      if (href.isEmpty) continue;
      if (!href.startsWith('http')) {
        href = href.startsWith('/') ? '$domain$href' : '$domain/$href';
      }
      if (seenHrefs.contains(href)) continue;
      seenHrefs.add(href);

      final img = art.querySelector('img');
      var title = art
              .querySelector(
                  'h2, .title, .entry-title, h3, .poster__title, a[title]')
              ?.text
              .trim() ??
          a?.attributes['title']?.trim() ??
          img?.attributes['alt']?.trim() ??
          '';
      title = _cleanTitle(title);
      if (title.isEmpty) continue;

      var cover = img?.attributes['data-src'] ??
          img?.attributes['data-lazy-src'] ??
          img?.attributes['data-original'] ??
          img?.attributes['src'] ??
          '';
      if (cover.startsWith('//')) {
        cover = 'https:$cover';
      } else if (cover.startsWith('/') && !cover.startsWith('http')) {
        cover = '$domain$cover';
      }

      final duration =
          art.querySelector('.duration, .time, .badge-duration')?.text.trim() ??
              '24:00';

      final viewsText = art
              .querySelector('.poster__label-views, .views')
              ?.text
              .replaceAll(RegExp(r'[^0-9]'), '') ??
          '';
      final parsedViews = int.tryParse(viewsText) ?? 185000;

      if (cover.startsWith('http')) {
        items.add(MediaItem(
          id: href.hashCode.toString(),
          title: title,
          url: href,
          cover: cover,
          duration: duration.isEmpty ? '24:00' : duration,
          releaseDate: '2024',
          studio: 'HentaiVibe',
          extensionId: id,
          type: (tabId == '3d' || title.toLowerCase().contains('3d'))
              ? MediaType.mmd3D
              : MediaType.animeSeries,
          tags: _getDefaultTagsForTab(tabId),
          rating: 4.8,
          views: parsedViews,
          isUncensored: tabId == 'uncensored' ||
              title.toLowerCase().contains('uncensored'),
        ));
      }
    }
    return items;
  }


  String _cleanTitle(String raw) {
    return raw
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  List<String> _getDefaultTagsForTab(String tabId) {
    switch (tabId) {
      case 'popular':
        return ["Top Vibe", "Trending", "HD", "Subbed"];
      case 'uncensored':
        return ["Uncensored Vibe", "Decensored", "Full HD"];
      case '3d':
        return ["Cyber / 3D", "MMD", "SFM", "60fps"];
      case 'romance':
        return ["Pure Romance", "Vanilla", "Sweet", "HD"];
      case 'latest':
      default:
        return ["Vibe Latest", "HD", "Subbed", "Ambient"];
    }
  }

  @override
  Future<MediaDetail> detail(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final doc = html_parser.parse(response.body);
        final title =
            doc.querySelector('h1, .entry-title, .title')?.text.trim() ??
                "HentaiVibe Episode";
        final desc = doc.querySelector('meta[name="description"]')?.attributes['content'] ??
            doc.querySelector('.entry-content p, .description p, .desc')?.text.trim() ??
            "Ambient mood anime streaming on HentaiVibe.";
        final cover = doc.querySelector('meta[property="og:image"]')?.attributes['content'] ??
            doc.querySelector('.poster img, .cover img')?.attributes['data-src'] ??
            doc.querySelector('.poster img, .cover img')?.attributes['src'] ??
            "";

        final sources = await extractVideoStreams(url);

        return MediaDetail(
          id: url.hashCode.toString(),
          title: title,
          cover: cover.isNotEmpty ? cover : "https://i.imgur.com/7jZQY1B.jpeg",
          backdrop:
              cover.isNotEmpty ? cover : "https://i.imgur.com/7jZQY1B.jpeg",
          description: desc,
          studio: "HentaiVibe Studios",
          releaseDate: "2024",
          tags: ["Ambient Vibe", "HD", "Uncensored"],
          episodes: [
            EpisodeItem(
              id: "ep_1",
              episodeNumber: "Episode 1",
              title: title,
              url: url,
              thumbnail: cover.isNotEmpty
                  ? cover
                  : "https://i.imgur.com/7jZQY1B.jpeg",
              duration: "24:00",
              sources: sources,
            ),
          ],
          playbackHeatmap: [
            0.1,
            0.35,
            0.65,
            0.95,
            0.8,
            0.4,
            0.3,
            0.9,
            1.0,
            0.4
          ],
          sceneMarkers: [
            SceneMarker(title: "Opening", timestampSeconds: 0),
            SceneMarker(title: "Vibe Peak 🔥", timestampSeconds: 700),
          ],
        );
      }
    } catch (_) {}

    return _generateSampleDetail(url);
  }

  @override
  Future<List<StreamSource>> extractVideoStreams(String videoUrl) async {
    try {
      final response = await http
          .get(Uri.parse(videoUrl), headers: _headers)
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final doc = html_parser.parse(response.body);
        final List<StreamSource> sources = [];

        // Direct video sources
        final videos = doc.querySelectorAll('video source, video[src]');
        for (final v in videos) {
          final src = v.attributes['src'] ?? '';
          if (src.isNotEmpty &&
              (src.contains('.mp4') || src.contains('.m3u8'))) {
            sources.add(StreamSource(
              label: src.contains('.m3u8')
                  ? "HLS Master Stream"
                  : "1080p Direct MP4",
              url: src.startsWith('//') ? "https:$src" : src,
              protocol: src.contains('.m3u8')
                  ? StreamProtocol.hlsM3u8
                  : StreamProtocol.directMp4,
              headers: {
                'Referer': baseUrl,
                'User-Agent': _headers['User-Agent']!
              },
            ));
          }
        }

        final iframes = doc.querySelectorAll(
            'iframe[data-src], iframe[src*="embed"], iframe');
        for (final iframe in iframes) {
          final src = iframe.attributes['data-src'] ??
              iframe.attributes['src'] ??
              '';
          if (src.isNotEmpty &&
              !src.contains('facebook') &&
              !src.contains('google') &&
              !sources.any((s) => s.url == src)) {
            sources.add(StreamSource(
              label: "Vibe Stream Server",
              url: src.startsWith('//') ? "https:$src" : src,
              protocol: StreamProtocol.embedIframe,
            ));
          }
        }
        if (sources.isNotEmpty) return sources;
      }
    } catch (_) {}

    return [
      StreamSource(
        label: "1080p 60fps Master",
        url: "https://oppai-str.shoujo-h.org/2026/Furachi/E01/x264.1080p.mp4",
        protocol: StreamProtocol.directMp4,
        headers: {'Referer': baseUrl, 'User-Agent': _headers['User-Agent']!},
      ),
    ];
  }

  List<MediaItem> _generateSampleList(String tabId, int page) {
    if (page > 1) return [];

    final Map<String, List<MediaItem>> sampleSets = {
      "latest": [
        MediaItem(
          id: "hvb_lat_1",
          title: "Kimi wa Meido-sama: Late Night Chill Session",
          url: "$baseUrl/kimi-wa-meido-sama-late-night",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "23:45",
          releaseDate: "2025",
          studio: "Felix Film",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Vibe Latest", "Maid", "Ambient", "HD"],
          rating: 4.9,
          views: 310000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hvb_lat_2",
          title: "Midnight City Lights: Neon Bedroom Encounter",
          url: "$baseUrl/midnight-city-lights-neon-encounter",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "22:15",
          releaseDate: "2025",
          studio: "CyberVibe",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Vibe Latest", "Romance", "City Pop", "HD"],
          rating: 4.8,
          views: 285000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hvb_lat_3",
          title: "Overflow: Chill Spring Water Resort Episode 1",
          url: "$baseUrl/overflow-chill-spring-water-resort",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "25:30",
          releaseDate: "2025",
          studio: "Houkiboshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Vibe Latest", "Harem", "Relaxing", "HD"],
          rating: 4.9,
          views: 460000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hvb_lat_4",
          title: "Lo-Fi Beats to Seduce: Rainy Evening with Senpai",
          url: "$baseUrl/lo-fi-beats-rainy-evening-senpai",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "24:10",
          releaseDate: "2025",
          studio: "Studio Vibe",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Vibe Latest", "Lo-Fi", "School", "HD"],
          rating: 4.7,
          views: 295000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hvb_lat_5",
          title: "Isekai Lounge: Slime Princess VIP Suite",
          url: "$baseUrl/isekai-lounge-slime-princess-vip",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "28:40",
          releaseDate: "2025",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Vibe Latest", "Fantasy", "Isekai", "HD"],
          rating: 4.9,
          views: 390000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hvb_lat_6",
          title: "Dokidoki Little Landlady: Moonlight Veranda",
          url: "$baseUrl/dokidoki-little-landlady-moonlight",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "21:50",
          releaseDate: "2025",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Vibe Latest", "Cute", "Comedy", "HD"],
          rating: 4.8,
          views: 320000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hvb_lat_7",
          title: "Tsubaki-chou Midnight Rooftop Session",
          url: "$baseUrl/tsubaki-chou-midnight-rooftop",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "26:00",
          releaseDate: "2025",
          studio: "Ziz",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Vibe Latest", "Drama", "Atmospheric", "HD"],
          rating: 4.8,
          views: 340000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hvb_lat_8",
          title: "Shoujo Ramune: Sunset Summer Breeze",
          url: "$baseUrl/shoujo-ramune-sunset-summer-breeze",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "27:15",
          releaseDate: "2025",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Vibe Latest", "Nostalgia", "Summer", "HD"],
          rating: 4.9,
          views: 410000,
          isUncensored: false,
        ),
      ],
      "popular": [
        MediaItem(
          id: "hvb_pop_1",
          title: "Mankitsu Happening: Midnight Manga Lounge",
          url: "$baseUrl/mankitsu-happening-midnight-lounge",
          cover: "https://i.imgur.com/wVqjC5P.jpeg",
          duration: "32:15",
          releaseDate: "2024",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Top Vibe", "Harem", "Manga Cafe", "Classic"],
          rating: 5.0,
          views: 890000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hvb_pop_2",
          title: "Bible Black: Velvet Sanctum Remaster",
          url: "$baseUrl/bible-black-velvet-sanctum",
          cover: "https://i.imgur.com/z4bKxNm.jpeg",
          duration: "30:10",
          releaseDate: "2024",
          studio: "Milky Animation",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Top Vibe", "Occult", "Classic", "Supernatural"],
          rating: 5.0,
          views: 1050000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hvb_pop_3",
          title: "Kuroinu: Dark Valkyrie Vibe Cut",
          url: "$baseUrl/kuroinu-dark-valkyrie-vibe",
          cover: "https://i.imgur.com/83pZ6XQ.jpeg",
          duration: "29:45",
          releaseDate: "2024",
          studio: "Eroman",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Top Vibe", "Dark Fantasy", "Action", "Knights"],
          rating: 4.9,
          views: 920000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hvb_pop_4",
          title: "Taimanin Asagi: Cyber Tokyo Stealth Mission",
          url: "$baseUrl/taimanin-asagi-cyber-stealth",
          cover: "https://i.imgur.com/N7GgqMv.jpeg",
          duration: "27:40",
          releaseDate: "2024",
          studio: "Lilith",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Top Vibe", "Ninja", "Action", "Supernatural"],
          rating: 4.9,
          views: 780000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hvb_pop_5",
          title: "Rance 01: The Golden Citadel Journey",
          url: "$baseUrl/rance-01-golden-citadel",
          cover: "https://i.imgur.com/J3ZqK9x.jpeg",
          duration: "29:50",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Top Vibe", "Adventure", "Fantasy", "Comedy"],
          rating: 4.9,
          views: 840000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hvb_pop_6",
          title: "Gakuen de Jikan yo Tomare: Silent Hours",
          url: "$baseUrl/gakuen-de-jikan-yo-tomare-silent",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "25:35",
          releaseDate: "2024",
          studio: "BOOTLEG",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Top Vibe", "Time Stop", "School", "Classic"],
          rating: 4.9,
          views: 820000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hvb_pop_7",
          title: "Kyonyuu Fantasy: Royal Bedroom Chronicles",
          url: "$baseUrl/kyonyuu-fantasy-royal-bedroom",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "28:00",
          releaseDate: "2024",
          studio: "W-Toon Studio",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Top Vibe", "Fantasy", "Comedy", "Harem"],
          rating: 4.8,
          views: 680000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hvb_pop_8",
          title: "Master Piece: The Midnight Suite Cut",
          url: "$baseUrl/master-piece-midnight-suite",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "26:15",
          releaseDate: "2024",
          studio: "PoJu",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Top Vibe", "School", "Drama", "HD"],
          rating: 4.8,
          views: 710000,
          isUncensored: false,
        ),
      ],
      "uncensored": [
        MediaItem(
          id: "hvb_unc_1",
          title: "Discipline: Absolute Authority Uncensored",
          url: "$baseUrl/discipline-absolute-authority-uncensored",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "28:10",
          releaseDate: "2024",
          studio: "Active",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Vibe", "Mind Control", "School", "Decensored"],
          rating: 4.9,
          views: 630000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hvb_unc_2",
          title: "Kuroinu Chapter IV: Silver Maiden Uncensored",
          url: "$baseUrl/kuroinu-silver-maiden-uncensored",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "30:00",
          releaseDate: "2024",
          studio: "Eroman",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Vibe", "Dark Fantasy", "Elves", "Decensored"],
          rating: 5.0,
          views: 750000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hvb_unc_3",
          title: "Taimanin Yukikaze: Voltage Overload Uncensored",
          url: "$baseUrl/taimanin-yukikaze-voltage-uncensored",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "26:45",
          releaseDate: "2024",
          studio: "Lilith",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Vibe", "Ninja", "Sci-Fi", "Decensored"],
          rating: 4.9,
          views: 690000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hvb_unc_4",
          title: "Euphoria: Ivory Labyrinth Uncensored",
          url: "$baseUrl/euphoria-ivory-labyrinth-uncensored",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "31:20",
          releaseDate: "2024",
          studio: "Magin",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Vibe", "Psychological", "Thriller", "Decensored"],
          rating: 4.8,
          views: 810000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hvb_unc_5",
          title: "Starless: Moonlight Castle Uncensored",
          url: "$baseUrl/starless-moonlight-castle-uncensored",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "29:15",
          releaseDate: "2024",
          studio: "Milky Animation",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Vibe", "Gothic", "Mystery", "Decensored"],
          rating: 4.8,
          views: 540000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hvb_unc_6",
          title: "Viper GTS: Cyber Seraph Awakening Uncensored",
          url: "$baseUrl/viper-gts-cyber-seraph-uncensored",
          cover: "https://i.imgur.com/wVqjC5P.jpeg",
          duration: "27:30",
          releaseDate: "2024",
          studio: "Sonomama",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Vibe", "Cyberpunk", "Classic", "Decensored"],
          rating: 4.7,
          views: 490000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hvb_unc_7",
          title: "Chou-kou Tenshi Escalayer: Divine Form Uncensored",
          url: "$baseUrl/chou-kou-tenshi-escalayer-divine",
          cover: "https://i.imgur.com/z4bKxNm.jpeg",
          duration: "28:50",
          releaseDate: "2024",
          studio: "Alice Soft",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Vibe", "Mahou Shoujo", "Sci-Fi", "Heroine"],
          rating: 4.9,
          views: 590000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hvb_unc_8",
          title: "Oni Chichi: Sweet Reversible Uncensored",
          url: "$baseUrl/oni-chichi-sweet-reversible-uncensored",
          cover: "https://i.imgur.com/83pZ6XQ.jpeg",
          duration: "29:00",
          releaseDate: "2024",
          studio: "Blue Eyes",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Vibe", "Family", "Comedy", "Decensored"],
          rating: 4.9,
          views: 770000,
          isUncensored: true,
        ),
      ],
      "3d": [
        MediaItem(
          id: "hvb_3d_1",
          title: "Cyberpunk 2077: Lucy & Rebecca Neon Afterlife 3D",
          url: "$baseUrl/cyberpunk-lucy-rebecca-neon-3d",
          cover: "https://i.imgur.com/N7GgqMv.jpeg",
          duration: "09:45",
          releaseDate: "2024",
          studio: "NeonSFM",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["Cyber / 3D", "Cyberpunk", "Lucy", "60fps"],
          rating: 5.0,
          views: 720000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hvb_3d_2",
          title: "Honkai Star Rail: Kafka Neon Lounge SFM 60FPS",
          url: "$baseUrl/honkai-star-rail-kafka-neon-3d",
          cover: "https://i.imgur.com/J3ZqK9x.jpeg",
          duration: "08:45",
          releaseDate: "2024",
          studio: "SFM Lab",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["Cyber / 3D", "Honkai", "Kafka", "Blender"],
          rating: 4.9,
          views: 580000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hvb_3d_3",
          title: "Final Fantasy VII: Tifa Lockhart Cyber Bar 3D",
          url: "$baseUrl/ffvii-tifa-lockhart-cyber-bar-3d",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "14:05",
          releaseDate: "2024",
          studio: "UnrealCGI",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["Cyber / 3D", "FFVII", "Tifa", "UE5"],
          rating: 5.0,
          views: 920000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hvb_3d_4",
          title: "NieR Automata: 2B Data Overdrive 3D 60FPS",
          url: "$baseUrl/nier-automata-2b-data-overdrive-3d",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "09:30",
          releaseDate: "2024",
          studio: "Vertex CGI",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["Cyber / 3D", "NieR", "2B", "Android"],
          rating: 4.9,
          views: 640000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hvb_3d_5",
          title: "Genshin Impact: Raiden Shogun Tenshukaku Midnight 3D",
          url: "$baseUrl/genshin-impact-raiden-shogun-midnight-3d",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "11:20",
          releaseDate: "2024",
          studio: "BlenderWorks",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["Cyber / 3D", "Genshin", "Raiden", "60fps"],
          rating: 5.0,
          views: 690000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hvb_3d_6",
          title: "Zenless Zone Zero: Nicole & Zhu Yuan Hologram Suite",
          url: "$baseUrl/zzz-nicole-zhu-yuan-hologram-3d",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "10:40",
          releaseDate: "2024",
          studio: "Hollow 3D",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["Cyber / 3D", "ZZZ", "Nicole", "SFM"],
          rating: 4.9,
          views: 470000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hvb_3d_7",
          title: "Overwatch 2: D.Va & Widowmaker Cyber Stage 3D",
          url: "$baseUrl/overwatch-2-dva-widowmaker-stage-3d",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "07:15",
          releaseDate: "2024",
          studio: "OverSFM",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["Cyber / 3D", "Overwatch", "D.Va", "60fps"],
          rating: 4.8,
          views: 510000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hvb_3d_8",
          title: "Dead or Alive: Kasumi Cyber Ninja Protocol 3D",
          url: "$baseUrl/doa-kasumi-cyber-ninja-protocol-3d",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "12:50",
          releaseDate: "2024",
          studio: "Team Ninja SFM",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["Cyber / 3D", "DOA", "Kasumi", "MMD"],
          rating: 4.8,
          views: 430000,
          isUncensored: true,
        ),
      ],
      "romance": [
        MediaItem(
          id: "hvb_rom_1",
          title: "Overflow: Warm Sunset Bath & Gentle Kiss",
          url: "$baseUrl/overflow-warm-sunset-bath",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "23:45",
          releaseDate: "2024",
          studio: "Houkiboshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Pure Romance", "Vanilla", "Sweet", "Bath"],
          rating: 4.9,
          views: 650000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hvb_rom_2",
          title: "Kanojo x Kanojo x Kanojo: Pure Heart Vow",
          url: "$baseUrl/kanojo-x-kanojo-pure-heart-vow",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "26:30",
          releaseDate: "2024",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Pure Romance", "Childhood Friend", "Vanilla", "Sweet"],
          rating: 4.8,
          views: 580000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hvb_rom_3",
          title: "Lovely Heart: Starlit Terrace Confession",
          url: "$baseUrl/lovely-heart-starlit-terrace",
          cover: "https://i.imgur.com/wVqjC5P.jpeg",
          duration: "24:15",
          releaseDate: "2024",
          studio: "Bunnywalker",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Pure Romance", "First Love", "Vanilla", "School"],
          rating: 4.9,
          views: 490000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hvb_rom_4",
          title: "Kimi ga Suki: Spring Blossom Promise",
          url: "$baseUrl/kimi-ga-suki-spring-blossom",
          cover: "https://i.imgur.com/z4bKxNm.jpeg",
          duration: "25:00",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Pure Romance", "Confession", "Sweet", "Vanilla"],
          rating: 5.0,
          views: 530000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hvb_rom_5",
          title: "Tiny Evil: Gentle Succubus Cozy Slumber",
          url: "$baseUrl/tiny-evil-gentle-succubus-slumber",
          cover: "https://i.imgur.com/83pZ6XQ.jpeg",
          duration: "27:20",
          releaseDate: "2024",
          studio: "Suzuki Mirano",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Pure Romance", "Cute", "Fantasy", "Vanilla"],
          rating: 4.8,
          views: 470000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hvb_rom_6",
          title: "Koi Magal: Sunny Seaside Holiday",
          url: "$baseUrl/koi-magal-sunny-seaside-holiday",
          cover: "https://i.imgur.com/N7GgqMv.jpeg",
          duration: "22:50",
          releaseDate: "2024",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Pure Romance", "Holiday", "Summer", "Vanilla"],
          rating: 4.9,
          views: 520000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hvb_rom_7",
          title: "Hatsukoi Time: First Love Secret Whispers",
          url: "$baseUrl/hatsukoi-time-first-love-whispers",
          cover: "https://i.imgur.com/J3ZqK9x.jpeg",
          duration: "24:30",
          releaseDate: "2024",
          studio: "Mousou",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Pure Romance", "School", "Sweet", "Tender"],
          rating: 4.8,
          views: 460000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hvb_rom_8",
          title: "Boku no Piko: Sweet Nostalgic Romance",
          url: "$baseUrl/boku-no-piko-sweet-nostalgic-romance",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "26:10",
          releaseDate: "2024",
          studio: "Natural High",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Pure Romance", "Classic", "Sweet", "Emotional"],
          rating: 4.7,
          views: 410000,
          isUncensored: false,
        ),
      ],
    };

    return sampleSets[tabId] ?? sampleSets["latest"] ?? [];
  }

  MediaDetail _generateSampleDetail(String url) {
    return MediaDetail(
      id: url.hashCode.toString(),
      title: "Taimanin Asagi Vibe Edition",
      cover: "https://i.imgur.com/7jZQY1B.jpeg",
      backdrop: "https://i.imgur.com/7jZQY1B.jpeg",
      description: "Ambient anime streaming release on HentaiVibe.",
      studio: "Lilith Animation",
      releaseDate: "2024",
      tags: ["Ambient Vibe", "HD", "Uncensored"],
      episodes: [
        EpisodeItem(
          id: "ep_1",
          episodeNumber: "Episode 1",
          title: "Taimanin Asagi Ep 1",
          url: url,
          thumbnail: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "24:00",
          sources: [
            StreamSource(
              label: "1080p Master",
              url: "https://oppai-str.shoujo-h.org/2026/Furachi/E01/x264.1080p.mp4",
              protocol: StreamProtocol.directMp4,
              headers: {'Referer': baseUrl, 'User-Agent': _headers['User-Agent']!},
            )
          ],
        )
      ],
      playbackHeatmap: [0.1, 0.4, 0.7, 0.95, 0.8, 0.4, 0.3, 0.9, 1.0, 0.4],
      sceneMarkers: [
        SceneMarker(title: "Opening", timestampSeconds: 0),
        SceneMarker(title: "Climax 🔥", timestampSeconds: 700),
      ],
    );
  }

  @override
  Future<ExtensionTaxonomy> fetchTaxonomy() async {
    return hentaiVibeTaxonomy;
  }

  @override
  Future<List<MediaItem>> fetchTaxonomyFeed(CatalogItem item, int page) async {
    // 1. Direct tab feed mapping if it matches a primary tab
    if (item.slug == 'latest' ||
        item.slug == 'popular' ||
        item.slug == 'uncensored' ||
        item.slug == '3d' ||
        item.slug == 'romance') {
      return fetchTabFeed(item.slug, page);
    }

    // 2. Live feed scraping across candidate domains using verified taxonomy routes
    final rawPath = item.endpointPath ??
        (item.type == CatalogType.tag
            ? '/tags/${Uri.encodeComponent(item.slug)}/'
            : '/genre/${Uri.encodeComponent(item.slug)}/');
    final cleanPath = rawPath.startsWith('/') ? rawPath : '/$rawPath';
    final normalizedPath =
        cleanPath.endsWith('/') ? cleanPath : '$cleanPath/';

    for (final domain in _candidateDomains) {
      try {
        final targetUrl = page == 1
            ? '$domain$normalizedPath'
            : '$domain${normalizedPath}page/$page/';

        final response = await http
            .get(Uri.parse(targetUrl), headers: _headers)
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final items =
              _parseCardsFromHtml(response.body, domain, tabId: item.slug);
          if (items.isNotEmpty) return items;
        }
      } catch (_) {}
    }

    // 3. Fallback to live search query on the site
    try {
      final searchResults = await search(item.name, page);
      if (searchResults.isNotEmpty) return searchResults;
    } catch (_) {}

    // 4. Offline sample fallback for Explore browsing
    return _generateTaxonomySampleList(item, page);
  }

  List<MediaItem> _generateTaxonomySampleList(CatalogItem item, int page) {
    if (page > 1) return [];

    final fallbackTab = (item.slug == '3d' ||
            item.categoryGroup == 'Visual Formats' ||
            item.name.toLowerCase().contains('3d'))
        ? '3d'
        : (item.slug == 'romance' ||
                item.categoryGroup == 'Mood' ||
                item.slug == 'vanilla')
            ? 'romance'
            : (item.slug == 'uncensored' ||
                    item.categoryGroup == 'Censorship' ||
                    item.slug == 'decensored')
                ? 'uncensored'
                : (item.slug == 'popular' || item.count > 100)
                    ? 'popular'
                    : 'latest';

    final baseItems = _generateSampleList(fallbackTab, 1);
    return baseItems.map((m) {
      final updatedTags = List<String>.from(m.tags);
      if (!updatedTags.contains(item.name)) {
        updatedTags.insert(0, item.name);
      }
      return MediaItem(
        id: "hvb_tax_${item.slug.replaceAll(' ', '_')}_${m.id}",
        title: m.title,
        url: m.url,
        cover: hentaiVibeCategoryCovers[item.slug] ?? m.cover,
        duration: m.duration,
        releaseDate: m.releaseDate,
        studio: m.studio,
        extensionId: id,
        type: (item.slug == '3d' || m.type == MediaType.mmd3D)
            ? MediaType.mmd3D
            : MediaType.animeSeries,
        tags: updatedTags,
        rating: m.rating,
        views: item.count > 0 ? (item.count * 1000 + 15000) : m.views,
        isUncensored: m.isUncensored ||
            item.slug == 'uncensored' ||
            item.categoryGroup == 'Censorship',
      );
    }).toList();
  }
}

