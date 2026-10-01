import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import '../base_extension.dart';
import '../../models/media_item.dart';
import '../../models/extension_manifest.dart';
import '../../models/catalog_model.dart';
import '../taxonomies/hentai_ht_taxonomy.dart';

/// Hentai.ht extension for HStream Neo.
/// Provides access to curated adult anime catalog with dual-language subtitles
/// (English & French), uncensored editions, studio indexing, and 1080p HLS master streams.
class HentaiHtExtension extends HentaiExtension {
  @override
  String get id => "hentai_ht";

  @override
  String get name => "Hentai.ht";

  @override
  String get baseUrl => "https://hentai.ht";

  @override
  String get iconUrl => "https://hentai.ht/favicon.ico";

  @override
  String get description =>
      "Curated adult anime catalog with uncensored releases, dual-language subtitles (English & French), and 1080p HLS master streams.";

  @override
  ViewLayoutType get defaultLayout => ViewLayoutType.widescreen16x9;

  @override
  bool get supportsShorts => false;

  @override
  List<ExtensionTab> get tabs => [
        ExtensionTab(id: "catalog", title: "All Titles", icon: Icons.grid_view_rounded),
        ExtensionTab(id: "recent", title: "Recently Published", icon: Icons.fiber_new_rounded),
        ExtensionTab(id: "popular", title: "Most Popular", icon: Icons.whatshot_rounded),
        ExtensionTab(id: "episodes", title: "Most Episodes", icon: Icons.video_library_rounded),
      ];

  @override
  List<FilterGroup> get filters => [];

  String? _sessionCookie;

  Map<String, String> get _headers => {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36',
        'Accept': 'application/json, text/html, */*',
        'Origin': 'https://hentai.ht',
        'Referer': 'https://hentai.ht/',
        'Cookie': ?_sessionCookie,
      };

