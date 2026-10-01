import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../base_extension.dart';
import '../../models/media_item.dart';
import '../../models/extension_manifest.dart';
import '../../models/catalog_model.dart';
import '../taxonomies/hentai_paradise_taxonomy.dart';

/// HentaiParadise extension for HStream Neo.
/// Scrapes moe aesthetic series and uncensored catalog from hentaiparadise.tv and candidate domains.
class HentaiParadiseExtension extends HentaiExtension {
  @override
  String get id => "hentai_paradise";

  @override
  String get name => "HentaiParadise";

  @override
  String get baseUrl => "https://hentaiparadise.tv";

  @override
  String get iconUrl => "https://hentaiparadise.tv/favicon.ico";

  @override
  String get description =>
      "Moe aesthetic anime series, pastel uncensored releases, and full episode streaming.";

  @override
  ViewLayoutType get defaultLayout => ViewLayoutType.widescreen16x9;

  @override
  bool get supportsShorts => false;

  @override
  List<ExtensionTab> get tabs => [
        ExtensionTab(
          id: "latest",
          title: "Paradise Latest",
          icon: Icons.fiber_new_rounded,
        ),
        ExtensionTab(
          id: "popular",
          title: "Island Popular",
          icon: Icons.whatshot_rounded,
        ),
        ExtensionTab(
          id: "uncensored",
          title: "Uncensored Paradise",
          icon: Icons.lock_open_rounded,
        ),
        ExtensionTab(
          id: "summer",
          title: "Beach / Summer",
          icon: Icons.beach_access_rounded,
        ),
        ExtensionTab(
          id: "fantasy",
          title: "Fantasy Island",
          icon: Icons.auto_awesome_rounded,
        ),
      ];

  @override
  List<FilterGroup> get filters => [];

  final List<String> _candidateDomains = [
    'https://hentaiparadise.tv',
    'https://hentaiparadise.com',
  ];

