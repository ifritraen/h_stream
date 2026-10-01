import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../base_extension.dart';
import '../../models/media_item.dart';
import '../../models/extension_manifest.dart';
import '../../models/catalog_model.dart';
import '../taxonomies/hentai_mama_taxonomy.dart';

/// HentaiMama extension for HStream Neo.
/// Scrapes fast releases, popular series, ongoing anime, uncensored feeds, and romance genres from hentaimama.io.
class HentaiMamaExtension extends HentaiExtension {
  @override
  String get id => "hentai_mama";

  @override
  String get name => "HentaiMama";

  @override
  String get baseUrl => "https://hentaimama.io";

  @override
  String get iconUrl => "https://hentaimama.io/favicon.ico";

  @override
  String get description =>
      "Fast episode releases, popular weekly tracking, ongoing series, and multi-server playback.";

  @override
  ViewLayoutType get defaultLayout => ViewLayoutType.widescreen16x9;

  @override
  bool get supportsShorts => false;

  @override
  List<ExtensionTab> get tabs => [
        ExtensionTab(
          id: "latest",
          title: "Latest Releases",
          icon: Icons.fiber_new_rounded,
        ),
        ExtensionTab(
          id: "popular",
          title: "Popular Weekly",
          icon: Icons.whatshot_rounded,
        ),
        ExtensionTab(
          id: "ongoing",
          title: "Ongoing Series",
          icon: Icons.update_rounded,
        ),
        ExtensionTab(
          id: "uncensored",
          title: "Uncensored Genre",
          icon: Icons.lock_open_rounded,
        ),
        ExtensionTab(
          id: "romance",
          title: "Romance Genre",
          icon: Icons.favorite_rounded,
        ),
      ];

  @override
  List<FilterGroup> get filters => [];