  Future<void> _ensureAgeConfirmed() async {
    if (_sessionCookie != null) return;
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/v1/age-confirmation"),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Origin': 'https://hentai.ht',
          'Referer': 'https://hentai.ht/',
        },
        body: '{}',
      ).timeout(const Duration(seconds: 8));

      final rawCookie = res.headers['set-cookie'];
      if (rawCookie != null && rawCookie.isNotEmpty) {
        final ageCookie = RegExp(r'(__Secure-hht_age=[^;]+)').firstMatch(rawCookie);
        if (ageCookie != null) {
          _sessionCookie = ageCookie.group(1);
        } else {
          _sessionCookie = rawCookie.split(';').first;
        }
      }
    } catch (_) {}
  }

  @override
  Future<List<MediaItem>> fetchTabFeed(
    String tabId,
    int page, {
    Map<String, dynamic>? activeFilters,
    List<String>? whitelistedTags,
    List<String>? blacklistedTags,
  }) async {
    try {
      await _ensureAgeConfirmed();

      String sort;
      switch (tabId) {
        case 'recent':
          sort = "recent";
          break;
        case 'popular':
          sort = "score";
          break;
        case 'episodes':
          sort = "episodes";
          break;
        case 'catalog':
        default:
          sort = "relevance";
          break;
      }

      final url = "$baseUrl/api/v1/catalog?sort=$sort&page=$page";
      var response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 403) {
        _sessionCookie = null;
        await _ensureAgeConfirmed();
        response = await http
            .get(Uri.parse(url), headers: _headers)
            .timeout(const Duration(seconds: 10));
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final titles = data['titles'] as List? ?? [];
        if (titles.isNotEmpty) {
          return _parseApiTitles(titles);
        }
      }
    } catch (_) {}

    // Fallback: parse SEO cards from HTML
    return _fetchSeoCatalog(page);
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
      await _ensureAgeConfirmed();

      final url = "$baseUrl/api/v1/catalog?q=${Uri.encodeComponent(query)}&page=$page";
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final titles = data['titles'] as List? ?? [];
        if (titles.isNotEmpty) {
          return _parseApiTitles(titles);
        }
      }
    } catch (_) {}

    return fetchTabFeed("catalog", page);
  }

  @override
  Future<MediaDetail> detail(String url) async {
    try {
      await _ensureAgeConfirmed();

      // Extract routeId or slug
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      String identifier = "";
      if (segments.contains("title") && segments.length > 1) {
        identifier = segments[segments.indexOf("title") + 1];
      } else if (segments.contains("watch") && segments.length > 1) {
        identifier = segments[segments.indexOf("watch") + 1];
      } else if (segments.isNotEmpty) {
        identifier = segments.last;
      }

      // 1. Fetch title metadata from API
      final apiUrl = "$baseUrl/api/v1/catalog/titles/$identifier";
      final response = await http
          .get(Uri.parse(apiUrl), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final titleObj = data['title'] ?? data;

        final title = titleObj['name']?.toString() ?? "Hentai.ht Anime";
        final slug = titleObj['slug']?.toString() ?? identifier;
        final studio = titleObj['studio']?.toString() ?? "Hentai.ht";
        final year = titleObj['year']?.toString() ?? "2024";
        final desc = titleObj['synopsis']?.toString() ??
            "Curated adult anime from Hentai.ht with dual-language subtitles.";
        var cover = titleObj['coverFull']?.toString() ??
            titleObj['cover']?.toString() ??
            hentaiHtCovers[slug] ??
            "";

        var backdrop = titleObj['banner']?.toString() ?? cover;

        // Build episodes
        final List<EpisodeItem> episodes = [];
        final activeEps = titleObj['activeEpisodes'] as List? ?? [];
        final epCount = activeEps.isNotEmpty
            ? activeEps.length
            : (titleObj['episodeCount'] as int? ?? 1);

        for (var i = 1; i <= epCount; i++) {
          final epNum = activeEps.isNotEmpty && i - 1 < activeEps.length
              ? activeEps[i - 1].toString()
              : "$i";
          final epUrl = "$baseUrl/watch/$slug/$epNum";
          episodes.add(
            EpisodeItem(
              id: 'ep_$epNum',
              episodeNumber: 'Episode $epNum',
              title: "$title - Episode $epNum",
              url: epUrl,
              thumbnail: cover.isNotEmpty ? cover : iconUrl,
              duration: "${titleObj['duration'] ?? '24'}:00",
              sources: const [],
            ),
          );
        }

        if (episodes.isNotEmpty) {
          final firstStreams = await extractVideoStreams(episodes.first.url);
          episodes[0] = EpisodeItem(
            id: episodes[0].id,
            episodeNumber: episodes[0].episodeNumber,
            title: episodes[0].title,
            url: episodes[0].url,
            thumbnail: episodes[0].thumbnail,
            duration: episodes[0].duration,
            sources: firstStreams,
          );
        }

        return MediaDetail(
          id: url.hashCode.toString(),
          title: title,
          cover: cover.isNotEmpty ? cover : iconUrl,
          backdrop: backdrop.isNotEmpty ? backdrop : iconUrl,
          description: desc,
          studio: studio,
          releaseDate: year,
          tags: ["Curated", studio, "1080p", "Subbed"],
          episodes: episodes,
          playbackHeatmap: const [0.1, 0.45, 0.7, 0.95, 0.85, 0.6, 0.9, 1.0, 0.4],
          sceneMarkers: [
            SceneMarker(title: "Opening", timestampSeconds: 0),
            SceneMarker(title: "Climax 🔥", timestampSeconds: 520),
          ],
        );
      }
    } catch (_) {}

    return MediaDetail(
      id: url,
      title: "Hentai.ht Title",
      cover: iconUrl,
      description: "Unable to load details.",
      episodes: const [],
    );
  }

  @override
  Future<List<StreamSource>> extractVideoStreams(String videoUrl) async {
    final List<StreamSource> sources = [];
    try {
      await _ensureAgeConfirmed();

      // Extract slug and episode number
      final uri = Uri.parse(videoUrl);
      final segments = uri.pathSegments;
      String slug = "";
      String ep = "1";

      if (segments.contains("watch") && segments.length >= 3) {
        final watchIdx = segments.indexOf("watch");
        slug = segments[watchIdx + 1];
        ep = segments[watchIdx + 2];
      } else if (segments.contains("title") && segments.length >= 2) {
        slug = segments[segments.indexOf("title") + 1];
        ep = "1";
      }

      if (slug.isNotEmpty) {
        // Query official playback API
        final playUrl =
            "$baseUrl/api/v1/playback/$slug/$ep?language=ENG%20SUB&censorship=censored";
        var res = await http
            .get(Uri.parse(playUrl), headers: _headers)
            .timeout(const Duration(seconds: 10));

        if (res.statusCode == 404) {
          // Try uncensored or FR SUB
          final playUrlUncensored =
              "$baseUrl/api/v1/playback/$slug/$ep?language=ENG%20SUB&censorship=uncensored";
          res = await http
              .get(Uri.parse(playUrlUncensored), headers: _headers)
              .timeout(const Duration(seconds: 10));
        }

        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          final asset = data['asset'] as Map<String, dynamic>?;
          final manifestUrl = asset?['manifestUrl']?.toString();

          if (manifestUrl != null && manifestUrl.isNotEmpty) {
            final fullManifest = manifestUrl.startsWith('http')
                ? manifestUrl
                : "$baseUrl$manifestUrl";

            sources.add(
              StreamSource(
                label: "Hentai.ht 1080p HLS Master",
                url: fullManifest,
                protocol: StreamProtocol.hlsM3u8,
                format: "m3u8",
                headers: {
                  'Referer': 'https://hentai.ht/',
                  'Cookie': ?_sessionCookie,
                },
              ),
            );
          }
        }
      }
    } catch (_) {}
    return sources;
  }

  @override
  Future<ExtensionTaxonomy> fetchTaxonomy() async {
    return hentaiHtTaxonomy;
  }

  @override
  Future<List<MediaItem>> fetchTaxonomyFeed(CatalogItem item, int page) async {
    try {
      await _ensureAgeConfirmed();

      String queryParam = "";
      if (item.endpointPath != null && item.endpointPath!.contains("uncensored-editions")) {
        queryParam = "cens=uncensored";
      } else if (item.endpointPath != null && item.endpointPath!.contains("recently-published")) {
        queryParam = "sort=recent";
      } else if (item.endpointPath != null && item.endpointPath!.contains("?tag=")) {
        queryParam = "tag=${Uri.encodeComponent(item.name)}";
      } else if (item.endpointPath != null && item.endpointPath!.contains("?studio=")) {
        queryParam = "studio=${Uri.encodeComponent(item.name)}";
      }

      if (queryParam.isNotEmpty) {
        final url = "$baseUrl/api/v1/catalog?$queryParam&page=$page";
        final response = await http
            .get(Uri.parse(url), headers: _headers)
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final titles = data['titles'] as List? ?? [];
          if (titles.isNotEmpty) {
            return _parseApiTitles(titles);
          }
        }
      }
    } catch (_) {}

    return search(item.name, page);
  }

  List<MediaItem> _parseApiTitles(List titles) {
    final List<MediaItem> result = [];
    for (final raw in titles) {
      if (raw is! Map) continue;
      final t = Map<String, dynamic>.from(raw);
      final routeId = t['routeId']?.toString() ?? t['slug']?.toString() ?? "";
      final name = t['name']?.toString() ?? "Anime";
      var cover = t['coverFull']?.toString() ?? t['cover']?.toString() ?? "";
      if (cover.startsWith('/')) cover = "$baseUrl$cover";

      final tags = <String>[];
      if (t['studio'] != null) tags.add(t['studio'].toString());
      if (t['format'] != null) tags.add(t['format'].toString());
      if (t['year'] != null) tags.add(t['year'].toString());

      final fullUrl = "$baseUrl/title/$routeId";
      result.add(
        MediaItem(
          id: fullUrl,
          title: name,
          cover: cover.isNotEmpty ? cover : iconUrl,
          url: fullUrl,
          extensionId: id,
          tags: tags,
        ),
      );
    }
    return result;
  }

  Future<List<MediaItem>> _fetchSeoCatalog(int page) async {
    try {
      final url = "$baseUrl/catalog?page=$page";
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final doc = html_parser.parse(response.body);
        final cards = doc.querySelectorAll('li.seo-card');
        final List<MediaItem> items = [];

        for (final c in cards) {
          final a = c.querySelector('a');
          if (a == null) continue;
          final href = a.attributes['href'] ?? '';
          final title = a.text.trim();
          final meta = c.querySelector('.seo-muted')?.text.trim() ?? "";

          final slug = href.replaceAll(RegExp(r'/+$'), '').split('/').last;
          final cover = hentaiHtCovers[slug] ?? "";

          final fullUrl = href.startsWith('http') ? href : "$baseUrl$href";
          items.add(
            MediaItem(
              id: fullUrl,
              title: title,
              cover: cover.isNotEmpty ? cover : iconUrl,
              url: fullUrl,
              extensionId: id,
              tags: meta.isNotEmpty ? [meta] : ["Curated"],
            ),
          );
        }
        return items;
      }
    } catch (_) {}
    return [];
  }
}