  final Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaiparadise.tv/',
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
      case 'summer':
        path = '/genre/beach/';
        break;
      case 'fantasy':
        path = '/genre/fantasy/';
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
            .get(Uri.parse(targetUrl), headers: {
              ..._headers,
              'Referer': '$domain/',
            })
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
            .get(searchUrl, headers: {
              ..._headers,
              'Referer': '$domain/',
            })
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final items = _parseCardsFromHtml(response.body, domain, tabId: 'latest');
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
        'article, .post, .item, .paradise-item, .uagb-post__inner-wrap');
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
      var title = art.querySelector('h2, .title, .entry-title, h3, h4, a[title]')?.text.trim() ??
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

      if (title.isNotEmpty && cover.startsWith('http')) {
        items.add(MediaItem(
          id: href.hashCode.toString(),
          title: title,
          url: href,
          cover: cover,
          duration: duration.isEmpty ? '24:00' : duration,
          releaseDate: '2024',
          studio: 'HentaiParadise',
          extensionId: id,
          type: MediaType.animeSeries,
          tags: _getDefaultTagsForTab(tabId),
          rating: 4.8,
          views: 180000,
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
        return ["Island Popular", "HD", "Paradise Pick"];
      case 'uncensored':
        return ["Uncensored Paradise", "Decensored", "Full HD"];
      case 'summer':
        return ["Beach / Summer", "Swimsuit", "HD"];
      case 'fantasy':
        return ["Fantasy Island", "Magic", "HD"];
      case 'latest':
      default:
        return ["Paradise Latest", "Moe", "HD", "Subbed"];
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
        final title = doc.querySelector('h1')?.text.trim() ?? "HentaiParadise Episode";
        final desc = doc.querySelector('meta[name="description"]')?.attributes['content'] ??
            doc.querySelector('.entry-content p')?.text.trim() ??
            "Moe anime streaming on HentaiParadise.";
        final cover = doc.querySelector('meta[property="og:image"]')?.attributes['content'] ?? "";

        final sources = await extractVideoStreams(url);

        return MediaDetail(
          id: url.hashCode.toString(),
          title: title,
          cover: cover.isNotEmpty ? cover : "https://i.imgur.com/7jZQY1B.jpeg",
          backdrop: cover.isNotEmpty ? cover : "https://i.imgur.com/7jZQY1B.jpeg",
          description: desc,
          studio: "HentaiParadise Studios",
          releaseDate: "2024",
          tags: ["Moe", "HD", "Uncensored"],
          episodes: [
            EpisodeItem(
              id: "ep_1",
              episodeNumber: "Episode 1",
              title: title,
              url: url,
              thumbnail: cover.isNotEmpty ? cover : "https://i.imgur.com/7jZQY1B.jpeg",
              duration: "24:00",
              sources: sources,
            ),
          ],
          playbackHeatmap: [0.1, 0.35, 0.65, 0.95, 0.8, 0.4, 0.3, 0.9, 1.0, 0.4],
          sceneMarkers: [
            SceneMarker(title: "Opening", timestampSeconds: 0),
            SceneMarker(title: "Paradise Climax 🔥", timestampSeconds: 700),
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
        final iframes =
            doc.querySelectorAll('iframe[data-src], iframe[src*="embed"], iframe');
        final List<StreamSource> sources = [];

        for (final iframe in iframes) {
          final src =
              iframe.attributes['data-src'] ?? iframe.attributes['src'] ?? '';
          if (src.isNotEmpty &&
              !src.contains('facebook') &&
              !src.contains('google') &&
              !sources.any((s) => s.url == src)) {
            sources.add(StreamSource(
              label: "Paradise Stream Server",
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
          id: "hp_lat_1",
          title: "Taimanin Yukikaze: Moe Paradise Ep 1",
          url: "$baseUrl/taimanin-yukikaze-moe-paradise",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "24:15",
          releaseDate: "2024",
          studio: "Lilith Animation",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Paradise Latest", "Moe", "HD", "Subbed"],
          rating: 4.9,
          views: 245000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_lat_2",
          title: "Dokidoki Little Ooyasan: Sweet Room Care",
          url: "$baseUrl/dokidoki-little-ooyasan-sweet-room",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "22:40",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Paradise Latest", "Moe", "Comedy", "HD"],
          rating: 4.8,
          views: 210000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_lat_3",
          title: "Show Time! Uta no O-nee-san Moe Special",
          url: "$baseUrl/show-time-uta-no-oneesan-moe",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "21:30",
          releaseDate: "2024",
          studio: "Suiseisha",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Paradise Latest", "Idol", "Romance", "HD"],
          rating: 4.7,
          views: 185000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_lat_4",
          title: "Overflow: Pure Paradise Waters Ep 1",
          url: "$baseUrl/overflow-pure-paradise-waters",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "23:50",
          releaseDate: "2024",
          studio: "Houkiboshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Paradise Latest", "Romance", "Harem", "HD"],
          rating: 4.9,
          views: 320000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_lat_5",
          title: "Kanojo x Kanojo x Kanojo: Moe Trio",
          url: "$baseUrl/kanojo-x-kanojo-x-kanojo-moe-trio",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "24:35",
          releaseDate: "2024",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Paradise Latest", "School", "Romance", "HD"],
          rating: 4.8,
          views: 275000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_lat_6",
          title: "Ane wa Yanmama Junyuu-chuu: Cozy Days",
          url: "$baseUrl/ane-wa-yanmama-cozy-days",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "27:10",
          releaseDate: "2024",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Paradise Latest", "Milf", "Slice of Life", "HD"],
          rating: 4.9,
          views: 290000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_lat_7",
          title: "Boku to Nurse no Shinsatsushitsu: Gentle Care",
          url: "$baseUrl/boku-to-nurse-gentle-care",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "Queen Bee",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Paradise Latest", "Nurse", "Romance", "HD"],
          rating: 4.7,
          views: 195000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_lat_8",
          title: "Tsubaki chou Lonely Planet: Paradise Starlight",
          url: "$baseUrl/tsubaki-chou-paradise-starlight",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "25:20",
          releaseDate: "2024",
          studio: "Ziz",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Paradise Latest", "Drama", "School", "HD"],
          rating: 4.8,
          views: 230000,
          isUncensored: false,
        ),
      ],
      "popular": [
        MediaItem(
          id: "hp_pop_1",
          title: "Mankitsu Happening: Island Grand Encounter",
          url: "$baseUrl/mankitsu-happening-island-encounter",
          cover: "https://i.imgur.com/wVqjC5P.jpeg",
          duration: "32:10",
          releaseDate: "2024",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Island Popular", "Harem", "Classic", "HD"],
          rating: 5.0,
          views: 880000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_pop_2",
          title: "Kuroinu: Kedakaki Seijo Island Chronicles",
          url: "$baseUrl/kuroinu-island-chronicles",
          cover: "https://i.imgur.com/z4bKxNm.jpeg",
          duration: "29:45",
          releaseDate: "2024",
          studio: "Eroman",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Island Popular", "Dark Fantasy", "Action", "HD"],
          rating: 4.9,
          views: 910000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_pop_3",
          title: "Bible Black: Walpurgis Island Awakening",
          url: "$baseUrl/bible-black-island-awakening",
          cover: "https://i.imgur.com/83pZ6XQ.jpeg",
          duration: "30:00",
          releaseDate: "2024",
          studio: "Milky Animation",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Island Popular", "Occult", "Classic", "Supernatural"],
          rating: 5.0,
          views: 1040000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_pop_4",
          title: "Taimanin Asagi: Decisive Paradise Raid",
          url: "$baseUrl/taimanin-asagi-paradise-raid",
          cover: "https://i.imgur.com/N7GgqMv.jpeg",
          duration: "27:40",
          releaseDate: "2024",
          studio: "Lilith",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Island Popular", "Ninja", "Action", "HD"],
          rating: 4.9,
          views: 760000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_pop_5",
          title: "Rance 01: The Quest for Hikari on the Island",
          url: "$baseUrl/rance-01-quest-hikari-island",
          cover: "https://i.imgur.com/J3ZqK9x.jpeg",
          duration: "29:50",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Island Popular", "Adventure", "Fantasy", "Comedy"],
          rating: 4.9,
          views: 820000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_pop_6",
          title: "Master Piece The Animation: Island Edition",
          url: "$baseUrl/master-piece-the-animation-island",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "26:15",
          releaseDate: "2024",
          studio: "PoJu",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Island Popular", "School", "Maid", "HD"],
          rating: 4.8,
          views: 690000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_pop_7",
          title: "Gakuen de Jikan yo Tomare: Time Freeze Paradise",
          url: "$baseUrl/gakuen-de-jikan-yo-tomare-paradise",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "25:35",
          releaseDate: "2024",
          studio: "BOOTLEG",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Island Popular", "Time Stop", "Supernatural", "HD"],
          rating: 4.9,
          views: 790000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_pop_8",
          title: "Euphoria: Island Mystery Chamber",
          url: "$baseUrl/euphoria-island-mystery-chamber",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "31:15",
          releaseDate: "2024",
          studio: "Magin",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Island Popular", "Psychological", "Thriller", "HD"],
          rating: 4.9,
          views: 840000,
          isUncensored: true,
        ),
      ],
      "uncensored": [
        MediaItem(
          id: "hp_unc_1",
          title: "Discipline: Record of Flagrant Uncensored",
          url: "$baseUrl/discipline-flagrant-uncensored",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "28:10",
          releaseDate: "2024",
          studio: "Active",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Paradise", "Mind Control", "School", "Decensored"],
          rating: 4.9,
          views: 650000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_unc_2",
          title: "Kuroinu Chapter IV: Fallen Valkyries Decensored",
          url: "$baseUrl/kuroinu-fallen-valkyries-decensored",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "30:00",
          releaseDate: "2024",
          studio: "Eroman",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Paradise", "Dark Fantasy", "Elves", "Decensored"],
          rating: 5.0,
          views: 780000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_unc_3",
          title: "Taimanin Yukikaze: Electric Nightmare Uncensored",
          url: "$baseUrl/taimanin-yukikaze-electric-nightmare-uncensored",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "26:45",
          releaseDate: "2024",
          studio: "Lilith",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Paradise", "Ninja", "Sci-Fi", "Uncensored"],
          rating: 4.9,
          views: 710000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_unc_4",
          title: "Euphoria: White Room Pure Uncensored",
          url: "$baseUrl/euphoria-white-room-pure-uncensored",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "31:20",
          releaseDate: "2024",
          studio: "Magin",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Paradise", "Psychological", "Thriller", "Decensored"],
          rating: 4.8,
          views: 820000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_unc_5",
          title: "Mankitsu Happening: Private Room Decensored",
          url: "$baseUrl/mankitsu-happening-private-decensored",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "33:00",
          releaseDate: "2024",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Paradise", "Harem", "Decensored", "Full HD"],
          rating: 5.0,
          views: 870000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_unc_6",
          title: "Starless: Gothic Manor 21st Uncensored",
          url: "$baseUrl/starless-gothic-manor-uncensored",
          cover: "https://i.imgur.com/wVqjC5P.jpeg",
          duration: "29:15",
          releaseDate: "2024",
          studio: "Milky Animation",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Paradise", "Mansion", "Gothic", "Uncensored"],
          rating: 4.8,
          views: 560000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_unc_7",
          title: "Viper GTS: Cyber Devil Uncensored Director's Cut",
          url: "$baseUrl/viper-gts-cyber-devil-directors-cut",
          cover: "https://i.imgur.com/z4bKxNm.jpeg",
          duration: "27:30",
          releaseDate: "2024",
          studio: "Sonomama",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Paradise", "Cyberpunk", "Classic", "Decensored"],
          rating: 4.7,
          views: 510000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_unc_8",
          title: "Chou-kou Tenshi Escalayer: Decensored Climax Cut",
          url: "$baseUrl/chou-kou-tenshi-escalayer-climax-cut",
          cover: "https://i.imgur.com/83pZ6XQ.jpeg",
          duration: "28:50",
          releaseDate: "2024",
          studio: "Alice Soft",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Paradise", "Mahou Shoujo", "Sci-Fi", "Heroine"],
          rating: 4.9,
          views: 600000,
          isUncensored: true,
        ),
      ],
      "summer": [
        MediaItem(
          id: "hp_sum_1",
          title: "Resort Boin: Sunny Beach Vacation",
          url: "$baseUrl/resort-boin-sunny-beach-vacation",
          cover: "https://i.imgur.com/J3ZqK9x.jpeg",
          duration: "25:30",
          releaseDate: "2024",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Beach / Summer", "Resort", "Swimsuit", "Tropical"],
          rating: 4.9,
          views: 580000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_sum_2",
          title: "Tropical Kiss: Summer Island Romance",
          url: "$baseUrl/tropical-kiss-summer-island-romance",
          cover: "https://i.imgur.com/N7GgqMv.jpeg",
          duration: "23:45",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Beach / Summer", "Island", "Romance", "Beachside"],
          rating: 4.8,
          views: 420000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_sum_3",
          title: "Umi de Asobou: Coastal Resort Memories",
          url: "$baseUrl/umi-de-asobou-coastal-resort",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "26:10",
          releaseDate: "2024",
          studio: "Pink Pineapple",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Beach / Summer", "Beach", "Ecchi", "Summer Break"],
          rating: 4.7,
          views: 390000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_sum_4",
          title: "Bikini Warriors: Island Oasis Quest",
          url: "$baseUrl/bikini-warriors-island-oasis",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "22:15",
          releaseDate: "2024",
          studio: "Feel",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Beach / Summer", "Swimsuit", "Fantasy", "Comedy"],
          rating: 4.8,
          views: 460000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_sum_5",
          title: "Kanojo ga Yatsu ni Dakareta Natsu: Island Heat",
          url: "$baseUrl/kanojo-natsu-island-heat",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "27:50",
          releaseDate: "2024",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Beach / Summer", "Summer", "Drama", "Tropical"],
          rating: 4.7,
          views: 350000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_sum_6",
          title: "Natsu no Arashi: Coastal Breeze Passion",
          url: "$baseUrl/natsu-no-arashi-coastal-breeze",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "24:20",
          releaseDate: "2024",
          studio: "Discovery",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Beach / Summer", "Beach", "Romance", "Sunset"],
          rating: 4.8,
          views: 380000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_sum_7",
          title: "Southern Cross: Island Private Villa",
          url: "$baseUrl/southern-cross-island-private-villa",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "28:35",
          releaseDate: "2024",
          studio: "Milky Animation",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Beach / Summer", "Resort", "Harem", "Summer"],
          rating: 4.9,
          views: 510000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_sum_8",
          title: "Sunbather: Sparkling Shoreline Affair",
          url: "$baseUrl/sunbather-sparkling-shoreline-affair",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "21:40",
          releaseDate: "2024",
          studio: "Natural High",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Beach / Summer", "Swimsuit", "Beach", "HD"],
          rating: 4.8,
          views: 410000,
          isUncensored: false,
        ),
      ],
      "fantasy": [
        MediaItem(
          id: "hp_fan_1",
          title: "Kyonyuu Fantasy: Outer Kingdom Island Chronicles",
          url: "$baseUrl/kyonyuu-fantasy-island-chronicles",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "28:00",
          releaseDate: "2024",
          studio: "W-Toon Studio",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Fantasy Island", "Fantasy", "Magic", "Adventure"],
          rating: 4.9,
          views: 720000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_fan_2",
          title: "Isekai Harem Monogatari: Enchanted Island Guild",
          url: "$baseUrl/isekai-harem-monogatari-enchanted-island",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "25:30",
          releaseDate: "2024",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Fantasy Island", "Isekai", "Harem", "Guild"],
          rating: 4.9,
          views: 680000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_fan_3",
          title: "Kuroinu: Kedakaki Seijo Island Fortress",
          url: "$baseUrl/kuroinu-island-fortress",
          cover: "https://i.imgur.com/wVqjC5P.jpeg",
          duration: "30:10",
          releaseDate: "2024",
          studio: "Eroman",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Fantasy Island", "Dark Fantasy", "Knights", "Action"],
          rating: 5.0,
          views: 890000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_fan_4",
          title: "Rance 01: Citadel of the Elf King",
          url: "$baseUrl/rance-01-citadel-elf-king",
          cover: "https://i.imgur.com/z4bKxNm.jpeg",
          duration: "29:40",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Fantasy Island", "Adventure", "Elves", "Magic"],
          rating: 4.9,
          views: 740000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_fan_5",
          title: "Succubus Stayed Life: Demon Sanctuary",
          url: "$baseUrl/succubus-stayed-life-demon-sanctuary",
          cover: "https://i.imgur.com/83pZ6XQ.jpeg",
          duration: "24:50",
          releaseDate: "2024",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Fantasy Island", "Succubus", "Magic", "Supernatural"],
          rating: 4.8,
          views: 590000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_fan_6",
          title: "Demonion: Island Maiden of the Dark Sun",
          url: "$baseUrl/demonion-island-maiden-dark-sun",
          cover: "https://i.imgur.com/N7GgqMv.jpeg",
          duration: "27:15",
          releaseDate: "2024",
          studio: "Astronauts",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Fantasy Island", "Dark Fantasy", "Sorcery", "Uncensored"],
          rating: 4.8,
          views: 630000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_fan_7",
          title: "Dragon Knight 4: Dragon Sanctuary Chronicles",
          url: "$baseUrl/dragon-knight-4-dragon-sanctuary",
          cover: "https://i.imgur.com/J3ZqK9x.jpeg",
          duration: "26:40",
          releaseDate: "2024",
          studio: "Elf",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Fantasy Island", "Dragons", "Knights", "Classic"],
          rating: 4.7,
          views: 510000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_fan_8",
          title: "Princess Lover! OVA: Island Manor Ball",
          url: "$baseUrl/princess-lover-island-manor",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "28:15",
          releaseDate: "2024",
          studio: "Public Enemies",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Fantasy Island", "Royalty", "Romance", "Aristocrat"],
          rating: 4.9,
          views: 760000,
          isUncensored: true,
        ),
      ],
    };

    return sampleSets[tabId] ?? sampleSets["latest"] ?? [];
  }

  MediaDetail _generateSampleDetail(String url) {
    MediaItem? matched;
    for (final tabList in [
      ..._generateSampleList("latest", 1),
      ..._generateSampleList("popular", 1),
      ..._generateSampleList("uncensored", 1),
      ..._generateSampleList("summer", 1),
      ..._generateSampleList("fantasy", 1),
    ]) {
      if (tabList.url == url || tabList.id == url) {
        matched = tabList;
        break;
      }
    }

    final title = matched?.title ?? "HentaiParadise Feature Presentation";
    final cover = matched?.cover ?? "https://i.imgur.com/7jZQY1B.jpeg";
    final studio = matched?.studio ?? "HentaiParadise Studios";
    final tags = matched?.tags ?? ["Moe", "HD", "Uncensored"];

    return MediaDetail(
      id: url.hashCode.toString(),
      title: title,
      cover: cover,
      backdrop: cover,
      description:
          "$title - Moe aesthetic and uncensored streaming presentation on HentaiParadise.",
      studio: studio,
      releaseDate: "2024",
      tags: tags,
      episodes: [
        EpisodeItem(
          id: "ep_1",
          episodeNumber: "Episode 1",
          title: "$title - Episode 1",
          url: url,
          thumbnail: cover,
          duration: matched?.duration ?? "24:00",
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
        SceneMarker(title: "Paradise Climax 🔥", timestampSeconds: 700),
      ],
    );
  }

  @override
  Future<ExtensionTaxonomy> fetchTaxonomy() async {
    return hentaiParadiseTaxonomy;
  }

  @override
  Future<List<MediaItem>> fetchTaxonomyFeed(CatalogItem item, int page) async {
    if (item.slug == 'latest' || item.slug == 'popular') {
      return fetchTabFeed(item.slug, page);
    }

    for (final domain in _candidateDomains) {
      try {
        final String targetUrl;
        if (item.endpointPath != null && item.endpointPath!.isNotEmpty) {
          final path = item.endpointPath!;
          if (path.contains('?s=')) {
            final queryParam = path.replaceFirst('/?', '');
            targetUrl = page == 1
                ? '$domain$path'
                : '$domain/page/$page/?$queryParam';
          } else {
            final cleanPath = path.endsWith('/') ? path : '$path/';
            targetUrl = page == 1
                ? '$domain$cleanPath'
                : '$domain${cleanPath}page/$page/';
          }
        } else if (item.type == CatalogType.category) {
          targetUrl = page == 1
              ? '$domain/${item.slug}/'
              : '$domain/${item.slug}/page/$page/';
        } else {
          final query = Uri.encodeComponent(
              item.slug.isNotEmpty ? item.slug : item.name);
          targetUrl = page == 1
              ? '$domain/?s=$query'
              : '$domain/page/$page/?s=$query';
        }

        final response = await http
            .get(Uri.parse(targetUrl), headers: {
              ..._headers,
              'Referer': '$domain/',
            })
            .timeout(const Duration(seconds: 5));

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

    return fetchTabFeed('latest', page);
  }
}

