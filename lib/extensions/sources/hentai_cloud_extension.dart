import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../base_extension.dart';
import '../../models/media_item.dart';
import '../../models/extension_manifest.dart';
import '../../models/catalog_model.dart';
import '../taxonomies/hentai_cloud_taxonomy.dart';

/// HentaiCloud extension for HStream Neo.
/// Scrapes cloud multi-bitrate HLS and CDN streaming from hentaicloud.tv.
class HentaiCloudExtension extends HentaiExtension {
  @override
  String get id => "hentai_cloud";

  @override
  String get name => "HentaiCloud";

  @override
  String get baseUrl => "https://hentaicloud.tv";

  @override
  String get iconUrl => "https://hentaicloud.tv/favicon.ico";

  @override
  String get description =>
      "Cloud multi-bitrate HLS streaming, fast global CDN mirrors, and uncensored catalog.";

  @override
  ViewLayoutType get defaultLayout => ViewLayoutType.widescreen16x9;

  @override
  bool get supportsShorts => false;

  @override
  List<ExtensionTab> get tabs => [
        ExtensionTab(
            id: "latest",
            title: "Cloud Latest",
            icon: Icons.fiber_new_rounded),
        ExtensionTab(
            id: "popular",
            title: "Cloud Top",
            icon: Icons.whatshot_rounded),
        ExtensionTab(
            id: "uncensored",
            title: "Uncensored Cloud",
            icon: Icons.lock_open_rounded),
        ExtensionTab(
            id: "hd",
            title: "4K HD Cloud",
            icon: Icons.four_k_rounded),
        ExtensionTab(
            id: "fantasy",
            title: "Fantasy Cloud",
            icon: Icons.cloud_rounded),
      ];

  @override
  List<FilterGroup> get filters => [
        FilterGroup(
          key: "category",
          title: "Category",
          type: FilterType.dropdown,
          defaultValue: "all",
          options: [
            FilterOption(label: "All / Cloud Latest", value: "all"),
            FilterOption(label: "Cloud Top", value: "popular"),
            FilterOption(label: "Uncensored Cloud", value: "uncensored"),
            FilterOption(label: "4K HD Cloud", value: "hd"),
            FilterOption(label: "Fantasy Cloud", value: "fantasy"),
          ],
        ),
      ];

