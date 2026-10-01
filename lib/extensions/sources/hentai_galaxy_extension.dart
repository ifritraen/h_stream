import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../base_extension.dart';
import '../../models/media_item.dart';
import '../../models/extension_manifest.dart';
import '../../models/catalog_model.dart';
import '../taxonomies/hentai_galaxy_taxonomy.dart';

/// HentaiGalaxy extension for HStream Neo.
/// Scrapes cosmic recommendation clusters, sci-fi/fantasy categories, and trending anime from hentaigalaxy.
class HentaiGalaxyExtension extends HentaiExtension {
  @override
  String get id => "hentai_galaxy";

  @override
  String get name => "HentaiGalaxy";

  @override
  String get baseUrl => "https://hentaigalaxy.me";

  @override
  String get iconUrl => "https://hentaigalaxy.me/favicon.ico";

  @override
  String get description =>
      "Cosmic recommendation engine, trending franchise clusters, and HD stream mirrors.";

  @override
  ViewLayoutType get defaultLayout => ViewLayoutType.widescreen16x9;

  @override
  bool get supportsShorts => false;

  @override
  List<ExtensionTab> get tabs => [
        ExtensionTab(
          id: "latest",
          title: "Cosmic Latest",
          icon: Icons.fiber_new_rounded,
        ),
        ExtensionTab(
          id: "popular",
          title: "Cosmic Popular",
          icon: Icons.whatshot_rounded,
        ),
        ExtensionTab(
          id: "uncensored",
          title: "Uncensored Galaxy",
          icon: Icons.lock_open_rounded,
        ),
        ExtensionTab(
          id: "scifi",
          title: "Sci-Fi / Cyberpunk",
          icon: Icons.rocket_launch_rounded,
        ),
        ExtensionTab(
          id: "fantasy",
          title: "Fantasy World",
          icon: Icons.auto_awesome_rounded,
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
            FilterOption(label: "All Categories", value: "all"),
            FilterOption(label: "Cosmic Popular", value: "popular"),
            FilterOption(label: "Uncensored Galaxy", value: "uncensored"),
            FilterOption(label: "Sci-Fi / Cyberpunk", value: "scifi"),
            FilterOption(label: "Fantasy World", value: "fantasy"),
          ],
        ),
      ];

  final Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaigalaxy.me/',
  };

  final List<String> _candidateDomains = [
    'https://hentaigalaxy.me',
    'https://hentaigalaxy.com',
    'https://galaxyhentai.com',
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
      case 'scifi':
        path = '/genre/sci-fi/';
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
        final searchUrl = Uri.parse(
            "$domain/?s=${Uri.encodeComponent(query)}&page=$page");
        final response = await http
            .get(searchUrl, headers: _headers)
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final items =
              _parseCardsFromHtml(response.body, domain, tabId: 'search');
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
    final articles =
        doc.querySelectorAll('article, .post, .item, .galaxy-item');
    final List<MediaItem> items = [];
    final Set<String> seenUrls = {};

    for (final art in articles) {
      final a = art.querySelector('a');
      var href = a?.attributes['href'] ?? '';
      if (href.isEmpty) continue;
      if (!href.startsWith('http')) {
        href = href.startsWith('/') ? '$domain$href' : '$domain/$href';
      }
      if (seenUrls.contains(href)) continue;
      seenUrls.add(href);

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

      if (cover.isEmpty || (!cover.startsWith('http') && !cover.startsWith('https'))) {
        continue;
      }

      final duration =
          art.querySelector('.duration, .time, .badge-duration')?.text.trim() ??
              '24:00';

      items.add(MediaItem(
        id: href.hashCode.toString(),
        title: title,
        url: href,
        cover: cover,
        duration: duration.isEmpty ? '24:00' : duration,
        releaseDate: '2024',
        studio: 'HentaiGalaxy',
        extensionId: id,
        type: MediaType.animeSeries,
        tags: _getDefaultTagsForTab(tabId),
        rating: 4.8,
        views: 190000,
        isUncensored:
            tabId == 'uncensored' || title.toLowerCase().contains('uncensored'),
      ));
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
        return ["Cosmic Popular", "HD", "Galaxy Top"];
      case 'uncensored':
        return ["Uncensored Galaxy", "Decensored", "Full HD"];
      case 'scifi':
        return ["Sci-Fi", "Cyberpunk", "Space"];
      case 'fantasy':
        return ["Fantasy World", "Isekai", "Magic"];
      case 'latest':
      default:
        return ["Cosmic Latest", "HD", "Subbed"];
    }
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
            doc.querySelector('h1')?.text.trim() ?? "HentaiGalaxy Episode";
        final desc = doc.querySelector('meta[name="description"]')?.attributes['content'] ??
            doc.querySelector('.entry-content p')?.text.trim() ??
            "Cosmic anime stream playback on HentaiGalaxy.";
        final cover =
            doc.querySelector('meta[property="og:image"]')?.attributes['content'] ?? "";

        final sources = await extractVideoStreams(url);

        return MediaDetail(
          id: url.hashCode.toString(),
          title: title,
          cover: cover.isNotEmpty ? cover : "https://i.imgur.com/7jZQY1B.jpeg",
          backdrop: cover.isNotEmpty ? cover : "https://i.imgur.com/7jZQY1B.jpeg",
          description: desc,
          studio: "HentaiGalaxy Studios",
          releaseDate: "2024",
          tags: ["Cosmic", "HD", "Uncensored"],
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
          playbackHeatmap: [0.1, 0.35, 0.65, 0.95, 0.8, 0.4, 0.3, 0.9, 1.0, 0.4],
          sceneMarkers: [
            SceneMarker(title: "Opening", timestampSeconds: 0),
            SceneMarker(title: "Galaxy Climax 🔥", timestampSeconds: 700),
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
        final iframes = doc.querySelectorAll(
            'iframe[src*="embed"], iframe[data-src], iframe');
        final List<StreamSource> sources = [];

        for (final iframe in iframes) {
          final src =
              iframe.attributes['data-src'] ?? iframe.attributes['src'] ?? '';
          if (src.isNotEmpty &&
              !src.contains('facebook') &&
              !src.contains('google') &&
              !sources.any((s) => s.url == src)) {
            sources.add(StreamSource(
              label: "Galaxy Stream Server",
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
          id: "hgx_lat_1",
          title: "Taimanin Yukikaze: Galaxy Infiltration",
          url: "$baseUrl/taimanin-yukikaze-galaxy-infiltration",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "24:15",
          releaseDate: "2025",
          studio: "Lilith",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Cosmic Latest", "Action", "Kunoichi", "Sci-Fi"],
          rating: 4.9,
          views: 320000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hgx_lat_2",
          title: "Space Pirate Sara: Cosmic Plunder",
          url: "$baseUrl/space-pirate-sara-cosmic-plunder",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "26:40",
          releaseDate: "2025",
          studio: "Pink Pineapple",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Cosmic Latest", "Space", "Pirate", "Sci-Fi"],
          rating: 4.8,
          views: 290000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hgx_lat_3",
          title: "Amon: Apocalypse Andromeda Awakening",
          url: "$baseUrl/amon-apocalypse-andromeda-awakening",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "25:10",
          releaseDate: "2025",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Cosmic Latest", "Supernatural", "Cosmic", "HD"],
          rating: 4.7,
          views: 245000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hgx_lat_4",
          title: "Starlight Frontier: Deep Cosmos Voyage",
          url: "$baseUrl/starlight-frontier-deep-cosmos",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "23:50",
          releaseDate: "2025",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Cosmic Latest", "Sci-Fi", "Voyage", "HD"],
          rating: 4.8,
          views: 275000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hgx_lat_5",
          title: "Viper GTS: Cyber Odyssey Episode 1",
          url: "$baseUrl/viper-gts-cyber-odyssey-ep1",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "28:30",
          releaseDate: "2025",
          studio: "Sonomama",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Cosmic Latest", "Cyberpunk", "Classic", "HD"],
          rating: 4.9,
          views: 310000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hgx_lat_6",
          title: "Cosmic Harem: Orbiting Station Beta",
          url: "$baseUrl/cosmic-harem-orbiting-station-beta",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "22:45",
          releaseDate: "2025",
          studio: "Bunnywalker",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Cosmic Latest", "Harem", "Space Station", "HD"],
          rating: 4.7,
          views: 260000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hgx_lat_7",
          title: "Star Knightess Ingrid: Nebula Encounter",
          url: "$baseUrl/star-knightess-ingrid-nebula-encounter",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "27:15",
          releaseDate: "2025",
          studio: "Lilith",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Cosmic Latest", "Knight", "Nebula", "HD"],
          rating: 4.8,
          views: 285000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hgx_lat_8",
          title: "Stella Maiden: Solar Flare Rapture",
          url: "$baseUrl/stella-maiden-solar-flare-rapture",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "24:00",
          releaseDate: "2025",
          studio: "Ziz",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Cosmic Latest", "Cosmic", "Maiden", "Subbed"],
          rating: 4.7,
          views: 230000,
          isUncensored: false,
        ),
      ],
      "popular": [
        MediaItem(
          id: "hgx_pop_1",
          title: "Kuroinu: Intergalactic Dominion",
          url: "$baseUrl/kuroinu-intergalactic-dominion",
          cover: "https://i.imgur.com/wVqjC5P.jpeg",
          duration: "29:50",
          releaseDate: "2024",
          studio: "Eroman",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Cosmic Popular", "Dark Fantasy", "Dominion", "4K"],
          rating: 5.0,
          views: 880000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hgx_pop_2",
          title: "Bible Black: Supernova Walpurgis",
          url: "$baseUrl/bible-black-supernova-walpurgis",
          cover: "https://i.imgur.com/z4bKxNm.jpeg",
          duration: "31:10",
          releaseDate: "2024",
          studio: "Milky",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Cosmic Popular", "Occult", "Classic", "HD"],
          rating: 4.9,
          views: 920000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hgx_pop_3",
          title: "Mankitsu Happening: Astral Suite",
          url: "$baseUrl/mankitsu-happening-astral-suite",
          cover: "https://i.imgur.com/83pZ6XQ.jpeg",
          duration: "32:00",
          releaseDate: "2024",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Cosmic Popular", "Harem", "Galaxy Hit", "Full HD"],
          rating: 4.95,
          views: 970000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hgx_pop_4",
          title: "Taimanin Asagi: Stellar Vanguard",
          url: "$baseUrl/taimanin-asagi-stellar-vanguard",
          cover: "https://i.imgur.com/6X2p9Lk.jpeg",
          duration: "28:15",
          releaseDate: "2024",
          studio: "Lilith",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Cosmic Popular", "Kunoichi", "Action", "Sci-Fi"],
          rating: 4.9,
          views: 850000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hgx_pop_5",
          title: "Gakuen de Jikan yo Tomare: Chrono Nebula",
          url: "$baseUrl/gakuen-de-jikan-yo-tomare-chrono-nebula",
          cover: "https://i.imgur.com/9v8Xg7d.jpeg",
          duration: "26:30",
          releaseDate: "2024",
          studio: "BOOTLEG",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Cosmic Popular", "Time Stop", "Supernatural", "HD"],
          rating: 4.88,
          views: 790000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hgx_pop_6",
          title: "Overflow: Zero-G Orbital Bathing",
          url: "$baseUrl/overflow-zerog-orbital-bathing",
          cover: "https://i.imgur.com/J3y8j5T.jpeg",
          duration: "23:45",
          releaseDate: "2024",
          studio: "Houkiboshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Cosmic Popular", "Romance", "Harem", "HD"],
          rating: 4.92,
          views: 940000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hgx_pop_7",
          title: "Master Piece: Galactic Harem Special",
          url: "$baseUrl/master-piece-galactic-harem-special",
          cover: "https://i.imgur.com/M5f7k2A.jpeg",
          duration: "27:10",
          releaseDate: "2024",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Cosmic Popular", "Maid", "Harem", "Classic"],
          rating: 4.87,
          views: 760000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hgx_pop_8",
          title: "Rance: The Quest for Cosmic Conquest",
          url: "$baseUrl/rance-quest-cosmic-conquest",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "30:20",
          releaseDate: "2024",
          studio: "AliceSoft",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Cosmic Popular", "Warrior", "Adventure", "Galaxy Top"],
          rating: 4.91,
          views: 810000,
          isUncensored: true,
        ),
      ],
      "uncensored": [
        MediaItem(
          id: "hgx_unc_1",
          title: "Discipline: Absolute Zero Decensored",
          url: "$baseUrl/discipline-absolute-zero-decensored",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "29:30",
          releaseDate: "2024",
          studio: "Active",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Galaxy", "Decensored", "School", "Classic"],
          rating: 4.95,
          views: 670000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hgx_unc_2",
          title: "Maison de M: Galaxy Suites Uncensored",
          url: "$baseUrl/maison-de-m-galaxy-suites-uncensored",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "28:10",
          releaseDate: "2024",
          studio: "Eroman",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Galaxy", "Decensored", "Maid", "HD"],
          rating: 4.9,
          views: 590000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hgx_unc_3",
          title: "Oni Chichi: Infinite Horizon Decensored",
          url: "$baseUrl/oni-chichi-infinite-horizon-decensored",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "25:40",
          releaseDate: "2024",
          studio: "Blue Eyes",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Galaxy", "Decensored", "Family", "HD"],
          rating: 4.88,
          views: 630000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hgx_unc_4",
          title: "Drop Out: Cosmic Academy Uncensored",
          url: "$baseUrl/drop-out-cosmic-academy-uncensored",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "27:50",
          releaseDate: "2024",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Galaxy", "Gyaru", "Decensored", "School"],
          rating: 4.92,
          views: 610000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hgx_unc_5",
          title: "Tiny Evil: Succubus Nebula Uncensored",
          url: "$baseUrl/tiny-evil-succubus-nebula-uncensored",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "24:20",
          releaseDate: "2024",
          studio: "Bunnywalker",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Galaxy", "Succubus", "Decensored", "Fantasy"],
          rating: 4.89,
          views: 580000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hgx_unc_6",
          title: "Ane wa Yanmama: Galaxy Mom Uncensored",
          url: "$baseUrl/ane-wa-yanmama-galaxy-mom-uncensored",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "28:00",
          releaseDate: "2024",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Galaxy", "Milf", "Decensored", "HD"],
          rating: 4.91,
          views: 640000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hgx_unc_7",
          title: "Dokidoki Little Ooyasan: Orbit Uncensored",
          url: "$baseUrl/dokidoki-little-ooyasan-orbit-uncensored",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "22:50",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Galaxy", "Romance", "Decensored", "Cute"],
          rating: 4.87,
          views: 520000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hgx_unc_8",
          title: "Boku to Nurse no Shinsatsushitsu: Decensored",
          url: "$baseUrl/boku-to-nurse-decensored",
          cover: "https://i.imgur.com/wVqjC5P.jpeg",
          duration: "24:30",
          releaseDate: "2024",
          studio: "Queen Bee",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Galaxy", "Nurse", "Decensored", "HD"],
          rating: 4.86,
          views: 550000,
          isUncensored: true,
        ),
      ],
      "scifi": [
        MediaItem(
          id: "hgx_sci_1",
          title: "Cybernetic Maiden: Android 09 Reclamation",
          url: "$baseUrl/cybernetic-maiden-android-09",
          cover: "https://i.imgur.com/z4bKxNm.jpeg",
          duration: "26:30",
          releaseDate: "2025",
          studio: "CyberPulse",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Sci-Fi", "Cyberpunk", "Android", "Futuristic"],
          rating: 4.92,
          views: 420000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hgx_sci_2",
          title: "Ghost in the Hentai: Neural Net Jack",
          url: "$baseUrl/ghost-in-the-hentai-neural-jack",
          cover: "https://i.imgur.com/83pZ6XQ.jpeg",
          duration: "28:15",
          releaseDate: "2025",
          studio: "Pink Pineapple",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Sci-Fi", "Cyberpunk", "Neural Net", "Hacking"],
          rating: 4.88,
          views: 395000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hgx_sci_3",
          title: "Mecha Pilot Asuka: Neon City Overdrive",
          url: "$baseUrl/mecha-pilot-asuka-neon-overdrive",
          cover: "https://i.imgur.com/6X2p9Lk.jpeg",
          duration: "25:40",
          releaseDate: "2025",
          studio: "Lilith",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Sci-Fi", "Mecha", "Cyberpunk", "Pilot"],
          rating: 4.9,
          views: 450000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hgx_sci_4",
          title: "Cyberpunk 2069: Night City Syndicate",
          url: "$baseUrl/cyberpunk-2069-night-city-syndicate",
          cover: "https://i.imgur.com/9v8Xg7d.jpeg",
          duration: "30:00",
          releaseDate: "2025",
          studio: "Ziz",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Sci-Fi", "Cyberpunk", "Dystopia", "Night City"],
          rating: 4.95,
          views: 530000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hgx_sci_5",
          title: "Viper F40: Synthetic Maiden Protocol",
          url: "$baseUrl/viper-f40-synthetic-protocol",
          cover: "https://i.imgur.com/J3y8j5T.jpeg",
          duration: "27:10",
          releaseDate: "2025",
          studio: "Sonomama",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Sci-Fi", "Synthetic", "Android", "Classic"],
          rating: 4.85,
          views: 360000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hgx_sci_6",
          title: "Holographic Concierge: Quantum AI Love",
          url: "$baseUrl/holographic-concierge-quantum-ai",
          cover: "https://i.imgur.com/M5f7k2A.jpeg",
          duration: "23:55",
          releaseDate: "2025",
          studio: "Bunnywalker",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Sci-Fi", "AI", "Hologram", "Virtual"],
          rating: 4.82,
          views: 340000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hgx_sci_7",
          title: "Zero-G Fighter: Void Siren Command",
          url: "$baseUrl/zerog-fighter-void-siren",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "24:50",
          releaseDate: "2025",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Sci-Fi", "Zero-G", "Space Fleet", "Military"],
          rating: 4.87,
          views: 380000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hgx_sci_8",
          title: "Borg Queen: Bio-Mechanical Assimilation",
          url: "$baseUrl/borg-queen-biomechanical-assimilation",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "29:00",
          releaseDate: "2025",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Sci-Fi", "Cyborg", "Dark Sci-Fi", "Tentacles"],
          rating: 4.89,
          views: 410000,
          isUncensored: true,
        ),
      ],
      "fantasy": [
        MediaItem(
          id: "hgx_fan_1",
          title: "Isekai Harem Monogatari: Astral Kingdom",
          url: "$baseUrl/isekai-harem-monogatari-astral",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "25:30",
          releaseDate: "2025",
          studio: "Bunnywalker",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Fantasy World", "Isekai", "Harem", "Magic"],
          rating: 4.94,
          views: 560000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hgx_fan_2",
          title: "Kyonyuu Fantasy: High Elf Citadel",
          url: "$baseUrl/kyonyuu-fantasy-high-elf-citadel",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "28:15",
          releaseDate: "2025",
          studio: "W-Toon Studio",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Fantasy World", "Elf", "Citadel", "Big Boobs"],
          rating: 4.89,
          views: 490000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hgx_fan_3",
          title: "Dungeon Guild Master: Labyrinth Maidens",
          url: "$baseUrl/dungeon-guild-master-labyrinth-maidens",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "26:40",
          releaseDate: "2025",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Fantasy World", "Dungeon", "Guild", "Adventure"],
          rating: 4.88,
          views: 475000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hgx_fan_4",
          title: "Re:Monster Harem: Goblin Warlord Seduction",
          url: "$baseUrl/remonster-harem-goblin-warlord",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "24:50",
          releaseDate: "2025",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Fantasy World", "Monster Girl", "Isekai", "HD"],
          rating: 4.81,
          views: 430000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hgx_fan_5",
          title: "Valkyrie Elysium: Sacred Maiden Binding",
          url: "$baseUrl/valkyrie-elysium-sacred-maiden",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "27:20",
          releaseDate: "2025",
          studio: "Lilith",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Fantasy World", "Valkyrie", "Mythology", "Magic"],
          rating: 4.9,
          views: 460000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hgx_fan_6",
          title: "Dragon Knight: Crimson Scaled Empress",
          url: "$baseUrl/dragon-knight-crimson-empress",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "29:10",
          releaseDate: "2025",
          studio: "Milky",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Fantasy World", "Dragon Girl", "Knight", "Royalty"],
          rating: 4.87,
          views: 440000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hgx_fan_7",
          title: "Succubus Stay: Demon Lord's Castle",
          url: "$baseUrl/succubus-stay-demon-lords-castle",
          cover: "https://i.imgur.com/wVqjC5P.jpeg",
          duration: "23:40",
          releaseDate: "2025",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Fantasy World", "Succubus", "Demon Lord", "Comedy"],
          rating: 4.86,
          views: 420000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hgx_fan_8",
          title: "Choukou Tenshi Escalayer: Divine Paladin",
          url: "$baseUrl/choukou-tenshi-escalayer-divine",
          cover: "https://i.imgur.com/z4bKxNm.jpeg",
          duration: "30:05",
          releaseDate: "2025",
          studio: "AliceSoft",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Fantasy World", "Angel", "Paladin", "Classic"],
          rating: 4.93,
          views: 510000,
          isUncensored: true,
        ),
      ],
    };

    return sampleSets[tabId] ?? sampleSets["latest"] ?? [];
  }

  MediaDetail _generateSampleDetail(String url) {
    return MediaDetail(
      id: url.hashCode.toString(),
      title: "Taimanin Yukikaze: Galaxy Infiltration",
      cover: "https://i.imgur.com/7jZQY1B.jpeg",
      backdrop: "https://i.imgur.com/7jZQY1B.jpeg",
      description: "Cosmic recommendation anime stream on HentaiGalaxy.",
      studio: "Lilith Animation",
      releaseDate: "2025",
      tags: ["Cosmic Latest", "Action", "Sci-Fi", "Uncensored"],
      episodes: [
        EpisodeItem(
          id: "ep_1",
          episodeNumber: "Episode 1",
          title: "Episode 1 – Infiltration",
          url: url,
          thumbnail: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "24:15",
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
        SceneMarker(title: "Galaxy Climax 🔥", timestampSeconds: 700),
      ],
    );
  }

  @override
  Future<ExtensionTaxonomy> fetchTaxonomy() async {
    return hentaiGalaxyTaxonomy;
  }

  @override
  Future<List<MediaItem>> fetchTaxonomyFeed(CatalogItem item, int page) async {
    // 1. Direct tab feed mapping if it corresponds to a primary tab
    if (item.slug == 'latest' ||
        item.slug == 'popular' ||
        item.slug == 'uncensored' ||
        item.slug == 'scifi' ||
        item.slug == 'fantasy') {
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
            : '$domain${normalizedPath}page/$page/';

        final response = await http
            .get(Uri.parse(targetUrl), headers: _headers)
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final items = _parseCardsFromHtml(response.body, domain, tabId: item.slug);
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

    final fallbackTab = (item.slug == 'scifi' ||
            item.categoryGroup == 'Cosmic & Sci-Fi' ||
            item.slug == 'cyberpunk' ||
            item.slug == 'android' ||
            item.slug == 'mecha')
        ? 'scifi'
        : (item.slug == 'fantasy' ||
                item.categoryGroup == 'Fantasy & Magic' ||
                item.slug == 'isekai' ||
                item.slug == 'magic' ||
                item.slug == 'elf')
            ? 'fantasy'
            : (item.slug == 'uncensored' ||
                    item.slug == 'decensored' ||
                    item.categoryGroup == 'Character Archetypes')
                ? 'uncensored'
                : (item.slug == 'popular' || item.count > 5000)
                    ? 'popular'
                    : 'latest';

    final baseItems = _generateSampleList(fallbackTab, 1);
    return baseItems.map((m) {
      final updatedTags = List<String>.from(m.tags);
      if (!updatedTags.contains(item.name)) {
        updatedTags.insert(0, item.name);
      }
      return MediaItem(
        id: "hgx_tax_${item.slug}_${m.id}",
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

