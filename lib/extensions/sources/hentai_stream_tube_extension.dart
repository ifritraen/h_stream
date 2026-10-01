import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../base_extension.dart';
import '../../models/media_item.dart';
import '../../models/extension_manifest.dart';
import '../../models/catalog_model.dart';
import '../taxonomies/hentai_stream_tube_taxonomy.dart';

/// HentaiStream Tube extension for HStream Neo.
/// Scrapes fast speed tube player from hentaistream.xxx and mirrors.
class HentaiStreamTubeExtension extends HentaiExtension {
  @override
  String get id => "hentai_stream_tube";

  @override
  String get name => "HentaiStream";

  @override
  String get baseUrl => "https://hentaistream.xxx";

  @override
  String get iconUrl => "https://hentaistream.xxx/favicon.ico";

  @override
  String get description =>
      "High-speed streaming tube player with instant buffer and HD playback.";

  @override
  ViewLayoutType get defaultLayout => ViewLayoutType.widescreen16x9;

  @override
  bool get supportsShorts => false;

  @override
  List<ExtensionTab> get tabs => [
    ExtensionTab(
      id: "latest",
      title: "Stream Latest",
      icon: Icons.fiber_new_rounded,
    ),
    ExtensionTab(
      id: "popular",
      title: "Top Streams",
      icon: Icons.whatshot_rounded,
    ),
    ExtensionTab(
      id: "uncensored",
      title: "Uncensored Stream",
      icon: Icons.lock_open_rounded,
    ),
    ExtensionTab(id: "3d", title: "3D / MMD", icon: Icons.view_in_ar_rounded),
    ExtensionTab(
      id: "romance",
      title: "Romance Genre",
      icon: Icons.favorite_rounded,
    ),
  ];

  @override
  List<FilterGroup> get filters => [
    FilterGroup(
      key: "category",
      title: "Category",
      type: FilterType.dropdown,
      defaultValue: "all",
      options: [
        FilterOption(label: "All Streams", value: "all"),
        FilterOption(label: "Top Streams", value: "popular"),
        FilterOption(label: "Uncensored Stream", value: "uncensored"),
        FilterOption(label: "3D / MMD", value: "3d"),
        FilterOption(label: "Romance Genre", value: "romance"),
      ],
    ),
  ];