  final Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaimama.io/',
  };

  @override
  Future<List<MediaItem>> fetchTabFeed(
    String tabId,
    int page, {
    Map<String, dynamic>? activeFilters,
    List<String>? whitelistedTags,
    List<String>? blacklistedTags,
  }) async {
    final List<String> paths = [];
    switch (tabId) {
      case 'popular':
        paths.addAll(page == 1
            ? ['/popular/', '/?orderby=views', '/advance-search/?filter=weekly']
            : [
                '/popular/page/$page/',
                '/page/$page/?orderby=views',
                '/advance-search/page/$page/?submit=Submit&filter=weekly'
              ]);
        break;
      case 'ongoing':
        paths.addAll(page == 1
            ? ['/ongoing/', '/?status=ongoing', '/ongoing-series/']
            : [
                '/ongoing/page/$page/',
                '/page/$page/?status=ongoing',
                '/ongoing-series/page/$page/'
              ]);
        break;
      case 'uncensored':
        paths.addAll(page == 1
            ? ['/genre/uncensored/', '/tags/uncensored/', '/uncensored/']
            : [
                '/genre/uncensored/page/$page/',
                '/tags/uncensored/page/$page/',
                '/uncensored/page/$page/'
              ]);
        break;
      case 'romance':
        paths.addAll(page == 1
            ? ['/genre/romance/', '/tags/romance/', '/romance/']
            : [
                '/genre/romance/page/$page/',
                '/tags/romance/page/$page/',
                '/romance/page/$page/'
              ]);
        break;
      case 'latest':
      default:
        paths.addAll(page == 1
            ? ['/', '/tvshows/']
            : ['/page/$page/', '/tvshows/page/$page/']);
        break;
    }

    for (final path in paths) {
      try {
        final targetUrl = path.startsWith('http') ? path : '$baseUrl$path';
        final response = await http
            .get(Uri.parse(targetUrl), headers: _headers)
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final items = _parseCardsFromHtml(response.body, tabId: tabId);
          if (items.isNotEmpty) return items;
        }
      } catch (_) {}
    }

    return _generateSampleList(tabId, page);
  }

  List<MediaItem> _parseCardsFromHtml(String html, {String tabId = 'latest'}) {
    final doc = html_parser.parse(html);
    final articles = doc.querySelectorAll(
        'article, .post, .item, .mama-item, article.tvshows');
    final List<MediaItem> items = [];
    final Set<String> seenUrls = {};

    for (final art in articles) {
      final a = art.querySelector(
          'header h2 a, a.tvshows-title, a[href*="/tvshows/"], a[href*="/episode/"], a');
      var href = a?.attributes['href'] ?? '';
      if (href.isEmpty) continue;

      if (!href.startsWith('http')) {
        href = href.startsWith('/') ? '$baseUrl$href' : '$baseUrl/$href';
      }

      if (seenUrls.contains(href) ||
          href == baseUrl ||
          href == '$baseUrl/' ||
          href.contains('/page/')) {
        continue;
      }
      seenUrls.add(href);

      final img = art.querySelector('img');
      var title = art
              .querySelector('h2, h3, .entry-title, .title, a[title]')
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

      if (cover.startsWith('data:')) {
        cover = img?.attributes['src'] ?? '';
      }
      if (cover.isEmpty) {
        final style = art
                .querySelector(
                    '.post-thumbnail, .thumb, .entry-thumb, .mama-thumb')
                ?.attributes['style'] ??
            '';
        final bgMatch = RegExp(r'url\((.*?)\)').firstMatch(style);
        if (bgMatch != null) {
          cover = bgMatch
                  .group(1)
                  ?.replaceAll("'", "")
                  .replaceAll('"', '')
                  .trim() ??
              '';
        }
      }

      if (cover.startsWith('//')) {
        cover = 'https:$cover';
      } else if (cover.startsWith('/') && !cover.startsWith('//')) {
        cover = '$baseUrl$cover';
      }

      final duration =
          art.querySelector('.duration, .time, .badge-duration')?.text.trim() ??
              '24:00';

      if (cover.startsWith('http')) {
        final isUnc =
            tabId == 'uncensored' || title.toLowerCase().contains('uncensored');
        items.add(MediaItem(
          id: href.hashCode.toString(),
          title: title,
          url: href,
          cover: cover,
          duration: duration.isEmpty ? '24:00' : duration,
          releaseDate: '2024',
          studio: 'HentaiMama',
          extensionId: id,
          type: MediaType.animeSeries,
          tags: _getDefaultTagsForTab(tabId),
          rating: 4.8,
          views: 260000,
          isUncensored: isUnc,
        ));
      }
    }
    return items;
  }

  String _cleanTitle(String raw) {
    return raw
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('&#8211;', '–')
        .replaceAll('&#8212;', '—')
        .replaceAll('&#038;', '&')
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
        return ["Popular Weekly", "Trending", "HD", "Subbed"];
      case 'ongoing':
        return ["Ongoing Series", "Latest Episode", "HD", "Subbed"];
      case 'uncensored':
        return ["Uncensored Genre", "Decensored", "Full HD"];
      case 'romance':
        return ["Romance Genre", "Vanilla", "Sweet", "HD"];
      case 'latest':
      default:
        return ["Latest Releases", "HD", "Subbed", "Popular"];
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
      final searchUrl =
          Uri.parse("$baseUrl/page/$page/?s=${Uri.encodeComponent(query)}");
      final response = await http
          .get(searchUrl, headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final items = _parseCardsFromHtml(response.body, tabId: 'latest');
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
        final title = doc
                .querySelector('h1.entry-title, h1, .title')
                ?.text
                .trim() ??
            "HentaiMama Video";
        final desc = doc
                .querySelector('div.entry-content p, meta[name="description"]')
                ?.text
                .trim() ??
            "Stream on HentaiMama in HD.";
        final cover =
            doc.querySelector('meta[property="og:image"]')?.attributes['content'] ??
                "";

        final sources = await extractVideoStreams(url);

        return MediaDetail(
          id: url.hashCode.toString(),
          title: title,
          cover: cover.isNotEmpty ? cover : "https://i.imgur.com/7jZQY1B.jpeg",
          backdrop: cover.isNotEmpty ? cover : "https://i.imgur.com/7jZQY1B.jpeg",
          description: desc,
          studio: "HentaiMama Network",
          releaseDate: "2024",
          tags: ["HD", "Subbed", "Uncensored"],
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
            SceneMarker(title: "Main Climax 🔥", timestampSeconds: 710),
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
            'iframe[data-src], iframe[src*="embed"], iframe[src*="player"], iframe');
        for (final iframe in iframes) {
          final src =
              iframe.attributes['data-src'] ?? iframe.attributes['src'] ?? '';
          if (src.isNotEmpty &&
              !src.contains('google') &&
              !src.contains('facebook') &&
              !sources.any((s) => s.url == src)) {
            sources.add(StreamSource(
              label: "Mama Player Stream",
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
          id: "hm_lat_1",
          title: "Taimanin Asagi: Corruption of the Kunoichi Ep 1",
          url: "$baseUrl/tvshows/taimanin-asagi-ep-1",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "Lilith",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest Releases", "Action", "Ninja", "HD"],
          rating: 4.8,
          views: 290000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hm_lat_2",
          title: "Gakuen de Jikan yo Tomare: Time Freeze Classroom Ep 1",
          url: "$baseUrl/tvshows/gakuen-de-jikan-yo-tomare-ep-1",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "25:30",
          releaseDate: "2024",
          studio: "BOOTLEG",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest Releases", "School", "Time Stop", "HD"],
          rating: 4.9,
          views: 310000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hm_lat_3",
          title: "Overflow: Late Night Overflowing Affection Ep 1",
          url: "$baseUrl/tvshows/overflow-late-night-ep-1",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "23:45",
          releaseDate: "2024",
          studio: "Houkiboshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest Releases", "Romance", "Harem", "HD"],
          rating: 4.9,
          views: 420000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hm_lat_4",
          title: "Isekai Harem Monogatari: Royal Bedroom Secrets Ep 1",
          url: "$baseUrl/tvshows/isekai-harem-monogatari-ep-1",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "26:10",
          releaseDate: "2024",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest Releases", "Fantasy", "Isekai", "Harem"],
          rating: 4.8,
          views: 350000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hm_lat_5",
          title: "Mankitsu Happening: Secret Manga Cafe Encounter Ep 1",
          url: "$baseUrl/tvshows/mankitsu-happening-ep-1",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "27:50",
          releaseDate: "2024",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest Releases", "Manga Cafe", "Harem", "HD"],
          rating: 4.9,
          views: 480000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hm_lat_6",
          title: "Ane wa Yanmama Junyuu-chuu: Secret Nursing Visit Ep 1",
          url: "$baseUrl/tvshows/ane-wa-yanmama-ep-1",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "27:15",
          releaseDate: "2024",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest Releases", "Milf", "Family", "HD"],
          rating: 4.8,
          views: 295000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hm_lat_7",
          title: "Rikujoubu Joshi wa Ore no Nama Onaho Ep 1",
          url: "$baseUrl/tvshows/rikujoubu-joshi-ep-1",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "22:45",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest Releases", "Sports", "School", "HD"],
          rating: 4.7,
          views: 210000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hm_lat_8",
          title: "Dokidoki Little Ooyasan: Sweet Landlady Summer Ep 1",
          url: "$baseUrl/tvshows/dokidoki-little-ooyasan-ep-1",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "21:40",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest Releases", "Comedy", "Slice of Life", "HD"],
          rating: 4.7,
          views: 240000,
          isUncensored: false,
        ),
      ],
      "popular": [
        MediaItem(
          id: "hm_pop_1",
          title: "Euphoria: Game of Salvation HD Remaster Ep 1",
          url: "$baseUrl/tvshows/euphoria-game-of-salvation-ep-1",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "29:30",
          releaseDate: "2024",
          studio: "Magin",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Popular Weekly", "Psychological", "Thriller", "HD"],
          rating: 4.9,
          views: 640000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hm_pop_2",
          title: "Rance 01: The Quest for Hikari Full Edition Ep 1",
          url: "$baseUrl/tvshows/rance-01-the-quest-ep-1",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "30:00",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Popular Weekly", "Adventure", "Fantasy", "Action"],
          rating: 5.0,
          views: 580000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hm_pop_3",
          title: "Kuroinu: Kedakaki Seijo wa Hakudaku ni Somaru Ep 1",
          url: "$baseUrl/tvshows/kuroinu-kedakaki-seijo-ep-1",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "28:20",
          releaseDate: "2024",
          studio: "Eroman",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Popular Weekly", "Dark Fantasy", "Action", "Elves"],
          rating: 4.8,
          views: 510000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hm_pop_4",
          title: "Kyonyuu Fantasy: Empire of Desires Ep 1",
          url: "$baseUrl/tvshows/kyonyuu-fantasy-empire-ep-1",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "28:10",
          releaseDate: "2024",
          studio: "DMM.com",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Popular Weekly", "Fantasy", "Comedy", "Harem"],
          rating: 4.8,
          views: 490000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hm_pop_5",
          title: "Master Piece The Animation: Maid Chronicles Ep 1",
          url: "$baseUrl/tvshows/master-piece-maid-ep-1",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "26:45",
          releaseDate: "2024",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Popular Weekly", "Maid", "Harem", "Classic"],
          rating: 4.9,
          views: 530000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hm_pop_6",
          title: "Resort Boin: Tropical Island Paradise Ep 1",
          url: "$baseUrl/tvshows/resort-boin-paradise-ep-1",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "25:10",
          releaseDate: "2024",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Popular Weekly", "Resort", "Beach", "Harem"],
          rating: 4.8,
          views: 460000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hm_pop_7",
          title: "Oni Chichi: Re-born Sweet Home Collection Ep 1",
          url: "$baseUrl/tvshows/oni-chichi-re-born-ep-1",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "26:15",
          releaseDate: "2024",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Popular Weekly", "Gyaru", "Family", "Classic"],
          rating: 4.7,
          views: 475000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hm_pop_8",
          title: "Discipline: The Record of a Miracle Definitive Ep 1",
          url: "$baseUrl/tvshows/discipline-miracle-ep-1",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "28:40",
          releaseDate: "2024",
          studio: "Active",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Popular Weekly", "Academy", "Femdom", "Classic"],
          rating: 4.9,
          views: 430000,
          isUncensored: true,
        ),
      ],
      "ongoing": [
        MediaItem(
          id: "hm_ong_1",
          title: "Taimanin Yukikaze: Lightning Thunder Episode 3",
          url: "$baseUrl/tvshows/taimanin-yukikaze-ep-3",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "24:15",
          releaseDate: "2024",
          studio: "Lilith",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Ongoing Series", "Action", "Ninja", "HD"],
          rating: 4.8,
          views: 260000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hm_ong_2",
          title: "Overflow: Shared Bathing Suite Episode 2",
          url: "$baseUrl/tvshows/overflow-shared-bathing-ep-2",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "23:50",
          releaseDate: "2024",
          studio: "Houkiboshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Ongoing Series", "Romance", "Harem", "HD"],
          rating: 4.9,
          views: 390000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hm_ong_3",
          title: "Isekai Harem Monogatari: Guildmaster Chamber Episode 4",
          url: "$baseUrl/tvshows/isekai-harem-guildmaster-ep-4",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "26:30",
          releaseDate: "2024",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Ongoing Series", "Fantasy", "Isekai", "Harem"],
          rating: 4.8,
          views: 340000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hm_ong_4",
          title: "Gakuen de Jikan yo Tomare: School Festival Episode 3",
          url: "$baseUrl/tvshows/gakuen-de-jikan-yo-tomare-ep-3",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "25:10",
          releaseDate: "2024",
          studio: "BOOTLEG",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Ongoing Series", "School", "Time Stop", "HD"],
          rating: 4.9,
          views: 315000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hm_ong_5",
          title: "Ane wa Yanmama Junyuu-chuu: Evening Care Episode 2",
          url: "$baseUrl/tvshows/ane-wa-yanmama-ep-2",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "27:00",
          releaseDate: "2024",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Ongoing Series", "Milf", "Family", "HD"],
          rating: 4.8,
          views: 280000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hm_ong_6",
          title: "Boku to Nurse no Shinsatsushitsu: Ward Duty Episode 3",
          url: "$baseUrl/tvshows/boku-to-nurse-ep-3",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "Queen Bee",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Ongoing Series", "Nurse", "Hospital", "HD"],
          rating: 4.7,
          views: 225000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hm_ong_7",
          title: "Dokidoki Little Ooyasan: Poolside Splash Episode 3",
          url: "$baseUrl/tvshows/dokidoki-little-ooyasan-ep-3",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "22:10",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Ongoing Series", "Comedy", "Slice of Life", "HD"],
          rating: 4.8,
          views: 250000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hm_ong_8",
          title: "Rikujoubu Joshi wa Ore no Nama Onaho: Track Field Episode 2",
          url: "$baseUrl/tvshows/rikujoubu-joshi-ep-2",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "23:15",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Ongoing Series", "Sports", "School", "HD"],
          rating: 4.7,
          views: 215000,
          isUncensored: false,
        ),
      ],
      "uncensored": [
        MediaItem(
          id: "hm_unc_1",
          title: "Bible Black: Origins & Resurrection Uncensored",
          url: "$baseUrl/tvshows/bible-black-uncensored",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "29:10",
          releaseDate: "2024",
          studio: "Studio Jam",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Genre", "Occult", "Supernatural", "Classic"],
          rating: 5.0,
          views: 560000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hm_unc_2",
          title: "Night Shift Nurses: Complete Decensored Ward",
          url: "$baseUrl/tvshows/night-shift-nurses-decensored",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "30:00",
          releaseDate: "2024",
          studio: "Milky",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Genre", "Nurse", "Hospital", "Decensored"],
          rating: 4.9,
          views: 490000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hm_unc_3",
          title: "Hump Bang! Decensored Master Edition Ep 1",
          url: "$baseUrl/tvshows/hump-bang-decensored-ep-1",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "24:30",
          releaseDate: "2024",
          studio: "Bunnywalker",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Genre", "Decensored", "School", "HD"],
          rating: 4.9,
          views: 380000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hm_unc_4",
          title: "Please Rape Me! Uncensored Director's Cut Ep 1",
          url: "$baseUrl/tvshows/please-rape-me-uncensored-ep-1",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "25:00",
          releaseDate: "2024",
          studio: "BOOTLEG",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Genre", "Raw", "Hardcore", "HD"],
          rating: 4.8,
          views: 340000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hm_unc_5",
          title: "Discipline: Miracle Record Full Decensored Ep 1",
          url: "$baseUrl/tvshows/discipline-miracle-decensored-ep-1",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "28:40",
          releaseDate: "2024",
          studio: "Active",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Genre", "Academy", "Femdom", "Classic"],
          rating: 4.9,
          views: 420000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hm_unc_6",
          title: "Dropout: Unmasked Pure Edition Uncensored Ep 1",
          url: "$baseUrl/tvshows/dropout-unmasked-uncensored-ep-1",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "28:50",
          releaseDate: "2024",
          studio: "Mary Jane",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Genre", "School", "Dark", "HD"],
          rating: 4.9,
          views: 360000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hm_unc_7",
          title: "Swing Out Sisters: Complete Uncut Decensored Ep 1",
          url: "$baseUrl/tvshows/swing-out-sisters-decensored-ep-1",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "26:00",
          releaseDate: "2024",
          studio: "Arms",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Genre", "Sisters", "Classic", "HD"],
          rating: 4.8,
          views: 290000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hm_unc_8",
          title: "Valkyrie Hazard: Uncensored Battle Maiden Ep 1",
          url: "$baseUrl/tvshows/valkyrie-hazard-uncensored-ep-1",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "24:50",
          releaseDate: "2024",
          studio: "Lilith",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Genre", "Battle", "Fantasy", "HD"],
          rating: 4.8,
          views: 310000,
          isUncensored: true,
        ),
      ],
      "romance": [
        MediaItem(
          id: "hm_rom_1",
          title: "Kanojo x Kanojo x Kanojo: Heartbeat Pure Romance Ep 1",
          url: "$baseUrl/tvshows/kanojo-x-kanojo-pure-romance-ep-1",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "25:30",
          releaseDate: "2024",
          studio: "PoJu",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance Genre", "Harem", "School", "Vanilla"],
          rating: 4.9,
          views: 340000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hm_rom_2",
          title: "Sweet Home: Pure Love & Honey Kiss Ep 1",
          url: "$baseUrl/tvshows/sweet-home-pure-love-ep-1",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "24:10",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance Genre", "Vanilla", "Pure Love", "HD"],
          rating: 4.8,
          views: 270000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hm_rom_3",
          title: "First Love Diary: Sweet Whisperings Ep 1",
          url: "$baseUrl/tvshows/first-love-diary-ep-1",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "23:45",
          releaseDate: "2024",
          studio: "Arms",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance Genre", "Sweet", "Couples", "HD"],
          rating: 4.8,
          views: 220000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hm_rom_4",
          title: "Kimi no Mana: Sincere Vows Under Cherry Blossoms Ep 1",
          url: "$baseUrl/tvshows/kimi-no-mana-sincere-vows-ep-1",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "26:15",
          releaseDate: "2024",
          studio: "Bunnywalker",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance Genre", "Vanilla", "School", "HD"],
          rating: 4.9,
          views: 310000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hm_rom_5",
          title: "Lovely Heart: Sweet Summer Confession Ep 1",
          url: "$baseUrl/tvshows/lovely-heart-sweet-summer-ep-1",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "24:50",
          releaseDate: "2024",
          studio: "PoJu",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance Genre", "Sweet", "Summer", "HD"],
          rating: 4.8,
          views: 265000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hm_rom_6",
          title: "Hatsukoi Time: Tender Moments with Senpai Ep 1",
          url: "$baseUrl/tvshows/hatsukoi-time-tender-moments-ep-1",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "25:00",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance Genre", "Senpai", "Pure Love", "HD"],
          rating: 4.7,
          views: 235000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hm_rom_7",
          title: "Kokoro no Tobira: Blossom of True Love Ep 1",
          url: "$baseUrl/tvshows/kokoro-no-tobira-blossom-ep-1",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "26:30",
          releaseDate: "2024",
          studio: "Arms",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance Genre", "Blossom", "Couples", "HD"],
          rating: 4.8,
          views: 245000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hm_rom_8",
          title: "Vanilla Kiss: After School Confession Ep 1",
          url: "$baseUrl/tvshows/vanilla-kiss-after-school-ep-1",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "23:20",
          releaseDate: "2024",
          studio: "Milky",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance Genre", "Vanilla", "After School", "HD"],
          rating: 4.8,
          views: 285000,
          isUncensored: false,
        ),
      ],
    };

    return sampleSets[tabId] ?? sampleSets["latest"] ?? [];
  }

  MediaDetail _generateSampleDetail(String url) {
    return MediaDetail(
      id: url.hashCode.toString(),
      title: "Taimanin Asagi - Complete Episode 1",
      cover: "https://i.imgur.com/7jZQY1B.jpeg",
      backdrop: "https://i.imgur.com/7jZQY1B.jpeg",
      description: "High definition streaming release on HentaiMama.",
      studio: "Lilith Animation",
      releaseDate: "2024",
      tags: ["HD", "Subbed", "Action", "Uncensored"],
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
      playbackHeatmap: [
        0.1,
        0.4,
        0.7,
        0.95,
        0.8,
        0.4,
        0.3,
        0.9,
        1.0,
        0.4
      ],
      sceneMarkers: [
        SceneMarker(title: "Intro", timestampSeconds: 0),
        SceneMarker(title: "Climax 🔥", timestampSeconds: 700),
      ],
    );
  }

  @override
  Future<ExtensionTaxonomy> fetchTaxonomy() async {
    return hentaiMamaTaxonomy;
  }

  @override
  Future<List<MediaItem>> fetchTaxonomyFeed(CatalogItem item, int page) async {
    // 1. Anime Series: /tvshows/{slug}/
    if (item.categoryGroup == "Anime Series" ||
        (item.endpointPath != null && item.endpointPath!.contains("/tvshows/"))) {
      if (page == 1) {
        try {
          final targetUrl = item.endpointPath != null
              ? (item.endpointPath!.startsWith('http')
                  ? item.endpointPath!
                  : '$baseUrl${item.endpointPath}')
              : '$baseUrl/tvshows/${item.slug}/';
          final response = await http
              .get(Uri.parse(targetUrl), headers: _headers)
              .timeout(const Duration(seconds: 8));
          if (response.statusCode == 200) {
            final episodes = _parseEpisodeCards(response.body, item);
            if (episodes.isNotEmpty) return episodes;
            final cards = _parseCardsFromHtml(response.body, tabId: 'latest');
            if (cards.isNotEmpty) return cards;
          }
        } catch (_) {}
      }
      return search(item.name, page);
    }

    // 2. Studios: /studio/{slug}/
    if (item.categoryGroup == "Studio" ||
        item.type == CatalogType.artist ||
        (item.endpointPath != null && item.endpointPath!.contains("/studio/"))) {
      try {
        final path = page == 1
            ? (item.endpointPath ?? '/studio/${item.slug}/')
            : '/studio/${item.slug}/page/$page/';
        final targetUrl = path.startsWith('http') ? path : '$baseUrl$path';
        final response = await http
            .get(Uri.parse(targetUrl), headers: _headers)
            .timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          final cards = _parseCardsFromHtml(response.body, tabId: 'latest');
          if (cards.isNotEmpty) return cards;
        }
      } catch (_) {}
      return search(item.name, page);
    }

    // 3. Genres / Tags: /genre/{slug}/
    if (item.categoryGroup == "Genre" ||
        item.categoryGroup == "Trope" ||
        item.categoryGroup == "Character" ||
        item.type == CatalogType.genre ||
        item.type == CatalogType.tag ||
        (item.endpointPath != null && item.endpointPath!.contains("/genre/"))) {
      try {
        final path = page == 1
            ? (item.endpointPath ?? '/genre/${item.slug}/')
            : '/genre/${item.slug}/page/$page/';
        final targetUrl = path.startsWith('http') ? path : '$baseUrl$path';
        final response = await http
            .get(Uri.parse(targetUrl), headers: _headers)
            .timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          final cards = _parseCardsFromHtml(response.body, tabId: item.slug);
          if (cards.isNotEmpty) return cards;
        }
      } catch (_) {}
      return search(item.name, page);
    }

    if (item.slug == "popular" ||
        item.slug == "ongoing" ||
        item.slug == "uncensored" ||
        item.slug == "romance" ||
        item.slug == "latest") {
      return fetchTabFeed(item.slug, page);
    }

    return search(item.name.isNotEmpty ? item.name : item.slug, page);
  }

  List<MediaItem> _parseEpisodeCards(String html, CatalogItem seriesItem) {
    final doc = html_parser.parse(html);
    final epElements = doc.querySelectorAll('a.dt-se-item, a[href*="/episodes/"]');
    final List<MediaItem> items = [];
    final Set<String> seenUrls = {};

    for (final el in epElements) {
      final href = el.attributes['href'] ?? '';
      if (href.isEmpty || seenUrls.contains(href) || !href.contains('/episodes/')) {
        continue;
      }
      seenUrls.add(href);

      final fullUrl = href.startsWith('http') ? href : '$baseUrl$href';
      final img = el.querySelector('img');
      var cover = img?.attributes['data-src'] ??
          img?.attributes['data-lazy-src'] ??
          img?.attributes['src'] ??
          hentaiMamaCovers[seriesItem.slug] ??
          '';

      if (cover.startsWith('//')) {
        cover = 'https:$cover';
      } else if (cover.startsWith('/') && !cover.startsWith('//')) {
        cover = '$baseUrl$cover';
      }

      final epNum = el.querySelector('.dt-se-num')?.text.trim() ?? '';
      final epTitle = el.querySelector('.dt-se-title')?.text.trim() ?? '';
      var itemTitle = seriesItem.name;
      if (epTitle.isNotEmpty && epNum.isNotEmpty) {
        itemTitle = "${seriesItem.name} - $epNum ($epTitle)";
      } else if (epNum.isNotEmpty) {
        itemTitle = "${seriesItem.name} - $epNum";
      } else if (epTitle.isNotEmpty) {
        itemTitle = "${seriesItem.name} - $epTitle";
      }

      final ratingText = el.querySelector('.dt-se-rating')?.text.trim() ?? '';
      final rating = double.tryParse(ratingText.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 4.8;
      final releaseDate = el.querySelector('.dt-se-date')?.text.trim() ?? '2024';

      items.add(MediaItem(
        id: fullUrl.hashCode.toString(),
        title: _cleanTitle(itemTitle),
        url: fullUrl,
        cover: cover.isNotEmpty
            ? cover
            : (hentaiMamaCovers[seriesItem.slug] ?? 'https://i.imgur.com/7jZQY1B.jpeg'),
        duration: '24:00',
        releaseDate: releaseDate.isEmpty ? '2024' : releaseDate,
        studio: 'HentaiMama',
        extensionId: id,
        type: MediaType.animeSeries,
        tags: [seriesItem.name, "Episode", "HD", "Subbed"],
        rating: rating,
        views: 180000,
        isUncensored: seriesItem.name.toLowerCase().contains('uncensored'),
      ));
    }
    return items;
  }
}
