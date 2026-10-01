import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../base_extension.dart';
import '../../models/media_item.dart';
import '../../models/extension_manifest.dart';
import '../../models/catalog_model.dart';
import '../taxonomies/simply_hentai_taxonomy.dart';

/// Simply Hentai extension for HStream Neo.
/// Provides access to major anime franchise series, doujinshi,
/// character collections, and manga albums via official v3 REST API.
class SimplyHentaiExtension extends HentaiExtension {
  @override
  String get id => "simply_hentai";

  @override
  String get name => "Simply Hentai";

  @override
  String get baseUrl => "https://www.simply-hentai.com";

  final String apiBase = "https://api.simply-hentai.com/v3";

  @override
  String get iconUrl => "https://www.simply-hentai.com/favicon.ico";

  @override
  String get description => "Extensive anime franchise series, doujinshi albums, and high-res manga collections.";

  @override
  ViewLayoutType get defaultLayout => ViewLayoutType.staggeredMasonry3x4;

  @override
  bool get supportsShorts => false;

  @override
  List<ExtensionTab> get tabs => [
        ExtensionTab(id: "popular", title: "Popular", icon: Icons.whatshot_rounded),
        ExtensionTab(id: "newest", title: "Newest Drops", icon: Icons.fiber_new_rounded),
        ExtensionTab(id: "top_rated", title: "Top Rated", icon: Icons.star_rounded),
        ExtensionTab(id: "series", title: "Anime Franchises", icon: Icons.auto_stories_rounded),
      ];

  @override
  List<FilterGroup> get filters => [];

  final Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Accept': 'application/json',
    'Referer': 'https://www.simply-hentai.com/',
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
          url = "$apiBase/mangas?sort=newest&page=$page";
          break;
        case 'top_rated':
          url = "$apiBase/mangas?sort=top-rated&page=$page";
          break;
        case 'series':
          url = "$apiBase/series?sort=largest&page=$page";
          break;
        case 'popular':
        default:
          url = "$apiBase/mangas?sort=popular&page=$page";
          break;
      }

      final response = await http.get(Uri.parse(url), headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (tabId == 'series') {
          return _parseSeriesList(data['data'] as List? ?? []);
        } else {
          return _parseMangaList(data['data'] as List? ?? []);
        }
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
      final url = "$apiBase/search?query=${Uri.encodeComponent(query)}&page=$page";
      final response = await http.get(Uri.parse(url), headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseMangaList(data['data'] as List? ?? []);
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<MediaDetail> detail(String url) async {
    try {
      // Extract manga slug from url
      final slug = url.split('/').lastWhere((s) => s.isNotEmpty, orElse: () => "");
      final apiUrl = "$apiBase/mangas/$slug";
      final response = await http.get(Uri.parse(apiUrl), headers: _headers);
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        final item = res['data'] ?? res;
        final title = item['title'] ?? "Simply Hentai Album";
        final preview = item['preview'] as Map<String, dynamic>?;
        final cover = preview?['sizes']?['medium'] ?? preview?['sizes']?['thumb'] ?? preview?['url'] ?? "";
        final desc = item['description'] ?? "";
        final seriesName = item['series']?['title'];

        final tags = <String>[];
        if (seriesName != null) tags.add(seriesName.toString());

        return MediaDetail(
          id: url,
          title: title,
          cover: cover,
          description: desc,
          tags: tags,
          episodes: [
            EpisodeItem(
              id: url,
              episodeNumber: "Full Chapter",
              title: title,
              url: url,
              thumbnail: cover,
            ),
          ],
        );
      }
    } catch (_) {}
    return MediaDetail(
      id: url,
      title: "Simply Hentai Album",
      cover: "",
    );
  }

  @override
  Future<List<StreamSource>> extractVideoStreams(String videoUrl) async {
    try {
      // Simply Hentai is a manga/doujinshi portal; returns preview / reader stream
      final slug = videoUrl.split('/').lastWhere((s) => s.isNotEmpty, orElse: () => "");
      final apiUrl = "$apiBase/mangas/$slug";
      final response = await http.get(Uri.parse(apiUrl), headers: _headers);
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        final item = res['data'] ?? res;
        final preview = item['preview'] as Map<String, dynamic>?;
        final imgUrl = preview?['sizes']?['full'] ?? preview?['url'] ?? "";
        if (imgUrl.isNotEmpty) {
          return [
            StreamSource(
              label: "High-Res Reader",
              url: imgUrl,
              protocol: StreamProtocol.directMp4,
              headers: _headers,
            )
          ];
        }
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<ExtensionTaxonomy> fetchTaxonomy() async {
    return simplyHentaiTaxonomy;
  }

  @override
  Future<List<MediaItem>> fetchTaxonomyFeed(CatalogItem item, int page) async {
    try {
      // 1. Try search by franchise name
      final searchItems = await search(item.name, page);
      if (searchItems.isNotEmpty) return searchItems;

      // 2. Try tag query
      final url = "$apiBase/mangas?tag=${item.slug}&page=$page";
      final response = await http.get(Uri.parse(url), headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = _parseMangaList(data['data'] as List? ?? []);
        if (list.isNotEmpty) return list;
      }
    } catch (_) {}
    return [];
  }

  List<MediaItem> _parseMangaList(List items) {
    final List<MediaItem> result = [];
    for (final raw in items) {
      if (raw is! Map) continue;
      final m = Map<String, dynamic>.from(raw);
      final slug = m['slug'] ?? "";
      final title = m['title'] ?? "Album";
      final preview = m['preview'] as Map<String, dynamic>?;
      final cover = preview?['sizes']?['medium'] ?? preview?['sizes']?['thumb'] ?? preview?['url'] ?? "";
      final fullUrl = "$baseUrl/manga/$slug";

      final tags = <String>[];
      final seriesTitle = m['series']?['title'];
      if (seriesTitle != null) tags.add(seriesTitle.toString());

      result.add(MediaItem(
        id: fullUrl,
        title: title,
        cover: cover,
        url: fullUrl,
        extensionId: id,
        tags: tags,
      ));
    }
    return result;
  }

  List<MediaItem> _parseSeriesList(List items) {
    final List<MediaItem> result = [];
    for (final raw in items) {
      if (raw is! Map) continue;
      final s = Map<String, dynamic>.from(raw);
      final slug = s['slug'] ?? "";
      final title = s['title'] ?? "Series";
      final preview = s['preview'] as Map<String, dynamic>?;
      final cover = preview?['sizes']?['medium'] ?? preview?['sizes']?['thumb'] ?? preview?['url'] ?? simplyHentaiSeriesCovers[slug] ?? "";
      final fullUrl = "$baseUrl/series/$slug";

      result.add(MediaItem(
        id: fullUrl,
        title: title,
        cover: cover,
        url: fullUrl,
        extensionId: id,
        tags: ["Franchise"],
      ));
    }
    return result;
  }
}