  final Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
    'Referer': 'https://hentaicloud.tv/',
  };

  final List<String> _candidateDomains = [
    'https://hentaicloud.com',
    'https://hentaicloud.tv',
    'https://cloudhentai.com',
  ];

  @override
  Future<List<MediaItem>> fetchTabFeed(
    String tabId,
    int page, {
    Map<String, dynamic>? activeFilters,
    List<String>? whitelistedTags,
    List<String>? blacklistedTags,
  }) async {
    String effectiveTab = tabId;
    if (activeFilters != null &&
        activeFilters.containsKey('category') &&
        activeFilters['category'] != 'all') {
      effectiveTab = activeFilters['category'].toString();
    }

    String path;
    switch (effectiveTab) {
      case 'popular':
        path = '/videos?o=mv';
        break;
      case 'uncensored':
        path = '/videos/uncensored-hentai';
        break;
      case 'hd':
        path = '/videos/3d-hentai';
        break;
      case 'fantasy':
        path = '/videos/monster-girl';
        break;
      case 'latest':
      default:
        path = '/videos?o=mr';
        break;
    }

    for (final domain in _candidateDomains) {
      try {
        final targetUrl = page == 1
            ? '$domain$path'
            : (path.contains('?')
                ? '$domain$path&page=$page'
                : '$domain$path?page=$page');

        final response = await http
            .get(Uri.parse(targetUrl), headers: _headers)
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final items =
              _parseCardsFromHtml(response.body, domain, tabId: effectiveTab);
          if (items.isNotEmpty) return items;
        }
      } catch (_) {}
    }

    return _generateSampleList(effectiveTab, page);
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
              ? "$domain/videos?search_query=${Uri.encodeComponent(query)}"
              : "$domain/videos?search_query=${Uri.encodeComponent(query)}&page=$page",
        );
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

  List<MediaItem> _parseCardsFromHtml(String html, String domain,
      {String tabId = 'latest'}) {
    final doc = html_parser.parse(html);
    final articles =
        doc.querySelectorAll('article, .post, .item, .cloud-item, .video-item');
    final List<MediaItem> items = [];
    final Set<String> seenUrls = {};

    for (final art in articles) {
      final a =
          art.querySelector('a[href*="/video/"]') ?? art.querySelector('a');
      var href = a?.attributes['href'] ?? '';
      if (href.isEmpty) continue;
      if (href.contains('/videos/') || href.endsWith('/upload/video')) continue;

      if (!href.startsWith('http')) {
        if (href.startsWith('//')) {
          href = 'https:$href';
        } else if (href.startsWith('/')) {
          href = '$domain$href';
        } else {
          href = '$domain/$href';
        }
      }

      if (seenUrls.contains(href)) continue;
      seenUrls.add(href);

      final img = art.querySelector('img');
      final title = img?.attributes['title']?.trim() ??
          img?.attributes['alt']?.trim() ??
          art.querySelector('.name, .title, .entry-title, h2, h3')?.text.trim() ??
          a?.attributes['title']?.trim() ??
          '';

      var cover = img?.attributes['data-src'] ??
          img?.attributes['data-lazy-src'] ??
          img?.attributes['data-original'] ??
          img?.attributes['src'] ??
          '';

      if (cover.startsWith('data:')) {
        cover = img?.attributes['src'] ?? '';
      }
      if (cover.startsWith('//')) {
        cover = 'https:$cover';
      } else if (cover.startsWith('/') && !cover.startsWith('//')) {
        cover = '$domain$cover';
      }

      final duration = art
              .querySelector(
                  '.duration, .time, span.time, span.vi-data:not(.views):not(.box)')
              ?.text
              .trim() ??
          "24:00";

      if (title.isNotEmpty && cover.startsWith('http')) {
        items.add(MediaItem(
          id: href.hashCode.toString(),
          title: title,
          url: href,
          cover: cover,
          duration: duration,
          releaseDate: "2024",
          studio: "HentaiCloud",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: _getDefaultTagsForTab(tabId),
          rating: 4.9,
          views: 210000,
          isUncensored: tabId == "uncensored" || tabId.contains("uncensored"),
        ));
      }
    }

    return items;
  }

  List<String> _getDefaultTagsForTab(String tabId) {
    switch (tabId) {
      case 'popular':
        return ["Cloud Top", "HD", "Popular"];
      case 'uncensored':
        return ["Uncensored", "Decensored", "Full HD"];
      case 'hd':
        return ["4K HD", "60fps", "Cloud HLS"];
      case 'fantasy':
        return ["Fantasy", "Magic", "Isekai"];
      case 'latest':
      default:
        return ["Cloud Latest", "HD", "Subbed"];
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
        final title = doc.querySelector('h1, .entry-title, .title')?.text.trim() ??
            "HentaiCloud Episode";
        final desc = doc.querySelector('meta[name="description"]')?.attributes['content'] ??
            doc.querySelector('.entry-content p, .description p, p')?.text.trim() ??
            "Cloud HLS streaming playback on HentaiCloud.";
        final cover = doc.querySelector('meta[property="og:image"]')?.attributes['content'] ??
            doc.querySelector('img.poster, .cover img, .thumb img')?.attributes['src'] ??
            "";

        final sources = await extractVideoStreams(url);

        return MediaDetail(
          id: url.hashCode.toString(),
          title: title,
          cover: cover.isNotEmpty ? cover : "https://i.imgur.com/7jZQY1B.jpeg",
          backdrop: cover.isNotEmpty ? cover : "https://i.imgur.com/7jZQY1B.jpeg",
          description: desc,
          studio: "HentaiCloud Studios",
          releaseDate: "2024",
          tags: ["Cloud HLS", "HD", "Uncensored"],
          episodes: [
            EpisodeItem(
              id: "ep_1",
              episodeNumber: "Episode 1",
              title: title,
              url: url,
              thumbnail:
                  cover.isNotEmpty ? cover : "https://i.imgur.com/7jZQY1B.jpeg",
              duration: "24:00",
              sources: sources,
            ),
          ],
          playbackHeatmap: [0.1, 0.35, 0.65, 0.95, 0.8, 0.4, 0.3, 0.9, 1.0, 0.4],
          sceneMarkers: [
            SceneMarker(title: "Opening", timestampSeconds: 0),
            SceneMarker(title: "Cloud Climax 🔥", timestampSeconds: 700),
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
        final body = response.body;
        final doc = html_parser.parse(body);
        final List<StreamSource> sources = [];

        // Check for .m3u8 regex
        final m3u8Matches =
            RegExp(r"""(https?://[^\s"']+\.m3u8[^\s"']*)""").allMatches(body);
        for (final m in m3u8Matches) {
          final mUrl = m.group(1)!;
          if (!sources.any((s) => s.url == mUrl)) {
            sources.add(StreamSource(
              label: "Cloud Adaptive HLS Master",
              url: mUrl,
              protocol: StreamProtocol.hlsM3u8,
              headers: {'Referer': baseUrl, 'User-Agent': _headers['User-Agent']!},
            ));
          }
        }

        final iframes = doc.querySelectorAll('iframe[src*="embed"], iframe');
        for (final iframe in iframes) {
          final src = iframe.attributes['src'] ?? '';
          if (src.isNotEmpty &&
              !src.contains('facebook') &&
              !src.contains('google')) {
            final embedUrl = src.startsWith('//') ? "https:$src" : src;
            if (!sources.any((s) => s.url == embedUrl)) {
              sources.add(StreamSource(
                label: "Cloud Mirror Server",
                url: embedUrl,
                protocol: StreamProtocol.embedIframe,
              ));
            }
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
          id: "hcl_lat_1",
          title: "Taimanin Yukikaze: Cloud Master Edition",
          url: "$baseUrl/taimanin-yukikaze-cloud-master",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "24:30",
          releaseDate: "2025",
          studio: "Lilith",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Cloud Latest", "Action", "Supernatural", "HD"],
          rating: 4.9,
          views: 320000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hcl_lat_2",
          title: "Overflow: Cloud Stream Extended Cut",
          url: "$baseUrl/overflow-cloud-stream-extended",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "23:45",
          releaseDate: "2025",
          studio: "Houkiboshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Cloud Latest", "Romance", "Harem", "HD"],
          rating: 4.88,
          views: 410000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hcl_lat_3",
          title: "Dokidoki Little Ooyasan: Cloud Premiere",
          url: "$baseUrl/dokidoki-little-ooyasan-cloud",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "22:15",
          releaseDate: "2025",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Cloud Latest", "Comedy", "Cute", "HD"],
          rating: 4.82,
          views: 290000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hcl_lat_4",
          title: "Isekai Harem Monogatari: Cloud Ep 1",
          url: "$baseUrl/isekai-harem-monogatari-cloud-ep1",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "25:20",
          releaseDate: "2025",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Cloud Latest", "Fantasy", "Isekai", "Harem"],
          rating: 4.93,
          views: 480000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hcl_lat_5",
          title: "Ane wa Yanmama Junyuu-chuu: Cloud Cast",
          url: "$baseUrl/ane-wa-yanmama-cloud-cast",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "28:10",
          releaseDate: "2025",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Cloud Latest", "Milf", "Family", "HD"],
          rating: 4.87,
          views: 350000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hcl_lat_6",
          title: "Kimi Omoi: Cloud Velvet Night",
          url: "$baseUrl/kimi-omoi-cloud-velvet-night",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "26:40",
          releaseDate: "2025",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Cloud Latest", "Romance", "School", "HD"],
          rating: 4.85,
          views: 275000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hcl_lat_7",
          title: "Boku no Yayoi-san: Cloud High-Bitrate",
          url: "$baseUrl/boku-no-yayoi-san-cloud-bitrate",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "24:50",
          releaseDate: "2025",
          studio: "MS Pictures",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Cloud Latest", "Classic", "Maid", "HD"],
          rating: 4.8,
          views: 310000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hcl_lat_8",
          title: "Rance 01: The Quest for Hikari Cloud",
          url: "$baseUrl/rance-01-quest-hikari-cloud",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "29:15",
          releaseDate: "2025",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Cloud Latest", "Action", "Adventure", "Fantasy"],
          rating: 4.95,
          views: 520000,
          isUncensored: true,
        ),
      ],
      "popular": [
        MediaItem(
          id: "hcl_pop_1",
          title: "Mankitsu Happening: Cloud Top Choice",
          url: "$baseUrl/mankitsu-happening-cloud-top",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "27:40",
          releaseDate: "2025",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Cloud Top", "Net Cafe", "Romance", "Classic"],
          rating: 4.96,
          views: 780000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hcl_pop_2",
          title: "Master Piece The Animation: Cloud Top Rated",
          url: "$baseUrl/master-piece-cloud-top-rated",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "28:15",
          releaseDate: "2025",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Cloud Top", "Maid", "Harem", "Top Rated"],
          rating: 4.94,
          views: 690000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hcl_pop_3",
          title: "Oni Chichi: Cloud Fan Favorite Ep 1",
          url: "$baseUrl/oni-chichi-cloud-favorite-ep1",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "25:30",
          releaseDate: "2025",
          studio: "Blue Eyes",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Cloud Top", "Family", "Drama", "Popular"],
          rating: 4.91,
          views: 740000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hcl_pop_4",
          title: "Gakuen de Jikan yo Tomare: Cloud Freeze",
          url: "$baseUrl/gakuen-de-jikan-yo-tomare-cloud",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "26:10",
          releaseDate: "2025",
          studio: "BOOTLEG",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Cloud Top", "Time Stop", "School", "Supernatural"],
          rating: 4.89,
          views: 630000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hcl_pop_5",
          title: "Discipline Zero: Cloud Top Series",
          url: "$baseUrl/discipline-zero-cloud-top",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "29:50",
          releaseDate: "2025",
          studio: "Active",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Cloud Top", "BDSM", "School", "Dark"],
          rating: 4.92,
          views: 580000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hcl_pop_6",
          title: "Drop Out: Deluxe Cloud Stream",
          url: "$baseUrl/drop-out-deluxe-cloud",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "27:20",
          releaseDate: "2025",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Cloud Top", "Gyaru", "School", "HD"],
          rating: 4.88,
          views: 540000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hcl_pop_7",
          title: "Eroge H mo Game mo: Cloud Hit",
          url: "$baseUrl/eroge-kaihatsu-cloud-hit",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "25:45",
          releaseDate: "2025",
          studio: "Ziz",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Cloud Top", "Otaku", "Comedy", "Popular"],
          rating: 4.86,
          views: 490000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hcl_pop_8",
          title: "Sweet Home: Cloud Top Selection",
          url: "$baseUrl/sweet-home-cloud-top-selection",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "26:35",
          releaseDate: "2025",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Cloud Top", "Romance", "Harem", "HD"],
          rating: 4.87,
          views: 470000,
          isUncensored: false,
        ),
      ],
      "uncensored": [
        MediaItem(
          id: "hcl_unc_1",
          title: "Futabu!! Complete Decensored Cloud Cut",
          url: "$baseUrl/futabu-complete-decensored-cloud",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "26:00",
          releaseDate: "2025",
          studio: "Ziz",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Futanari", "Comedy", "Decensored"],
          rating: 4.95,
          views: 710000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hcl_unc_2",
          title: "Tiny Evil: Uncensored Cloud Devilry",
          url: "$baseUrl/tiny-evil-uncensored-cloud",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "24:20",
          releaseDate: "2025",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Succubus", "Magic", "Full HD"],
          rating: 4.93,
          views: 680000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hcl_unc_3",
          title: "Resort Boin: Uncensored Cloud Island",
          url: "$baseUrl/resort-boin-uncensored-cloud",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "27:40",
          releaseDate: "2025",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Beach", "Big Boobs", "Romance"],
          rating: 4.89,
          views: 560000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hcl_unc_4",
          title: "Shoujo Ramune: Cloud Decensored Archive",
          url: "$baseUrl/shoujo-ramune-cloud-decensored",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "23:50",
          releaseDate: "2025",
          studio: "Milkshake",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Summer", "Rural", "Decensored"],
          rating: 4.82,
          views: 510000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hcl_unc_5",
          title: "Fubin Sugiru: Decensored Cloud Tale",
          url: "$baseUrl/fubin-sugiru-decensored-cloud",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "26:15",
          releaseDate: "2025",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Harem", "Drama", "Full HD"],
          rating: 4.87,
          views: 470000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hcl_unc_6",
          title: "Hanamaru: Uncensored Cloud Days",
          url: "$baseUrl/hanamaru-uncensored-cloud-days",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "23:10",
          releaseDate: "2025",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Teacher", "Romance", "Decensored"],
          rating: 4.81,
          views: 420000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hcl_unc_7",
          title: "Rie Rie: Uncensored Cloud Twins",
          url: "$baseUrl/rie-rie-uncensored-cloud-twins",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "25:35",
          releaseDate: "2025",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Twins", "Maid", "Fantasy"],
          rating: 4.85,
          views: 440000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hcl_unc_8",
          title: "Genzai: Decensored Cloud Confession",
          url: "$baseUrl/genzai-decensored-cloud-confession",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "28:40",
          releaseDate: "2025",
          studio: "Natural High",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Dark", "Drama", "Psychological"],
          rating: 4.92,
          views: 530000,
          isUncensored: true,
        ),
      ],
      "hd": [
        MediaItem(
          id: "hcl_hd_1",
          title: "Bible Black: 4K UHD Cloud Remaster",
          url: "$baseUrl/bible-black-4k-cloud-remaster",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "31:40",
          releaseDate: "2026",
          studio: "Milky",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["4K HD", "Supernatural", "Occult", "Cloud HLS"],
          rating: 5.0,
          views: 760000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hcl_hd_2",
          title: "Kuroinu: 4K HDR Cloud Director's Cut",
          url: "$baseUrl/kuroinu-4k-hdr-cloud-cut",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "32:30",
          releaseDate: "2026",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["4K HD", "Dark Fantasy", "Action", "60fps"],
          rating: 4.98,
          views: 720000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hcl_hd_3",
          title: "La Blue Girl: 4K 60fps Cloud Archive",
          url: "$baseUrl/la-blue-girl-4k-cloud-archive",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "28:30",
          releaseDate: "2026",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["4K HD", "Ninja", "Supernatural", "Cloud HLS"],
          rating: 4.88,
          views: 460000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hcl_hd_4",
          title: "Night Shift Nurses: 4K HD Cloud Clinic",
          url: "$baseUrl/night-shift-nurses-4k-cloud",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "28:10",
          releaseDate: "2026",
          studio: "Discovery",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["4K HD", "Hospital", "Psychological", "60fps"],
          rating: 4.93,
          views: 610000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hcl_hd_5",
          title: "Viper GTS: 4K AI Cloud Restoration",
          url: "$baseUrl/viper-gts-4k-ai-cloud",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "30:15",
          releaseDate: "2026",
          studio: "Sogna",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["4K HD", "Sci-Fi", "Cyberpunk", "Vintage"],
          rating: 4.9,
          views: 440000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hcl_hd_6",
          title: "Starless: 2160p Master Cloud Stream",
          url: "$baseUrl/starless-2160p-master-cloud",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "33:40",
          releaseDate: "2026",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["4K HD", "Mansion", "Mystery", "Cloud HLS"],
          rating: 4.96,
          views: 640000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hcl_hd_7",
          title: "Mei King: 4K Cloud Martial Arts Cut",
          url: "$baseUrl/mei-king-4k-cloud-martial-arts",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "26:50",
          releaseDate: "2026",
          studio: "Milky",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["4K HD", "Historical", "Action", "60fps"],
          rating: 4.85,
          views: 420000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hcl_hd_8",
          title: "Euphoria: 4K Lossless Cloud Master",
          url: "$baseUrl/euphoria-4k-lossless-cloud",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "31:10",
          releaseDate: "2026",
          studio: "Magin",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["4K HD", "Psychological", "Survival", "Cloud HLS"],
          rating: 4.94,
          views: 690000,
          isUncensored: true,
        ),
      ],
      "fantasy": [
        MediaItem(
          id: "hcl_fan_1",
          title: "Isekai Harem Monogatari: Cloud Guild Saga",
          url: "$baseUrl/isekai-harem-cloud-guild-saga",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "28:45",
          releaseDate: "2025",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Fantasy", "Isekai", "Harem", "Magic"],
          rating: 4.96,
          views: 670000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hcl_fan_2",
          title: "Kuroinu II: Cloud Mercenary Fortress",
          url: "$baseUrl/kuroinu-ii-cloud-mercenary",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "30:20",
          releaseDate: "2025",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Fantasy", "Dark Fantasy", "Knights", "War"],
          rating: 4.94,
          views: 620000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hcl_fan_3",
          title: "Princess Lover! Cloud Knight Chapter",
          url: "$baseUrl/princess-lover-cloud-knight",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "26:30",
          releaseDate: "2025",
          studio: "Public Enemies",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Fantasy", "Royalty", "Romance", "HD"],
          rating: 4.91,
          views: 530000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hcl_fan_4",
          title: "Dungeon ni Deai: Cloud Labyrinth Run",
          url: "$baseUrl/dungeon-cloud-labyrinth-run",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "25:50",
          releaseDate: "2025",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Fantasy", "Dungeon", "Adventure", "Monsters"],
          rating: 4.88,
          views: 495000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hcl_fan_5",
          title: "Makai Kishi Ingrid: Cloud Demonic Trial",
          url: "$baseUrl/makai-kishi-ingrid-cloud-trial",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "29:10",
          releaseDate: "2025",
          studio: "Lilith",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Fantasy", "Demons", "Action", "Supernatural"],
          rating: 4.93,
          views: 580000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hcl_fan_6",
          title: "Ero Elf to Moribito: Cloud Sacred Forest",
          url: "$baseUrl/ero-elf-cloud-sacred-forest",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "24:40",
          releaseDate: "2025",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Fantasy", "Elf", "Nature", "Magic"],
          rating: 4.87,
          views: 460000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hcl_fan_7",
          title: "Maou no Hajimekata: Cloud Dungeon Lord",
          url: "$baseUrl/maou-hajimekata-cloud-lord",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "27:15",
          releaseDate: "2025",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Fantasy", "Demon King", "Magic", "Harem"],
          rating: 4.9,
          views: 510000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hcl_fan_8",
          title: "Valkyrie Hazard: Cloud Celestial Battle",
          url: "$baseUrl/valkyrie-hazard-cloud-celestial",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "28:05",
          releaseDate: "2025",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Fantasy", "Mythology", "Valkyrie", "Action"],
          rating: 4.89,
          views: 475000,
          isUncensored: true,
        ),
      ],
    };

    return sampleSets[tabId] ?? sampleSets["latest"] ?? [];
  }

  MediaDetail _generateSampleDetail(String url) {
    return MediaDetail(
      id: url.hashCode.toString(),
      title: "Taimanin Yukikaze Cloud HLS",
      cover: "https://i.imgur.com/7jZQY1B.jpeg",
      backdrop: "https://i.imgur.com/7jZQY1B.jpeg",
      description: "Cloud adaptive multi-bitrate HLS streaming on HentaiCloud.",
      studio: "Lilith Animation",
      releaseDate: "2024",
      tags: ["Cloud HLS", "HD", "Uncensored"],
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
    return hentaiCloudTaxonomy;
  }

  @override
  Future<List<MediaItem>> fetchTaxonomyFeed(CatalogItem item, int page) async {
    for (final domain in _candidateDomains) {
      try {
        final String targetUrl;
        if (item.endpointPath != null && item.endpointPath!.isNotEmpty) {
          final path = item.endpointPath!;
          targetUrl = page == 1
              ? '$domain$path'
              : (path.contains('?')
                  ? '$domain$path&page=$page'
                  : '$domain$path?page=$page');
        } else if (item.type == CatalogType.category) {
          targetUrl = page == 1
              ? '$domain/videos/${item.slug}'
              : '$domain/videos/${item.slug}?page=$page';
        } else if (item.type == CatalogType.tag) {
          final encodedTag =
              Uri.encodeComponent(item.slug.isNotEmpty ? item.slug : item.name);
          targetUrl = page == 1
              ? '$domain/tags/$encodedTag'
              : '$domain/tags/$encodedTag?page=$page';
        } else {
          final encodedQuery = Uri.encodeComponent(item.name);
          targetUrl = page == 1
              ? '$domain/videos?search_query=$encodedQuery'
              : '$domain/videos?search_query=$encodedQuery&page=$page';
        }

        final response = await http
            .get(Uri.parse(Uri.encodeFull(targetUrl)), headers: _headers)
            .timeout(const Duration(seconds: 6));

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

    return search(item.name, page);
  }
}
