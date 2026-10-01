import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../base_extension.dart';
import '../../models/media_item.dart';
import '../../models/extension_manifest.dart';
import '../../models/catalog_model.dart';
import '../taxonomies/pornhub_taxonomy.dart';

/// PornHub Hentai extension for HStream Neo.
/// High-speed access to Pornhub's dedicated Hentai (c=36), Cosplay (c=241),
/// 3D, and 60FPS video feeds with multi-bitrate HLS and MP4 streaming.
class PornhubExtension extends HentaiExtension {
  @override
  String get id => "pornhub";

  @override
  String get name => "PornHub Hentai";

  @override
  String get baseUrl => "https://www.pornhub.com";

  @override
  String get iconUrl => "https://www.pornhub.com/favicon.ico";

  @override
  String get description => "PornHub dedicated Hentai category, 3D anime animations, and cosplay video feeds.";

  @override
  ViewLayoutType get defaultLayout => ViewLayoutType.widescreen16x9;

  @override
  bool get supportsShorts => true;

  @override
  List<ExtensionTab> get tabs => [
        ExtensionTab(id: "hentai", title: "Hentai Hub", icon: Icons.movie_filter_rounded),
        ExtensionTab(id: "cosplay", title: "Cosplay", icon: Icons.theater_comedy_rounded),
        ExtensionTab(id: "60fps", title: "60FPS HD", icon: Icons.speed_rounded),
        ExtensionTab(id: "japanese", title: "Japanese", icon: Icons.language_rounded),
        ExtensionTab(id: "vr", title: "VR 3D", icon: Icons.view_in_ar_rounded),
      ];

  @override
  List<FilterGroup> get filters => [];

  final Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Cookie': 'hasVisited=1; accessAgeDisclaimerPH=1; platform=pc',
    'Referer': 'https://www.pornhub.com/',
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
        case 'cosplay':
          path = "/video?c=241&page=$page";
          break;
        case '60fps':
          path = "/video?c=105&page=$page";
          break;
        case 'japanese':
          path = "/video?c=111&page=$page";
          break;
        case 'vr':
          path = "/vr?page=$page";
          break;
        case 'hentai':
        default:
          path = "/video?c=36&page=$page";
          break;
      }

      final response = await http.get(Uri.parse("$baseUrl$path"), headers: _headers);
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
      final url = "$baseUrl/video/search?search=${Uri.encodeComponent(query)}&page=$page";
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
        final title = document.querySelector('h1.title span, h1.title, .video-wrapper h1')?.text.trim() ?? "PornHub Video";
        final img = document.querySelector('meta[property="og:image"]')?.attributes['content'] ??
            document.querySelector('#player img')?.attributes['src'] ??
            "";

        final tags = document
            .querySelectorAll('.tagsWrapper a, .categoriesWrapper a, a[href*="/video/search?search="]')
            .map((e) => e.text.trim())
            .where((t) => t.isNotEmpty && !t.startsWith('+'))
            .toList();

        return MediaDetail(
          id: url,
          title: title,
          cover: img,
          tags: tags,
          episodes: [
            EpisodeItem(
              id: url,
              episodeNumber: "Full Video",
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
      title: "PornHub Video",
      cover: "",
    );
  }

  @override
  Future<List<StreamSource>> extractVideoStreams(String videoUrl) async {
    try {
      final response = await http.get(Uri.parse(videoUrl), headers: _headers);
      if (response.statusCode == 200) {
        final body = response.body;

        // 1. Check flashvars mediaDefinitions
        final regex = RegExp(r'var\s+flashvars_\d+\s*=\s*(\{.*?\});\s*(?:var|\n)', dotAll: true);
        final match = regex.firstMatch(body);
        if (match != null) {
          try {
            final jsonStr = match.group(1);
            if (jsonStr != null) {
              final data = json.decode(jsonStr);
              final mediaDefs = data['mediaDefinitions'] as List? ?? [];
              final List<StreamSource> sources = [];

              for (final def in mediaDefs) {
                if (def is Map) {
                  final vUrl = def['videoUrl']?.toString();
                  final format = def['format']?.toString() ?? 'mp4';
                  final quality = def['quality']?.toString() ?? '720p';

                  if (vUrl != null && vUrl.isNotEmpty) {
                    sources.add(StreamSource(
                      label: "PornHub $quality ($format)",
                      url: vUrl,
                      protocol: format == 'hls' ? StreamProtocol.hlsM3u8 : StreamProtocol.directMp4,
                      headers: _headers,
                      format: format,
                    ));
                  }
                }
              }
              if (sources.isNotEmpty) return sources;
            }
          } catch (_) {}
        }

        // 2. Direct MP4 or video source fallback
        final document = html_parser.parse(body);
        final videoSrc = document.querySelector('video source, video')?.attributes['src'];
        if (videoSrc != null && videoSrc.isNotEmpty) {
          return [
            StreamSource(
              label: "Direct MP4",
              url: videoSrc,
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
    return pornhubTaxonomy;
  }

  @override
  Future<List<MediaItem>> fetchTaxonomyFeed(CatalogItem item, int page) async {
    try {
      final path = item.endpointPath ?? "/video?c=${item.slug}";
      final separator = path.contains('?') ? '&' : '?';
      final url = page == 1 ? "$baseUrl$path" : "$baseUrl$path${separator}page=$page";

      final response = await http.get(Uri.parse(url), headers: _headers);
      if (response.statusCode == 200) {
        final items = _parseCardsFromHtml(response.body);
        if (items.isNotEmpty) return items;
      }
    } catch (_) {}

    return search(item.name, page);
  }

  List<MediaItem> _parseCardsFromHtml(String html) {
    final List<MediaItem> items = [];
    final document = html_parser.parse(html);

    final listItems = document.querySelectorAll('div.gridWrapper li.pcVideoListItem, li.pcVideoListItem');
    for (final li in listItems) {
      final vkey = li.attributes['data-video-vkey'] ?? li.attributes['_vkey'] ?? "";
      final aLink = li.querySelector('span.title a, a.linkVideoThumb');
      final href = aLink?.attributes['href'] ?? (vkey.isNotEmpty ? "/view_video.php?viewkey=$vkey" : "");
      if (href.isEmpty) continue;

      final fullUrl = href.startsWith('http') ? href : "$baseUrl$href";
      final title = aLink?.text.trim() ?? aLink?.attributes['title']?.trim() ?? "PornHub Video";

      final img = li.querySelector('img');
      String thumb = img?.attributes['data-src'] ?? img?.attributes['src'] ?? img?.attributes['data-thumb_url'] ?? "";
      if (thumb.startsWith('//')) thumb = "https:$thumb";

      final duration = li.querySelector('var.duration')?.text.trim();
      final viewsText = li.querySelector('span.views var')?.text.replaceAll(RegExp(r'[^0-9]'), '') ?? "";
      final views = int.tryParse(viewsText);

      items.add(MediaItem(
        id: fullUrl,
        title: title,
        cover: thumb,
        url: fullUrl,
        extensionId: id,
        duration: duration,
        views: views,
      ));
    }
    return items;
  }
}
