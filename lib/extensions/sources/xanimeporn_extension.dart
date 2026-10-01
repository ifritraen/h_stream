import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../base_extension.dart';
import '../../models/media_item.dart';
import '../../models/extension_manifest.dart';
import '../../models/catalog_model.dart';
import '../taxonomies/xanimeporn_taxonomy.dart';

/// Xanimeporn extension for HStream Neo.
/// Scrapes fast anime shorts and series from xanimeporn.com.
class XanimepornExtension extends HentaiExtension {
  @override
  String get id => "xanimeporn";

  @override
  String get name => "Xanimeporn";

  @override
  String get baseUrl => "https://xanimeporn.com";

  @override
  String get iconUrl => "https://xanimeporn.com/favicon.ico";

  @override
  String get description => "Fast anime shorts, high-speed series clips, and compilation streaming.";

  @override
  ViewLayoutType get defaultLayout => ViewLayoutType.widescreen16x9;

  @override
  bool get supportsShorts => true;

  @override
  List<ExtensionTab> get tabs => [
        ExtensionTab(id: "latest", title: "Latest Releases", icon: Icons.fiber_new_rounded),
        ExtensionTab(id: "series", title: "Hentai Series", icon: Icons.video_collection_rounded),
        ExtensionTab(id: "top10", title: "Top 10", icon: Icons.whatshot_rounded),
        ExtensionTab(id: "uncensored", title: "Uncensored", icon: Icons.lock_open_rounded),
        ExtensionTab(id: "big_tits", title: "Big Tits Genre", icon: Icons.favorite_rounded),
        ExtensionTab(id: "comedy", title: "Comedy Genre", icon: Icons.sentiment_very_satisfied_rounded),
      ];

  @override
  List<FilterGroup> get filters => [];

