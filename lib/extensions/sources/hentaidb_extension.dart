import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import '../base_extension.dart';
import '../../models/media_item.dart';
import '../../models/extension_manifest.dart';
import '../../models/catalog_model.dart';
import '../taxonomies/hentaidb_taxonomy.dart';

/// HentaiDB extension for HStream Neo.
/// Provides access to comprehensive adult anime database catalog with over 2,083 series,
/// 4,906 indexed episodes, multi-tag filtering, and up to 4K direct MP4 streams.
class HentaiDbExtension extends HentaiExtension {
  @override
  String get id => "hentaidb";

  @override
  String get name => "HentaiDB";

  @override
  String get baseUrl => "https://hentaidb.xyz";

  @override
  String get iconUrl => "https://hentaidb.xyz/favicon.ico";

  @override
  String get description =>
      "Comprehensive adult anime database indexing over 2,083 series and 4,906 episodes with up to 4K direct streams.";

  @override
  ViewLayoutType get defaultLayout => ViewLayoutType.widescreen16x9;

  @override
  bool get supportsShorts => false;

  @override
  List<ExtensionTab> get tabs => [
        ExtensionTab(id: "popular", title: "Most Popular", icon: Icons.whatshot_rounded),
        ExtensionTab(id: "newest", title: "Newest Releases", icon: Icons.fiber_new_rounded),
        ExtensionTab(id: "episodes", title: "Most Episodes", icon: Icons.video_library_rounded),
        ExtensionTab(id: "runtime", title: "Longest Runtime", icon: Icons.schedule_rounded),
      ];

  @override
  List<FilterGroup> get filters => [];

