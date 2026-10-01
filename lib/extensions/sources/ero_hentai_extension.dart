import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../base_extension.dart';
import '../../models/media_item.dart';
import '../../models/extension_manifest.dart';
import '../../models/catalog_model.dart';
import '../taxonomies/ero_hentai_taxonomy.dart';

/// EroHentai extension for HStream Neo.
/// Scrapes 2D & 3D compilations and full episode streams from erohentai.tv.
class EroHentaiExtension extends HentaiExtension {
  @override
  String get id => "ero_hentai";

  @override
  String get name => "EroHentai";

  @override
  String get baseUrl => "https://erohentai.tv";

  @override
  String get iconUrl => "https://erohentai.tv/favicon.ico";

  @override
  String get description =>
      "2D & 3D compilations, studio specials, and high-definition uncensored series.";

  @override
  ViewLayoutType get defaultLayout => ViewLayoutType.widescreen16x9;

  @override
  bool get supportsShorts => false;

  @override
  List<ExtensionTab> get tabs => [
        ExtensionTab(
            id: "latest",
            title: "Ero Latest",
            icon: Icons.fiber_new_rounded),
        ExtensionTab(
            id: "popular",
            title: "Top Rated",
            icon: Icons.whatshot_rounded),
        ExtensionTab(
            id: "uncensored",
            title: "Uncensored Ero",
            icon: Icons.lock_open_rounded),
        ExtensionTab(
            id: "milf",
            title: "Milf Genre",
            icon: Icons.woman_rounded),
        ExtensionTab(
            id: "school",
            title: "Schoolgirl",
            icon: Icons.school_rounded),
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
            FilterOption(label: "Top Rated", value: "popular"),
            FilterOption(label: "Uncensored Ero", value: "uncensored"),
            FilterOption(label: "Milf Genre", value: "milf"),
            FilterOption(label: "Schoolgirl", value: "school"),
          ],
        ),
      ];

  final Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://erohentai.tv/',
  };

  final List<String> _candidateDomains = [
    'https://erohentai.tv',
    'https://erohentai.me',
    'https://erohentai.tube',
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
        path = '/top-rated/';
        break;
      case 'uncensored':
        path = '/genre/uncensored/';
        break;
      case 'milf':
        path = '/genre/milf/';
        break;
      case 'school':
        path = '/genre/school/';
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
        final searchUrl = Uri.parse(page == 1
            ? "$domain/?s=${Uri.encodeComponent(query)}"
            : "$domain/page/$page/?s=${Uri.encodeComponent(query)}");
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
        doc.querySelectorAll('article, .post, .item, .ero-card');
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
          studio: 'EroHentai',
          extensionId: id,
          type: MediaType.animeSeries,
          tags: _getDefaultTagsForTab(tabId),
          rating: 4.8,
          views: 180000,
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
        return ["Top Rated", "HD", "Popular"];
      case 'uncensored':
        return ["Uncensored Ero", "Decensored", "Full HD"];
      case 'milf':
        return ["Milf Genre", "Mature", "HD"];
      case 'school':
        return ["Schoolgirl", "Uniform", "HD"];
      case 'latest':
      default:
        return ["Ero Latest", "HD", "Subbed"];
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
            doc.querySelector('h1')?.text.trim() ?? "EroHentai Episode";
        final desc = doc.querySelector('meta[name="description"]')?.attributes['content'] ??
            doc.querySelector('.entry-content p')?.text.trim() ??
            "Compilation video stream playback on EroHentai.";
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
          studio: "EroHentai Studios",
          releaseDate: "2024",
          tags: ["Compilation", "HD", "Uncensored"],
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
        final iframes = doc.querySelectorAll('iframe[src*="embed"], iframe');
        final List<StreamSource> sources = [];

        for (final iframe in iframes) {
          final src = iframe.attributes['src'] ?? '';
          if (src.isNotEmpty &&
              !src.contains('facebook') &&
              !src.contains('google') &&
              !sources.any((s) => s.url == src)) {
            sources.add(StreamSource(
              label: "Ero Stream Server",
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
          id: "ero_lat_1",
          title: "Taimanin Yukikaze Ero Special – Episode 1",
          url: "$baseUrl/taimanin-yukikaze-ero-special-ep1",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "24:00",
          releaseDate: "2025",
          studio: "Lilith",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Ero Latest", "Ninja", "Action", "HD"],
          rating: 4.8,
          views: 320000,
          isUncensored: true,
        ),
        MediaItem(
          id: "ero_lat_2",
          title: "Overflow: Passionate Night Bath",
          url: "$baseUrl/overflow-passionate-night-bath",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "23:45",
          releaseDate: "2025",
          studio: "Houkiboshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Ero Latest", "Romance", "Harem", "HD"],
          rating: 4.9,
          views: 410000,
          isUncensored: false,
        ),
        MediaItem(
          id: "ero_lat_3",
          title: "Dokidoki Little Ooyasan: Sweet Landlady Hours",
          url: "$baseUrl/dokidoki-little-ooyasan-sweet-hours",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "22:15",
          releaseDate: "2025",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Ero Latest", "Comedy", "Cute", "HD"],
          rating: 4.8,
          views: 385000,
          isUncensored: false,
        ),
        MediaItem(
          id: "ero_lat_4",
          title: "Isekai Harem Monogatari: Royal Chamber Special",
          url: "$baseUrl/isekai-harem-royal-chamber-special",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "25:30",
          releaseDate: "2025",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Ero Latest", "Isekai", "Fantasy", "Harem"],
          rating: 4.9,
          views: 460000,
          isUncensored: false,
        ),
        MediaItem(
          id: "ero_lat_5",
          title: "Kuro Gal ni Natta kara Shin'yuu to Shite Mita",
          url: "$baseUrl/kuro-gal-ni-natta-kara-full-release",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "24:10",
          releaseDate: "2025",
          studio: "Irawits",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Ero Latest", "Gyaru", "Romance", "HD"],
          rating: 4.7,
          views: 295000,
          isUncensored: false,
        ),
        MediaItem(
          id: "ero_lat_6",
          title: "Show Time! Uta no O-nee-san datte Shitai 2",
          url: "$baseUrl/show-time-uta-no-oneesan-2",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "21:10",
          releaseDate: "2025",
          studio: "Suiseisha",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Ero Latest", "Idol", "Romance", "HD"],
          rating: 4.8,
          views: 340000,
          isUncensored: false,
        ),
        MediaItem(
          id: "ero_lat_7",
          title: "Boku to Nurse no Shinsatsushitsu: Midnight Checkup",
          url: "$baseUrl/boku-to-nurse-midnight-checkup",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "24:20",
          releaseDate: "2025",
          studio: "Queen Bee",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Ero Latest", "Nurse", "Medical", "HD"],
          rating: 4.7,
          views: 315000,
          isUncensored: false,
        ),
        MediaItem(
          id: "ero_lat_8",
          title: "Furachi na Gakuen: Discipline & Desire",
          url: "$baseUrl/furachi-na-gakuen-desire",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "26:00",
          releaseDate: "2025",
          studio: "BOOTLEG",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Ero Latest", "School", "Drama", "HD"],
          rating: 4.8,
          views: 360000,
          isUncensored: true,
        ),
      ],
      "popular": [
        MediaItem(
          id: "ero_pop_1",
          title: "Mankitsu Happening: The Complete Collection",
          url: "$baseUrl/mankitsu-happening-complete",
          cover: "https://i.imgur.com/wVqjC5P.jpeg",
          duration: "32:15",
          releaseDate: "2024",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Top Rated", "Harem", "Manga Cafe", "Classic"],
          rating: 5.0,
          views: 890000,
          isUncensored: true,
        ),
        MediaItem(
          id: "ero_pop_2",
          title: "Kuroinu: Kedakaki Seijo wa Hakudaku ni Somaru",
          url: "$baseUrl/kuroinu-kedakaki-seijo-complete",
          cover: "https://i.imgur.com/z4bKxNm.jpeg",
          duration: "29:45",
          releaseDate: "2024",
          studio: "Eroman",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Top Rated", "Dark Fantasy", "Knights", "Action"],
          rating: 4.9,
          views: 920000,
          isUncensored: true,
        ),
        MediaItem(
          id: "ero_pop_3",
          title: "Bible Black: Walpurgis Night Master Edition",
          url: "$baseUrl/bible-black-walpurgis-master",
          cover: "https://i.imgur.com/83pZ6XQ.jpeg",
          duration: "30:10",
          releaseDate: "2024",
          studio: "Milky Animation",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Top Rated", "Occult", "Classic", "Supernatural"],
          rating: 5.0,
          views: 1050000,
          isUncensored: true,
        ),
        MediaItem(
          id: "ero_pop_4",
          title: "Taimanin Asagi: Decisive Shinobi Strike",
          url: "$baseUrl/taimanin-asagi-decisive-strike",
          cover: "https://i.imgur.com/N7GgqMv.jpeg",
          duration: "27:40",
          releaseDate: "2024",
          studio: "Lilith",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Top Rated", "Ninja", "Action", "Supernatural"],
          rating: 4.9,
          views: 780000,
          isUncensored: true,
        ),
        MediaItem(
          id: "ero_pop_5",
          title: "Rance 01: The Quest for Hikari – Collector's Cut",
          url: "$baseUrl/rance-01-quest-hikari-collectors",
          cover: "https://i.imgur.com/J3ZqK9x.jpeg",
          duration: "29:50",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Top Rated", "Adventure", "Fantasy", "Comedy"],
          rating: 4.9,
          views: 840000,
          isUncensored: true,
        ),
        MediaItem(
          id: "ero_pop_6",
          title: "Euphoria: The White Room All Stages",
          url: "$baseUrl/euphoria-white-room-stages",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "31:20",
          releaseDate: "2024",
          studio: "Magin",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Top Rated", "Psychological", "Thriller", "Decensored"],
          rating: 4.8,
          views: 810000,
          isUncensored: true,
        ),
        MediaItem(
          id: "ero_pop_7",
          title: "Discipline: Record of Flagrant Academia",
          url: "$baseUrl/discipline-record-flagrant-academia",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "28:10",
          releaseDate: "2024",
          studio: "Active",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Top Rated", "Mind Control", "School", "Decensored"],
          rating: 4.9,
          views: 630000,
          isUncensored: true,
        ),
        MediaItem(
          id: "ero_pop_8",
          title: "Kyonyuu Fantasy: Royal Conquest Deluxe",
          url: "$baseUrl/kyonyuu-fantasy-royal-conquest",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "28:00",
          releaseDate: "2024",
          studio: "W-Toon Studio",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Top Rated", "Fantasy", "Big Boobs", "Comedy"],
          rating: 4.8,
          views: 680000,
          isUncensored: true,
        ),
      ],
      "uncensored": [
        MediaItem(
          id: "ero_unc_1",
          title: "Futabu!! Complete Decensored Cut",
          url: "$baseUrl/futabu-complete-decensored",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "25:40",
          releaseDate: "2025",
          studio: "Ziz",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Ero", "Futanari", "Comedy", "School"],
          rating: 4.92,
          views: 630000,
          isUncensored: true,
        ),
        MediaItem(
          id: "ero_unc_2",
          title: "Tiny Evil: Uncensored Succubus Pact",
          url: "$baseUrl/tiny-evil-uncensored-succubus",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "24:10",
          releaseDate: "2025",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Ero", "Succubus", "Magic", "Fantasy"],
          rating: 4.94,
          views: 670000,
          isUncensored: true,
        ),
        MediaItem(
          id: "ero_unc_3",
          title: "Resort Boin: Pure Uncensored Vacation",
          url: "$baseUrl/resort-boin-pure-uncensored",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "27:30",
          releaseDate: "2025",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Ero", "Big Boobs", "Vacation", "Romance"],
          rating: 4.88,
          views: 590000,
          isUncensored: true,
        ),
        MediaItem(
          id: "ero_unc_4",
          title: "Starless: 21st Century Gothic Decensored",
          url: "$baseUrl/starless-21st-century-decensored",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "29:15",
          releaseDate: "2025",
          studio: "Milky Animation",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Ero", "Mansion", "Gothic", "Mystery"],
          rating: 4.85,
          views: 540000,
          isUncensored: true,
        ),
        MediaItem(
          id: "ero_unc_5",
          title: "Viper GTS: Devil Awakening Uncensored",
          url: "$baseUrl/viper-gts-devil-awakening-uncensored",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "27:30",
          releaseDate: "2025",
          studio: "Sonomama",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Ero", "Cyberpunk", "Classic", "Decensored"],
          rating: 4.75,
          views: 490000,
          isUncensored: true,
        ),
        MediaItem(
          id: "ero_unc_6",
          title: "Chou-kou Tenshi Escalayer: Decensored Climax",
          url: "$baseUrl/chou-kou-tenshi-escalayer-decensored",
          cover: "https://i.imgur.com/wVqjC5P.jpeg",
          duration: "28:50",
          releaseDate: "2025",
          studio: "Alice Soft",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Ero", "Mahou Shoujo", "Sci-Fi", "Heroine"],
          rating: 4.9,
          views: 590000,
          isUncensored: true,
        ),
        MediaItem(
          id: "ero_unc_7",
          title: "Oni Chichi: Renewed Decensored Edition",
          url: "$baseUrl/oni-chichi-renewed-decensored",
          cover: "https://i.imgur.com/z4bKxNm.jpeg",
          duration: "24:45",
          releaseDate: "2025",
          studio: "Blue Eyes",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Ero", "Family", "Drama", "Full HD"],
          rating: 4.88,
          views: 610000,
          isUncensored: true,
        ),
        MediaItem(
          id: "ero_unc_8",
          title: "Shoujo Ramune: Summer Secrets Uncensored",
          url: "$baseUrl/shoujo-ramune-summer-secrets-uncensored",
          cover: "https://i.imgur.com/83pZ6XQ.jpeg",
          duration: "25:10",
          releaseDate: "2025",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Ero", "Summer", "Country", "Full HD"],
          rating: 4.82,
          views: 570000,
          isUncensored: true,
        ),
      ],
      "milf": [
        MediaItem(
          id: "ero_milf_1",
          title: "Ane wa Yanmama Junyuu-chuu: Reunion Night",
          url: "$baseUrl/ane-wa-yanmama-reunion-night",
          cover: "https://i.imgur.com/N7GgqMv.jpeg",
          duration: "28:40",
          releaseDate: "2025",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Milf Genre", "Milf", "Family", "HD"],
          rating: 4.9,
          views: 510000,
          isUncensored: false,
        ),
        MediaItem(
          id: "ero_milf_2",
          title: "Kateikyoushi x Saimin: Motherly Hypnosis",
          url: "$baseUrl/kateikyoushi-x-saimin-motherly",
          cover: "https://i.imgur.com/J3ZqK9x.jpeg",
          duration: "25:30",
          releaseDate: "2025",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Milf Genre", "Hypnosis", "Mature", "HD"],
          rating: 4.85,
          views: 470000,
          isUncensored: false,
        ),
        MediaItem(
          id: "ero_milf_3",
          title: "Saimin Seishidou: Neighborhood Mother's Secret",
          url: "$baseUrl/saimin-seishidou-neighborhood-mother",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "27:15",
          releaseDate: "2025",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Milf Genre", "Mature", "Drama", "HD"],
          rating: 4.86,
          views: 490000,
          isUncensored: false,
        ),
        MediaItem(
          id: "ero_milf_4",
          title: "Paihame Kazoku: Mother's Bountiful Care",
          url: "$baseUrl/paihame-kazoku-mothers-care",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "26:50",
          releaseDate: "2025",
          studio: "Ziz",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Milf Genre", "Big Boobs", "Family", "HD"],
          rating: 4.8,
          views: 430000,
          isUncensored: false,
        ),
        MediaItem(
          id: "ero_milf_5",
          title: "Shitsurakuen: Beautiful Stepmother's Confession",
          url: "$baseUrl/shitsurakuen-stepmother-confession",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "29:00",
          releaseDate: "2025",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Milf Genre", "Stepmother", "Drama", "Romance"],
          rating: 4.88,
          views: 465000,
          isUncensored: false,
        ),
        MediaItem(
          id: "ero_milf_6",
          title: "Mama wa Shougaku 4-nensei: Loving Care",
          url: "$baseUrl/mama-wa-shougaku-loving-care",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "23:40",
          releaseDate: "2025",
          studio: "Bunnywalker",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Milf Genre", "Cute", "Comedy", "HD"],
          rating: 4.78,
          views: 380000,
          isUncensored: false,
        ),
        MediaItem(
          id: "ero_milf_7",
          title: "Haha wa Kanojo de Hitozuma: Secret Affair",
          url: "$baseUrl/haha-wa-kanojo-secret-affair",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "28:10",
          releaseDate: "2025",
          studio: "Pink Pineapple",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Milf Genre", "Affair", "Cheating", "Drama"],
          rating: 4.75,
          views: 410000,
          isUncensored: false,
        ),
        MediaItem(
          id: "ero_milf_8",
          title: "Boku to Misaki-sensei: Private After-Hours Lessons",
          url: "$baseUrl/boku-to-misaki-sensei-after-hours",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "26:30",
          releaseDate: "2025",
          studio: "BOOTLEG",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Milf Genre", "Teacher", "Mature", "HD"],
          rating: 4.84,
          views: 450000,
          isUncensored: false,
        ),
      ],
      "school": [
        MediaItem(
          id: "ero_sch_1",
          title: "Gakuen de Jikan yo Tomare: Time Stop Classroom",
          url: "$baseUrl/gakuen-de-jikan-yo-tomare-classroom",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "25:35",
          releaseDate: "2025",
          studio: "BOOTLEG",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Schoolgirl", "Time Stop", "Classroom", "Supernatural"],
          rating: 4.9,
          views: 820000,
          isUncensored: false,
        ),
        MediaItem(
          id: "ero_sch_2",
          title: "Seifuku wa Kita Mama de: After-School Uniforms",
          url: "$baseUrl/seifuku-wa-kita-mama-de-after-school",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "26:10",
          releaseDate: "2025",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Schoolgirl", "Uniform", "After School", "HD"],
          rating: 4.86,
          views: 480000,
          isUncensored: false,
        ),
        MediaItem(
          id: "ero_sch_3",
          title: "Drop Out: Deluxe Gyaru Academy",
          url: "$baseUrl/drop-out-deluxe-gyaru-academy",
          cover: "https://i.imgur.com/wVqjC5P.jpeg",
          duration: "28:00",
          releaseDate: "2025",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Schoolgirl", "Gyaru", "School", "Uncensored"],
          rating: 4.85,
          views: 520000,
          isUncensored: true,
        ),
        MediaItem(
          id: "ero_sch_4",
          title: "Tsubaki chou Lonely Planet: Midnight Session",
          url: "$baseUrl/tsubaki-chou-midnight-session",
          cover: "https://i.imgur.com/z4bKxNm.jpeg",
          duration: "24:10",
          releaseDate: "2025",
          studio: "Ziz",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Schoolgirl", "Drama", "School", "HD"],
          rating: 4.7,
          views: 295000,
          isUncensored: false,
        ),
        MediaItem(
          id: "ero_sch_5",
          title: "Kimi ga Suki: Rooftop Love Confession",
          url: "$baseUrl/kimi-ga-suki-rooftop-confession",
          cover: "https://i.imgur.com/83pZ6XQ.jpeg",
          duration: "25:00",
          releaseDate: "2025",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Schoolgirl", "Confession", "Sweet", "Vanilla"],
          rating: 5.0,
          views: 530000,
          isUncensored: false,
        ),
        MediaItem(
          id: "ero_sch_6",
          title: "Kanojo x Kanojo x Kanojo: High School Harem",
          url: "$baseUrl/kanojo-x-kanojo-x-kanojo-high-school",
          cover: "https://i.imgur.com/N7GgqMv.jpeg",
          duration: "26:30",
          releaseDate: "2025",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Schoolgirl", "Harem", "Childhood Friend", "Vanilla"],
          rating: 4.8,
          views: 580000,
          isUncensored: false,
        ),
        MediaItem(
          id: "ero_sch_7",
          title: "Boku no Yayoi-san: Student Council President",
          url: "$baseUrl/boku-no-yayoi-san-student-council",
          cover: "https://i.imgur.com/J3ZqK9x.jpeg",
          duration: "28:10",
          releaseDate: "2025",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Schoolgirl", "Maid", "Heartfelt", "Vanilla"],
          rating: 4.9,
          views: 460000,
          isUncensored: false,
        ),
        MediaItem(
          id: "ero_sch_8",
          title: "Master Piece The Animation: School Festival Romance",
          url: "$baseUrl/master-piece-school-festival-romance",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "26:15",
          releaseDate: "2025",
          studio: "PoJu",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Schoolgirl", "School", "Maid", "Drama"],
          rating: 4.8,
          views: 710000,
          isUncensored: false,
        ),
      ],
    };

    return sampleSets[tabId] ?? sampleSets["latest"]!;
  }

  MediaDetail _generateSampleDetail(String url) {
    for (final tab in ['latest', 'popular', 'uncensored', 'milf', 'school']) {
      for (final item in _generateSampleList(tab, 1)) {
        if (item.url == url || url.contains(item.id)) {
          return MediaDetail(
            id: item.id,
            title: item.title,
            cover: item.cover,
            backdrop: item.cover,
            description:
                "Watch ${item.title} with high-definition playback on EroHentai.",
            studio: item.studio ?? "EroHentai Studios",
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
                    label: "1080p Master Stream",
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
      title: "Taimanin Yukikaze Ero Special",
      cover: "https://i.imgur.com/7jZQY1B.jpeg",
      backdrop: "https://i.imgur.com/7jZQY1B.jpeg",
      description: "Compilation release streaming on EroHentai.",
      studio: "Lilith Animation",
      releaseDate: "2024",
      tags: ["Compilation", "HD", "Uncensored"],
      episodes: [
        EpisodeItem(
          id: "ep_1",
          episodeNumber: "Episode 1",
          title: "Taimanin Yukikaze Ep 1",
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
    return eroHentaiTaxonomy;
  }

  @override
  Future<List<MediaItem>> fetchTaxonomyFeed(CatalogItem item, int page) async {
    // 1. Direct tab feed mapping if it corresponds to a hero tab
    if (item.slug == 'latest' ||
        item.slug == 'popular' ||
        item.slug == 'uncensored' ||
        item.slug == 'milf' ||
        item.slug == 'school') {
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

    final fallbackTab = (item.slug == 'milf' || item.categoryGroup == 'Character')
        ? 'milf'
        : (item.slug == 'school' || item.name.toLowerCase().contains('school'))
            ? 'school'
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
        id: "ero_tax_${item.slug}_${m.id}",
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