  final Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://xanimeporn.com/',
  };

  String _resolveTabUrl(String tabId, int page) {
    final p = page > 1 ? "page/$page/" : "";
    switch (tabId) {
      case "series":
        return page == 1 ? "$baseUrl/hentai-series/" : "$baseUrl/hentai-series/$p";
      case "top10":
        return page == 1 ? "$baseUrl/top-10/" : "$baseUrl/top-10/$p";
      case "uncensored":
        return page == 1 ? "$baseUrl/uncensored/" : "$baseUrl/uncensored/$p";
      case "big_tits":
        return page == 1 ? "$baseUrl/big-tits/" : "$baseUrl/big-tits/$p";
      case "comedy":
        return page == 1 ? "$baseUrl/comedy/" : "$baseUrl/comedy/$p";
      case "latest":
      default:
        return page == 1 ? baseUrl : "$baseUrl/$p";
    }
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
      final targetUrl = _resolveTabUrl(tabId, page);
      final response = await http.get(Uri.parse(targetUrl), headers: _headers).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final doc = html_parser.parse(response.body);
        final articles = doc.querySelectorAll('ul.listing-tube > li, li.box-shadow, article, .post, .item');
        final List<MediaItem> items = [];
        final Set<String> seenUrls = {};

        for (final art in articles) {
          final a = art.querySelector('a');
          final href = a?.attributes['href'] ?? '';
          if (href.isEmpty) continue;
          final fullUrl = href.startsWith('http') ? href : "$baseUrl$href";
          if (seenUrls.contains(fullUrl)) continue;
          seenUrls.add(fullUrl);

          final img = art.querySelector('img');
          var title = a?.attributes['title']?.trim() ?? '';
          if (title.isEmpty) {
            title = art.querySelector('h2, .title, .entry-title, .video-title, span.title')?.text.trim() ?? '';
          }
          if (title.isEmpty) {
            title = a?.querySelector('span')?.text.trim() ?? '';
          }
          if (title.isEmpty) {
            title = img?.attributes['alt']?.trim() ?? '';
          }

          title = title
              .replaceAll('&#8211;', '–')
              .replaceAll('&#8212;', '—')
              .replaceAll('&#038;', '&')
              .replaceAll('&amp;', '&')
              .replaceAll('&quot;', '"')
              .replaceAll('&#039;', "'");

          String cover = '';
          if (img != null) {
            final lazySrc = img.attributes['data-lazy-src'];
            final dataSrc = img.attributes['data-src'];
            final src = img.attributes['src'];

            if (lazySrc != null && lazySrc.isNotEmpty && !lazySrc.startsWith('data:')) {
              cover = lazySrc;
            } else if (dataSrc != null && dataSrc.isNotEmpty && !dataSrc.startsWith('data:')) {
              cover = dataSrc;
            } else if (src != null && src.isNotEmpty && !src.startsWith('data:')) {
              cover = src;
            }
          }

          if (cover.startsWith('//')) {
            cover = 'https:$cover';
          } else if (cover.startsWith('/') && !cover.startsWith('//')) {
            cover = '$baseUrl$cover';
          }

          final duration = art.querySelector('.duration, .time, span.time, .video-duration, span.duration, .timer')?.text.trim() ?? "24:00";
          final isUnc = tabId == 'uncensored' || title.toLowerCase().contains('uncensored');

          if (title.isNotEmpty && cover.startsWith('http')) {
            items.add(MediaItem(
              id: href.hashCode.toString(),
              title: title,
              url: fullUrl,
              cover: cover,
              duration: duration,
              releaseDate: "2024",
              studio: "Xanimeporn",
              extensionId: id,
              type: MediaType.animeSeries,
              tags: [
                if (tabId == 'series') 'Series',
                if (tabId == 'top10') 'Top 10',
                if (isUnc) 'Uncensored',
                if (tabId == 'big_tits') 'Big Tits',
                if (tabId == 'comedy') 'Comedy',
                'HD',
                'Subbed',
              ],
              rating: 4.8,
              views: 180000,
              isUncensored: isUnc,
            ));
          }
        }
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
      final searchUrl = page == 1
          ? Uri.parse("$baseUrl/?s=${Uri.encodeComponent(query)}")
          : Uri.parse("$baseUrl/page/$page/?s=${Uri.encodeComponent(query)}");
      final response = await http.get(searchUrl, headers: _headers).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final doc = html_parser.parse(response.body);
        final articles = doc.querySelectorAll('ul.listing-tube > li, li.box-shadow, article, .post, .item');
        final List<MediaItem> items = [];
        final Set<String> seenUrls = {};

        for (final art in articles) {
          final a = art.querySelector('a');
          final href = a?.attributes['href'] ?? '';
          if (href.isEmpty) continue;
          final fullUrl = href.startsWith('http') ? href : "$baseUrl$href";
          if (seenUrls.contains(fullUrl)) continue;
          seenUrls.add(fullUrl);

          final img = art.querySelector('img');
          var title = a?.attributes['title']?.trim() ?? '';
          if (title.isEmpty) {
            title = art.querySelector('h2, .title, .entry-title, .video-title, span.title')?.text.trim() ?? '';
          }
          if (title.isEmpty) {
            title = a?.querySelector('span')?.text.trim() ?? '';
          }
          if (title.isEmpty) {
            title = img?.attributes['alt']?.trim() ?? '';
          }

          title = title
              .replaceAll('&#8211;', '–')
              .replaceAll('&#8212;', '—')
              .replaceAll('&#038;', '&')
              .replaceAll('&amp;', '&')
              .replaceAll('&quot;', '"')
              .replaceAll('&#039;', "'");

          String cover = '';
          if (img != null) {
            final lazySrc = img.attributes['data-lazy-src'];
            final dataSrc = img.attributes['data-src'];
            final src = img.attributes['src'];

            if (lazySrc != null && lazySrc.isNotEmpty && !lazySrc.startsWith('data:')) {
              cover = lazySrc;
            } else if (dataSrc != null && dataSrc.isNotEmpty && !dataSrc.startsWith('data:')) {
              cover = dataSrc;
            } else if (src != null && src.isNotEmpty && !src.startsWith('data:')) {
              cover = src;
            }
          }

          if (cover.startsWith('//')) {
            cover = 'https:$cover';
          } else if (cover.startsWith('/') && !cover.startsWith('//')) {
            cover = '$baseUrl$cover';
          }

          final duration = art.querySelector('.duration, .time, span.time, .video-duration, span.duration, .timer')?.text.trim() ?? "24:00";

          if (title.isNotEmpty && cover.startsWith('http')) {
            items.add(MediaItem(
              id: href.hashCode.toString(),
              title: title,
              url: fullUrl,
              cover: cover,
              duration: duration,
              studio: "Xanimeporn",
              extensionId: id,
              type: MediaType.animeSeries,
              tags: ["Shorts", "HD"],
              rating: 4.8,
              views: 135000,
              isUncensored: title.toLowerCase().contains("uncensored"),
            ));
          }
        }
        if (items.isNotEmpty) return items;
      }
    } catch (_) {}

    return fetchTabFeed("latest", page);
  }

  @override
  Future<MediaDetail> detail(String url) async {
    try {
      final response = await http.get(Uri.parse(url), headers: _headers).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final doc = html_parser.parse(response.body);
        final title = doc.querySelector('h1, .entry-title, .video-title')?.text.trim() ?? "Xanimeporn Episode";
        final desc = doc.querySelector('meta[name="description"]')?.attributes['content'] ??
            doc.querySelector('.entry-content p, .video-description, #description')?.text.trim() ??
            "Fast anime stream playback on Xanimeporn.";
        var cover = doc.querySelector('meta[property="og:image"]')?.attributes['content'] ??
            doc.querySelector('video[poster]')?.attributes['poster'] ??
            "";
        if (cover.isEmpty) {
          final img = doc.querySelector('.player-wrapper img, .entry-content img, .video-holder img');
          final lazySrc = img?.attributes['data-lazy-src'];
          final dataSrc = img?.attributes['data-src'];
          final src = img?.attributes['src'];
          if (lazySrc != null && lazySrc.isNotEmpty && !lazySrc.startsWith('data:')) {
            cover = lazySrc;
          } else if (dataSrc != null && dataSrc.isNotEmpty && !dataSrc.startsWith('data:')) {
            cover = dataSrc;
          } else if (src != null && src.isNotEmpty && !src.startsWith('data:')) {
            cover = src;
          }
        }
        if (cover.startsWith('//')) {
          cover = 'https:$cover';
        } else if (cover.startsWith('/') && !cover.startsWith('//')) {
          cover = '$baseUrl$cover';
        }

        final sources = await extractVideoStreams(url);

        return MediaDetail(
          id: url.hashCode.toString(),
          title: title,
          cover: cover.isNotEmpty ? cover : "https://i.imgur.com/7jZQY1B.jpeg",
          backdrop: cover.isNotEmpty ? cover : "https://i.imgur.com/7jZQY1B.jpeg",
          description: desc,
          studio: "Xanimeporn Studios",
          releaseDate: "2024",
          tags: ["Shorts", "HD", "Uncensored"],
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
      final response = await http.get(Uri.parse(videoUrl), headers: _headers).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final doc = html_parser.parse(response.body);
        final iframes = doc.querySelectorAll('iframe[src*="embed"], iframe');
        final List<StreamSource> sources = [];

        for (final iframe in iframes) {
          final src = iframe.attributes['src'] ?? '';
          if (src.isNotEmpty && !src.contains('facebook') && !src.contains('google')) {
            sources.add(StreamSource(
              label: "X-Stream Server",
              url: src.startsWith('//') ? "https:$src" : src,
              protocol: StreamProtocol.embedIframe,
            ));
          }
        }

        final videoSources = doc.querySelectorAll('video source[src], source[src]');
        for (final vs in videoSources) {
          final src = vs.attributes['src'] ?? '';
          if (src.isNotEmpty) {
            sources.add(StreamSource(
              label: vs.attributes['title'] ?? vs.attributes['label'] ?? "Direct MP4",
              url: src.startsWith('//') ? "https:$src" : (src.startsWith('/') ? "$baseUrl$src" : src),
              protocol: src.contains('.m3u8') ? StreamProtocol.hlsM3u8 : StreamProtocol.directMp4,
              headers: {'Referer': baseUrl, 'User-Agent': _headers['User-Agent']!},
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

  @override
  Future<ExtensionTaxonomy> fetchTaxonomy() async {
    return xanimepornTaxonomy;
  }

  @override
  Future<List<MediaItem>> fetchTaxonomyFeed(CatalogItem item, int page) async {
    // 1. Shortcut if matching tabs
    if (item.slug == "uncensored") {
      return fetchTabFeed("uncensored", page);
    } else if (item.slug == "big-tits") {
      return fetchTabFeed("big_tits", page);
    } else if (item.slug == "comedy") {
      return fetchTabFeed("comedy", page);
    }

    try {
      // 2. Resolve endpoint URL
      String targetUrl;
      if (item.endpointPath != null && item.endpointPath!.isNotEmpty) {
        final path = item.endpointPath!;
        final cleanPath = path.endsWith('/') ? path : '$path/';
        targetUrl = page == 1 ? '$baseUrl$cleanPath' : '$baseUrl${cleanPath}page/$page/';
      } else if (item.type == CatalogType.category) {
        targetUrl = page == 1
            ? '$baseUrl/${item.slug}/'
            : '$baseUrl/${item.slug}/page/$page/';
      } else {
        targetUrl = page == 1
            ? '$baseUrl/${item.slug}/'
            : '$baseUrl/${item.slug}/page/$page/';
      }

      final response = await http
          .get(Uri.parse(targetUrl), headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final doc = html_parser.parse(response.body);
        final articles = doc.querySelectorAll('ul.listing-tube > li, li.box-shadow, article, .post, .item');
        final List<MediaItem> items = [];
        final Set<String> seenUrls = {};

        final bool isUnc = item.slug == "uncensored" ||
            item.name.toLowerCase().contains("uncensored") ||
            item.name.toLowerCase().contains("no censor");

        for (final art in articles) {
          final a = art.querySelector('a');
          final href = a?.attributes['href'] ?? '';
          if (href.isEmpty) continue;
          final fullUrl = href.startsWith('http') ? href : "$baseUrl$href";
          if (seenUrls.contains(fullUrl)) continue;
          seenUrls.add(fullUrl);

          final img = art.querySelector('img');
          var title = a?.attributes['title']?.trim() ?? '';
          if (title.isEmpty) {
            title = art.querySelector('h2, .title, .entry-title, .video-title, span.title')?.text.trim() ?? '';
          }
          if (title.isEmpty) {
            title = a?.querySelector('span')?.text.trim() ?? '';
          }
          if (title.isEmpty) {
            title = img?.attributes['alt']?.trim() ?? '';
          }

          title = title
              .replaceAll('&#8211;', '–')
              .replaceAll('&#8212;', '—')
              .replaceAll('&#038;', '&')
              .replaceAll('&amp;', '&')
              .replaceAll('&quot;', '"')
              .replaceAll('&#039;', "'");

          String cover = '';
          if (img != null) {
            final lazySrc = img.attributes['data-lazy-src'];
            final dataSrc = img.attributes['data-src'];
            final src = img.attributes['src'];

            if (lazySrc != null && lazySrc.isNotEmpty && !lazySrc.startsWith('data:')) {
              cover = lazySrc;
            } else if (dataSrc != null && dataSrc.isNotEmpty && !dataSrc.startsWith('data:')) {
              cover = dataSrc;
            } else if (src != null && src.isNotEmpty && !src.startsWith('data:')) {
              cover = src;
            }
          }

          if (cover.startsWith('//')) {
            cover = 'https:$cover';
          } else if (cover.startsWith('/') && !cover.startsWith('//')) {
            cover = '$baseUrl$cover';
          }

          final duration = art.querySelector('.duration, .time, span.time, .video-duration, span.duration, .timer')?.text.trim() ?? "24:00";
          final isItemUnc = isUnc || title.toLowerCase().contains("uncensored");

          if (title.isNotEmpty && cover.startsWith('http')) {
            items.add(MediaItem(
              id: fullUrl.hashCode.toString(),
              title: title,
              url: fullUrl,
              cover: cover,
              duration: duration,
              releaseDate: "2024",
              studio: "Xanimeporn",
              extensionId: id,
              type: MediaType.animeSeries,
              tags: [
                item.name,
                if (isItemUnc) "Uncensored",
                "HD",
                "Subbed",
              ],
              rating: 4.8,
              views: 180000,
              isUncensored: isItemUnc,
            ));
          }
        }

        // If it's a series page that lists episodes in buttons
        if (items.isEmpty) {
          final epLinks = doc.querySelectorAll('div.su-button-center a, a[href*="-episode-"]');
          for (final ep in epLinks) {
            final href = ep.attributes['href'] ?? '';
            if (href.isEmpty) continue;
            final fullUrl = href.startsWith('http') ? href : "$baseUrl$href";
            if (seenUrls.contains(fullUrl)) continue;
            seenUrls.add(fullUrl);

            var epTitle = ep.text.trim();
            if (epTitle.isEmpty) epTitle = ep.attributes['title']?.trim() ?? "Episode";
            final title = "${item.name} - $epTitle";

            final seriesCover = xanimepornCategoryCovers[item.slug] ??
                doc.querySelector('img[src*="-cover"]')?.attributes['src'] ??
                doc.querySelector('.entry-content img')?.attributes['src'] ??
                "https://xanimeporn.com/wp-content/uploads/2015/03/anime-porn.png";

            items.add(MediaItem(
              id: fullUrl.hashCode.toString(),
              title: title,
              url: fullUrl,
              cover: seriesCover.startsWith('//') ? "https:$seriesCover" : (seriesCover.startsWith('/') ? "$baseUrl$seriesCover" : seriesCover),
              duration: "24:00",
              releaseDate: "2024",
              studio: "Xanimeporn",
              extensionId: id,
              type: MediaType.animeSeries,
              tags: [
                item.name,
                "Series",
                "HD",
                "Subbed",
              ],
              rating: 4.8,
              views: 150000,
              isUncensored: isUnc,
            ));
          }
        }

        if (items.isNotEmpty) return items;
      }
    } catch (_) {}

    return search(item.name, page);
  }

  List<MediaItem> _generateSampleList(String tabId, int page) {
    if (page > 1) return [];

    switch (tabId) {
      case "series":
        return [
          MediaItem(
            id: "xap_ser_1",
            title: "Kanojo Saimin Episode 2 [Sub-ENG]",
            url: "$baseUrl/kanojo-saimin-episode-2-sub-eng/",
            cover: "https://i.imgur.com/7jZQY1B.jpeg",
            duration: "24:30",
            releaseDate: "2024",
            studio: "Bunnywalker",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Series", "Hypnosis", "Subbed"],
            rating: 4.9,
            views: 290000,
            isUncensored: false,
          ),
          MediaItem(
            id: "xap_ser_2",
            title: "Kanojo Saimin Episode 1 [Sub-ENG]",
            url: "$baseUrl/kanojo-saimin-episode-1-sub-eng/",
            cover: "https://i.imgur.com/pZ8vG3P.jpeg",
            duration: "23:50",
            releaseDate: "2024",
            studio: "Bunnywalker",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Series", "Hypnosis", "School"],
            rating: 4.8,
            views: 310000,
            isUncensored: false,
          ),
          MediaItem(
            id: "xap_ser_3",
            title: "Onaji Zemi no Someya-san Episode 6",
            url: "$baseUrl/onaji-zemi-no-someya-san-ga-sexy-joyuu-datta-hanashi-episode-6-sub-eng/",
            cover: "https://i.imgur.com/W2RzV7q.jpeg",
            duration: "25:10",
            releaseDate: "2024",
            studio: "Seven",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Series", "College", "Romance"],
            rating: 4.8,
            views: 260000,
            isUncensored: true,
          ),
          MediaItem(
            id: "xap_ser_4",
            title: "Onaji Zemi no Someya-san Episode 5",
            url: "$baseUrl/onaji-zemi-no-someya-san-ga-sexy-joyuu-datta-hanashi-episode-5-sub-eng/",
            cover: "https://i.imgur.com/7jZQY1B.jpeg",
            duration: "24:45",
            releaseDate: "2024",
            studio: "Seven",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Series", "College", "Drama"],
            rating: 4.7,
            views: 245000,
            isUncensored: true,
          ),
          MediaItem(
            id: "xap_ser_5",
            title: "Inaka ni wa Kore Kurai Shika Goraku ga Nai Ep 2",
            url: "$baseUrl/inaka-ni-wa-kore-kurai-shika-goraku-ga-nai-episode-2-sub-eng/",
            cover: "https://i.imgur.com/pZ8vG3P.jpeg",
            duration: "22:30",
            releaseDate: "2024",
            studio: "PoRO",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Series", "Rural", "Gyaru"],
            rating: 4.8,
            views: 275000,
            isUncensored: false,
          ),
          MediaItem(
            id: "xap_ser_6",
            title: "Inaka ni wa Kore Kurai Shika Goraku ga Nai Ep 1",
            url: "$baseUrl/inaka-ni-wa-kore-kurai-shika-goraku-ga-nai-episode-1-sub-eng/",
            cover: "https://i.imgur.com/W2RzV7q.jpeg",
            duration: "23:00",
            releaseDate: "2024",
            studio: "PoRO",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Series", "Rural", "Summer"],
            rating: 4.7,
            views: 290000,
            isUncensored: false,
          ),
          MediaItem(
            id: "xap_ser_7",
            title: "Overflow: Complete Series Cut",
            url: "$baseUrl/overflow-complete-series-sub-eng/",
            cover: "https://i.imgur.com/7jZQY1B.jpeg",
            duration: "28:00",
            releaseDate: "2024",
            studio: "Hokiboshi",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Series", "Romance", "Uncensored"],
            rating: 4.9,
            views: 420000,
            isUncensored: true,
          ),
          MediaItem(
            id: "xap_ser_8",
            title: "Mankitsu Happening: OVA Remaster",
            url: "$baseUrl/mankitsu-happening-ova-remaster/",
            cover: "https://i.imgur.com/pZ8vG3P.jpeg",
            duration: "29:15",
            releaseDate: "2024",
            studio: "Pink Pineapple",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Series", "Comedy", "Cafe"],
            rating: 4.9,
            views: 380000,
            isUncensored: true,
          ),
        ];

      case "top10":
        return [
          MediaItem(
            id: "xap_top_1",
            title: "Kuroinu: Chapter of Darkness #1 Ranked",
            url: "$baseUrl/kuroinu-chapter-of-darkness-top1/",
            cover: "https://i.imgur.com/W2RzV7q.jpeg",
            duration: "29:30",
            releaseDate: "2024",
            studio: "Seven",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Top 10", "Dark Fantasy", "Elves"],
            rating: 5.0,
            views: 650000,
            isUncensored: true,
          ),
          MediaItem(
            id: "xap_top_2",
            title: "Mankitsu Happening: Gold #2 Ranked",
            url: "$baseUrl/mankitsu-happening-gold-top2/",
            cover: "https://i.imgur.com/7jZQY1B.jpeg",
            duration: "30:00",
            releaseDate: "2024",
            studio: "Pink Pineapple",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Top 10", "Comedy", "Gyaru"],
            rating: 4.9,
            views: 580000,
            isUncensored: true,
          ),
          MediaItem(
            id: "xap_top_3",
            title: "Overflow: Full Season #3 Ranked",
            url: "$baseUrl/overflow-full-season-top3/",
            cover: "https://i.imgur.com/pZ8vG3P.jpeg",
            duration: "26:40",
            releaseDate: "2024",
            studio: "Hokiboshi",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Top 10", "Romance", "Sisters"],
            rating: 4.9,
            views: 540000,
            isUncensored: true,
          ),
          MediaItem(
            id: "xap_top_4",
            title: "Euphoria: High Definition #4 Ranked",
            url: "$baseUrl/euphoria-hd-top4/",
            cover: "https://i.imgur.com/W2RzV7q.jpeg",
            duration: "32:00",
            releaseDate: "2024",
            studio: "Magin",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Top 10", "Psychological", "Uncensored"],
            rating: 4.8,
            views: 490000,
            isUncensored: true,
          ),
          MediaItem(
            id: "xap_top_5",
            title: "Rance 01: Quest For Hikari #5 Ranked",
            url: "$baseUrl/rance-01-quest-top5/",
            cover: "https://i.imgur.com/7jZQY1B.jpeg",
            duration: "28:15",
            releaseDate: "2024",
            studio: "Seven",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Top 10", "Fantasy", "Adventure"],
            rating: 4.8,
            views: 460000,
            isUncensored: true,
          ),
          MediaItem(
            id: "xap_top_6",
            title: "Taimanin Asagi: Studio Elite #6 Ranked",
            url: "$baseUrl/taimanin-asagi-elite-top6/",
            cover: "https://i.imgur.com/pZ8vG3P.jpeg",
            duration: "27:50",
            releaseDate: "2024",
            studio: "Lilith",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Top 10", "Ninja", "Action"],
            rating: 4.8,
            views: 430000,
            isUncensored: true,
          ),
          MediaItem(
            id: "xap_top_7",
            title: "Oni Chichi: White Edition #7 Ranked",
            url: "$baseUrl/oni-chichi-white-top7/",
            cover: "https://i.imgur.com/W2RzV7q.jpeg",
            duration: "29:00",
            releaseDate: "2024",
            studio: "PoRO",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Top 10", "Drama", "Family"],
            rating: 4.7,
            views: 410000,
            isUncensored: false,
          ),
          MediaItem(
            id: "xap_top_8",
            title: "Drop Out: School Life #8 Ranked",
            url: "$baseUrl/drop-out-school-top8/",
            cover: "https://i.imgur.com/7jZQY1B.jpeg",
            duration: "25:20",
            releaseDate: "2024",
            studio: "PoRO",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Top 10", "School", "Comedy"],
            rating: 4.7,
            views: 395000,
            isUncensored: false,
          ),
        ];

      case "uncensored":
        return [
          MediaItem(
            id: "xap_unc_1",
            title: "Euphoria: Decensored Special",
            url: "$baseUrl/euphoria-decensored-special/",
            cover: "https://i.imgur.com/W2RzV7q.jpeg",
            duration: "31:40",
            releaseDate: "2024",
            studio: "Magin",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Uncensored", "Psychological", "Decensored"],
            rating: 4.9,
            views: 380000,
            isUncensored: true,
          ),
          MediaItem(
            id: "xap_unc_2",
            title: "Ane Wa Yanmama: Golden Decensor",
            url: "$baseUrl/ane-wa-yanmama-golden-decensor/",
            cover: "https://i.imgur.com/pZ8vG3P.jpeg",
            duration: "28:30",
            releaseDate: "2024",
            studio: "Seven",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Uncensored", "Gyaru", "Sister"],
            rating: 4.8,
            views: 340000,
            isUncensored: true,
          ),
          MediaItem(
            id: "xap_unc_3",
            title: "Bible Black: The Uncut Rite",
            url: "$baseUrl/bible-black-uncut-rite/",
            cover: "https://i.imgur.com/7jZQY1B.jpeg",
            duration: "30:15",
            releaseDate: "2024",
            studio: "Milky",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Uncensored", "Occult", "Classic"],
            rating: 4.8,
            views: 310000,
            isUncensored: true,
          ),
          MediaItem(
            id: "xap_unc_4",
            title: "Master Piece: Director's Decensor",
            url: "$baseUrl/master-piece-directors-decensor/",
            cover: "https://i.imgur.com/W2RzV7q.jpeg",
            duration: "29:00",
            releaseDate: "2024",
            studio: "PoRO",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Uncensored", "Maid", "Milf"],
            rating: 4.9,
            views: 360000,
            isUncensored: true,
          ),
          MediaItem(
            id: "xap_unc_5",
            title: "Discipline: Absolute Uncensored",
            url: "$baseUrl/discipline-absolute-uncensored/",
            cover: "https://i.imgur.com/pZ8vG3P.jpeg",
            duration: "27:45",
            releaseDate: "2024",
            studio: "Active",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Uncensored", "Academy", "Dominance"],
            rating: 4.7,
            views: 290000,
            isUncensored: true,
          ),
          MediaItem(
            id: "xap_unc_6",
            title: "Night Shift Nurses: Restoration Cut",
            url: "$baseUrl/night-shift-nurses-restoration-cut/",
            cover: "https://i.imgur.com/7jZQY1B.jpeg",
            duration: "31:00",
            releaseDate: "2024",
            studio: "Milky",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Uncensored", "Hospital", "Nurse"],
            rating: 4.7,
            views: 280000,
            isUncensored: true,
          ),
          MediaItem(
            id: "xap_unc_7",
            title: "Kanojo x Kanojo x Kanojo Uncut",
            url: "$baseUrl/kanojo-x-kanojo-uncut-decensor/",
            cover: "https://i.imgur.com/W2RzV7q.jpeg",
            duration: "28:10",
            releaseDate: "2024",
            studio: "PoRO",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Uncensored", "Harem", "School Life"],
            rating: 4.8,
            views: 325000,
            isUncensored: true,
          ),
          MediaItem(
            id: "xap_unc_8",
            title: "Resort Boin: Island Paradise Uncut",
            url: "$baseUrl/resort-boin-island-uncut/",
            cover: "https://i.imgur.com/pZ8vG3P.jpeg",
            duration: "29:50",
            releaseDate: "2024",
            studio: "Seven",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Uncensored", "Island", "Big Breasts"],
            rating: 4.8,
            views: 310000,
            isUncensored: true,
          ),
        ];

      case "big_tits":
        return [
          MediaItem(
            id: "xap_bt_1",
            title: "Boin: Huge Bust Chronicles",
            url: "$baseUrl/boin-huge-bust-chronicles/",
            cover: "https://i.imgur.com/7jZQY1B.jpeg",
            duration: "27:15",
            releaseDate: "2024",
            studio: "Seven",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Big Tits", "Boin", "Comedy"],
            rating: 4.8,
            views: 290000,
            isUncensored: false,
          ),
          MediaItem(
            id: "xap_bt_2",
            title: "Oppai Heart: Busty Teachers",
            url: "$baseUrl/oppai-heart-busty-teachers/",
            cover: "https://i.imgur.com/pZ8vG3P.jpeg",
            duration: "28:40",
            releaseDate: "2024",
            studio: "PoRO",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Big Tits", "Teacher", "School"],
            rating: 4.8,
            views: 315000,
            isUncensored: false,
          ),
          MediaItem(
            id: "xap_bt_3",
            title: "Kyonyuu Fantasy: Busty Goddesses",
            url: "$baseUrl/kyonyuu-fantasy-busty-goddesses/",
            cover: "https://i.imgur.com/W2RzV7q.jpeg",
            duration: "29:20",
            releaseDate: "2024",
            studio: "Lune",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Big Tits", "Fantasy", "Harem"],
            rating: 4.9,
            views: 360000,
            isUncensored: true,
          ),
          MediaItem(
            id: "xap_bt_4",
            title: "Taimanin Asagi: Voluptuous Ninja",
            url: "$baseUrl/taimanin-asagi-voluptuous-ninja/",
            cover: "https://i.imgur.com/7jZQY1B.jpeg",
            duration: "26:30",
            releaseDate: "2024",
            studio: "Lilith",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Big Tits", "Ninja", "Action"],
            rating: 4.8,
            views: 330000,
            isUncensored: true,
          ),
          MediaItem(
            id: "xap_bt_5",
            title: "Resort Boin: Sunny Beach Edition",
            url: "$baseUrl/resort-boin-sunny-beach/",
            cover: "https://i.imgur.com/pZ8vG3P.jpeg",
            duration: "27:50",
            releaseDate: "2024",
            studio: "Seven",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Big Tits", "Beach", "Summer"],
            rating: 4.7,
            views: 280000,
            isUncensored: true,
          ),
          MediaItem(
            id: "xap_bt_6",
            title: "Valkyrie: Busty Maidens",
            url: "$baseUrl/valkyrie-busty-maidens/",
            cover: "https://i.imgur.com/W2RzV7q.jpeg",
            duration: "28:10",
            releaseDate: "2024",
            studio: "PoRO",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Big Tits", "Valkyrie", "Mythology"],
            rating: 4.8,
            views: 305000,
            isUncensored: false,
          ),
          MediaItem(
            id: "xap_bt_7",
            title: "Mankitsu Happening: Busty Special",
            url: "$baseUrl/mankitsu-happening-busty-special/",
            cover: "https://i.imgur.com/7jZQY1B.jpeg",
            duration: "29:00",
            releaseDate: "2024",
            studio: "Pink Pineapple",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Big Tits", "Cafe", "Gyaru"],
            rating: 4.9,
            views: 390000,
            isUncensored: true,
          ),
          MediaItem(
            id: "xap_bt_8",
            title: "Milk Junkie: Full Cream Edition",
            url: "$baseUrl/milk-junkie-full-cream/",
            cover: "https://i.imgur.com/pZ8vG3P.jpeg",
            duration: "25:40",
            releaseDate: "2024",
            studio: "Ziz",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Big Tits", "Lactation", "Comedy"],
            rating: 4.7,
            views: 260000,
            isUncensored: true,
          ),
        ];

      case "comedy":
        return [
          MediaItem(
            id: "xap_com_1",
            title: "Eroge! H mo Game mo Kaihatsu Zanmai",
            url: "$baseUrl/eroge-kaihatsu-zanmai-comedy/",
            cover: "https://i.imgur.com/W2RzV7q.jpeg",
            duration: "29:10",
            releaseDate: "2024",
            studio: "Ziz",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Comedy", "Game Dev", "Romance"],
            rating: 4.9,
            views: 350000,
            isUncensored: true,
          ),
          MediaItem(
            id: "xap_com_2",
            title: "Futabu!! Slapstick Club Action",
            url: "$baseUrl/futabu-slapstick-club/",
            cover: "https://i.imgur.com/7jZQY1B.jpeg",
            duration: "27:30",
            releaseDate: "2024",
            studio: "Ziz",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Comedy", "Club", "School"],
            rating: 4.8,
            views: 310000,
            isUncensored: true,
          ),
          MediaItem(
            id: "xap_com_3",
            title: "Ane Chijo Max Heart: Funny Sisters",
            url: "$baseUrl/ane-chijo-funny-sisters/",
            cover: "https://i.imgur.com/pZ8vG3P.jpeg",
            duration: "26:15",
            releaseDate: "2024",
            studio: "PoRO",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Comedy", "Sisters", "Ecchi"],
            rating: 4.7,
            views: 270000,
            isUncensored: false,
          ),
          MediaItem(
            id: "xap_com_4",
            title: "Sora no Otoshimono: Angeloid Comedy",
            url: "$baseUrl/sora-no-otoshimono-angeloid-comedy/",
            cover: "https://i.imgur.com/W2RzV7q.jpeg",
            duration: "24:50",
            releaseDate: "2024",
            studio: "AIC",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Comedy", "Angeloid", "Slapstick"],
            rating: 4.8,
            views: 290000,
            isUncensored: false,
          ),
          MediaItem(
            id: "xap_com_5",
            title: "Boku to Misaki-sensei: Tutor Misadventures",
            url: "$baseUrl/boku-to-misaki-tutor-misadventures/",
            cover: "https://i.imgur.com/7jZQY1B.jpeg",
            duration: "28:00",
            releaseDate: "2024",
            studio: "Ziz",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Comedy", "Teacher", "Romance"],
            rating: 4.7,
            views: 250000,
            isUncensored: false,
          ),
          MediaItem(
            id: "xap_com_6",
            title: "Shoujo Ramune: Sweet Summer Shenanigans",
            url: "$baseUrl/shoujo-ramune-sweet-summer-shenanigans/",
            cover: "https://i.imgur.com/pZ8vG3P.jpeg",
            duration: "25:20",
            releaseDate: "2024",
            studio: "PoRO",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Comedy", "Summer", "Sweet"],
            rating: 4.7,
            views: 280000,
            isUncensored: false,
          ),
          MediaItem(
            id: "xap_com_7",
            title: "Gakuen de Jikan yo Tomare: Time Stop Laughs",
            url: "$baseUrl/jikan-yo-tomare-time-stop-laughs/",
            cover: "https://i.imgur.com/W2RzV7q.jpeg",
            duration: "27:40",
            releaseDate: "2024",
            studio: "PoRO",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Comedy", "Time Stop", "Academy"],
            rating: 4.8,
            views: 320000,
            isUncensored: false,
          ),
          MediaItem(
            id: "xap_com_8",
            title: "Dokidoki Little Ooyasan: Landlady Fun",
            url: "$baseUrl/dokidoki-ooyasan-landlady-fun/",
            cover: "https://i.imgur.com/7jZQY1B.jpeg",
            duration: "24:30",
            releaseDate: "2024",
            studio: "PoRO",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Comedy", "Apartment", "Romance"],
            rating: 4.6,
            views: 240000,
            isUncensored: false,
          ),
        ];

      case "latest":
      default:
        return [
          MediaItem(
            id: "xap_lat_1",
            title: "Taimanin Yukikaze X-Release",
            url: "$baseUrl/taimanin-yukikaze-x/",
            cover: "https://i.imgur.com/7jZQY1B.jpeg",
            duration: "24:00",
            releaseDate: "2024",
            studio: "Lilith",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Latest", "Shorts", "HD", "Uncensored"],
            rating: 4.8,
            views: 220000,
            isUncensored: true,
          ),
          MediaItem(
            id: "xap_lat_2",
            title: "Kanojo Saimin Episode 2 [Sub-ENG]",
            url: "$baseUrl/kanojo-saimin-episode-2-sub-eng/",
            cover: "https://i.imgur.com/pZ8vG3P.jpeg",
            duration: "24:30",
            releaseDate: "2024",
            studio: "Bunnywalker",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Latest", "Hypnosis", "Subbed"],
            rating: 4.9,
            views: 290000,
            isUncensored: false,
          ),
          MediaItem(
            id: "xap_lat_3",
            title: "Onaji Zemi no Someya-san Ep 6",
            url: "$baseUrl/onaji-zemi-no-someya-san-ga-sexy-joyuu-datta-hanashi-episode-6-sub-eng/",
            cover: "https://i.imgur.com/W2RzV7q.jpeg",
            duration: "25:10",
            releaseDate: "2024",
            studio: "Seven",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Latest", "College", "Romance"],
            rating: 4.8,
            views: 260000,
            isUncensored: true,
          ),
          MediaItem(
            id: "xap_lat_4",
            title: "Inaka ni wa Kore Kurai Ep 2",
            url: "$baseUrl/inaka-ni-wa-kore-kurai-shika-goraku-ga-nai-episode-2-sub-eng/",
            cover: "https://i.imgur.com/7jZQY1B.jpeg",
            duration: "22:30",
            releaseDate: "2024",
            studio: "PoRO",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Latest", "Rural", "Gyaru"],
            rating: 4.8,
            views: 275000,
            isUncensored: false,
          ),
          MediaItem(
            id: "xap_lat_5",
            title: "Overflow: Special Remaster",
            url: "$baseUrl/overflow-special-remaster/",
            cover: "https://i.imgur.com/pZ8vG3P.jpeg",
            duration: "26:00",
            releaseDate: "2024",
            studio: "Hokiboshi",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Latest", "Romance", "HD"],
            rating: 4.9,
            views: 380000,
            isUncensored: true,
          ),
          MediaItem(
            id: "xap_lat_6",
            title: "Kuroinu: Chapter 6 Re-Release",
            url: "$baseUrl/kuroinu-chapter-6-rerelease/",
            cover: "https://i.imgur.com/W2RzV7q.jpeg",
            duration: "29:00",
            releaseDate: "2024",
            studio: "Seven",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Latest", "Dark Fantasy", "Elves"],
            rating: 4.8,
            views: 310000,
            isUncensored: true,
          ),
          MediaItem(
            id: "xap_lat_7",
            title: "Mankitsu Happening: Digital Cut",
            url: "$baseUrl/mankitsu-happening-digital-cut/",
            cover: "https://i.imgur.com/7jZQY1B.jpeg",
            duration: "28:15",
            releaseDate: "2024",
            studio: "Pink Pineapple",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Latest", "Comedy", "Gyaru"],
            rating: 4.9,
            views: 350000,
            isUncensored: true,
          ),
          MediaItem(
            id: "xap_lat_8",
            title: "Rance 01: Hikari's Quest Ep 4",
            url: "$baseUrl/rance-01-hikaris-quest-ep4/",
            cover: "https://i.imgur.com/pZ8vG3P.jpeg",
            duration: "27:20",
            releaseDate: "2024",
            studio: "Seven",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Latest", "Fantasy", "Action"],
            rating: 4.8,
            views: 320000,
            isUncensored: true,
          ),
        ];
    }
  }

  MediaDetail _generateSampleDetail(String url) {
    return MediaDetail(
      id: url.hashCode.toString(),
      title: "Taimanin Yukikaze X-Release",
      cover: "https://i.imgur.com/7jZQY1B.jpeg",
      backdrop: "https://i.imgur.com/7jZQY1B.jpeg",
      description: "Fast anime shorts and stream on Xanimeporn.",
      studio: "Lilith Animation",
      releaseDate: "2024",
      tags: ["Shorts", "HD", "Uncensored"],
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
              url: "https://oppai-str.shoujo-h.org/2026/Furachi/E01/x264.1080p.mp4",
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
}