  final Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
    'Referer': 'https://hentaidb.xyz/',
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
      String url;
      switch (tabId) {
        case 'newest':
          url = "$baseUrl/?sort=year&page=$page";
          break;
        case 'episodes':
          url = "$baseUrl/?sort=eps&page=$page";
          break;
        case 'runtime':
          url = "$baseUrl/?sort=runtime&page=$page";
          break;
        case 'popular':
        default:
          url = "$baseUrl/?sort=pop&page=$page";
          break;
      }

      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return _parseSeriesCards(response.body);
      }
    } catch (_) {}
    return [];
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
      final searchUrl = "$baseUrl/?q=${Uri.encodeComponent(query)}&page=$page";
      final response = await http
          .get(Uri.parse(searchUrl), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final items = _parseSeriesCards(response.body);
        if (items.isNotEmpty) return items;
      }
    } catch (_) {}
    return fetchTabFeed("popular", page);
  }

  @override
  Future<MediaDetail> detail(String url) async {
    try {
      final fullUrl = url.startsWith('http') ? url : "$baseUrl$url";
      final response = await http
          .get(Uri.parse(fullUrl), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final doc = html_parser.parse(response.body);
        final title = doc.querySelector('h1')?.text.trim() ??
            doc.querySelector('title')?.text.split('|').first.trim() ??
            "HentaiDB Series";

        final desc = doc
                .querySelector('meta[name="description"]')
                ?.attributes['content'] ??
            doc.querySelector('p')?.text.trim() ??
            "Complete anime series from HentaiDB index.";

        var cover = doc
                .querySelector('meta[property="og:image"]')
                ?.attributes['content'] ??
            doc.querySelector('.cv img, img')?.attributes['src'] ??
            "";

        if (cover.startsWith('/')) cover = "$baseUrl$cover";

        // Extract series tags
        final tags = <String>[];
        for (final a in doc.querySelectorAll('a[href*="tag="]')) {
          final t = a.text.trim();
          if (t.isNotEmpty && !tags.contains(t)) tags.add(t);
        }

        // Extract episodes
        final List<EpisodeItem> episodes = [];
        final watchLinks = doc.querySelectorAll('a[href*="/watch/"]');
        final seenHrefs = <String>{};

        for (final a in watchLinks) {
          final href = a.attributes['href'] ?? '';
          if (href.isEmpty || seenHrefs.contains(href)) continue;
          seenHrefs.add(href);

          final epNumMatch = RegExp(r'~(\d+)').firstMatch(href);
          final epNum = epNumMatch != null ? epNumMatch.group(1)! : "${episodes.length + 1}";
          final epTitle = a.text.trim().isNotEmpty
              ? a.text.trim()
              : "$title - Episode $epNum";
          final epUrl = href.startsWith('http') ? href : "$baseUrl$href";

          episodes.add(
            EpisodeItem(
              id: 'ep_$epNum',
              episodeNumber: 'Episode $epNum',
              title: epTitle,
              url: epUrl,
              thumbnail: cover.isNotEmpty ? cover : iconUrl,
              duration: "24:00",
              sources: const [],
            ),
          );
        }

        // If no episode links found, create default episode for the series
        if (episodes.isEmpty) {
          final slug = url.replaceAll(RegExp(r'/+$'), '').split('/').last;
          episodes.add(
            EpisodeItem(
              id: 'ep_1',
              episodeNumber: 'Episode 1',
              title: "$title - Episode 1",
              url: "$baseUrl/watch/$slug~1",
              thumbnail: cover.isNotEmpty ? cover : iconUrl,
              duration: "24:00",
              sources: const [],
            ),
          );
        }

        // Pre-extract streams for the first episode
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

        return MediaDetail(
          id: url.hashCode.toString(),
          title: title,
          cover: cover.isNotEmpty ? cover : iconUrl,
          backdrop: cover.isNotEmpty ? cover : iconUrl,
          description: desc,
          studio: "HentaiDB Catalog",
          releaseDate: "2024",
          tags: tags.isNotEmpty ? tags : ["Series", "HentaiDB", "Indexed"],
          episodes: episodes,
          playbackHeatmap: const [0.1, 0.4, 0.7, 0.95, 0.85, 0.6, 0.9, 1.0, 0.5],
          sceneMarkers: [
            SceneMarker(title: "Opening", timestampSeconds: 0),
            SceneMarker(title: "Climax 🔥", timestampSeconds: 680),
          ],
        );
      }
    } catch (_) {}

    return MediaDetail(
      id: url,
      title: "HentaiDB Title",
      cover: iconUrl,
      description: "Unable to load details.",
      episodes: const [],
    );
  }

  @override
  Future<List<StreamSource>> extractVideoStreams(String videoUrl) async {
    final List<StreamSource> sources = [];
    try {
      final fullUrl = videoUrl.startsWith('http') ? videoUrl : "$baseUrl$videoUrl";
      final response = await http
          .get(Uri.parse(fullUrl), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = response.body;

        // 1. Try extracting window.EP={...} JSON payload
        final epMatch = RegExp(r'window\.EP\s*=\s*(\{.+?\})(?:;|</script>)', dotAll: true).firstMatch(body);
        if (epMatch != null) {
          try {
            final epData = json.decode(epMatch.group(1)!);
            final srcList = epData['src'] as List? ?? [];
            for (final s in srcList) {
              if (s is! Map) continue;
              final file = s['file']?.toString() ?? "";
              final quality = s['q']?.toString() ?? "${s['r'] ?? '720'}p";
              if (file.isNotEmpty) {
                final fileUrl = file.startsWith('http') ? file : "$baseUrl$file";
                sources.add(
                  StreamSource(
                    label: "HentaiDB MP4 ($quality)",
                    url: fileUrl,
                    protocol: StreamProtocol.directMp4,
                    format: "mp4",
                    headers: const {'Referer': 'https://hentaidb.xyz/'},
                  ),
                );
              }
            }
          } catch (_) {}
        }

        // 2. Fallback: regex search for mp4 files
        if (sources.isEmpty) {
          final mp4Matches = RegExp(r'"(/v/[^"]+\.mp4)"').allMatches(body);
          for (final m in mp4Matches) {
            final path = m.group(1)!;
            final fileUrl = "$baseUrl$path";
            if (!sources.any((s) => s.url == fileUrl)) {
              sources.add(
                StreamSource(
                  label: "HentaiDB Direct MP4 (1080p)",
                  url: fileUrl,
                  protocol: StreamProtocol.directMp4,
                  format: "mp4",
                  headers: const {'Referer': 'https://hentaidb.xyz/'},
                ),
              );
            }
          }
        }
      }
    } catch (_) {}
    return sources;
  }

  @override
  Future<ExtensionTaxonomy> fetchTaxonomy() async {
    return hentaiDbTaxonomy;
  }

  @override
  Future<List<MediaItem>> fetchTaxonomyFeed(CatalogItem item, int page) async {
    try {
      if (item.endpointPath != null && item.endpointPath!.contains("tag=")) {
        final url = "$baseUrl/?tag=${Uri.encodeComponent(item.name)}&page=$page";
        final response = await http
            .get(Uri.parse(url), headers: _headers)
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final items = _parseSeriesCards(response.body);
          if (items.isNotEmpty) return items;
        }
      } else if (item.endpointPath != null && item.endpointPath!.startsWith("/s/")) {
        final slug = item.slug;
        final cover = hentaiDbSeriesCovers[slug] ?? "";
        return [
          MediaItem(
            id: "$baseUrl/s/$slug",
            title: item.name,
            cover: cover.isNotEmpty ? cover : iconUrl,
            url: "$baseUrl/s/$slug",
            extensionId: id,
            tags: [item.categoryGroup ?? "Series"],
          )
        ];
      }
    } catch (_) {}

    return search(item.name, page);
  }

  List<MediaItem> _parseSeriesCards(String html) {
    final List<MediaItem> result = [];
    final doc = html_parser.parse(html);
    final links = doc.querySelectorAll('a[href^="/s/"]');
    final seenSlugs = <String>{};

    for (final a in links) {
      final href = a.attributes['href'] ?? '';
      final slugMatch = RegExp(r'/s/([^/?#]+)').firstMatch(href);
      if (slugMatch == null) continue;
      final slug = slugMatch.group(1)!;
      if (seenSlugs.contains(slug)) continue;
      seenSlugs.add(slug);

      var title = a.attributes['title']?.trim() ?? "";
      if (title.isEmpty) {
        title = a.querySelector('h2, h3, span, p')?.text.trim() ?? "";
      }
      if (title.isEmpty) {
        title = slug.replaceAll('-', ' ').toUpperCase();
      }

      var img = a.querySelector('img')?.attributes['src'] ??
          a.querySelector('img')?.attributes['data-src'] ??
          hentaiDbSeriesCovers[slug] ??
          "";

      if (img.startsWith('/')) img = "$baseUrl$img";

      final fullUrl = "$baseUrl/s/$slug";
      result.add(
        MediaItem(
          id: fullUrl,
          title: title,
          cover: img.isNotEmpty ? img : iconUrl,
          url: fullUrl,
          extensionId: id,
          tags: ["Series"],
        ),
      );
    }

    return result;
  }
}
