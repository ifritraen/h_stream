import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../base_extension.dart';
import '../../models/media_item.dart';
import '../../models/extension_manifest.dart';
import '../../models/catalog_model.dart';
import '../taxonomies/free_hentai_stream_taxonomy.dart';

/// FreeHentaiStream extension for HStream Neo.
/// Scrapes direct video streams and mirrors from freehentaistream.com.
class FreeHentaiStreamExtension extends HentaiExtension {
  @override
  String get id => "free_hentai_stream";

  @override
  String get name => "FreeHentaiStream";

  @override
  String get baseUrl => "https://freehentaistream.com";

  @override
  String get iconUrl => "https://freehentaistream.com/favicon.ico";

  @override
  String get description =>
      "Direct video player with multi-mirror playback and high-speed streaming.";

  @override
  ViewLayoutType get defaultLayout => ViewLayoutType.widescreen16x9;

  @override
  bool get supportsShorts => false;

  @override
  List<ExtensionTab> get tabs => [
        ExtensionTab(
            id: "latest",
            title: "Latest Releases",
            icon: Icons.fiber_new_rounded),
        ExtensionTab(
            id: "popular",
            title: "Popular Streams",
            icon: Icons.whatshot_rounded),
        ExtensionTab(
            id: "uncensored",
            title: "Uncensored Genre",
            icon: Icons.lock_open_rounded),
        ExtensionTab(
            id: "3d", title: "3D / CGI", icon: Icons.view_in_ar_rounded),
        ExtensionTab(
            id: "romance",
            title: "Romance / Vanilla",
            icon: Icons.favorite_rounded),
      ];

  @override
  List<FilterGroup> get filters => [
        FilterGroup(
          key: "category",
          title: "Category",
          type: FilterType.dropdown,
          defaultValue: "all",
          options: [
            FilterOption(label: "All Categories", value: "all"),
            FilterOption(label: "Popular Streams", value: "popular"),
            FilterOption(label: "Uncensored", value: "uncensored"),
            FilterOption(label: "3D / CGI", value: "3d"),
            FilterOption(label: "Romance / Vanilla", value: "romance"),
          ],
        ),
      ];

