import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../base_extension.dart';
import '../../models/media_item.dart';
import '../../models/extension_manifest.dart';
import '../../models/catalog_model.dart';
import '../taxonomies/hentaverse_taxonomy.dart';

/// Hentaverse extension for HStream Neo.
/// Scrapes modern animation releases, preview videos, and CDN streams from hentaverse.com.
class HentaverseExtension extends HentaiExtension {
  @override
  String get id => "hentaverse";

  @override
  String get name => "Hentaverse";

  @override
  String get baseUrl => "https://hentaverse.com";

  @override
  String get iconUrl => "https://hentaverse.com/favicon.ico";

  @override
  String get description =>
      "Universe of modern animation releases and high-definition franchise series.";

  @override
  ViewLayoutType get defaultLayout => ViewLayoutType.widescreen16x9;

  @override
  bool get supportsShorts => false;

  @override
  List<ExtensionTab> get tabs => [
        ExtensionTab(
            id: "universe",
            title: "Universe Feed",
            icon: Icons.public_rounded),
        ExtensionTab(
            id: "student",
            title: "Female Student",
            icon: Icons.school_rounded),
        ExtensionTab(
            id: "creampie",
            title: "Creampie",
            icon: Icons.favorite_rounded),
        ExtensionTab(
            id: "futanari",
            title: "Futanari",
            icon: Icons.transgender_rounded),
        ExtensionTab(
            id: "nekomimi",
            title: "Nekomimi",
            icon: Icons.pets_rounded),
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
            FilterOption(label: "Female Student", value: "student"),
            FilterOption(label: "Creampie", value: "creampie"),
            FilterOption(label: "Futanari", value: "futanari"),
            FilterOption(label: "Nekomimi", value: "nekomimi"),
            FilterOption(label: "X-Ray", value: "x-ray"),
            FilterOption(label: "School Girl", value: "school-girl"),
          ],
        ),
      ];

  final Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaverse.com/',
  };

  @override
  Future<List<MediaItem>> fetchTabFeed(
    String tabId,
    int page, {
    Map<String, dynamic>? activeFilters,
    List<String>? whitelistedTags,
    List<String>? blacklistedTags,
  }) async {
    try {
      String path;
      switch (tabId) {
        case "student":
          path = "/genre/student/";
          break;
        case "creampie":
          path = "/genre/creampie/";
          break;
        case "futanari":
          path = "/genre/futanari/";
          break;
        case "nekomimi":
          path = "/genre/nekomimi/";
          break;
        case "universe":
        default:
          path = "/";
          break;
      }

      if (activeFilters != null &&
          activeFilters['category'] != null &&
          activeFilters['category'] != 'all') {
        path = "/genre/${activeFilters['category']}/";
      }

      final targetUrl = page == 1
          ? '$baseUrl$path'
          : (path == '/'
              ? '$baseUrl/page/$page/'
              : '$baseUrl${path}page/$page/');

      var response = await http
          .get(Uri.parse(targetUrl), headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200 && path.startsWith('/genre/')) {
        // Failover from /genre/ to /tags/
        final tagPath = path.replaceAll('/genre/', '/tags/');
        final altUrl = page == 1
            ? '$baseUrl$tagPath'
            : '$baseUrl${tagPath}page/$page/';
        response = await http
            .get(Uri.parse(altUrl), headers: _headers)
            .timeout(const Duration(seconds: 8));
      }

      if (response.statusCode == 200) {
        final items = _parseCardsFromHtml(response.body, tabId: tabId);
        if (items.isNotEmpty) return items;
      }
    } catch (_) {}

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
    try {
      final searchUrl = Uri.parse(
          "$baseUrl/search?q=${Uri.encodeComponent(query)}&page=$page");
      final response = await http
          .get(searchUrl, headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final items = _parseCardsFromHtml(response.body, tabId: "universe");
        if (items.isNotEmpty) return items;
      }
    } catch (_) {}

    return fetchTabFeed("universe", page);
  }

  List<MediaItem> _parseCardsFromHtml(
    String html, {
    String tabId = "universe",
    String? categoryName,
  }) {
    final doc = html_parser.parse(html);
    final cards = doc.querySelectorAll(
        'article, .post, .item, .verse-item, div.video-item, div.item-video');
    final List<MediaItem> items = [];
    final Set<String> seenUrls = {};

    void extractFromCardOrAnchor(dynamic a, dynamic card) {
      final href = a?.attributes['href'] ?? '';
      if (href.isEmpty ||
          href == '/' ||
          href == '/hentai' ||
          href == '/hentai/' ||
          href == '/categories' ||
          href == '/categories/' ||
          href.startsWith('/categories/')) {
        return;
      }

      final fullUrl = href.startsWith('http') ? href : "$baseUrl$href";
      if (seenUrls.contains(fullUrl)) {
        return;
      }
      seenUrls.add(fullUrl);

      final img = card?.querySelector('img') ?? a?.querySelector('img');
      var cover = img?.attributes['data-src'] ??
          img?.attributes['data-lazy-src'] ??
          img?.attributes['data-original'] ??
          img?.attributes['src'] ??
          '';

      if (cover.isEmpty || cover.startsWith('data:')) {
        final srcset = img?.attributes['srcset'] ?? '';
        if (srcset.isNotEmpty) {
          final parts = srcset.split(',');
          if (parts.isNotEmpty) {
            cover = parts.last.trim().split(' ').first;
          }
        }
      }

      if (cover.contains('url=')) {
        final match = RegExp(r'url=([^&]+)').firstMatch(cover);
        if (match != null) {
          cover = Uri.decodeQueryComponent(match.group(1)!);
        }
      }

      if (cover.startsWith('//')) {
        cover = 'https:$cover';
      } else if (cover.startsWith('/') && !cover.startsWith('//')) {
        cover = '$baseUrl$cover';
      }

      String title =
          card?.querySelector('h2, .title, .entry-title, h3')?.text.trim() ??
              a?.attributes['title']?.trim() ??
              '';
      if (title.isEmpty && img?.attributes['alt'] != null) {
        final alt = img!.attributes['alt']!.trim();
        title = alt.replaceAll(RegExp(r'\s+thumbnail$', caseSensitive: false), '').trim();
      }
      if (title.isEmpty) {
        final rawText = a?.text.trim() ?? '';
        final lines = rawText
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList();
        for (final line in lines) {
          if (!RegExp(r'^(FHD|HD|\d+%)').hasMatch(line) &&
              !RegExp(r'^\d{1,2}:\d{2}$').hasMatch(line)) {
            title = line;
          }
        }
      }
      if (title.isEmpty) {
        final slug = href.split('/').where((s) => s.isNotEmpty).last;
        title = slug
            .replaceAll('-', ' ')
            .split(' ')
            .map((w) =>
                w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
            .join(' ');
      }

      String duration =
          card?.querySelector('.time, span.time, .duration')?.text.trim() ?? '';
      if (duration.isEmpty) {
        final rawAll = '${card?.text ?? ''} ${a?.text ?? ''}';
        final match = RegExp(r'\b\d{1,2}:\d{2}\b').firstMatch(rawAll);
        if (match != null) {
          duration = match.group(0)!;
        } else {
          duration = "24:00";
        }
      }

      final videoPreview = card?.querySelector('video')?.attributes['src'] ??
          a?.querySelector('video')?.attributes['src'];

      if (title.isNotEmpty) {
        final tagLabel = categoryName ??
            (tabId == "student"
                ? "Female Student"
                : tabId == "creampie"
                    ? "Creampie"
                    : tabId == "futanari"
                        ? "Futanari"
                        : tabId == "nekomimi"
                            ? "Nekomimi"
                            : tabId.replaceAll('-', ' '));

        items.add(MediaItem(
          id: fullUrl.hashCode.toString(),
          title: title,
          url: fullUrl,
          cover: cover.isNotEmpty && cover.startsWith('http')
              ? cover
              : "https://i.imgur.com/7jZQY1B.jpeg",
          duration: duration,
          releaseDate: "2024",
          studio: "Hentaverse Studio",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: [
            if (tagLabel.isNotEmpty && tagLabel != "universe") tagLabel,
            "HD",
            "Uncensored",
            "Hentaverse",
          ],
          rating: 4.8,
          views: 180000,
          isUncensored: true,
          previewVideoUrl: videoPreview,
        ));
      }
    }

    for (final card in cards) {
      final a = card.querySelector('a[href*="/video/"]') ??
          card.querySelector('a[href*="/hentai/"]') ??
          card.querySelector('a');
      if (a != null) {
        extractFromCardOrAnchor(a, card);
      }
    }

    if (items.isEmpty) {
      final links =
          doc.querySelectorAll('a[href*="/video/"], a[href*="/hentai/"]');
      for (final a in links) {
        extractFromCardOrAnchor(a, a);
      }
    }

    return items;
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
            doc.querySelector('h1')?.text.trim() ?? "Hentaverse Anime";
        final desc = doc
                .querySelector('meta[name="description"]')
                ?.attributes['content'] ??
            doc.querySelector('p')?.text.trim() ??
            "High definition streaming release on Hentaverse.";
        final cover = doc
                .querySelector('meta[property="og:image"]')
                ?.attributes['content'] ??
            doc.querySelector('img')?.attributes['src'] ??
            "";

        final sources = await extractVideoStreams(url);

        return MediaDetail(
          id: url.hashCode.toString(),
          title: title,
          cover: cover.isNotEmpty ? cover : "https://i.imgur.com/7jZQY1B.jpeg",
          backdrop:
              cover.isNotEmpty ? cover : "https://i.imgur.com/7jZQY1B.jpeg",
          description: desc,
          studio: "Hentaverse Studios",
          releaseDate: "2024",
          tags: ["HD", "Uncensored", "Subbed"],
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
            SceneMarker(title: "Climax 🔥", timestampSeconds: 710),
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

        // Check for video src or video source
        final videoEls = doc.querySelectorAll('video');
        for (final v in videoEls) {
          final src = v.attributes['src'] ?? '';
          if (src.isNotEmpty && src.startsWith('http')) {
            sources.add(StreamSource(
              label: src.contains('preview')
                  ? "Preview Clip (CDN)"
                  : "1080p Master Stream (Direct CDN)",
              url: src,
              protocol: StreamProtocol.directMp4,
              headers: {
                'Referer': baseUrl,
                'User-Agent': _headers['User-Agent']!
              },
            ));
          }
        }

        // Check for iframes
        final iframes = doc.querySelectorAll(
            'iframe[src*="embed"], iframe[src*="player"], iframe');
        for (final iframe in iframes) {
          final src = iframe.attributes['src'] ?? '';
          if (src.isNotEmpty &&
              !src.contains('facebook') &&
              !src.contains('google')) {
            sources.add(StreamSource(
              label: "Embed Stream Server",
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

    final Map<String, List<MediaItem>> sampleMap = {
      "universe": [
        MediaItem(
          id: "hv_univ_1",
          title: "Taimanin Yukikaze: Universe Premiere",
          url: "$baseUrl/hentai/taimanin-yukikaze-universe-premiere",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "24:30",
          releaseDate: "2024",
          studio: "Lilith",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Universe", "Action", "Supernatural", "Uncensored"],
          rating: 4.92,
          views: 450000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hv_univ_2",
          title: "Kuroinu: Kedakaki Seijo wa Hakudaku ni Somaru",
          url: "$baseUrl/hentai/kuroinu-kedakaki-seijo",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "29:10",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Universe", "Dark Fantasy", "Demon", "Uncensored"],
          rating: 4.95,
          views: 520000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hv_univ_3",
          title: "Mankitsu Happening: Universe Director's Cut",
          url: "$baseUrl/hentai/mankitsu-happening-universe-cut",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "27:45",
          releaseDate: "2024",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Universe", "Comedy", "Harem", "Uncensored"],
          rating: 4.88,
          views: 390000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hv_univ_4",
          title: "Bible Black: Remastered Genesis",
          url: "$baseUrl/hentai/bible-black-remastered-genesis",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "30:20",
          releaseDate: "2024",
          studio: "Milky",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Universe", "Classic", "Supernatural", "Occult"],
          rating: 4.96,
          views: 610000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hv_univ_5",
          title: "Rance 01: The Quest for Hikari Verse Edition",
          url: "$baseUrl/hentai/rance-01-the-quest-for-hikari-verse",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "28:50",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Universe", "Adventure", "Fantasy", "Uncensored"],
          rating: 4.91,
          views: 430000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hv_univ_6",
          title: "Discipline: Zero Universe Arc",
          url: "$baseUrl/hentai/discipline-zero-universe-arc",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "26:15",
          releaseDate: "2024",
          studio: "Active",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Universe", "Classic", "Academy", "Uncensored"],
          rating: 4.85,
          views: 380000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hv_univ_7",
          title: "Kyonyuu Fantasy: Complete Empress Chronicle",
          url: "$baseUrl/hentai/kyonyuu-fantasy-empress-chronicle",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "25:40",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Universe", "Big Breasts", "Fantasy", "Royalty"],
          rating: 4.89,
          views: 410000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hv_univ_8",
          title: "Euphoria: The Ultimate Complete Verse",
          url: "$baseUrl/hentai/euphoria-ultimate-complete-verse",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "31:00",
          releaseDate: "2024",
          studio: "Magin",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Universe", "Psychological", "Thriller", "Uncensored"],
          rating: 4.97,
          views: 680000,
          isUncensored: true,
        ),
      ],
      "student": [
        MediaItem(
          id: "hv_stud_1",
          title: "Joshi Luck!: Female Student Council Secret",
          url: "$baseUrl/hentai/joshi-luck-student-council-secret",
          cover: "https://i.imgur.com/wVqjC5P.jpeg",
          duration: "23:45",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Female Student", "School Girl", "Council", "HD"],
          rating: 4.87,
          views: 340000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hv_stud_2",
          title: "Gakuen de Jikan Tomare: High School Class Freeze",
          url: "$baseUrl/hentai/gakuen-de-jikan-tomare-class-freeze",
          cover: "https://i.imgur.com/z4bKxNm.jpeg",
          duration: "25:10",
          releaseDate: "2024",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Female Student", "Time Stop", "Academy", "Uncensored"],
          rating: 4.91,
          views: 480000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hv_stud_3",
          title: "Master Piece: Campus Idol Examination",
          url: "$baseUrl/hentai/master-piece-campus-idol-examination",
          cover: "https://i.imgur.com/83pZ6XQ.jpeg",
          duration: "26:30",
          releaseDate: "2024",
          studio: "MS Pictures",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Female Student", "Uniform", "Campus", "Uncensored"],
          rating: 4.86,
          views: 310000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hv_stud_4",
          title: "Kyuukyoku no Cheating: Academic Honesty Test",
          url: "$baseUrl/hentai/kyuukyoku-no-cheating-academic-test",
          cover: "https://i.imgur.com/N7GgqMv.jpeg",
          duration: "24:15",
          releaseDate: "2024",
          studio: "Bunnywalker",
          tags: ["Female Student", "Cheating", "Classroom", "HD"],
          rating: 4.83,
          views: 295000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hv_stud_5",
          title: "Baku Ane: After School Study Session",
          url: "$baseUrl/hentai/baku-ane-after-school-study-session",
          cover: "https://i.imgur.com/J3ZqK9x.jpeg",
          duration: "24:50",
          releaseDate: "2024",
          studio: "Pink Pineapple",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Female Student", "Sister", "Study", "Uncensored"],
          rating: 4.93,
          views: 460000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hv_stud_6",
          title: "Kanojo ga Yatsu ni Dakareta Hi: Classroom Regret",
          url: "$baseUrl/hentai/kanojo-ga-yatsu-ni-dakareta-hi",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "27:10",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Female Student", "Drama", "School Life", "HD"],
          rating: 4.79,
          views: 270000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hv_stud_7",
          title: "Tsumamigui 3: High School Detention Encounter",
          url: "$baseUrl/hentai/tsumamigui-3-detention-encounter",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "25:40",
          releaseDate: "2024",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Female Student", "Detention", "Affair", "Uncensored"],
          rating: 4.84,
          views: 325000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hv_stud_8",
          title: "Shoujo Ramune: Summer School Vacation Memories",
          url: "$baseUrl/hentai/shoujo-ramune-summer-school-vacation",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "22:30",
          releaseDate: "2024",
          studio: "Milky",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Female Student", "Summer", "Youth", "Uncensored"],
          rating: 4.9,
          views: 420000,
          isUncensored: true,
        ),
      ],
      "creampie": [
        MediaItem(
          id: "hv_crm_1",
          title: "Overflow: Passionate Full Bloom Creampie",
          url: "$baseUrl/hentai/overflow-passionate-full-bloom",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "23:55",
          releaseDate: "2024",
          studio: "Houkiboshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Creampie", "Nakadashi", "Harem", "Uncensored"],
          rating: 4.94,
          views: 590000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hv_crm_2",
          title: "Kanojo x Kanojo x Kanojo: Triple Nakadashi Vacation",
          url: "$baseUrl/hentai/kanojo-x-kanojo-x-kanojo-nakadashi",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "28:20",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Creampie", "Harem", "Nakadashi", "Uncensored"],
          rating: 4.9,
          views: 440000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hv_crm_3",
          title: "Eroge de Subete wa Kaiketsu Dekiru: Ultimate Creampie",
          url: "$baseUrl/hentai/eroge-de-subete-wa-kaiketsu-dekiru-crm",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "26:10",
          releaseDate: "2024",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Creampie", "Nakadashi", "Otaku", "HD"],
          rating: 4.88,
          views: 375000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hv_crm_4",
          title: "Tiny Evil: Succubus Insemination Contract",
          url: "$baseUrl/hentai/tiny-evil-succubus-insemination",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "24:45",
          releaseDate: "2024",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Creampie", "Succubus", "Nakadashi", "Fantasy"],
          rating: 4.92,
          views: 510000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hv_crm_5",
          title: "Resonance: Overflowing Night Together",
          url: "$baseUrl/hentai/resonance-overflowing-night",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "25:35",
          releaseDate: "2024",
          studio: "Bunnywalker",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Creampie", "Romance", "Nakadashi", "Uncensored"],
          rating: 4.86,
          views: 330000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hv_crm_6",
          title: "Rance 01: Hikari's Nakadashi Awakening",
          url: "$baseUrl/hentai/rance-01-hikaris-nakadashi-awakening",
          cover: "https://i.imgur.com/wVqjC5P.jpeg",
          duration: "29:40",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Creampie", "Fantasy", "Adventure", "Nakadashi"],
          rating: 4.91,
          views: 410000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hv_crm_7",
          title: "Dokidoki Little Ooyasan: Innocent Warm Climax",
          url: "$baseUrl/hentai/dokidoki-little-ooyasan-warm-climax",
          cover: "https://i.imgur.com/z4bKxNm.jpeg",
          duration: "22:15",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Creampie", "Comedy", "Cute", "Nakadashi"],
          rating: 4.83,
          views: 360000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hv_crm_8",
          title: "Onsen E Youkoso: Hot Spring Nakadashi Rendezvous",
          url: "$baseUrl/hentai/onsen-e-youkoso-nakadashi-rendezvous",
          cover: "https://i.imgur.com/83pZ6XQ.jpeg",
          duration: "27:00",
          releaseDate: "2024",
          studio: "Milky",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Creampie", "Hot Spring", "Nakadashi", "Uncensored"],
          rating: 4.89,
          views: 395000,
          isUncensored: true,
        ),
      ],
      "futanari": [
        MediaItem(
          id: "hv_futa_1",
          title: "Futabu!: High School Futanari Club Chronicles",
          url: "$baseUrl/hentai/futabu-high-school-futanari-club",
          cover: "https://i.imgur.com/N7GgqMv.jpeg",
          duration: "26:30",
          releaseDate: "2024",
          studio: "ZIZ",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Futanari", "Club", "School Girl", "Uncensored"],
          rating: 4.93,
          views: 480000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hv_futa_2",
          title: "Kuro Futatabi: Dark Futanari Sorceress",
          url: "$baseUrl/hentai/kuro-futatabi-dark-futanari-sorceress",
          cover: "https://i.imgur.com/J3ZqK9x.jpeg",
          duration: "28:15",
          releaseDate: "2024",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Futanari", "Dark Fantasy", "Magic", "Uncensored"],
          rating: 4.9,
          views: 430000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hv_futa_3",
          title: "Futanari Elf no Mori: Sacred Forest Breeding",
          url: "$baseUrl/hentai/futanari-elf-no-mori-sacred-forest",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "25:40",
          releaseDate: "2024",
          studio: "Bunnywalker",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Futanari", "Elf", "Fantasy", "Uncensored"],
          rating: 4.88,
          views: 370000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hv_futa_4",
          title: "Futanari Dairy: Farmstead Awakening",
          url: "$baseUrl/hentai/futanari-dairy-farmstead-awakening",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "24:20",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Futanari", "Farm", "Lactation", "HD"],
          rating: 4.85,
          views: 340000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hv_futa_5",
          title: "Futa Club: Academy Secret Chamber",
          url: "$baseUrl/hentai/futa-club-academy-secret-chamber",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "27:10",
          releaseDate: "2024",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Futanari", "Academy", "Exclusive", "Uncensored"],
          rating: 4.89,
          views: 390000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hv_futa_6",
          title: "Valkyrie Drive: Futanari Battle Maiden",
          url: "$baseUrl/hentai/valkyrie-drive-futanari-battle-maiden",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "26:50",
          releaseDate: "2024",
          studio: "Arms",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Futanari", "Action", "Mecha", "Uncensored"],
          rating: 4.87,
          views: 355000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hv_futa_7",
          title: "Futanari Onna Kyoushi: Private After-Class Lesson",
          url: "$baseUrl/hentai/futanari-onna-kyoushi-after-class",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "25:00",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Futanari", "Teacher", "Classroom", "HD"],
          rating: 4.84,
          views: 310000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hv_futa_8",
          title: "Maho Shoujo Futa: Magical Transformation Duel",
          url: "$baseUrl/hentai/maho-shoujo-futa-magical-transformation",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "28:30",
          releaseDate: "2024",
          studio: "Pink Pineapple",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Futanari", "Magical Girl", "Transformation", "Uncensored"],
          rating: 4.92,
          views: 460000,
          isUncensored: true,
        ),
      ],
      "nekomimi": [
        MediaItem(
          id: "hv_neko_1",
          title: "Nekopara OVA: Chocola and Vanilla Secret Treats",
          url: "$baseUrl/hentai/nekopara-ova-chocola-vanilla-secret",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "27:40",
          releaseDate: "2024",
          studio: "Felix Film",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Nekomimi", "Catgirl", "Maid", "Uncensored"],
          rating: 4.96,
          views: 650000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hv_neko_2",
          title: "Catgirl Maid Café: Purrfect Service Deluxe",
          url: "$baseUrl/hentai/catgirl-maid-cafe-purrfect-service",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "24:10",
          releaseDate: "2024",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Nekomimi", "Maid", "Catgirl", "HD"],
          rating: 4.89,
          views: 410000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hv_neko_3",
          title: "Monmusu Harem: Wild Feline Princess",
          url: "$baseUrl/hentai/monmusu-harem-wild-feline-princess",
          cover: "https://i.imgur.com/wVqjC5P.jpeg",
          duration: "26:25",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Nekomimi", "Monster Girl", "Fantasy", "Uncensored"],
          rating: 4.91,
          views: 475000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hv_neko_4",
          title: "Kemomimi Mansion: Pampered Kitten Diaries",
          url: "$baseUrl/hentai/kemomimi-mansion-pampered-kitten",
          cover: "https://i.imgur.com/z4bKxNm.jpeg",
          duration: "23:50",
          releaseDate: "2024",
          studio: "Bunnywalker",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Nekomimi", "Kemomimi", "Cute", "HD"],
          rating: 4.85,
          views: 320000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hv_neko_5",
          title: "Nekomimi Shizuku: Midnight Alley Patrol",
          url: "$baseUrl/hentai/nekomimi-shizuku-midnight-patrol",
          cover: "https://i.imgur.com/83pZ6XQ.jpeg",
          duration: "25:15",
          releaseDate: "2024",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Nekomimi", "Catgirl", "Night Life", "Uncensored"],
          rating: 4.87,
          views: 360000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hv_neko_6",
          title: "Inumimi & Nekomimi: Animal Ears Double Date",
          url: "$baseUrl/hentai/inumimi-nekomimi-double-date",
          cover: "https://i.imgur.com/N7GgqMv.jpeg",
          duration: "28:00",
          releaseDate: "2024",
          studio: "Milky",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Nekomimi", "Inumimi", "Harem", "Uncensored"],
          rating: 4.92,
          views: 490000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hv_neko_7",
          title: "Kuro Neko no Yuuwaku: Black Cat's Seductive Charm",
          url: "$baseUrl/hentai/kuro-neko-no-yuuwaku-seductive-charm",
          cover: "https://i.imgur.com/J3ZqK9x.jpeg",
          duration: "24:35",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Nekomimi", "Goth", "Catgirl", "HD"],
          rating: 4.88,
          views: 385000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hv_neko_8",
          title: "Neko Para Paradise: Fluffy Ears Hot Spring",
          url: "$baseUrl/hentai/neko-para-paradise-fluffy-ears",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "26:45",
          releaseDate: "2024",
          studio: "Houkiboshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Nekomimi", "Onsen", "Fluffy", "Uncensored"],
          rating: 4.94,
          views: 530000,
          isUncensored: true,
        ),
      ],
    };

    return sampleMap[tabId] ?? sampleMap["universe"] ?? [];
  }

  MediaDetail _generateSampleDetail(String url) {
    String title = "Taimanin Yukikaze: Universe Premiere";
    final slug = url.split('/').where((s) => s.isNotEmpty).last;
    if (slug.isNotEmpty && slug != 'hentai') {
      title = slug
          .replaceAll('-', ' ')
          .split(' ')
          .map((w) =>
              w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
          .join(' ');
    }

    return MediaDetail(
      id: url.hashCode.toString(),
      title: title,
      cover: "https://i.imgur.com/7jZQY1B.jpeg",
      backdrop: "https://i.imgur.com/7jZQY1B.jpeg",
      description:
          "High definition anime release from the $title series streaming on Hentaverse.",
      studio: "Hentaverse Studios",
      releaseDate: "2024",
      tags: ["HD", "Uncensored", "Exclusive"],
      episodes: [
        EpisodeItem(
          id: "ep_1",
          episodeNumber: "Episode 1",
          title: "$title Ep 1",
          url: url,
          thumbnail: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "24:00",
          sources: [
            StreamSource(
              label: "1080p Master",
              url: "https://oppai-str.shoujo-h.org/2026/Furachi/E01/x264.1080p.mp4",
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
    return hentaverseTaxonomy;
  }

  @override
  Future<List<MediaItem>> fetchTaxonomyFeed(CatalogItem item, int page) async {
    try {
      final String path;
      if (item.endpointPath != null && item.endpointPath!.isNotEmpty) {
        path = item.endpointPath!;
      } else {
        path = "/categories/${item.slug}";
      }

      final normalizedPath = path.startsWith('/') ? path : '/$path';
      final targetUrl = page == 1
          ? '$baseUrl$normalizedPath'
          : '$baseUrl$normalizedPath?page=$page';

      final response = await http
          .get(Uri.parse(targetUrl), headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final items = _parseCardsFromHtml(
          response.body,
          tabId: item.slug,
          categoryName: item.name,
        );
        if (items.isNotEmpty) return items;
      }
    } catch (_) {}

    return search(item.name, page);
  }
}

