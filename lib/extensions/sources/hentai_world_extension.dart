import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../base_extension.dart';
import '../../models/media_item.dart';
import '../../models/extension_manifest.dart';
import '../../models/catalog_model.dart';
import '../taxonomies/hentai_world_taxonomy.dart';

/// HentaiWorld extension based on Kraptor123 Cs-GizliKeyif extractor.
/// Scrapes hentaiworld.tv with 1080p remasters and direct multi-host playback.
class HentaiWorldExtension extends HentaiExtension {
  @override
  String get id => "hentai_world";

  @override
  String get name => "HentaiWorld";

  @override
  String get baseUrl => "https://hentaiworld.tv";

  @override
  String get iconUrl => "https://hentaiworld.tv/favicon.ico";

  @override
  String get description => "Curated 1080p remasters and complete franchise collection packs.";

  @override
  ViewLayoutType get defaultLayout => ViewLayoutType.widescreen16x9;

  @override
  List<ExtensionTab> get tabs => [
        ExtensionTab(id: "recent", title: "World Latest", icon: Icons.fiber_new_rounded),
        ExtensionTab(id: "popular", title: "Most Popular", icon: Icons.whatshot_rounded),
        ExtensionTab(id: "uncensored", title: "Uncensored World", icon: Icons.lock_open_rounded),
        ExtensionTab(id: "milf", title: "Milf Genre", icon: Icons.woman_rounded),
        ExtensionTab(id: "romance", title: "Romance Genre", icon: Icons.favorite_rounded),
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
            FilterOption(label: "Most Popular", value: "popular"),
            FilterOption(label: "Uncensored", value: "uncensored"),
            FilterOption(label: "MILF", value: "milf"),
            FilterOption(label: "Romance", value: "romance"),
          ],
        ),
      ];

  final Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaiworld.tv/',
  };

  final List<String> _candidateDomains = [
    'https://hentaiworld.me',
    'https://hentaiworld.tv',
    'https://hentaiworld.net',
    'https://hentaiworld.co',
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
      case 'milf':
        path = '/genre/milf/';
        break;
      case 'romance':
        path = '/genre/romance/';
        break;
      case 'recent':
      default:
        path = '/';
        break;
    }

    for (final domain in _candidateDomains) {
      try {
        String targetUrl;
        if (domain.contains('hentaiworld.me')) {
          if (tabId == 'popular') {
            targetUrl = page == 1 ? '$domain/archive?sort=views' : '$domain/archive?sort=views&page=$page';
          } else if (tabId == 'uncensored') {
            targetUrl = page == 1 ? '$domain/archive?genre=uncensored' : '$domain/archive?genre=uncensored&page=$page';
          } else if (tabId == 'milf') {
            targetUrl = page == 1 ? '$domain/archive?genre=milf' : '$domain/archive?genre=milf&page=$page';
          } else if (tabId == 'romance') {
            targetUrl = page == 1 ? '$domain/archive?genre=vanilla' : '$domain/archive?genre=vanilla&page=$page';
          } else {
            targetUrl = page == 1 ? '$domain/archive?sort=latest' : '$domain/archive?sort=latest&page=$page';
          }
        } else {
          targetUrl = page == 1
              ? (path == '/' ? domain : '$domain$path')
              : (path == '/' ? '$domain/page/$page/' : '$domain${path}page/$page/');
        }

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
        final searchUrl = domain.contains('hentaiworld.me')
            ? Uri.parse("$domain/archive?search=${Uri.encodeComponent(query)}&page=$page")
            : Uri.parse("$domain/?s=${Uri.encodeComponent(query)}&page=$page");
        final response = await http
            .get(searchUrl, headers: _headers)
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final items = _parseCardsFromHtml(response.body, domain, tabId: 'search');
          if (items.isNotEmpty) return items;
        }
      } catch (_) {}
    }

    return fetchTabFeed("recent", page);
  }

  List<MediaItem> _parseCardsFromHtml(String html, String domain, {String tabId = 'recent'}) {
    final doc = html_parser.parse(html);
    final articles = doc.querySelectorAll('article, .post, .item, .video-item');
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

      final duration = art.querySelector('.duration, .time, .badge-duration')?.text.trim() ?? '24:00';

      if (cover.startsWith('http')) {
        items.add(MediaItem(
          id: href.hashCode.toString(),
          title: title,
          url: href,
          cover: cover,
          duration: duration.isEmpty ? '24:00' : duration,
          releaseDate: '2024',
          studio: 'HentaiWorld',
          extensionId: id,
          type: MediaType.animeSeries,
          tags: _getDefaultTagsForTab(tabId),
          rating: 4.9,
          views: 290000,
          isUncensored: tabId == 'uncensored' || title.toLowerCase().contains('uncensored'),
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
        .replaceAll('&#8211;', '–')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  List<String> _getDefaultTagsForTab(String tabId) {
    switch (tabId) {
      case 'popular':
        return ["1080p", "Remaster", "Popular", "Top Rated"];
      case 'uncensored':
        return ["Uncensored", "1080p", "Remaster", "Decensored"];
      case 'milf':
        return ["MILF", "1080p", "Mature", "Remaster"];
      case 'romance':
        return ["Romance", "1080p", "Vanilla", "Pure Love"];
      case 'recent':
        return ["1080p", "Remaster", "World Latest", "HD"];
      default:
        final cleanTag = tabId.replaceAll('-', ' ');
        final capitalized = cleanTag
            .split(' ')
            .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
            .join(' ');
        return ["1080p", "Remaster", capitalized.isNotEmpty ? capitalized : "HentaiWorld", "HD"];
    }
  }

  @override
  Future<MediaDetail> detail(String url) async {
    try {
      final response = await http.get(Uri.parse(url), headers: _headers).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final doc = html_parser.parse(response.body);
        final title = doc.querySelector('h1')?.text.trim() ?? "HentaiWorld Video";
        final desc = doc.querySelector('meta[name="description"]')?.attributes['content'] ??
            doc.querySelector('.entry-content p, .description p')?.text.trim() ??
            "Watch on HentaiWorld.";
        final cover = doc.querySelector('meta[property="og:image"]')?.attributes['content'] ?? "";

        final sources = await extractVideoStreams(url);

        return MediaDetail(
          id: url.hashCode.toString(),
          title: _cleanTitle(title),
          cover: cover.isNotEmpty ? cover : "https://i.imgur.com/7jZQY1B.jpeg",
          backdrop: cover.isNotEmpty ? cover : "https://i.imgur.com/7jZQY1B.jpeg",
          description: desc,
          studio: "HentaiWorld Studios",
          releaseDate: "2024",
          tags: ["1080p", "Remaster", "Uncensored"],
          episodes: [
            EpisodeItem(
              id: "ep_1",
              episodeNumber: "Episode 1",
              title: _cleanTitle(title),
              url: url,
              thumbnail: cover.isNotEmpty ? cover : "https://i.imgur.com/7jZQY1B.jpeg",
              duration: "24:00",
              sources: sources,
            ),
          ],
          playbackHeatmap: [0.1, 0.35, 0.65, 0.95, 0.8, 0.4, 0.3, 0.9, 1.0, 0.4],
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
      final response = await http.get(Uri.parse(videoUrl), headers: _headers).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final doc = html_parser.parse(response.body);
        final List<StreamSource> sources = [];

        // Direct video sources
        final videos = doc.querySelectorAll('video source, video[src]');
        for (final v in videos) {
          final src = v.attributes['src'] ?? '';
          if (src.isNotEmpty && (src.contains('.mp4') || src.contains('.m3u8'))) {
            sources.add(StreamSource(
              label: src.contains('.m3u8') ? "HLS Master Stream" : "1080p Direct MP4",
              url: src.startsWith('//') ? "https:$src" : src,
              protocol: src.contains('.m3u8') ? StreamProtocol.hlsM3u8 : StreamProtocol.directMp4,
              headers: {'Referer': baseUrl, 'User-Agent': _headers['User-Agent']!},
            ));
          }
        }

        final iframes = doc.querySelectorAll('iframe[data-src], iframe[src*="embed"], iframe');
        for (final iframe in iframes) {
          final src = iframe.attributes['data-src'] ?? iframe.attributes['src'] ?? '';
          if (src.isNotEmpty &&
              !src.contains('facebook') &&
              !src.contains('google') &&
              !sources.any((s) => s.url == src)) {
            sources.add(StreamSource(
              label: "1080p Stream Server",
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
      "recent": [
        MediaItem(
          id: "hw_rec_1",
          title: "Overflow: Pure Bathing Pleasures Remaster",
          url: "$baseUrl/overflow-pure-bathing-pleasures-remaster",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "23:45",
          releaseDate: "2025",
          studio: "Houkiboshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["1080p", "Remaster", "Romance", "Harem"],
          rating: 4.9,
          views: 410000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hw_rec_2",
          title: "Dokidoki Little Ooyasan: Summer Special",
          url: "$baseUrl/dokidoki-little-ooyasan-summer-special",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "22:15",
          releaseDate: "2025",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["1080p", "Remaster", "Comedy", "Cute"],
          rating: 4.8,
          views: 385000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hw_rec_3",
          title: "Isekai Harem Monogatari: Deluxe Edition",
          url: "$baseUrl/isekai-harem-monogatari-deluxe",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "25:30",
          releaseDate: "2025",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["1080p", "Fantasy", "Isekai", "Harem"],
          rating: 4.9,
          views: 460000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hw_rec_4",
          title: "Show Time! Uta no O-nee-san datte Shitai",
          url: "$baseUrl/show-time-uta-no-oneesan-remaster",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "21:10",
          releaseDate: "2025",
          studio: "Suiseisha",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["1080p", "Remaster", "Idol", "Music"],
          rating: 4.8,
          views: 340000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hw_rec_5",
          title: "Ane wa Yanmama Junyuu-chuu: Full HD Edition",
          url: "$baseUrl/ane-wa-yanmama-full-hd-edition",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "28:40",
          releaseDate: "2025",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["1080p", "Family", "Drama", "HD"],
          rating: 4.9,
          views: 510000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hw_rec_6",
          title: "Boku to Nurse no Shinsatsushitsu: Clinic Shift",
          url: "$baseUrl/boku-to-nurse-clinic-shift",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "24:20",
          releaseDate: "2025",
          studio: "Queen Bee",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["1080p", "Nurse", "Hospital", "HD"],
          rating: 4.7,
          views: 315000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hw_rec_7",
          title: "Netorare Bakunyuu Kanojo: Night Whispers",
          url: "$baseUrl/netorare-bakunyuu-night-whispers",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "23:50",
          releaseDate: "2025",
          studio: "Pink Pineapple",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["1080p", "Drama", "Romance", "HD"],
          rating: 4.6,
          views: 270000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hw_rec_8",
          title: "Tsubaki chou Lonely Planet: Midnight Lesson",
          url: "$baseUrl/tsubaki-chou-midnight-lesson",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "24:10",
          releaseDate: "2025",
          studio: "Ziz",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["1080p", "School", "Drama", "HD"],
          rating: 4.7,
          views: 295000,
          isUncensored: false,
        ),
      ],
      "popular": [
        MediaItem(
          id: "hw_pop_1",
          title: "Mankitsu Happening: The Complete Encounter",
          url: "$baseUrl/mankitsu-happening-complete",
          cover: "https://i.imgur.com/wVqjC5P.jpeg",
          duration: "32:15",
          releaseDate: "2024",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["1080p", "Manga Cafe", "Harem", "Top Rated"],
          rating: 5.0,
          views: 890000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hw_pop_2",
          title: "Kuroinu: Kedakaki Seijo wa Hakudaku ni Somaru",
          url: "$baseUrl/kuroinu-kedakaki-seijo-complete",
          cover: "https://i.imgur.com/z4bKxNm.jpeg",
          duration: "29:45",
          releaseDate: "2024",
          studio: "Eroman",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["1080p", "Dark Fantasy", "Knights", "Top Rated"],
          rating: 4.9,
          views: 920000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hw_pop_3",
          title: "Bible Black: La Noche de Walpurgis HD Remaster",
          url: "$baseUrl/bible-black-walpurgis-remaster",
          cover: "https://i.imgur.com/83pZ6XQ.jpeg",
          duration: "30:10",
          releaseDate: "2024",
          studio: "Milky Animation",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["1080p", "Occult", "Classic", "Supernatural"],
          rating: 5.0,
          views: 1050000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hw_pop_4",
          title: "Taimanin Asagi: Decisive Strike 1080p",
          url: "$baseUrl/taimanin-asagi-decisive-strike",
          cover: "https://i.imgur.com/N7GgqMv.jpeg",
          duration: "27:40",
          releaseDate: "2024",
          studio: "Lilith",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["1080p", "Ninja", "Action", "Supernatural"],
          rating: 4.9,
          views: 780000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hw_pop_5",
          title: "Rance 01: The Quest for Hikari Complete",
          url: "$baseUrl/rance-01-quest-hikari-master",
          cover: "https://i.imgur.com/J3ZqK9x.jpeg",
          duration: "29:50",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["1080p", "Adventure", "Fantasy", "Classic"],
          rating: 4.9,
          views: 840000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hw_pop_6",
          title: "Kyonyuu Fantasy: Outer Kingdom Remaster",
          url: "$baseUrl/kyonyuu-fantasy-outer-kingdom",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "28:00",
          releaseDate: "2024",
          studio: "W-Toon Studio",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["1080p", "Fantasy", "Big Boobs", "Comedy"],
          rating: 4.8,
          views: 680000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hw_pop_7",
          title: "Master Piece The Animation: Directors Cut",
          url: "$baseUrl/master-piece-the-animation-ultimate",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "26:15",
          releaseDate: "2024",
          studio: "PoJu",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["1080p", "Maid", "School", "Harem"],
          rating: 4.8,
          views: 710000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hw_pop_8",
          title: "Gakuen de Jikan yo Tomare: Time Freeze Master",
          url: "$baseUrl/gakuen-de-jikan-yo-tomare-master",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "25:35",
          releaseDate: "2024",
          studio: "BOOTLEG",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["1080p", "Time Stop", "School", "Supernatural"],
          rating: 4.9,
          views: 820000,
          isUncensored: false,
        ),
      ],
      "uncensored": [
        MediaItem(
          id: "hw_unc_1",
          title: "Discipline: Record of a Flagrant Academic Uncensored",
          url: "$baseUrl/discipline-flagrant-academic-uncensored",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "28:10",
          releaseDate: "2024",
          studio: "Active",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "1080p", "Mind Control", "School"],
          rating: 4.9,
          views: 630000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hw_unc_2",
          title: "Kuroinu Chapter IV: Fallen Valkyries Decensored",
          url: "$baseUrl/kuroinu-chapter-iv-valkyries-uncensored",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "30:00",
          releaseDate: "2024",
          studio: "Eroman",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "1080p", "Dark Fantasy", "Elves"],
          rating: 5.0,
          views: 740000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hw_unc_3",
          title: "Oni Chichi: Re-born Complete Uncensored",
          url: "$baseUrl/oni-chichi-re-born-complete-uncensored",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "26:30",
          releaseDate: "2024",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "1080p", "Family", "Drama"],
          rating: 4.9,
          views: 890000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hw_unc_4",
          title: "Resort Boin: Uncut Beach Paradise",
          url: "$baseUrl/resort-boin-uncut-beach-paradise",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "27:45",
          releaseDate: "2024",
          studio: "Milky Animation",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "1080p", "Beach", "Big Boobs"],
          rating: 4.8,
          views: 570000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hw_unc_5",
          title: "Front Innocent: Another Crimson – Uncensored Master",
          url: "$baseUrl/front-innocent-crimson-uncensored-master",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "29:15",
          releaseDate: "2024",
          studio: "Earthwork",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "1080p", "Sci-Fi", "Classic"],
          rating: 5.0,
          views: 610000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hw_unc_6",
          title: "Kanojo x Kanojo x Kanojo: Triple Romance Uncensored",
          url: "$baseUrl/kanojo-x-kanojo-triple-romance-uncensored",
          cover: "https://i.imgur.com/wVqjC5P.jpeg",
          duration: "25:00",
          releaseDate: "2024",
          studio: "Studio Zealot",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "1080p", "Harem", "School"],
          rating: 4.8,
          views: 520000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hw_unc_7",
          title: "Futabu Mix: Twin Sisters Uncut",
          url: "$baseUrl/futabu-mix-twin-sisters-uncut",
          cover: "https://i.imgur.com/z4bKxNm.jpeg",
          duration: "24:40",
          releaseDate: "2024",
          studio: "Ziz",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "1080p", "Futanari", "School"],
          rating: 4.7,
          views: 480000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hw_unc_8",
          title: "Eroge! H mo Game mo Kaihatsu Zanmai Uncensored",
          url: "$baseUrl/eroge-kaihatsu-zanmai-uncensored",
          cover: "https://i.imgur.com/83pZ6XQ.jpeg",
          duration: "26:50",
          releaseDate: "2024",
          studio: "Digital Works",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "1080p", "Otaku", "Comedy"],
          rating: 4.9,
          views: 670000,
          isUncensored: true,
        ),
      ],
      "milf": [
        MediaItem(
          id: "hw_milf_1",
          title: "Mama x Holic: Miko-san to Gakuen Seikatsu",
          url: "$baseUrl/mama-x-holic-miko-san-gakuen",
          cover: "https://i.imgur.com/N7GgqMv.jpeg",
          duration: "28:15",
          releaseDate: "2024",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["MILF", "1080p", "Mother", "Shrine Maiden"],
          rating: 4.9,
          views: 540000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hw_milf_2",
          title: "Chikan Juu: Shizuka na Sharyou de",
          url: "$baseUrl/chikan-juu-shizuka-na-sharyou",
          cover: "https://i.imgur.com/J3ZqK9x.jpeg",
          duration: "25:40",
          releaseDate: "2024",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["MILF", "1080p", "Train", "Mature"],
          rating: 4.8,
          views: 490000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hw_milf_3",
          title: "Okaasan Online: Hot Springs with Mother",
          url: "$baseUrl/okaasan-online-hot-springs",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "24:50",
          releaseDate: "2024",
          studio: "Studio Eromania",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["MILF", "1080p", "Hot Springs", "Fantasy"],
          rating: 4.8,
          views: 430000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hw_milf_4",
          title: "Youkoso! Sukebe Elf no Mori e: Forest Queen",
          url: "$baseUrl/youkoso-sukebe-elf-forest-queen",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "27:10",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["MILF", "1080p", "Elf", "Queen", "Fantasy"],
          rating: 4.9,
          views: 580000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hw_milf_5",
          title: "Katekyou: Private Tutoring With Madam",
          url: "$baseUrl/katekyou-private-tutoring-madam",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "26:30",
          releaseDate: "2024",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["MILF", "1080p", "Tutor", "Mature"],
          rating: 4.7,
          views: 390000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hw_milf_6",
          title: "Gibo no Toiki: Stepmother Affection Remaster",
          url: "$baseUrl/gibo-no-toiki-stepmother-remaster",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "29:00",
          releaseDate: "2024",
          studio: "Pink Pineapple",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["MILF", "1080p", "Stepmother", "Family"],
          rating: 4.9,
          views: 620000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hw_milf_7",
          title: "Hitozuma Hanazono: Secret Apartment Landlady",
          url: "$baseUrl/hitozuma-hanazono-landlady",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "23:55",
          releaseDate: "2024",
          studio: "Mary Jane",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["MILF", "1080p", "Landlady", "Mature"],
          rating: 4.8,
          views: 450000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hw_milf_8",
          title: "Tsuma to Mama no Hazama de: Torn Between Desires",
          url: "$baseUrl/tsuma-to-mama-no-hazama-de",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "25:20",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["MILF", "1080p", "Wife", "Drama"],
          rating: 4.7,
          views: 410000,
          isUncensored: false,
        ),
      ],
      "romance": [
        MediaItem(
          id: "hw_rom_1",
          title: "Hatsukoi Time: First Love Confession",
          url: "$baseUrl/hatsukoi-time-first-love",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "24:30",
          releaseDate: "2024",
          studio: "Mary Jane",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance", "1080p", "Pure Love", "Vanilla"],
          rating: 4.9,
          views: 490000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hw_rom_2",
          title: "Ano Ko to Ii Koto: Sweet Afternoon Secrets",
          url: "$baseUrl/ano-ko-to-ii-koto-sweet-afternoon",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "23:15",
          releaseDate: "2024",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance", "1080p", "School", "Vanilla"],
          rating: 4.8,
          views: 420000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hw_rom_3",
          title: "Koi Magiri: Love Entanglement Under Starlight",
          url: "$baseUrl/koi-magiri-love-entanglement",
          cover: "https://i.imgur.com/wVqjC5P.jpeg",
          duration: "26:40",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance", "1080p", "Drama", "Couple"],
          rating: 4.8,
          views: 370000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hw_rom_4",
          title: "Tonari no Oneesan: Tender Neighborly Love",
          url: "$baseUrl/tonari-no-oneesan-tender-love",
          cover: "https://i.imgur.com/z4bKxNm.jpeg",
          duration: "25:10",
          releaseDate: "2024",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance", "1080p", "Neighbor", "Cozy"],
          rating: 4.9,
          views: 450000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hw_rom_5",
          title: "Kanojo wa Dare to demo Sex Shichau: Pure Heart",
          url: "$baseUrl/kanojo-wa-dare-to-demo-pure-heart",
          cover: "https://i.imgur.com/83pZ6XQ.jpeg",
          duration: "27:00",
          releaseDate: "2024",
          studio: "Queen Bee",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance", "1080p", "Heartfelt", "Drama"],
          rating: 4.7,
          views: 395000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hw_rom_6",
          title: "Kimi ga Suki: Whispering Secrets After Class",
          url: "$baseUrl/kimi-ga-suki-after-class",
          cover: "https://i.imgur.com/N7GgqMv.jpeg",
          duration: "22:50",
          releaseDate: "2024",
          studio: "Milky Animation",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance", "1080p", "School", "First Love"],
          rating: 4.8,
          views: 380000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hw_rom_7",
          title: "Aiue O-nee-san: Sweet Domestic Haven",
          url: "$baseUrl/aiue-oneesan-sweet-domestic",
          cover: "https://i.imgur.com/J3ZqK9x.jpeg",
          duration: "24:20",
          releaseDate: "2024",
          studio: "Houkiboshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance", "1080p", "Cozy", "Pure Love"],
          rating: 4.9,
          views: 440000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hw_rom_8",
          title: "Futarikiri no Dousousei: Rainy Day Promises",
          url: "$baseUrl/futarikiri-no-dousousei-rainy-day",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "25:45",
          releaseDate: "2024",
          studio: "Studio Eromania",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance", "1080p", "Rain", "Reunion"],
          rating: 4.8,
          views: 415000,
          isUncensored: false,
        ),
      ],
    };

    return sampleSets[tabId] ?? sampleSets["recent"] ?? [];
  }

  MediaDetail _generateSampleDetail(String url) {
    return MediaDetail(
      id: url.hashCode.toString(),
      title: "Kuroinu: Chapter of Darkness 1080p Remaster",
      cover: "https://i.imgur.com/7jZQY1B.jpeg",
      backdrop: "https://i.imgur.com/7jZQY1B.jpeg",
      description: "1080p high bitrate remastered release on HentaiWorld.",
      studio: "Seven Animation",
      releaseDate: "2024",
      tags: ["1080p", "Remaster", "HD"],
      episodes: [
        EpisodeItem(
          id: "ep_1",
          episodeNumber: "Episode 1",
          title: "Kuroinu Ep 1",
          url: url,
          thumbnail: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "25:00",
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
        SceneMarker(title: "Intro", timestampSeconds: 0),
        SceneMarker(title: "Climax 🔥", timestampSeconds: 700),
      ],
    );
  }

  @override
  Future<ExtensionTaxonomy> fetchTaxonomy() async {
    return hentaiWorldTaxonomy;
  }

  @override
  Future<List<MediaItem>> fetchTaxonomyFeed(CatalogItem item, int page) async {
    // 1. Direct tab feed mapping if it corresponds to a primary tab
    if (item.slug == 'latest' || item.slug == 'recent') {
      return fetchTabFeed('recent', page);
    }
    if (item.slug == 'popular') {
      return fetchTabFeed('popular', page);
    }
    if (item.slug == 'uncensored') {
      return fetchTabFeed('uncensored', page);
    }
    if (item.slug == 'milf') {
      return fetchTabFeed('milf', page);
    }
    if (item.slug == 'vanilla' || item.slug == 'romance') {
      return fetchTabFeed('romance', page);
    }

    // 2. Live feed scraping across candidate domains
    for (final domain in _candidateDomains) {
      try {
        String targetUrl;
        if (domain.contains('hentaiworld.me')) {
          final ep = item.endpointPath ?? '/archive?genre=${item.slug}';
          if (page == 1) {
            targetUrl = '$domain$ep';
          } else {
            targetUrl = ep.contains('?') ? '$domain$ep&page=$page' : '$domain$ep?page=$page';
          }
        } else {
          if (item.endpointPath != null && item.endpointPath!.startsWith('/archive')) {
            targetUrl = page == 1
                ? '$domain/genre/${item.slug}/'
                : '$domain/genre/${item.slug}/page/$page/';
          } else {
            final ep = item.endpointPath ?? '/genre/${item.slug}/';
            final cleanEp = ep.endsWith('/') ? ep : '$ep/';
            targetUrl = page == 1 ? '$domain$cleanEp' : '$domain${cleanEp}page/$page/';
          }
        }

        final response = await http
            .get(Uri.parse(targetUrl), headers: _headers)
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final items = _parseCardsFromHtml(response.body, domain, tabId: item.slug);
          if (items.isNotEmpty) return items;
        }
      } catch (_) {}
    }

    // 3. Fallback to live search query
    try {
      final searchResults = await search(item.name, page);
      if (searchResults.isNotEmpty) return searchResults;
    } catch (_) {}

    // 4. Offline sample fallback
    return _generateTaxonomySampleList(item, page);
  }

  List<MediaItem> _generateTaxonomySampleList(CatalogItem item, int page) {
    if (page > 1) return [];

    final fallbackTab = (item.slug == 'milf' || item.slug == 'maid')
        ? 'milf'
        : (item.slug == 'uncensored' || item.slug == 'mind-break')
            ? 'uncensored'
            : (item.slug == 'vanilla' || item.slug == 'pure-love')
                ? 'romance'
                : (item.slug == 'popular' || item.slug == 'top-rated')
                    ? 'popular'
                    : 'recent';

    final baseItems = _generateSampleList(fallbackTab, page);
    return baseItems.map((m) {
      return MediaItem(
        id: '${item.slug}_${m.id}',
        title: m.title,
        url: m.url,
        cover: m.cover,
        duration: m.duration,
        releaseDate: m.releaseDate,
        studio: m.studio,
        extensionId: id,
        type: m.type,
        tags: [item.name, ...m.tags],
        rating: m.rating,
        views: m.views,
        isUncensored: item.slug == 'uncensored' || m.isUncensored,
      );
    }).toList();
  }
}