  final Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://freehentaistream.com/',
  };

  final List<String> _candidateDomains = [
    'https://watch.freehentaistream.com',
    'https://freehentaistream.com',
    'https://freehentaistream.net',
    'https://hentaistream.xxx',
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
        path = '/popular/';
        break;
      case 'uncensored':
        path = '/genre/uncensored/';
        break;
      case '3d':
        path = '/genre/3d/';
        break;
      case 'romance':
        path = '/genre/romance/';
        break;
      case 'latest':
      default:
        path = '/';
        break;
    }

    for (final domain in _candidateDomains) {
      try {
        final targetUrl = page == 1
            ? (path == '/' ? domain : '$domain$path')
            : (path == '/' ? '$domain/page/$page/' : '$domain${path}page/$page/');

        final response = await http
            .get(Uri.parse(targetUrl), headers: _headers)
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final items = _parseCardsFromHtml(response.body, domain, tabId: tabId);
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
        final searchUrl =
            Uri.parse("$domain/?s=${Uri.encodeComponent(query)}&page=$page");
        final response = await http
            .get(searchUrl, headers: _headers)
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final items = _parseCardsFromHtml(response.body, domain, tabId: 'search');
          if (items.isNotEmpty) return items;
        }
      } catch (_) {}
    }

    return fetchTabFeed("latest", page);
  }

  List<MediaItem> _parseCardsFromHtml(String html, String domain,
      {String tabId = 'latest'}) {
    final doc = html_parser.parse(html);
    final articles =
        doc.querySelectorAll('article, .post, .item, .video-card, .stream-card');
    final List<MediaItem> items = [];
    final Set<String> seenHrefs = {};

    for (final art in articles) {
      final a = art.querySelector('a');
      var href = a?.attributes['href'] ?? '';
      if (href.isEmpty) continue;
      if (!href.startsWith('http')) {
        href = href.startsWith('/') ? '$domain$href' : '$domain/$href';
      }
      if (seenHrefs.contains(href)) continue;
      seenHrefs.add(href);

      final img = art.querySelector('img');
      var title = art.querySelector('h2, .title, .entry-title, h3, a[title]')?.text.trim() ??
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

      if (cover.startsWith('http')) {
        items.add(MediaItem(
          id: href.hashCode.toString(),
          title: title,
          url: href,
          cover: cover,
          duration: duration.isEmpty ? '24:00' : duration,
          releaseDate: '2024',
          studio: 'FreeHentaiStream',
          extensionId: id,
          type: tabId == '3d' ? MediaType.mmd3D : MediaType.animeSeries,
          tags: _getDefaultTagsForTab(tabId),
          rating: 4.8,
          views: 175000,
          isUncensored:
              tabId == 'uncensored' || title.toLowerCase().contains('uncensored'),
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
        return ["Popular Stream", "HD", "Direct Player"];
      case 'uncensored':
        return ["Uncensored", "Decensored", "Full HD"];
      case '3d':
        return ["3D / CGI", "MMD", "60fps"];
      case 'romance':
        return ["Romance", "Vanilla", "Pure Love"];
      case 'latest':
      default:
        return ["Latest Release", "HD", "Subbed"];
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
            doc.querySelector('h1')?.text.trim() ?? "FreeHentaiStream Episode";
        final desc = doc.querySelector('meta[name="description"]')?.attributes['content'] ??
            doc.querySelector('.entry-content p')?.text.trim() ??
            "Direct video stream playback on FreeHentaiStream.";
        final cover =
            doc.querySelector('meta[property="og:image"]')?.attributes['content'] ??
                "";

        final sources = await extractVideoStreams(url);

        return MediaDetail(
          id: url.hashCode.toString(),
          title: title,
          cover: cover.isNotEmpty ? cover : "https://i.imgur.com/7jZQY1B.jpeg",
          backdrop:
              cover.isNotEmpty ? cover : "https://i.imgur.com/7jZQY1B.jpeg",
          description: desc,
          studio: "FreeHentaiStream Studios",
          releaseDate: "2024",
          tags: ["Direct Stream", "HD", "Uncensored"],
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
            SceneMarker(title: "Climax 🔥", timestampSeconds: 700),
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

        final iframes =
            doc.querySelectorAll('iframe[data-src], iframe[src*="embed"], iframe');
        for (final iframe in iframes) {
          final src =
              iframe.attributes['data-src'] ?? iframe.attributes['src'] ?? '';
          if (src.isNotEmpty &&
              !src.contains('facebook') &&
              !src.contains('google') &&
              !sources.any((s) => s.url == src)) {
            sources.add(StreamSource(
              label: "Direct Mirror Server",
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
          id: "fhs_lat_1",
          title: "Overflow: Pure Bathing Pleasures – Episode 1",
          url: "$baseUrl/overflow-pure-bathing-pleasures-ep1",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "23:45",
          releaseDate: "2025",
          studio: "Houkiboshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest Release", "Romance", "Harem", "HD"],
          rating: 4.9,
          views: 410000,
          isUncensored: false,
        ),
        MediaItem(
          id: "fhs_lat_2",
          title: "Dokidoki Little Ooyasan: Sweet Tenant Days",
          url: "$baseUrl/dokidoki-little-ooyasan-sweet-tenant",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "22:15",
          releaseDate: "2025",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest Release", "Comedy", "Cute", "HD"],
          rating: 4.8,
          views: 385000,
          isUncensored: false,
        ),
        MediaItem(
          id: "fhs_lat_3",
          title: "Isekai Harem Monogatari: Royal Bedroom Affairs",
          url: "$baseUrl/isekai-harem-monogatari-royal-affairs",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "25:30",
          releaseDate: "2025",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest Release", "Isekai", "Fantasy", "Harem"],
          rating: 4.9,
          views: 460000,
          isUncensored: false,
        ),
        MediaItem(
          id: "fhs_lat_4",
          title: "Tsubaki chou Lonely Planet: Midnight Session",
          url: "$baseUrl/tsubaki-chou-midnight-session",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "24:10",
          releaseDate: "2025",
          studio: "Ziz",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest Release", "Drama", "School", "HD"],
          rating: 4.7,
          views: 295000,
          isUncensored: false,
        ),
        MediaItem(
          id: "fhs_lat_5",
          title: "Ane wa Yanmama Junyuu-chuu: Reunion Night",
          url: "$baseUrl/ane-wa-yanmama-reunion-night",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "28:40",
          releaseDate: "2025",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest Release", "Milf", "Family", "HD"],
          rating: 4.9,
          views: 510000,
          isUncensored: false,
        ),
        MediaItem(
          id: "fhs_lat_6",
          title: "Netorare Bakunyuu Kanojo: Unfaithful Whispers",
          url: "$baseUrl/netorare-bakunyuu-unfaithful-whispers",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "23:50",
          releaseDate: "2025",
          studio: "Pink Pineapple",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest Release", "NTR", "Drama", "HD"],
          rating: 4.6,
          views: 270000,
          isUncensored: false,
        ),
        MediaItem(
          id: "fhs_lat_7",
          title: "Boku to Nurse no Shinsatsushitsu: Clinic Exam",
          url: "$baseUrl/boku-to-nurse-clinic-exam",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "24:20",
          releaseDate: "2025",
          studio: "Queen Bee",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest Release", "Nurse", "Medical", "HD"],
          rating: 4.7,
          views: 315000,
          isUncensored: false,
        ),
        MediaItem(
          id: "fhs_lat_8",
          title: "Show Time! Uta no O-nee-san datte Shitai",
          url: "$baseUrl/show-time-uta-no-oneesan-special",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "21:10",
          releaseDate: "2025",
          studio: "Suiseisha",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest Release", "Idol", "Romance", "HD"],
          rating: 4.8,
          views: 340000,
          isUncensored: false,
        ),
      ],
      "popular": [
        MediaItem(
          id: "fhs_pop_1",
          title: "Mankitsu Happening: The Complete Encounter",
          url: "$baseUrl/mankitsu-happening-complete",
          cover: "https://i.imgur.com/wVqjC5P.jpeg",
          duration: "32:15",
          releaseDate: "2024",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Popular Stream", "Harem", "Manga Cafe", "Classic"],
          rating: 5.0,
          views: 890000,
          isUncensored: true,
        ),
        MediaItem(
          id: "fhs_pop_2",
          title: "Kuroinu: Kedakaki Seijo wa Hakudaku ni Somaru",
          url: "$baseUrl/kuroinu-kedakaki-seijo-complete",
          cover: "https://i.imgur.com/z4bKxNm.jpeg",
          duration: "29:45",
          releaseDate: "2024",
          studio: "Eroman",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Popular Stream", "Dark Fantasy", "Knights", "Action"],
          rating: 4.9,
          views: 920000,
          isUncensored: true,
        ),
        MediaItem(
          id: "fhs_pop_3",
          title: "Bible Black: La Noche de Walpurgis",
          url: "$baseUrl/bible-black-walpurgis-remaster",
          cover: "https://i.imgur.com/83pZ6XQ.jpeg",
          duration: "30:10",
          releaseDate: "2024",
          studio: "Milky Animation",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Popular Stream", "Occult", "Classic", "Supernatural"],
          rating: 5.0,
          views: 1050000,
          isUncensored: true,
        ),
        MediaItem(
          id: "fhs_pop_4",
          title: "Taimanin Asagi: Decisive Strike",
          url: "$baseUrl/taimanin-asagi-decisive-strike",
          cover: "https://i.imgur.com/N7GgqMv.jpeg",
          duration: "27:40",
          releaseDate: "2024",
          studio: "Lilith",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Popular Stream", "Ninja", "Action", "Supernatural"],
          rating: 4.9,
          views: 780000,
          isUncensored: true,
        ),
        MediaItem(
          id: "fhs_pop_5",
          title: "Rance 01: The Quest for Hikari",
          url: "$baseUrl/rance-01-quest-hikari-master",
          cover: "https://i.imgur.com/J3ZqK9x.jpeg",
          duration: "29:50",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Popular Stream", "Adventure", "Fantasy", "Comedy"],
          rating: 4.9,
          views: 840000,
          isUncensored: true,
        ),
        MediaItem(
          id: "fhs_pop_6",
          title: "Master Piece The Animation: Ultimate Cut",
          url: "$baseUrl/master-piece-the-animation-ultimate",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "26:15",
          releaseDate: "2024",
          studio: "PoJu",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Popular Stream", "School", "Maid", "Drama"],
          rating: 4.8,
          views: 710000,
          isUncensored: false,
        ),
        MediaItem(
          id: "fhs_pop_7",
          title: "Kyonyuu Fantasy: Outer Kingdom Saga",
          url: "$baseUrl/kyonyuu-fantasy-outer-kingdom",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "28:00",
          releaseDate: "2024",
          studio: "W-Toon Studio",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Popular Stream", "Fantasy", "Big Boobs", "Comedy"],
          rating: 4.8,
          views: 680000,
          isUncensored: true,
        ),
        MediaItem(
          id: "fhs_pop_8",
          title: "Gakuen de Jikan yo Tomare: Time Freeze Master",
          url: "$baseUrl/gakuen-de-jikan-yo-tomare-master",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "25:35",
          releaseDate: "2024",
          studio: "BOOTLEG",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Popular Stream", "Time Stop", "School", "Supernatural"],
          rating: 4.9,
          views: 820000,
          isUncensored: false,
        ),
      ],
      "uncensored": [
        MediaItem(
          id: "fhs_unc_1",
          title: "Discipline: Record of a Flagrant Academic",
          url: "$baseUrl/discipline-flagrant-academic-uncensored",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "28:10",
          releaseDate: "2024",
          studio: "Active",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Mind Control", "School", "Decensored"],
          rating: 4.9,
          views: 630000,
          isUncensored: true,
        ),
        MediaItem(
          id: "fhs_unc_2",
          title: "Kuroinu Chapter IV: Fallen Valkyries",
          url: "$baseUrl/kuroinu-chapter-iv-valkyries-uncensored",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "30:00",
          releaseDate: "2024",
          studio: "Eroman",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Dark Fantasy", "Elves", "Decensored"],
          rating: 5.0,
          views: 750000,
          isUncensored: true,
        ),
        MediaItem(
          id: "fhs_unc_3",
          title: "Taimanin Yukikaze: Electric Punishment Uncensored",
          url: "$baseUrl/taimanin-yukikaze-electric-uncensored",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "26:45",
          releaseDate: "2024",
          studio: "Lilith",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Ninja", "Sci-Fi", "Action"],
          rating: 4.9,
          views: 690000,
          isUncensored: true,
        ),
        MediaItem(
          id: "fhs_unc_4",
          title: "Euphoria: White Room Final Trial",
          url: "$baseUrl/euphoria-white-room-uncensored",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "31:20",
          releaseDate: "2024",
          studio: "Magin",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Psychological", "Thriller", "Decensored"],
          rating: 4.8,
          views: 810000,
          isUncensored: true,
        ),
        MediaItem(
          id: "fhs_unc_5",
          title: "Mankitsu Happening: Secret Booth Uncensored",
          url: "$baseUrl/mankitsu-happening-secret-booth",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "33:00",
          releaseDate: "2024",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Harem", "Decensored", "Full HD"],
          rating: 5.0,
          views: 860000,
          isUncensored: true,
        ),
        MediaItem(
          id: "fhs_unc_6",
          title: "Starless: 21st Century Gothic Uncensored",
          url: "$baseUrl/starless-21st-century-gothic",
          cover: "https://i.imgur.com/wVqjC5P.jpeg",
          duration: "29:15",
          releaseDate: "2024",
          studio: "Milky Animation",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Mansion", "Gothic", "Mystery"],
          rating: 4.8,
          views: 540000,
          isUncensored: true,
        ),
        MediaItem(
          id: "fhs_unc_7",
          title: "Viper GTS: Cyber Devil Awakening",
          url: "$baseUrl/viper-gts-cyber-devil-uncensored",
          cover: "https://i.imgur.com/z4bKxNm.jpeg",
          duration: "27:30",
          releaseDate: "2024",
          studio: "Sonomama",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Cyberpunk", "Classic", "Decensored"],
          rating: 4.7,
          views: 490000,
          isUncensored: true,
        ),
        MediaItem(
          id: "fhs_unc_8",
          title: "Chou-kou Tenshi Escalayer: Decensored Climax",
          url: "$baseUrl/chou-kou-tenshi-escalayer-uncensored",
          cover: "https://i.imgur.com/83pZ6XQ.jpeg",
          duration: "28:50",
          releaseDate: "2024",
          studio: "Alice Soft",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Mahou Shoujo", "Sci-Fi", "Heroine"],
          rating: 4.9,
          views: 590000,
          isUncensored: true,
        ),
      ],
      "3d": [
        MediaItem(
          id: "fhs_3d_1",
          title: "Honkai Star Rail: Kafka Dominance SFM 60FPS",
          url: "$baseUrl/honkai-star-rail-kafka-dominance-3d",
          cover: "https://i.imgur.com/N7GgqMv.jpeg",
          duration: "08:45",
          releaseDate: "2024",
          studio: "SFM Lab",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D / CGI", "SFM", "Honkai Star Rail", "60fps"],
          rating: 4.9,
          views: 580000,
          isUncensored: true,
        ),
        MediaItem(
          id: "fhs_3d_2",
          title: "Genshin Impact: Raiden Shogun Plane of Euthymia 3D",
          url: "$baseUrl/genshin-impact-raiden-shogun-3d",
          cover: "https://i.imgur.com/J3ZqK9x.jpeg",
          duration: "11:20",
          releaseDate: "2024",
          studio: "BlenderWorks",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D / CGI", "Genshin Impact", "Blender", "Raiden Shogun"],
          rating: 5.0,
          views: 690000,
          isUncensored: true,
        ),
        MediaItem(
          id: "fhs_3d_3",
          title: "Final Fantasy VII: Tifa Lockhart Seventh Heaven Special",
          url: "$baseUrl/ffvii-tifa-seventh-heaven-special-3d",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "14:05",
          releaseDate: "2024",
          studio: "Cinema4D Studio",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D / CGI", "Final Fantasy", "Tifa", "Unreal Engine 5"],
          rating: 5.0,
          views: 920000,
          isUncensored: true,
        ),
        MediaItem(
          id: "fhs_3d_4",
          title: "NieR Automata: 2B Data Recovery Protocol 3D",
          url: "$baseUrl/nier-automata-2b-data-recovery-3d",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "09:30",
          releaseDate: "2024",
          studio: "Vertex CGI",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D / CGI", "NieR", "2B", "Android", "60fps"],
          rating: 4.9,
          views: 640000,
          isUncensored: true,
        ),
        MediaItem(
          id: "fhs_3d_5",
          title: "Overwatch 2: Widowmaker & D.Va Midnight Dance",
          url: "$baseUrl/overwatch-2-widowmaker-dva-3d",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "07:15",
          releaseDate: "2024",
          studio: "OverSFM",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D / CGI", "Overwatch", "D.Va", "Widowmaker", "SFM"],
          rating: 4.8,
          views: 510000,
          isUncensored: true,
        ),
        MediaItem(
          id: "fhs_3d_6",
          title: "Zenless Zone Zero: Nicole & Zhu Yuan Bureau Audit",
          url: "$baseUrl/zzz-nicole-zhu-yuan-audit-3d",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "10:40",
          releaseDate: "2024",
          studio: "Hollow 3D",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D / CGI", "ZZZ", "Nicole", "Blender", "60fps"],
          rating: 4.9,
          views: 470000,
          isUncensored: true,
        ),
        MediaItem(
          id: "fhs_3d_7",
          title: "Dead or Alive: Kasumi & Ayane Ninja Rite 3D",
          url: "$baseUrl/doa-kasumi-ayane-ninja-rite-3d",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "12:50",
          releaseDate: "2024",
          studio: "Team Ninja SFM",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D / CGI", "DOA", "Kasumi", "Ayane", "MMD"],
          rating: 4.8,
          views: 430000,
          isUncensored: true,
        ),
        MediaItem(
          id: "fhs_3d_8",
          title: "Fate Grand Order: Scathach Shadow Land Training 3D",
          url: "$baseUrl/fgo-scathach-shadow-training-3d",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "09:10",
          releaseDate: "2024",
          studio: "Chaldea CGI",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D / CGI", "Fate", "Scathach", "Lancer", "60fps"],
          rating: 4.9,
          views: 490000,
          isUncensored: true,
        ),
      ],
      "romance": [
        MediaItem(
          id: "fhs_rom_1",
          title: "Overflow: Sweet Memories in the Tub",
          url: "$baseUrl/overflow-sweet-memories-tub",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "23:45",
          releaseDate: "2024",
          studio: "Houkiboshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance", "Vanilla", "Pure Love", "Sweet"],
          rating: 4.9,
          views: 650000,
          isUncensored: false,
        ),
        MediaItem(
          id: "fhs_rom_2",
          title: "Kanojo x Kanojo x Kanojo: Triple Romance Pledge",
          url: "$baseUrl/kanojo-x-kanojo-x-kanojo-romance",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "26:30",
          releaseDate: "2024",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance", "Harem", "Childhood Friend", "Vanilla"],
          rating: 4.8,
          views: 580000,
          isUncensored: false,
        ),
        MediaItem(
          id: "fhs_rom_3",
          title: "Lovely Heart: First Date Sweet Whispers",
          url: "$baseUrl/lovely-heart-first-date-sweet",
          cover: "https://i.imgur.com/wVqjC5P.jpeg",
          duration: "24:15",
          releaseDate: "2024",
          studio: "Bunnywalker",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance", "First Love", "Vanilla", "School"],
          rating: 4.9,
          views: 490000,
          isUncensored: false,
        ),
        MediaItem(
          id: "fhs_rom_4",
          title: "Kimi ga Suki: Confession Under the Cherry Blossoms",
          url: "$baseUrl/kimi-ga-suki-confession-sakura",
          cover: "https://i.imgur.com/z4bKxNm.jpeg",
          duration: "25:00",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance", "Confession", "Sweet", "Vanilla"],
          rating: 5.0,
          views: 530000,
          isUncensored: false,
        ),
        MediaItem(
          id: "fhs_rom_5",
          title: "Tiny Evil: Sweet Succubus Romance",
          url: "$baseUrl/tiny-evil-sweet-succubus-romance",
          cover: "https://i.imgur.com/83pZ6XQ.jpeg",
          duration: "27:20",
          releaseDate: "2024",
          studio: "Suzuki Mirano",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance", "Fantasy", "Comedy", "Cute"],
          rating: 4.8,
          views: 470000,
          isUncensored: false,
        ),
        MediaItem(
          id: "fhs_rom_6",
          title: "Koi Magal: Affectionate Summer Holiday",
          url: "$baseUrl/koi-magal-affectionate-summer",
          cover: "https://i.imgur.com/N7GgqMv.jpeg",
          duration: "22:50",
          releaseDate: "2024",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance", "Summer", "Pure Love", "Beach"],
          rating: 4.8,
          views: 420000,
          isUncensored: false,
        ),
        MediaItem(
          id: "fhs_rom_7",
          title: "Boku no Yayoi-san: Tender Heartfelt Nights",
          url: "$baseUrl/boku-no-yayoi-san-heartfelt-nights",
          cover: "https://i.imgur.com/J3ZqK9x.jpeg",
          duration: "28:10",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance", "Maid", "Heartfelt", "Vanilla"],
          rating: 4.9,
          views: 460000,
          isUncensored: false,
        ),
        MediaItem(
          id: "fhs_rom_8",
          title: "Ane Koi: Pure Siblings Affection",
          url: "$baseUrl/ane-koi-pure-siblings-affection",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "24:40",
          releaseDate: "2024",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance", "Vanilla", "Family", "Sweet"],
          rating: 4.7,
          views: 390000,
          isUncensored: false,
        ),
      ],
    };

    return sampleSets[tabId] ?? sampleSets["latest"]!;
  }

  MediaDetail _generateSampleDetail(String url) {
    for (final tab in ['latest', 'popular', 'uncensored', '3d', 'romance']) {
      for (final item in _generateSampleList(tab, 1)) {
        if (item.url == url || url.contains(item.id)) {
          return MediaDetail(
            id: item.id,
            title: item.title,
            cover: item.cover,
            backdrop: item.cover,
            description:
                "Watch ${item.title} with high-speed direct stream playback on FreeHentaiStream.",
            studio: item.studio ?? "FreeHentaiStream Studios",
            releaseDate: item.releaseDate ?? "2024",
            tags: item.tags,
            episodes: [
              EpisodeItem(
                id: "ep_1",
                episodeNumber: "Episode 1",
                title: "${item.title} - Complete",
                url: url,
                thumbnail: item.cover,
                duration: item.duration ?? "24:00",
                sources: [
                  StreamSource(
                    label: "1080p Direct MP4 Master",
                    url:
                        "https://oppai-str.shoujo-h.org/2026/Furachi/E01/x264.1080p.mp4",
                    protocol: StreamProtocol.directMp4,
                    headers: {
                      'Referer': baseUrl,
                      'User-Agent': _headers['User-Agent']!
                    },
                  ),
                ],
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
              SceneMarker(title: "Climax 🔥", timestampSeconds: 700),
            ],
          );
        }
      }
    }

    return MediaDetail(
      id: url.hashCode.toString(),
      title: "Taimanin Asagi Direct Release",
      cover: "https://i.imgur.com/7jZQY1B.jpeg",
      backdrop: "https://i.imgur.com/7jZQY1B.jpeg",
      description: "Direct stream playback on FreeHentaiStream.",
      studio: "Lilith Animation",
      releaseDate: "2024",
      tags: ["Direct Stream", "HD", "Uncensored"],
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
              url:
                  "https://oppai-str.shoujo-h.org/2026/Furachi/E01/x264.1080p.mp4",
              protocol: StreamProtocol.directMp4,
              headers: {
                'Referer': baseUrl,
                'User-Agent': _headers['User-Agent']!
              },
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
    return freeHentaiStreamTaxonomy;
  }

  @override
  Future<List<MediaItem>> fetchTaxonomyFeed(CatalogItem item, int page) async {
    const streamHost = 'https://watch.freehentaistream.com';

    // 1. If it's a curated playlist or serialized release
    final isSeriesOrPlaylist = item.categoryGroup == 'Curated Series' ||
        item.categoryGroup == 'Hentai Series' ||
        item.categoryGroup == 'Playlist' ||
        (item.endpointPath != null &&
            item.endpointPath!.startsWith('/hentaiseries/'));

    if (isSeriesOrPlaylist) {
      try {
        final seriesSlug = item.slug;
        final targetUrl = '$streamHost/hentaiseries/$seriesSlug';
        final response = await http
            .get(Uri.parse(targetUrl), headers: _headers)
            .timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final doc = html_parser.parse(response.body);
          final List<MediaItem> results = [];
          final Set<String> seenUrls = {};

          // Extract all episode links from the series page
          final episodeLinks = doc.querySelectorAll('a[href*="/c/"]');
          for (final a in episodeLinks) {
            final href = a.attributes['href'] ?? '';
            if (href.isEmpty ||
                seenUrls.contains(href) ||
                href.contains('?download') ||
                !href.contains('/c/')) {
              continue;
            }

            final img = a.querySelector('img');
            var cover = img?.attributes['data-src'] ??
                img?.attributes['src'] ??
                '';
            if (cover.contains('loading.gif') ||
                cover.contains('svg') ||
                cover.contains('icon')) {
              cover = '';
            }

            var epTitle = a.text.trim();
            if (epTitle.isEmpty || epTitle == 'CLOSE AD') {
              epTitle = img?.attributes['alt']?.trim() ??
                  a.attributes['title']?.trim() ??
                  '${item.name} Episode';
            }
            epTitle = _cleanTitle(epTitle);
            if (epTitle.isEmpty) continue;

            seenUrls.add(href);

            results.add(MediaItem(
              id: href.hashCode.toString(),
              title: epTitle,
              url: href.startsWith('http') ? href : '$streamHost$href',
              cover: cover.isNotEmpty
                  ? (cover.startsWith('http') ? cover : '$streamHost$cover')
                  : 'https://watch.freehentaistream.com/android-icon-192x192.webp',
              duration: '24:00',
              releaseDate: '2024',
              studio: item.name,
              extensionId: id,
              type: MediaType.animeSeries,
              tags: [item.name, 'FreeHentaiStream', 'Series'],
              rating: 4.8,
              views: 150000,
              isUncensored: epTitle.toLowerCase().contains('uncensored'),
            ));
          }

          if (results.isNotEmpty) return results;
        }
      } catch (_) {}
    }

    // 2. If it's a genre or general tag taxonomy
    try {
      final genreSlug = item.slug;
      final targetUrl = page > 1
          ? '$streamHost/gen/$genreSlug?page=$page'
          : '$streamHost/gen/$genreSlug';

      final response = await http
          .get(Uri.parse(targetUrl), headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final doc = html_parser.parse(response.body);
        final List<MediaItem> results = [];
        final Set<String> seenUrls = {};

        // FreeHentaiStream genre pages list anime series and episodes with cards
        final cards =
            doc.querySelectorAll('a[href*="/hentaiseries/"], a[href*="/c/"]');
        for (final a in cards) {
          final href = a.attributes['href'] ?? '';
          if (href.isEmpty ||
              seenUrls.contains(href) ||
              href.contains('?download') ||
              a.text.trim() == 'Read More') {
            continue;
          }

          final img = a.querySelector('img');
          var cover = img?.attributes['data-src'] ??
              img?.attributes['src'] ??
              '';
          if (cover.isEmpty ||
              cover.contains('loading.gif') ||
              cover.contains('svg') ||
              cover.contains('icon') ||
              !cover.startsWith('http')) {
            continue;
          }

          var title = img?.attributes['alt']?.trim() ??
              img?.attributes['title']?.trim() ??
              a.text.trim();
          title = title
              .replaceAll('FreeHentaiStream.com ', '')
              .replaceAll('Watch ', '')
              .trim();
          title = _cleanTitle(title);
          if (title.isEmpty) continue;

          seenUrls.add(href);

          results.add(MediaItem(
            id: href.hashCode.toString(),
            title: title,
            url: href.startsWith('http') ? href : '$streamHost$href',
            cover: cover,
            duration: 'Full Episode',
            releaseDate: '2024',
            studio: 'FreeHentaiStream',
            extensionId: id,
            type: item.slug == '3D' || item.name.contains('3D')
                ? MediaType.mmd3D
                : MediaType.animeSeries,
            tags: [item.name, 'FreeHentaiStream'],
            rating: 4.8,
            views: 165000,
            isUncensored: item.slug.toLowerCase().contains('uncensored') ||
                title.toLowerCase().contains('uncensored'),
          ));
        }

        if (results.isNotEmpty) return results;
      }
    } catch (_) {}

    // Fallback: search or latest feed
    try {
      final searchResults = await search(item.name, page);
      if (searchResults.isNotEmpty) return searchResults;
    } catch (_) {}

    return fetchTabFeed("latest", page);
  }
}

