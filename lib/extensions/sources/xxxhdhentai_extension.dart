import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../base_extension.dart';
import '../../models/media_item.dart';
import '../../models/extension_manifest.dart';
import '../../models/catalog_model.dart';
import '../taxonomies/xxxhdhentai_taxonomy.dart';

/// HD Hentai (xxxhdhentai) extension for HStream Neo.
/// High-definition 2D/3D anime streaming tube with studio feeds,
/// category directories, and multi-protocol video extraction.
class XxxHdhentaiExtension extends HentaiExtension {
  @override
  String get id => "xxxhdhentai";

  @override
  String get name => "HD Hentai";

  @override
  String get baseUrl => "https://hdhentai.tv";

  @override
  String get iconUrl => "https://hdhentai.tv/favicon.ico";

  @override
  String get description => "High-definition 2D and 3D anime video tube with studio catalogs and fast streaming.";

  @override
  ViewLayoutType get defaultLayout => ViewLayoutType.widescreen16x9;

  @override
  bool get supportsShorts => true;

  @override
  List<ExtensionTab> get tabs => [
        ExtensionTab(id: "latest", title: "Latest Releases", icon: Icons.fiber_new_rounded),
        ExtensionTab(id: "3d", title: "3D Animation", icon: Icons.view_in_ar_rounded),
        ExtensionTab(id: "hanime", title: "Hanime Series", icon: Icons.movie_rounded),
        ExtensionTab(id: "censored", title: "Censored Vault", icon: Icons.lock_rounded),
        ExtensionTab(id: "harem", title: "Harem Tropes", icon: Icons.favorite_rounded),
      ];

  @override
  List<FilterGroup> get filters => [];

  final Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hdhentai.tv/',
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
      final p = page > 1 ? "page/$page/" : "";
      switch (tabId) {
        case '3d':
          url = page == 1 ? "$baseUrl/category/3d/" : "$baseUrl/category/3d/$p";
          break;
        case 'hanime':
          url = page == 1 ? "$baseUrl/category/hanime/" : "$baseUrl/category/hanime/$p";
          break;
        case 'censored':
          url = page == 1 ? "$baseUrl/category/censored/" : "$baseUrl/category/censored/$p";
          break;
        case 'harem':
          url = page == 1 ? "$baseUrl/category/harem/" : "$baseUrl/category/harem/$p";
          break;
        case 'latest':
        default:
          url = page == 1 ? "$baseUrl/" : "$baseUrl/$p";
          break;
      }

      final response = await http.get(Uri.parse(url), headers: _headers);
      if (response.statusCode == 200) {
        return _parseCardsFromHtml(response.body);
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
      final p = page > 1 ? "page/$page/" : "";
      final url = page == 1 ? "$baseUrl/?s=${Uri.encodeComponent(query)}" : "$baseUrl/$p?s=${Uri.encodeComponent(query)}";
      final response = await http.get(Uri.parse(url), headers: _headers);
      if (response.statusCode == 200) {
        return _parseCardsFromHtml(response.body);
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<MediaDetail> detail(String url) async {
    try {
      final response = await http.get(Uri.parse(url), headers: _headers);
      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        final title = document.querySelector('h1, .video-title, .entry-title')?.text.trim() ?? "HD Hentai Video";
        final img = document.querySelector('meta[property="og:image"]')?.attributes['content'] ??
            document.querySelector('.video-player img, img.thumb')?.attributes['src'] ??
            "";
        final desc = document.querySelector('.video-description, .entry-content, meta[name="description"]')?.text.trim() ?? "";

        final tags = document
            .querySelectorAll('a[href*="/tag/"], a[href*="/category/"]')
            .map((e) => e.text.trim())
            .where((t) => t.isNotEmpty)
            .toList();

        return MediaDetail(
          id: url,
          title: title,
          cover: img,
          description: desc,
          tags: tags,
          episodes: [
            EpisodeItem(
              id: url,
              episodeNumber: "1",
              title: title,
              url: url,
              thumbnail: img,
            ),
          ],
        );
      }
    } catch (_) {}
    return MediaDetail(
      id: url,
      title: "HD Hentai Video",
      cover: "",
    );
  }

  @override
  Future<List<StreamSource>> extractVideoStreams(String videoUrl) async {
    try {
      final response = await http.get(Uri.parse(videoUrl), headers: _headers);
      if (response.statusCode == 200) {
        final body = response.body;
        final document = html_parser.parse(body);

        // 1. Direct video source in document
        final videoSrc = document.querySelector('video source, video')?.attributes['src'];
        if (videoSrc != null && videoSrc.isNotEmpty) {
          final resolvedUrl = videoSrc.startsWith('//') ? "https:$videoSrc" : videoSrc;
          return [
            StreamSource(
              label: "1080p HD",
              url: resolvedUrl,
              protocol: StreamProtocol.directMp4,
              headers: _headers,
            )
          ];
        }

        // 2. Iframe embed player
        final iframe = document.querySelector('iframe[src*="embed"], iframe[src*="player"], .video-embed iframe');
        final iframeSrc = iframe?.attributes['src'];
        if (iframeSrc != null && iframeSrc.isNotEmpty) {
          final resolvedUrl = iframeSrc.startsWith('//') ? "https:$iframeSrc" : iframeSrc;
          return [
            StreamSource(
              label: "Embed Player",
              url: resolvedUrl,
              protocol: StreamProtocol.embedIframe,
              headers: {'Referer': baseUrl, ..._headers},
            )
          ];
        }
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<ExtensionTaxonomy> fetchTaxonomy() async {
    return hdHentaiTaxonomy;
  }

  @override
  Future<List<MediaItem>> fetchTaxonomyFeed(CatalogItem item, int page) async {
    try {
      final basePath = item.endpointPath ?? "/category/${item.slug}/";
      final cleanBase = basePath.endsWith('/') ? basePath : "$basePath/";
      final url = page == 1 ? "$baseUrl$cleanBase" : "$baseUrl${cleanBase}page/$page/";

      final response = await http.get(Uri.parse(url), headers: _headers);
      if (response.statusCode == 200) {
        final items = _parseCardsFromHtml(response.body);
        if (items.isNotEmpty) return items;
      }
    } catch (_) {}

    // Fallback to search if category endpoint returns empty
    return search(item.name, page);
  }

  List<MediaItem> _parseCardsFromHtml(String html) {
    final List<MediaItem> items = [];
    final document = html_parser.parse(html);

    final blocks = document.querySelectorAll('div.video-block, div.item, article.post');
    for (final b in blocks) {
      if (b.classes.contains('video-block-cat')) continue;

      final aThumb = b.querySelector('a.thumb, a[href*="/video/"], a[href*="/hentai/"]');
      final href = aThumb?.attributes['href'] ?? "";
      if (href.isEmpty) continue;

      final fullUrl = href.startsWith('http') ? href : "$baseUrl$href";
      final title = b.querySelector('.title, span.title, h2 a')?.text.trim() ?? aThumb?.attributes['title']?.trim() ?? "Video";

      final img = b.querySelector('img');
      String thumb = img?.attributes['data-src'] ?? img?.attributes['data-lazy-src'] ?? img?.attributes['src'] ?? "";
      if (thumb.startsWith('//')) thumb = "https:$thumb";

      final duration = b.querySelector('.duration, .time')?.text.trim();

      items.add(MediaItem(
        id: fullUrl,
        title: title,
        cover: thumb,
        url: fullUrl,
        extensionId: id,
        duration: duration,
      ));
    }
    return items;
  }
}
