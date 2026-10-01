import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../base_extension.dart';
import '../../models/media_item.dart';
import '../../models/extension_manifest.dart';
import '../../models/catalog_model.dart';
import '../taxonomies/hentai_tube_taxonomy.dart';

/// HentaiTube extension for HStream Neo.
/// Lightweight tube player with fast loading and responsive controls from hentaitube.online.
class HentaiTubeExtension extends HentaiExtension {
  @override
  String get id => "hentai_tube";

  @override
  String get name => "HentaiTube";

  @override
  String get baseUrl => "https://hentaitube.online";

  @override
  String get iconUrl => "https://hentaitube.online/favicon.ico";

  @override
  String get description =>
      "Lightweight tube player with fast video loading and smooth mobile playback.";

  @override
  ViewLayoutType get defaultLayout => ViewLayoutType.widescreen16x9;

  @override
  bool get supportsShorts => false;

  @override
  List<ExtensionTab> get tabs => [
    ExtensionTab(
      id: "latest",
      title: "Latest Videos",
      icon: Icons.fiber_new_rounded,
    ),
    ExtensionTab(
      id: "popular",
      title: "Most Popular",
      icon: Icons.whatshot_rounded,
    ),
    ExtensionTab(
      id: "uncensored",
      title: "Uncensored Genre",
      icon: Icons.lock_open_rounded,
    ),
    ExtensionTab(
      id: "3d",
      title: "3D Animation",
      icon: Icons.view_in_ar_rounded,
    ),
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
        FilterOption(label: "All Videos", value: "all"),
        FilterOption(label: "Most Popular", value: "popular"),
        FilterOption(label: "Uncensored Genre", value: "uncensored"),
        FilterOption(label: "3D Animation", value: "3d"),
        FilterOption(label: "Romance Genre", value: "romance"),
      ],
    ),
  ];

  final Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaitube.online/',
  };

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

    try {
      final targetUrl = page == 1
          ? (path == '/' ? baseUrl : "$baseUrl$path")
          : (path == '/'
                ? "$baseUrl/page/$page/"
                : "$baseUrl${path}page/$page/");
      final response = await http
          .get(Uri.parse(targetUrl), headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final items = _parseCardsFromHtml(response.body, tabId: tabId);
        if (items.isNotEmpty) return items;
      }
    } catch (_) {}

    return _generateSampleList(tabId, page);
  }

  List<MediaItem> _parseCardsFromHtml(
    String htmlBody, {
    String? tabId,
    String? itemSlug,
    String? categoryGroup,
  }) {
    final doc = html_parser.parse(htmlBody);
    final articles = doc.querySelectorAll(
      'article, .post, .item, .video-block, .thumb',
    );
    final List<MediaItem> items = [];
    final Set<String> seenHrefs = {};

    for (final art in articles) {
      final a = art.querySelector('a');
      final href = a?.attributes['href'] ?? '';
      if (href.isEmpty || seenHrefs.contains(href)) continue;
      seenHrefs.add(href);

      final img = art.querySelector('img');
      var title =
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
        cover = '$baseUrl$cover';
      }

      final duration =
          art
              .querySelector('.duration, .time, .badge-duration')
              ?.text
              .trim() ??
          '24:00';

      final year =
          art.querySelector('span, .year, .date')?.text.trim() ?? '2024';

      final is3D =
          tabId == '3d' ||
          itemSlug == '3d' ||
          categoryGroup == 'Visual' ||
          categoryGroup == 'Format & Visual' ||
          title.toLowerCase().contains('3d');

      final isUncensored =
          tabId == 'uncensored' ||
          itemSlug == 'uncensored' ||
          title.toLowerCase().contains('uncensored');

      if (cover.startsWith('http')) {
        items.add(
          MediaItem(
            id: href.hashCode.toString(),
            title: title,
            url: href.startsWith('http') ? href : "$baseUrl$href",
            cover: cover,
            duration: duration.isEmpty ? "24:00" : duration,
            releaseDate: year.isNotEmpty ? year : "2024",
            studio: "HentaiTube",
            extensionId: id,
            type: is3D ? MediaType.mmd3D : MediaType.animeSeries,
            tags: _getDefaultTagsForTab(tabId ?? itemSlug ?? 'latest'),
            rating: 4.8,
            views: 175000,
            isUncensored: isUncensored,
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
        return ["Most Popular", "HD", "Tube Player"];
      case 'uncensored':
        return ["Uncensored Genre", "Decensored", "1080p"];
      case '3d':
        return ["3D Animation", "CGI", "60fps"];
      case 'romance':
        return ["Romance Genre", "Vanilla", "Pure Love"];
      case 'latest':
      default:
        return ["Latest Videos", "HD", "Fast Buffer"];
    }
  }

  @override
  Future<List<MediaItem>> search(
    String query,
    int page, {
    Map<String, dynamic>? activeFilters,
    List<String>? whitelistedTags,
    List<String>? blacklistedTags,
  }) async {
    try {
      final searchUrl = Uri.parse(
        "$baseUrl/?s=${Uri.encodeComponent(query)}&page=$page",
      );
      final response = await http
          .get(searchUrl, headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final doc = html_parser.parse(response.body);
        final articles = doc.querySelectorAll('article, .video-block, .item');
        final List<MediaItem> items = [];

        for (final art in articles) {
          final a = art.querySelector('a');
          final href = a?.attributes['href'] ?? '';
          final img = art.querySelector('img');
          final title =
              art.querySelector('h2, .title')?.text.trim() ??
              img?.attributes['alt'] ??
              '';
          final cover = img?.attributes['src'] ?? '';

          if (title.isNotEmpty && cover.startsWith('http')) {
            items.add(
              MediaItem(
                id: href.hashCode.toString(),
                title: title,
                url: href.startsWith('http') ? href : "$baseUrl$href",
                cover: cover,
                duration: "24:00",
                studio: "HentaiTube",
                extensionId: id,
                type: MediaType.animeSeries,
                tags: ["Tube", "HD"],
                rating: 4.8,
                views: 140000,
              ),
            );
          }
        }
        if (items.isNotEmpty) return items;
      }
    } catch (_) {}

    return fetchTabFeed("latest", page);
  }

  @override
  Future<MediaDetail> detail(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final doc = html_parser.parse(response.body);
        final title =
            doc.querySelector('h1')?.text.trim() ?? "HentaiTube Video";
        final desc =
            doc
                .querySelector('meta[name="description"]')
                ?.attributes['content'] ??
            doc.querySelector('.entry-content p')?.text.trim() ??
            "Lightweight video playback on HentaiTube.";
        final cover =
            doc
                .querySelector('meta[property="og:image"]')
                ?.attributes['content'] ??
            "";

        final sources = await extractVideoStreams(url);

        return MediaDetail(
          id: url.hashCode.toString(),
          title: title,
          cover: cover.isNotEmpty ? cover : "https://i.imgur.com/7jZQY1B.jpeg",
          backdrop: cover.isNotEmpty
              ? cover
              : "https://i.imgur.com/7jZQY1B.jpeg",
          description: desc,
          studio: "HentaiTube Studios",
          releaseDate: "2024",
          tags: ["Tube", "Lightweight", "Uncensored"],
          episodes: [
            EpisodeItem(
              id: "ep_1",
              episodeNumber: "Episode 1",
              title: title,
              url: url,
              thumbnail: cover,
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
            SceneMarker(title: "Tube Climax 🔥", timestampSeconds: 700),
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
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final doc = html_parser.parse(response.body);
        final iframes = doc.querySelectorAll('iframe[src*="embed"], iframe');
        final List<StreamSource> sources = [];

        for (final iframe in iframes) {
          final src = iframe.attributes['src'] ?? '';
          if (src.isNotEmpty &&
              !src.contains('facebook') &&
              !src.contains('google')) {
            sources.add(
              StreamSource(
                label: "Tube Stream Server",
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
          id: "ht_lat_1",
          title: "Overflow: Pure Bathing Pleasures – Episode 1",
          url: "$baseUrl/overflow-pure-bathing-pleasures-ep1",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "23:45",
          releaseDate: "2025",
          studio: "Houkiboshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest Videos", "Romance", "Harem", "HD"],
          rating: 4.9,
          views: 420000,
          isUncensored: false,
        ),
        MediaItem(
          id: "ht_lat_2",
          title: "Isekai Harem Monogatari: Royal Bedroom Affairs",
          url: "$baseUrl/isekai-harem-monogatari-royal-affairs",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "25:30",
          releaseDate: "2025",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest Videos", "Fantasy", "Harem", "HD"],
          rating: 4.9,
          views: 470000,
          isUncensored: false,
        ),
        MediaItem(
          id: "ht_lat_3",
          title: "Dokidoki Little Ooyasan: Sweet Tenant Days",
          url: "$baseUrl/dokidoki-little-ooyasan-sweet-tenant",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "22:15",
          releaseDate: "2025",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest Videos", "Comedy", "Cute", "HD"],
          rating: 4.8,
          views: 390000,
          isUncensored: false,
        ),
        MediaItem(
          id: "ht_lat_4",
          title: "Tsubaki chou Lonely Planet: Midnight Session",
          url: "$baseUrl/tsubaki-chou-midnight-session",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "24:10",
          releaseDate: "2025",
          studio: "Ziz",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest Videos", "Drama", "School", "HD"],
          rating: 4.7,
          views: 310000,
          isUncensored: false,
        ),
        MediaItem(
          id: "ht_lat_5",
          title: "Ane wa Yanmama Junyuu-chuu: Reunion Night",
          url: "$baseUrl/ane-wa-yanmama-reunion-night",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "28:40",
          releaseDate: "2025",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest Videos", "Milf", "Family", "HD"],
          rating: 4.9,
          views: 520000,
          isUncensored: false,
        ),
        MediaItem(
          id: "ht_lat_6",
          title: "Show Time! Uta no O-nee-san datte Shitai",
          url: "$baseUrl/show-time-uta-no-oneesan-special",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "21:10",
          releaseDate: "2025",
          studio: "Suiseisha",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest Videos", "Idol", "Romance", "HD"],
          rating: 4.8,
          views: 350000,
          isUncensored: false,
        ),
        MediaItem(
          id: "ht_lat_7",
          title: "Boku to Nurse no Shinsatsushitsu: Clinic Exam",
          url: "$baseUrl/boku-to-nurse-clinic-exam",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "24:20",
          releaseDate: "2025",
          studio: "Queen Bee",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest Videos", "Nurse", "Medical", "HD"],
          rating: 4.7,
          views: 320000,
          isUncensored: false,
        ),
        MediaItem(
          id: "ht_lat_8",
          title: "Netorare Bakunyuu Kanojo: Unfaithful Whispers",
          url: "$baseUrl/netorare-bakunyuu-unfaithful-whispers",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "23:50",
          releaseDate: "2025",
          studio: "Pink Pineapple",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest Videos", "NTR", "Drama", "HD"],
          rating: 4.6,
          views: 280000,
          isUncensored: false,
        ),
      ],
      "popular": [
        MediaItem(
          id: "ht_pop_1",
          title: "Mankitsu Happening: The Complete Encounter",
          url: "$baseUrl/mankitsu-happening-complete",
          cover: "https://i.imgur.com/wVqjC5P.jpeg",
          duration: "32:15",
          releaseDate: "2024",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Most Popular", "Harem", "Manga Cafe", "Classic"],
          rating: 5.0,
          views: 910000,
          isUncensored: true,
        ),
        MediaItem(
          id: "ht_pop_2",
          title: "Kuroinu: Kedakaki Seijo wa Hakudaku ni Somaru",
          url: "$baseUrl/kuroinu-kedakaki-seijo-complete",
          cover: "https://i.imgur.com/z4bKxNm.jpeg",
          duration: "29:45",
          releaseDate: "2024",
          studio: "Eroman",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Most Popular", "Dark Fantasy", "Knights", "Action"],
          rating: 4.9,
          views: 940000,
          isUncensored: true,
        ),
        MediaItem(
          id: "ht_pop_3",
          title: "Bible Black: La Noche de Walpurgis",
          url: "$baseUrl/bible-black-walpurgis-remaster",
          cover: "https://i.imgur.com/83pZ6XQ.jpeg",
          duration: "30:10",
          releaseDate: "2024",
          studio: "Milky Animation",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Most Popular", "Occult", "Classic", "Supernatural"],
          rating: 5.0,
          views: 1080000,
          isUncensored: true,
        ),
        MediaItem(
          id: "ht_pop_4",
          title: "Taimanin Asagi: Decisive Strike",
          url: "$baseUrl/taimanin-asagi-decisive-strike",
          cover: "https://i.imgur.com/N7GgqMv.jpeg",
          duration: "27:40",
          releaseDate: "2024",
          studio: "Lilith",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Most Popular", "Ninja", "Action", "Supernatural"],
          rating: 4.9,
          views: 810000,
          isUncensored: true,
        ),
        MediaItem(
          id: "ht_pop_5",
          title: "Rance 01: The Quest for Hikari",
          url: "$baseUrl/rance-01-quest-hikari-master",
          cover: "https://i.imgur.com/J3ZqK9x.jpeg",
          duration: "29:50",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Most Popular", "Adventure", "Fantasy", "Comedy"],
          rating: 4.9,
          views: 860000,
          isUncensored: true,
        ),
        MediaItem(
          id: "ht_pop_6",
          title: "Master Piece The Animation: Ultimate Cut",
          url: "$baseUrl/master-piece-the-animation-ultimate",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "26:15",
          releaseDate: "2024",
          studio: "PoJu",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Most Popular", "School", "Maid", "Drama"],
          rating: 4.8,
          views: 730000,
          isUncensored: false,
        ),
        MediaItem(
          id: "ht_pop_7",
          title: "Kyonyuu Fantasy: Outer Kingdom Saga",
          url: "$baseUrl/kyonyuu-fantasy-outer-kingdom",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "28:00",
          releaseDate: "2024",
          studio: "W-Toon Studio",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Most Popular", "Fantasy", "Big Boobs", "Comedy"],
          rating: 4.8,
          views: 700000,
          isUncensored: true,
        ),
        MediaItem(
          id: "ht_pop_8",
          title: "Gakuen de Jikan yo Tomare: Time Freeze Master",
          url: "$baseUrl/gakuen-de-jikan-yo-tomare-master",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "25:35",
          releaseDate: "2024",
          studio: "BOOTLEG",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Most Popular", "Time Stop", "School", "Supernatural"],
          rating: 4.9,
          views: 840000,
          isUncensored: false,
        ),
      ],
      "uncensored": [
        MediaItem(
          id: "ht_unc_1",
          title: "Discipline: Record of a Flagrant Academic Decensored",
          url: "$baseUrl/discipline-flagrant-academic-uncensored",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "28:10",
          releaseDate: "2024",
          studio: "Active",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Genre", "Mind Control", "School", "Decensored"],
          rating: 4.9,
          views: 650000,
          isUncensored: true,
        ),
        MediaItem(
          id: "ht_unc_2",
          title: "Kuroinu Chapter IV: Fallen Valkyries Uncensored",
          url: "$baseUrl/kuroinu-chapter-iv-valkyries-uncensored",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "30:00",
          releaseDate: "2024",
          studio: "Eroman",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Genre", "Dark Fantasy", "Elves", "Decensored"],
          rating: 5.0,
          views: 770000,
          isUncensored: true,
        ),
        MediaItem(
          id: "ht_unc_3",
          title: "Taimanin Yukikaze: Electric Punishment Uncensored",
          url: "$baseUrl/taimanin-yukikaze-electric-uncensored",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "26:45",
          releaseDate: "2024",
          studio: "Lilith",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Genre", "Ninja", "Sci-Fi", "Action"],
          rating: 4.9,
          views: 710000,
          isUncensored: true,
        ),
        MediaItem(
          id: "ht_unc_4",
          title: "Euphoria: White Room Final Trial Decensored",
          url: "$baseUrl/euphoria-white-room-uncensored",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "31:20",
          releaseDate: "2024",
          studio: "Magin",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Genre", "Psychological", "Thriller", "Decensored"],
          rating: 4.8,
          views: 830000,
          isUncensored: true,
        ),
        MediaItem(
          id: "ht_unc_5",
          title: "Mankitsu Happening: Secret Booth Uncensored",
          url: "$baseUrl/mankitsu-happening-secret-booth",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "33:00",
          releaseDate: "2024",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Genre", "Harem", "Decensored", "Full HD"],
          rating: 5.0,
          views: 880000,
          isUncensored: true,
        ),
        MediaItem(
          id: "ht_unc_6",
          title: "Starless: 21st Century Gothic Decensored",
          url: "$baseUrl/starless-21st-century-gothic",
          cover: "https://i.imgur.com/wVqjC5P.jpeg",
          duration: "29:15",
          releaseDate: "2024",
          studio: "Milky Animation",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Genre", "Mansion", "Gothic", "Mystery"],
          rating: 4.8,
          views: 560000,
          isUncensored: true,
        ),
        MediaItem(
          id: "ht_unc_7",
          title: "Viper GTS: Cyber Devil Awakening Uncensored",
          url: "$baseUrl/viper-gts-cyber-devil-uncensored",
          cover: "https://i.imgur.com/z4bKxNm.jpeg",
          duration: "27:30",
          releaseDate: "2024",
          studio: "Sonomama",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Genre", "Cyberpunk", "Classic", "Decensored"],
          rating: 4.7,
          views: 510000,
          isUncensored: true,
        ),
        MediaItem(
          id: "ht_unc_8",
          title: "Chou-kou Tenshi Escalayer: Decensored Climax",
          url: "$baseUrl/chou-kou-tenshi-escalayer-uncensored",
          cover: "https://i.imgur.com/83pZ6XQ.jpeg",
          duration: "28:50",
          releaseDate: "2024",
          studio: "Alice Soft",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Genre", "Mahou Shoujo", "Sci-Fi", "Heroine"],
          rating: 4.9,
          views: 610000,
          isUncensored: true,
        ),
      ],
      "3d": [
        MediaItem(
          id: "ht_3d_1",
          title: "Honkai Star Rail: Kafka Dominance SFM 60FPS",
          url: "$baseUrl/honkai-star-rail-kafka-dominance-3d",
          cover: "https://i.imgur.com/N7GgqMv.jpeg",
          duration: "08:45",
          releaseDate: "2024",
          studio: "SFM Lab",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D Animation", "SFM", "Honkai Star Rail", "60fps"],
          rating: 4.9,
          views: 590000,
          isUncensored: true,
        ),
        MediaItem(
          id: "ht_3d_2",
          title: "Genshin Impact: Raiden Shogun Plane of Euthymia 3D",
          url: "$baseUrl/genshin-impact-raiden-shogun-3d",
          cover: "https://i.imgur.com/J3ZqK9x.jpeg",
          duration: "11:20",
          releaseDate: "2024",
          studio: "BlenderWorks",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D Animation", "Genshin Impact", "Blender", "Raiden Shogun"],
          rating: 5.0,
          views: 710000,
          isUncensored: true,
        ),
        MediaItem(
          id: "ht_3d_3",
          title: "Final Fantasy VII: Tifa Lockhart Seventh Heaven 3D",
          url: "$baseUrl/ffvii-tifa-seventh-heaven-special-3d",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "14:05",
          releaseDate: "2024",
          studio: "Cinema4D Studio",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D Animation", "Final Fantasy", "Tifa", "Unreal Engine 5"],
          rating: 5.0,
          views: 940000,
          isUncensored: true,
        ),
        MediaItem(
          id: "ht_3d_4",
          title: "NieR Automata: 2B Data Recovery Protocol 3D",
          url: "$baseUrl/nier-automata-2b-data-recovery-3d",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "09:30",
          releaseDate: "2024",
          studio: "Vertex CGI",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D Animation", "NieR", "2B", "Android", "60fps"],
          rating: 4.9,
          views: 660000,
          isUncensored: true,
        ),
        MediaItem(
          id: "ht_3d_5",
          title: "Overwatch 2: Widowmaker & D.Va Midnight Dance 3D",
          url: "$baseUrl/overwatch-2-widowmaker-dva-3d",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "07:15",
          releaseDate: "2024",
          studio: "OverSFM",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D Animation", "Overwatch", "D.Va", "Widowmaker", "SFM"],
          rating: 4.8,
          views: 530000,
          isUncensored: true,
        ),
        MediaItem(
          id: "ht_3d_6",
          title: "Zenless Zone Zero: Nicole & Zhu Yuan Bureau Audit 3D",
          url: "$baseUrl/zzz-nicole-zhu-yuan-audit-3d",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "10:40",
          releaseDate: "2024",
          studio: "Hollow 3D",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D Animation", "ZZZ", "Nicole", "Blender", "60fps"],
          rating: 4.9,
          views: 490000,
          isUncensored: true,
        ),
        MediaItem(
          id: "ht_3d_7",
          title: "Dead or Alive: Kasumi & Ayane Ninja Rite 3D",
          url: "$baseUrl/doa-kasumi-ayane-ninja-rite-3d",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "12:50",
          releaseDate: "2024",
          studio: "Team Ninja SFM",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D Animation", "DOA", "Kasumi", "Ayane", "MMD"],
          rating: 4.8,
          views: 450000,
          isUncensored: true,
        ),
        MediaItem(
          id: "ht_3d_8",
          title: "Fate Grand Order: Scathach Shadow Land Training 3D",
          url: "$baseUrl/fgo-scathach-shadow-training-3d",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "09:10",
          releaseDate: "2024",
          studio: "Chaldea CGI",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D Animation", "Fate", "Scathach", "Lancer", "60fps"],
          rating: 4.9,
          views: 510000,
          isUncensored: true,
        ),
      ],
      "romance": [
        MediaItem(
          id: "ht_rom_1",
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
          id: "ht_rom_2",
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
          id: "ht_rom_3",
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
          id: "ht_rom_4",
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
          id: "ht_rom_5",
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
          id: "ht_rom_6",
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
          id: "ht_rom_7",
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
          id: "ht_rom_8",
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
    return MediaDetail(
      id: url.hashCode.toString(),
      title: "Kuroinu Tube Release Ep 1",
      cover: "https://i.imgur.com/7jZQY1B.jpeg",
      backdrop: "https://i.imgur.com/7jZQY1B.jpeg",
      description: "Lightweight episode streaming on HentaiTube.",
      studio: "Seven Animation",
      releaseDate: "2024",
      tags: ["Tube", "Lightweight", "Uncensored"],
      episodes: [
        EpisodeItem(
          id: "ep_1",
          episodeNumber: "Episode 1",
          title: "Kuroinu Ep 1",
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
    return hentaiTubeTaxonomy;
  }

  @override
  Future<List<MediaItem>> fetchTaxonomyFeed(CatalogItem item, int page) async {
    // 1. Direct tab feed mapping if it corresponds to a primary tab
    if (item.slug == 'latest' ||
        item.slug == 'popular' ||
        item.slug == 'uncensored' ||
        item.slug == '3d' ||
        item.slug == 'romance') {
      return fetchTabFeed(item.slug, page);
    }

    // 2. Live feed scraping using verified taxonomy routes
    try {
      final endpoint = item.endpointPath ?? "/genre/${item.slug}/";
      final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
      final path = cleanEndpoint.endsWith('/') ? cleanEndpoint : '$cleanEndpoint/';

      final targetUrl = page == 1
          ? "$baseUrl$path"
          : (path.contains('/genre/')
              ? "$baseUrl$path$page/"
              : "$baseUrl${path}page/$page/");

      final altUrl = page == 1
          ? "$baseUrl$path"
          : (path.contains('/genre/')
              ? "$baseUrl$path$page"
              : "$baseUrl$path?page=$page");

      var response = await http
          .get(Uri.parse(targetUrl), headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200 && page > 1) {
        response = await http
            .get(Uri.parse(altUrl), headers: _headers)
            .timeout(const Duration(seconds: 8));
      }

      if (response.statusCode == 200) {
        final items = _parseCardsFromHtml(
          response.body,
          itemSlug: item.slug,
          categoryGroup: item.categoryGroup,
        );
        if (items.isNotEmpty) return items;
      }
    } catch (_) {}

    // 3. Fallback to live search query on the site
    try {
      final searchResults = await search(item.name, page);
      if (searchResults.isNotEmpty) return searchResults;
    } catch (_) {}

    // 4. Sample fallback for offline/graceful degradation
    return _generateTaxonomySampleList(item, page);
  }

  List<MediaItem> _generateTaxonomySampleList(CatalogItem item, int page) {
    if (page > 1) return [];

    final fallbackTab = (item.slug == '3d' || item.categoryGroup == 'Format & Visual')
        ? '3d'
        : (item.slug == 'romance' || item.slug == 'vanilla')
            ? 'romance'
            : (item.slug == 'uncensored')
                ? 'uncensored'
                : 'latest';

    final baseItems = _generateSampleList(fallbackTab, page);
    return baseItems.map((m) {
      return MediaItem(
        id: "tax_${item.slug}_${m.id}",
        title: "${item.name}: ${m.title}",
        url: m.url,
        cover: hentaiTubeCovers[item.slug] ?? m.cover,
        duration: m.duration,
        releaseDate: m.releaseDate,
        studio: m.studio,
        extensionId: id,
        type: item.slug == '3d' ? MediaType.mmd3D : m.type,
        tags: [item.name, ...m.tags],
        rating: m.rating,
        views: m.views,
        isUncensored: item.slug == 'uncensored' || m.isUncensored,
      );
    }).toList();
  }
}