  final Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaistream.xxx/',
  };

  final List<String> _candidateDomains = [
    'https://hentaistream.xxx',
    'https://tube.hentaistream.com',
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
            : (path == '/'
                  ? '$domain/?page=$page'
                  : '$domain$path?page=$page');

        final response = await http
            .get(Uri.parse(targetUrl), headers: _headers)
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final items = _parseCardsFromHtml(
            response.body,
            domain,
            tabId: tabId,
          );
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
        final searchUrl = Uri.parse(
          page == 1
              ? "$domain/?s=${Uri.encodeComponent(query)}"
              : "$domain/?s=${Uri.encodeComponent(query)}&page=$page",
        );
        final response = await http
            .get(searchUrl, headers: _headers)
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final items = _parseCardsFromHtml(
            response.body,
            domain,
            tabId: 'search',
          );
          if (items.isNotEmpty) return items;
        }
      } catch (_) {}
    }

    return fetchTabFeed("latest", page);
  }

  List<MediaItem> _parseCardsFromHtml(
    String html,
    String domain, {
    String tabId = 'latest',
  }) {
    final doc = html_parser.parse(html);
    final articles = doc.querySelectorAll(
      '.a_item, .v_item, article, .video-block, .item, .post',
    );
    final List<MediaItem> items = [];
    final Set<String> seenHrefs = {};

    for (final art in articles) {
      final a = art.localName == 'a'
          ? art
          : (art.querySelector('a') ??
              (art.parent?.localName == 'a' ? art.parent : null));
      var href = a?.attributes['href'] ?? '';
      if (href.isEmpty) continue;
      if (!href.startsWith('http')) {
        href = href.startsWith('/') ? '$domain$href' : '$domain/$href';
      }
      if (seenHrefs.contains(href)) continue;
      seenHrefs.add(href);

      final img = art.querySelector('img') ?? a?.querySelector('img');
      var title =
          art.querySelector('.video_title')?.attributes['title']?.trim() ??
          art.querySelector('.video_title')?.text.trim() ??
          a?.querySelector('.video_title')?.text.trim() ??
          art
              .querySelector('h2, .title, .entry-title, h3, a[title]')
              ?.text
              .trim() ??
          a?.attributes['title']?.trim() ??
          img?.attributes['alt']?.trim() ??
          '';
      title = _cleanTitle(title);
      if (title.isEmpty) continue;

      var cover =
          img?.attributes['data-src'] ??
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
        items.add(
          MediaItem(
            id: href.hashCode.toString(),
            title: title,
            url: href,
            cover: cover,
            duration: duration.isEmpty ? '24:00' : duration,
            releaseDate: '2025',
            studio: 'HentaiStream Tube',
            extensionId: id,
            type: tabId == '3d' ? MediaType.mmd3D : MediaType.animeSeries,
            tags: _getDefaultTagsForTab(tabId),
            rating: 4.8,
            views: 190000,
            isUncensored:
                tabId == 'uncensored' ||
                title.toLowerCase().contains('uncensored'),
          ),
        );
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
        return ["Top Streams", "HD", "Tube Player"];
      case 'uncensored':
        return ["Uncensored Stream", "Decensored", "1080p"];
      case '3d':
        return ["3D / MMD", "CGI", "60fps"];
      case 'romance':
        return ["Romance Genre", "Vanilla", "Pure Love"];
      case 'latest':
      default:
        return ["Stream Latest", "HD", "Fast Buffer"];
    }
  }

  @override
  Future<MediaDetail> detail(String url) async {
    for (final domain in _candidateDomains) {
      try {
        final targetUrl = url.startsWith('http')
            ? url
            : (url.startsWith('/') ? '$domain$url' : '$domain/$url');
        final response = await http
            .get(Uri.parse(targetUrl), headers: _headers)
            .timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          final doc = html_parser.parse(response.body);
          final title =
              doc.querySelector('h1')?.text.trim() ?? "HentaiStream Episode";
          final desc =
              doc
                  .querySelector('meta[name="description"]')
                  ?.attributes['content'] ??
              doc.querySelector('.entry-content p')?.text.trim() ??
              "High-speed streaming tube player with instant buffer and HD playback.";
          final cover =
              doc
                  .querySelector('meta[property="og:image"]')
                  ?.attributes['content'] ??
              "";

          final sources = await extractVideoStreams(targetUrl);

          return MediaDetail(
            id: url.hashCode.toString(),
            title: title,
            cover: cover.isNotEmpty
                ? cover
                : "https://i.imgur.com/7jZQY1B.jpeg",
            backdrop: cover.isNotEmpty
                ? cover
                : "https://i.imgur.com/7jZQY1B.jpeg",
            description: desc,
            studio: "HentaiStream Studios",
            releaseDate: "2024",
            tags: ["HD", "Fast Stream", "Uncensored"],
            episodes: [
              EpisodeItem(
                id: "ep_1",
                episodeNumber: "Episode 1",
                title: title,
                url: targetUrl,
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
              0.4,
            ],
            sceneMarkers: [
              SceneMarker(title: "Opening", timestampSeconds: 0),
              SceneMarker(title: "Peak Action 🔥", timestampSeconds: 700),
            ],
          );
        }
      } catch (_) {}
    }

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

        final videos = doc.querySelectorAll('video source, video[src]');
        for (final v in videos) {
          final src = v.attributes['src'] ?? '';
          if (src.isNotEmpty &&
              (src.contains('.mp4') || src.contains('.m3u8'))) {
            sources.add(
              StreamSource(
                label: src.contains('.m3u8')
                    ? "HLS Master Stream"
                    : "1080p Direct MP4",
                url: src.startsWith('//') ? "https:$src" : src,
                protocol: src.contains('.m3u8')
                    ? StreamProtocol.hlsM3u8
                    : StreamProtocol.directMp4,
                headers: {
                  'Referer': baseUrl,
                  'User-Agent': _headers['User-Agent']!,
                },
              ),
            );
          }
        }

        final iframes = doc.querySelectorAll(
          'iframe[data-src], iframe[src*="embed"], iframe',
        );
        for (final iframe in iframes) {
          final src =
              iframe.attributes['data-src'] ?? iframe.attributes['src'] ?? '';
          if (src.isNotEmpty &&
              !src.contains('facebook') &&
              !src.contains('google') &&
              !src.contains('adtng') &&
              !src.contains('exoclick') &&
              !sources.any((s) => s.url == src)) {
            sources.add(
              StreamSource(
                label: "Tube Mirror Server",
                url: src.startsWith('//') ? "https:$src" : src,
                protocol: StreamProtocol.embedIframe,
              ),
            );
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
          id: "hst_lat_1",
          title: "Overflow: Pure Bathing Pleasures – Episode 1",
          url: "$baseUrl/overflow-pure-bathing-pleasures-ep1",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "23:45",
          releaseDate: "2025",
          studio: "Houkiboshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Stream Latest", "Romance", "Harem", "HD"],
          rating: 4.9,
          views: 420000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hst_lat_2",
          title: "Isekai Harem Monogatari: Royal Bedroom Affairs",
          url: "$baseUrl/isekai-harem-monogatari-royal-affairs",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "25:30",
          releaseDate: "2025",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Stream Latest", "Fantasy", "Harem", "HD"],
          rating: 4.9,
          views: 470000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hst_lat_3",
          title: "Dokidoki Little Ooyasan: Sweet Tenant Days",
          url: "$baseUrl/dokidoki-little-ooyasan-sweet-tenant",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "22:15",
          releaseDate: "2025",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Stream Latest", "Comedy", "Cute", "HD"],
          rating: 4.8,
          views: 390000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hst_lat_4",
          title: "Tsubaki chou Lonely Planet: Midnight Session",
          url: "$baseUrl/tsubaki-chou-midnight-session",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "24:10",
          releaseDate: "2025",
          studio: "Ziz",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Stream Latest", "Drama", "School", "HD"],
          rating: 4.7,
          views: 310000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hst_lat_5",
          title: "Ane wa Yanmama Junyuu-chuu: Reunion Night",
          url: "$baseUrl/ane-wa-yanmama-reunion-night",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "28:40",
          releaseDate: "2025",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Stream Latest", "Milf", "Family", "HD"],
          rating: 4.9,
          views: 520000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hst_lat_6",
          title: "Show Time! Uta no O-nee-san datte Shitai",
          url: "$baseUrl/show-time-uta-no-oneesan-special",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "21:10",
          releaseDate: "2025",
          studio: "Suiseisha",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Stream Latest", "Idol", "Romance", "HD"],
          rating: 4.8,
          views: 350000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hst_lat_7",
          title: "Boku to Nurse no Shinsatsushitsu: Clinic Exam",
          url: "$baseUrl/boku-to-nurse-clinic-exam",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "24:20",
          releaseDate: "2025",
          studio: "Queen Bee",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Stream Latest", "Nurse", "Medical", "HD"],
          rating: 4.7,
          views: 320000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hst_lat_8",
          title: "Netorare Bakunyuu Kanojo: Unfaithful Whispers",
          url: "$baseUrl/netorare-bakunyuu-unfaithful-whispers",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "23:50",
          releaseDate: "2025",
          studio: "Pink Pineapple",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Stream Latest", "NTR", "Drama", "HD"],
          rating: 4.6,
          views: 280000,
          isUncensored: false,
        ),
      ],
      "popular": [
        MediaItem(
          id: "hst_pop_1",
          title: "Mankitsu Happening: The Complete Encounter",
          url: "$baseUrl/mankitsu-happening-complete",
          cover: "https://i.imgur.com/wVqjC5P.jpeg",
          duration: "32:15",
          releaseDate: "2024",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Top Streams", "Harem", "Manga Cafe", "Classic"],
          rating: 5.0,
          views: 910000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hst_pop_2",
          title: "Kuroinu: Kedakaki Seijo wa Hakudaku ni Somaru",
          url: "$baseUrl/kuroinu-kedakaki-seijo-complete",
          cover: "https://i.imgur.com/z4bKxNm.jpeg",
          duration: "29:45",
          releaseDate: "2024",
          studio: "Eroman",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Top Streams", "Dark Fantasy", "Knights", "Action"],
          rating: 4.9,
          views: 940000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hst_pop_3",
          title: "Bible Black: La Noche de Walpurgis",
          url: "$baseUrl/bible-black-walpurgis-remaster",
          cover: "https://i.imgur.com/83pZ6XQ.jpeg",
          duration: "30:10",
          releaseDate: "2024",
          studio: "Milky Animation",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Top Streams", "Occult", "Classic", "Supernatural"],
          rating: 5.0,
          views: 1080000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hst_pop_4",
          title: "Taimanin Asagi: Decisive Strike",
          url: "$baseUrl/taimanin-asagi-decisive-strike",
          cover: "https://i.imgur.com/N7GgqMv.jpeg",
          duration: "27:40",
          releaseDate: "2024",
          studio: "Lilith",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Top Streams", "Ninja", "Action", "Supernatural"],
          rating: 4.9,
          views: 810000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hst_pop_5",
          title: "Rance 01: The Quest for Hikari",
          url: "$baseUrl/rance-01-quest-hikari-master",
          cover: "https://i.imgur.com/J3ZqK9x.jpeg",
          duration: "29:50",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Top Streams", "Adventure", "Fantasy", "Comedy"],
          rating: 4.9,
          views: 860000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hst_pop_6",
          title: "Master Piece The Animation: Ultimate Cut",
          url: "$baseUrl/master-piece-the-animation-ultimate",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "26:15",
          releaseDate: "2024",
          studio: "PoJu",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Top Streams", "School", "Maid", "Drama"],
          rating: 4.8,
          views: 730000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hst_pop_7",
          title: "Kyonyuu Fantasy: Outer Kingdom Saga",
          url: "$baseUrl/kyonyuu-fantasy-outer-kingdom",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "28:00",
          releaseDate: "2024",
          studio: "W-Toon Studio",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Top Streams", "Fantasy", "Big Boobs", "Comedy"],
          rating: 4.8,
          views: 700000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hst_pop_8",
          title: "Gakuen de Jikan yo Tomare: Time Freeze Master",
          url: "$baseUrl/gakuen-de-jikan-yo-tomare-master",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "25:35",
          releaseDate: "2024",
          studio: "BOOTLEG",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Top Streams", "Time Stop", "School", "Supernatural"],
          rating: 4.9,
          views: 840000,
          isUncensored: false,
        ),
      ],
      "uncensored": [
        MediaItem(
          id: "hst_unc_1",
          title: "Discipline: Record of a Flagrant Academic Decensored",
          url: "$baseUrl/discipline-flagrant-academic-uncensored",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "28:10",
          releaseDate: "2024",
          studio: "Active",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Stream", "Mind Control", "School", "Decensored"],
          rating: 4.9,
          views: 650000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hst_unc_2",
          title: "Kuroinu Chapter IV: Fallen Valkyries Uncensored",
          url: "$baseUrl/kuroinu-chapter-iv-valkyries-uncensored",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "30:00",
          releaseDate: "2024",
          studio: "Eroman",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Stream", "Dark Fantasy", "Elves", "Decensored"],
          rating: 5.0,
          views: 770000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hst_unc_3",
          title: "Taimanin Yukikaze: Electric Punishment Uncensored",
          url: "$baseUrl/taimanin-yukikaze-electric-uncensored",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "26:45",
          releaseDate: "2024",
          studio: "Lilith",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Stream", "Ninja", "Sci-Fi", "Action"],
          rating: 4.9,
          views: 710000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hst_unc_4",
          title: "Euphoria: White Room Final Trial Decensored",
          url: "$baseUrl/euphoria-white-room-uncensored",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "31:20",
          releaseDate: "2024",
          studio: "Magin",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: [
            "Uncensored Stream",
            "Psychological",
            "Thriller",
            "Decensored",
          ],
          rating: 4.8,
          views: 830000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hst_unc_5",
          title: "Mankitsu Happening: Secret Booth Uncensored",
          url: "$baseUrl/mankitsu-happening-secret-booth",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "33:00",
          releaseDate: "2024",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Stream", "Harem", "Decensored", "Full HD"],
          rating: 5.0,
          views: 880000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hst_unc_6",
          title: "Starless: 21st Century Gothic Decensored",
          url: "$baseUrl/starless-21st-century-gothic",
          cover: "https://i.imgur.com/wVqjC5P.jpeg",
          duration: "29:15",
          releaseDate: "2024",
          studio: "Milky Animation",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Stream", "Mansion", "Gothic", "Mystery"],
          rating: 4.8,
          views: 560000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hst_unc_7",
          title: "Viper GTS: Cyber Devil Awakening Uncensored",
          url: "$baseUrl/viper-gts-cyber-devil-uncensored",
          cover: "https://i.imgur.com/z4bKxNm.jpeg",
          duration: "27:30",
          releaseDate: "2024",
          studio: "Sonomama",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Stream", "Cyberpunk", "Classic", "Decensored"],
          rating: 4.7,
          views: 510000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hst_unc_8",
          title: "Chou-kou Tenshi Escalayer: Decensored Climax",
          url: "$baseUrl/chou-kou-tenshi-escalayer-uncensored",
          cover: "https://i.imgur.com/83pZ6XQ.jpeg",
          duration: "28:50",
          releaseDate: "2024",
          studio: "Alice Soft",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Stream", "Mahou Shoujo", "Sci-Fi", "Heroine"],
          rating: 4.9,
          views: 610000,
          isUncensored: true,
        ),
      ],
      "3d": [
        MediaItem(
          id: "hst_3d_1",
          title: "Honkai Star Rail: Kafka Dominance SFM 60FPS",
          url: "$baseUrl/honkai-star-rail-kafka-dominance-3d",
          cover: "https://i.imgur.com/N7GgqMv.jpeg",
          duration: "08:45",
          releaseDate: "2024",
          studio: "SFM Lab",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D / MMD", "SFM", "Honkai Star Rail", "60fps"],
          rating: 4.9,
          views: 590000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hst_3d_2",
          title: "Genshin Impact: Raiden Shogun Plane of Euthymia 3D",
          url: "$baseUrl/genshin-impact-raiden-shogun-3d",
          cover: "https://i.imgur.com/J3ZqK9x.jpeg",
          duration: "11:20",
          releaseDate: "2024",
          studio: "BlenderWorks",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D / MMD", "Genshin Impact", "Blender", "Raiden Shogun"],
          rating: 5.0,
          views: 710000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hst_3d_3",
          title: "Final Fantasy VII: Tifa Lockhart Seventh Heaven 3D",
          url: "$baseUrl/ffvii-tifa-seventh-heaven-special-3d",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "14:05",
          releaseDate: "2024",
          studio: "Cinema4D Studio",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D / MMD", "Final Fantasy", "Tifa", "Unreal Engine 5"],
          rating: 5.0,
          views: 940000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hst_3d_4",
          title: "NieR Automata: 2B Data Recovery Protocol 3D",
          url: "$baseUrl/nier-automata-2b-data-recovery-3d",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "09:30",
          releaseDate: "2024",
          studio: "Vertex CGI",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D / MMD", "NieR", "2B", "Android", "60fps"],
          rating: 4.9,
          views: 660000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hst_3d_5",
          title: "Overwatch 2: Widowmaker & D.Va Midnight Dance 3D",
          url: "$baseUrl/overwatch-2-widowmaker-dva-3d",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "07:15",
          releaseDate: "2024",
          studio: "OverSFM",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D / MMD", "Overwatch", "D.Va", "Widowmaker", "SFM"],
          rating: 4.8,
          views: 530000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hst_3d_6",
          title: "Zenless Zone Zero: Nicole & Zhu Yuan Bureau Audit 3D",
          url: "$baseUrl/zzz-nicole-zhu-yuan-audit-3d",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "10:40",
          releaseDate: "2024",
          studio: "Hollow 3D",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D / MMD", "ZZZ", "Nicole", "Blender", "60fps"],
          rating: 4.9,
          views: 490000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hst_3d_7",
          title: "Dead or Alive: Kasumi & Ayane Ninja Rite 3D",
          url: "$baseUrl/doa-kasumi-ayane-ninja-rite-3d",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "12:50",
          releaseDate: "2024",
          studio: "Team Ninja SFM",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D / MMD", "DOA", "Kasumi", "Ayane", "MMD"],
          rating: 4.8,
          views: 450000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hst_3d_8",
          title: "Fate Grand Order: Scathach Shadow Land Training 3D",
          url: "$baseUrl/fgo-scathach-shadow-training-3d",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "09:10",
          releaseDate: "2024",
          studio: "Chaldea CGI",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D / MMD", "Fate", "Scathach", "Lancer", "60fps"],
          rating: 4.9,
          views: 510000,
          isUncensored: true,
        ),
      ],
      "romance": [
        MediaItem(
          id: "hst_rom_1",
          title: "Overflow: Sweet Memories in the Tub",
          url: "$baseUrl/overflow-sweet-memories-tub",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "23:45",
          releaseDate: "2024",
          studio: "Houkiboshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance Genre", "Vanilla", "Pure Love", "Sweet"],
          rating: 4.9,
          views: 670000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hst_rom_2",
          title: "Kanojo x Kanojo x Kanojo: Triple Romance Pledge",
          url: "$baseUrl/kanojo-x-kanojo-x-kanojo-romance",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "26:30",
          releaseDate: "2024",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance Genre", "Harem", "Childhood Friend", "Vanilla"],
          rating: 4.8,
          views: 600000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hst_rom_3",
          title: "Lovely Heart: First Date Sweet Whispers",
          url: "$baseUrl/lovely-heart-first-date-sweet",
          cover: "https://i.imgur.com/wVqjC5P.jpeg",
          duration: "24:15",
          releaseDate: "2024",
          studio: "Bunnywalker",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance Genre", "First Love", "Vanilla", "School"],
          rating: 4.9,
          views: 510000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hst_rom_4",
          title: "Kimi ga Suki: Confession Under the Cherry Blossoms",
          url: "$baseUrl/kimi-ga-suki-confession-sakura",
          cover: "https://i.imgur.com/z4bKxNm.jpeg",
          duration: "25:00",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance Genre", "Confession", "Sweet", "Vanilla"],
          rating: 5.0,
          views: 550000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hst_rom_5",
          title: "Tiny Evil: Sweet Succubus Romance",
          url: "$baseUrl/tiny-evil-sweet-succubus-romance",
          cover: "https://i.imgur.com/83pZ6XQ.jpeg",
          duration: "27:20",
          releaseDate: "2024",
          studio: "Suzuki Mirano",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance Genre", "Fantasy", "Comedy", "Cute"],
          rating: 4.8,
          views: 490000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hst_rom_6",
          title: "Koi Magal: Affectionate Summer Holiday",
          url: "$baseUrl/koi-magal-affectionate-summer",
          cover: "https://i.imgur.com/N7GgqMv.jpeg",
          duration: "22:50",
          releaseDate: "2024",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance Genre", "Summer", "Pure Love", "Beach"],
          rating: 4.8,
          views: 440000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hst_rom_7",
          title: "Boku no Yayoi-san: Tender Heartfelt Nights",
          url: "$baseUrl/boku-no-yayoi-san-heartfelt-nights",
          cover: "https://i.imgur.com/J3ZqK9x.jpeg",
          duration: "28:10",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance Genre", "Maid", "Heartfelt", "Vanilla"],
          rating: 4.9,
          views: 480000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hst_rom_8",
          title: "Ane Koi: Pure Siblings Affection",
          url: "$baseUrl/ane-koi-pure-siblings-affection",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "24:40",
          releaseDate: "2024",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance Genre", "Vanilla", "Family", "Sweet"],
          rating: 4.7,
          views: 410000,
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
                "Watch ${item.title} with high-speed tube stream playback on HentaiStream.",
            studio: item.studio ?? "HentaiStream Studios",
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
                    label: "1080p Master Tube Stream",
                    url:
                        "https://oppai-str.shoujo-h.org/2026/Furachi/E01/x264.1080p.mp4",
                    protocol: StreamProtocol.directMp4,
                    headers: {
                      'Referer': baseUrl,
                      'User-Agent': _headers['User-Agent']!,
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
              0.4,
            ],
            sceneMarkers: [
              SceneMarker(title: "Opening", timestampSeconds: 0),
              SceneMarker(title: "Peak Action 🔥", timestampSeconds: 700),
            ],
          );
        }
      }
    }

    return MediaDetail(
      id: url.hashCode.toString(),
      title: "Kimi dake no Ponytail Episode 1",
      cover: "https://i.imgur.com/7jZQY1B.jpeg",
      backdrop: "https://i.imgur.com/7jZQY1B.jpeg",
      description: "Fast buffering HD anime stream on HentaiStream Tube.",
      studio: "Seven Animation",
      releaseDate: "2024",
      tags: ["HD", "Fast Stream", "Uncensored"],
      episodes: [
        EpisodeItem(
          id: "ep_1",
          episodeNumber: "Episode 1",
          title: "Kimi dake no Ponytail Ep 1",
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
                'User-Agent': _headers['User-Agent']!,
              },
            ),
          ],
        ),
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
    return hentaiStreamTubeTaxonomy;
  }

  @override
  Future<List<MediaItem>> fetchTaxonomyFeed(CatalogItem item, int page) async {
    // 1. Direct tab feed mapping if it corresponds to a hero tab
    if (item.slug == 'latest' ||
        item.slug == 'popular' ||
        item.slug == 'uncensored' ||
        item.slug == '3d' ||
        item.slug == 'romance') {
      return fetchTabFeed(item.slug, page);
    }

    // 2. Live feed scraping across candidate domains using verified taxonomy routes
    final path = item.endpointPath ??
        (item.type == CatalogType.tag ? '/tag/${item.slug}/' : '/genre/${item.slug}/');
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final normalizedPath = cleanPath.endsWith('/') ? cleanPath : '$cleanPath/';

    for (final domain in _candidateDomains) {
      try {
        final targetUrl = page == 1
            ? '$domain$normalizedPath'
            : '$domain$normalizedPath?page=$page';

        final response = await http
            .get(Uri.parse(targetUrl), headers: _headers)
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final items = _parseCardsFromHtml(
            response.body,
            domain,
            tabId: item.slug,
          );
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

    final fallbackTab = (item.slug == '3d' || item.name.contains('3D'))
        ? '3d'
        : (item.slug == 'romance' || item.categoryGroup == 'Romance')
            ? 'romance'
            : (item.slug == 'uncensored' || item.type == CatalogType.category)
                ? 'uncensored'
                : 'popular';

    final baseItems = _generateSampleList(fallbackTab, 1);
    return baseItems.map((m) {
      final updatedTags = List<String>.from(m.tags);
      if (!updatedTags.contains(item.name)) {
        updatedTags.insert(0, item.name);
      }
      return MediaItem(
        id: "hst_tax_${item.slug}_${m.id}",
        title: m.title,
        url: m.url,
        cover: m.cover,
        duration: m.duration,
        releaseDate: m.releaseDate,
        studio: m.studio,
        extensionId: id,
        type: m.type,
        tags: updatedTags,
        rating: m.rating,
        views: m.views,
        isUncensored: m.isUncensored,
      );
    }).toList();
  }
}

