import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../base_extension.dart';
import '../../models/media_item.dart';
import '../../models/extension_manifest.dart';
import '../taxonomies/under_hentai_taxonomy.dart';
import '../../models/catalog_model.dart';

/// UnderHentai extension for HStream Neo.
/// Scrapes underground and classic anime vault from underhentai.net.
class UnderHentaiExtension extends HentaiExtension {
  @override
  String get id => "under_hentai";

  @override
  String get name => "UnderHentai";

  @override
  String get baseUrl => "https://www.underhentai.net";

  @override
  String get iconUrl => "https://www.underhentai.net/favicon.ico";

  @override
  String get description => "Underground vintage and classic anime vault with multi-server streams.";

  @override
  ViewLayoutType get defaultLayout => ViewLayoutType.widescreen16x9;

  @override
  bool get supportsShorts => false;

  @override
  List<ExtensionTab> get tabs => [
        ExtensionTab(id: "latest", title: "Latest Releases", icon: Icons.fiber_new_rounded),
        ExtensionTab(id: "popular", title: "Popular Anime", icon: Icons.whatshot_rounded),
        ExtensionTab(id: "uncensored", title: "Uncensored Genre", icon: Icons.lock_open_rounded),
        ExtensionTab(id: "ova", title: "OVA Series", icon: Icons.movie_filter_rounded),
        ExtensionTab(id: "3d", title: "3D / MMD", icon: Icons.animation_rounded),
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
            FilterOption(label: "Uncensored", value: "uncensored"),
            FilterOption(label: "OVA", value: "ova"),
            FilterOption(label: "3D / MMD", value: "3d"),
            FilterOption(label: "Classic", value: "classic"),
            FilterOption(label: "MILF", value: "milf"),
            FilterOption(label: "Harem", value: "harem"),
          ],
        ),
      ];

  final Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://www.underhentai.net/',
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
        case 'popular':
          path = '/popular/';
          break;
        case 'uncensored':
          path = '/genre/uncensored/';
          break;
        case 'ova':
          path = '/genre/ova/';
          break;
        case '3d':
          path = '/genre/3d/';
          break;
        case 'latest':
        default:
          path = '/';
          break;
      }
      final targetUrl = page == 1
          ? '$baseUrl$path'
          : (path == '/' ? '$baseUrl/page/$page/' : '$baseUrl${path}page/$page/');
      final response = await http.get(Uri.parse(targetUrl), headers: _headers).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final doc = html_parser.parse(response.body);
        final articles = doc.querySelectorAll('article, .post, .item-video, div.item');
        final List<MediaItem> items = [];
        final Set<String> seenUrls = {};

        for (final art in articles) {
          final a = art.querySelector('a.thumb-img, a[href*="/video/"]') ?? art.querySelector('a');
          final href = a?.attributes['href'] ?? '';
          if (href.isEmpty) continue;

          final fullUrl = href.startsWith('http') ? href : "$baseUrl$href";
          if (seenUrls.contains(fullUrl)) continue;
          seenUrls.add(fullUrl);

          final img = art.querySelector('img');
          var title = art.querySelector('h2, .title, .entry-title, h3')?.text.trim() ??
              a?.attributes['title']?.trim() ??
              img?.attributes['alt']?.trim() ??
              '';

          title = title
              .replaceAll('&#8211;', '–')
              .replaceAll('&#8212;', '—')
              .replaceAll('&#038;', '&')
              .replaceAll('&amp;', '&')
              .replaceAll('&quot;', '"')
              .replaceAll('&#039;', "'");

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
            cover = '$baseUrl$cover';
          }

          if (title.isNotEmpty && cover.startsWith('http')) {
            items.add(MediaItem(
              id: href.hashCode.toString(),
              title: title,
              url: fullUrl,
              cover: cover,
              duration: art.querySelector('.time, span.time, .duration')?.text.trim() ?? "24:00",
              releaseDate: "2024",
              studio: "UnderHentai Vault",
              extensionId: id,
              type: tabId == "3d" ? MediaType.mmd3D : MediaType.animeSeries,
              tags: [
                if (tabId == "uncensored") "Uncensored",
                if (tabId == "ova") "OVA",
                if (tabId == "3d") "3D / MMD",
                "Classic",
                "Underground",
                "HD",
              ],
              rating: 4.8,
              views: 140000,
              isUncensored: tabId == "uncensored" || title.toLowerCase().contains("uncensored"),
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
      final searchUrl = Uri.parse("$baseUrl/?s=${Uri.encodeComponent(query)}&page=$page");
      final response = await http.get(searchUrl, headers: _headers).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final doc = html_parser.parse(response.body);
        final articles = doc.querySelectorAll('article, .post, .item-video, div.item');
        final List<MediaItem> items = [];
        final Set<String> seenUrls = {};

        for (final art in articles) {
          final a = art.querySelector('a.thumb-img, a[href*="/video/"]') ?? art.querySelector('a');
          final href = a?.attributes['href'] ?? '';
          final fullUrl = href.startsWith('http') ? href : "$baseUrl$href";
          if (href.isEmpty || seenUrls.contains(fullUrl)) continue;
          seenUrls.add(fullUrl);

          final img = art.querySelector('img');
          var title = art.querySelector('h2, .title, .entry-title, h3')?.text.trim() ??
              a?.attributes['title']?.trim() ??
              img?.attributes['alt']?.trim() ??
              '';

          title = title
              .replaceAll('&#8211;', '–')
              .replaceAll('&#8212;', '—')
              .replaceAll('&#038;', '&')
              .replaceAll('&amp;', '&')
              .replaceAll('&quot;', '"')
              .replaceAll('&#039;', "'");

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
            cover = '$baseUrl$cover';
          }

          if (title.isNotEmpty && cover.startsWith('http')) {
            items.add(MediaItem(
              id: href.hashCode.toString(),
              title: title,
              url: fullUrl,
              cover: cover,
              duration: art.querySelector('.time, span.time, .duration')?.text.trim() ?? "24:00",
              studio: "UnderHentai Vault",
              extensionId: id,
              type: MediaType.animeSeries,
              tags: ["Classic", "HD"],
              rating: 4.8,
              views: 110000,
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
        final title = doc.querySelector('h1')?.text.trim() ?? "UnderHentai Vault Title";
        final desc = doc.querySelector('meta[name="description"]')?.attributes['content'] ??
            doc.querySelector('.entry-content p')?.text.trim() ??
            "Watch rare classic vault releases.";
        final cover = doc.querySelector('meta[property="og:image"]')?.attributes['content'] ?? "";

        final sources = await extractVideoStreams(url);

        return MediaDetail(
          id: url.hashCode.toString(),
          title: title,
          cover: cover.isNotEmpty ? cover : "https://i.imgur.com/7jZQY1B.jpeg",
          backdrop: cover.isNotEmpty ? cover : "https://i.imgur.com/7jZQY1B.jpeg",
          description: desc,
          studio: "UnderHentai Vault Studios",
          releaseDate: "2024",
          tags: ["Classic", "Underground", "Uncensored"],
          episodes: [
            EpisodeItem(
              id: "ep_1",
              episodeNumber: "Episode 1",
              title: title,
              url: url,
              thumbnail: cover,
              duration: "24:00",
              sources: sources,
            ),
          ],
          playbackHeatmap: [0.1, 0.35, 0.65, 0.95, 0.8, 0.4, 0.3, 0.9, 1.0, 0.4],
          sceneMarkers: [
            SceneMarker(title: "Opening", timestampSeconds: 0),
            SceneMarker(title: "Vault Climax 🔥", timestampSeconds: 700),
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
              label: "Vault Stream Server",
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

  @override
  Future<ExtensionTaxonomy> fetchTaxonomy() async {
    return underHentaiTaxonomy;
  }

  @override
  Future<List<MediaItem>> fetchTaxonomyFeed(CatalogItem item, int page) async {
    // 1. Direct tab feed mapping if matching standard tab
    if (item.slug == 'latest') {
      return fetchTabFeed('latest', page);
    }

    // 2. Determine target path on UnderHentai
    String path;
    if (item.endpointPath != null && item.endpointPath!.isNotEmpty) {
      path = item.endpointPath!;
    } else if (item.type == CatalogType.genre) {
      path = '/genre/${item.slug}/';
    } else {
      path = '/${item.slug}/';
    }

    // Ensure leading slash
    if (!path.startsWith('/')) path = '/$path';

    // 3. Handle Series / OVA single anime pages with episodes
    final isSingleSeries = item.categoryGroup == 'OVA & Classic Series' ||
        (!path.startsWith('/genre/') &&
            !path.startsWith('/releases/') &&
            path != '/' &&
            path != '/index/' &&
            path != '/uncensored/' &&
            !path.startsWith('/top/'));

    if (isSingleSeries) {
      try {
        final targetUrl = '$baseUrl$path';
        final response = await http
            .get(Uri.parse(targetUrl), headers: _headers)
            .timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final doc = html_parser.parse(response.body);
          final title = doc.querySelector('h1')?.text.trim() ?? item.name;
          final cover = doc.querySelector('meta[property="og:image"]')?.attributes['content'] ??
              doc.querySelector('.entry-content img, article img, img.img-d')?.attributes['src'] ??
              '';

          final watchLinks = doc.querySelectorAll('a[href*="/watch/"]');
          final List<MediaItem> epItems = [];
          final Set<String> seenWatch = {};

          for (int i = 0; i < watchLinks.length; i++) {
            final a = watchLinks[i];
            final href = a.attributes['href'] ?? '';
            if (href.isEmpty || seenWatch.contains(href)) continue;
            seenWatch.add(href);

            final epNum = i + 1;
            final fullWatchUrl = href.startsWith('http') ? href : '$baseUrl$href';
            epItems.add(MediaItem(
              id: href.hashCode.toString(),
              title: '$title - Episode $epNum',
              url: fullWatchUrl,
              cover: cover.isNotEmpty ? cover : 'https://static.underhentai.net/themes/undernet-bs5/assets/images/logo.svg',
              duration: '24:00',
              releaseDate: '2024',
              studio: 'UnderHentai Vault',
              extensionId: id,
              type: MediaType.animeSeries,
              tags: [item.name, 'OVA', 'Classic', 'Underground'],
              rating: 4.8,
              views: 120000,
              isUncensored: title.toLowerCase().contains('uncensored'),
            ));
          }

          if (epItems.isNotEmpty) return epItems;

          // If no separate episode links found, return the single series item
          return [
            MediaItem(
              id: path.hashCode.toString(),
              title: title,
              url: targetUrl,
              cover: cover.isNotEmpty ? cover : 'https://static.underhentai.net/themes/undernet-bs5/assets/images/logo.svg',
              duration: '26:00',
              releaseDate: '2024',
              studio: 'UnderHentai Vault',
              extensionId: id,
              type: MediaType.animeSeries,
              tags: [item.name, 'OVA', 'Classic'],
              rating: 4.8,
              views: 95000,
              isUncensored: title.toLowerCase().contains('uncensored'),
            ),
          ];
        }
      } catch (_) {}
    }

    // 4. Archive, Category, or Genre Listing Feed
    try {
      final normalizedPath = path.endsWith('/') ? path : '$path/';
      final targetUrl = page == 1
          ? '$baseUrl$normalizedPath'
          : '$baseUrl${normalizedPath}page/$page/';

      final response = await http
          .get(Uri.parse(targetUrl), headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final doc = html_parser.parse(response.body);
        final articles = doc.querySelectorAll('article, .post, .item-video, div.item, .post-card');
        final List<MediaItem> items = [];
        final Set<String> seenUrls = {};

        for (final art in articles) {
          final a = art.querySelector('a');
          final href = a?.attributes['href'] ?? '';
          if (href.isEmpty) continue;

          // Skip 3rd party ad networks
          if (href.contains('hentaipros') ||
              href.contains('nutaku') ||
              href.contains('patreon') ||
              href.contains('brazzers') ||
              href.contains('theporndude')) {
            continue;
          }

          final fullUrl = href.startsWith('http') ? href : '$baseUrl$href';
          if (seenUrls.contains(fullUrl)) continue;
          seenUrls.add(fullUrl);

          final img = art.querySelector('img');
          var title = art.querySelector('h3, h2, .title, .entry-title')?.text.trim() ??
              a?.attributes['title']?.trim() ??
              img?.attributes['alt']?.trim() ??
              '';

          title = title
              .replaceAll('&#8211;', '–')
              .replaceAll('&#8212;', '—')
              .replaceAll('&#038;', '&')
              .replaceAll('&amp;', '&')
              .replaceAll('&quot;', '"')
              .replaceAll('&#039;', "'");

          var cover = img?.attributes['src'] ??
              img?.attributes['data-src'] ??
              img?.attributes['data-lazy-src'] ??
              img?.attributes['data-original'] ??
              '';

          if (cover.startsWith('data:')) {
            cover = img?.attributes['src'] ?? '';
          }
          if (cover.startsWith('//')) {
            cover = 'https:$cover';
          } else if (cover.startsWith('/') && !cover.startsWith('//')) {
            cover = '$baseUrl$cover';
          }

          if (title.isNotEmpty && (cover.startsWith('http') || cover.isNotEmpty)) {
            items.add(MediaItem(
              id: href.hashCode.toString(),
              title: title,
              url: fullUrl,
              cover: cover.isNotEmpty ? cover : 'https://static.underhentai.net/themes/undernet-bs5/assets/images/logo.svg',
              duration: art.querySelector('.time, span.time, .duration')?.text.trim() ?? "24:00",
              releaseDate: item.categoryGroup == 'Annual Vaults' ? item.name.split(' ')[0] : '2024',
              studio: "UnderHentai Vault",
              extensionId: id,
              type: MediaType.animeSeries,
              tags: [
                item.name,
                if (item.type == CatalogType.genre) "Genre",
                if (item.categoryGroup != null) item.categoryGroup!,
                "Classic",
                "HD",
              ],
              rating: 4.8,
              views: 135000,
              isUncensored: item.slug == "uncensored" || title.toLowerCase().contains("uncensored"),
            ));
          }
        }
        if (items.isNotEmpty) return items;
      }
    } catch (_) {}

    // 5. Fallback live search on UnderHentai
    try {
      final searchResults = await search(item.name, page);
      if (searchResults.isNotEmpty) return searchResults;
    } catch (_) {}

    // 6. Curated Fallback
    return _generateTaxonomySampleList(item, page);
  }

  List<MediaItem> _generateTaxonomySampleList(CatalogItem item, int page) {
    if (page > 1) return [];
    final baseItems = _generateSampleList(
      item.slug == 'uncensored' ? 'uncensored' : 'latest',
      1,
    );
    return baseItems.map((m) {
      final updatedTags = List<String>.from(m.tags);
      if (!updatedTags.contains(item.name)) {
        updatedTags.insert(0, item.name);
      }
      return MediaItem(
        id: "uh_tax_${item.slug}_${m.id}",
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
        isUncensored: m.isUncensored || item.slug == 'uncensored',
      );
    }).toList();
  }

  List<MediaItem> _generateSampleList(String tabId, int page) {
    if (tabId == "popular") {
      return [
        MediaItem(
          id: "uh_pop_1",
          title: "Euphoria: High Voltage Remaster",
          url: "$baseUrl/euphoria-high-voltage/",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "28:30",
          releaseDate: "2024",
          studio: "Magin",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Psychological", "Underground", "Thriller"],
          rating: 4.9,
          views: 520000,
          isUncensored: true,
        ),
        MediaItem(
          id: "uh_pop_2",
          title: "Rance 01: The Quest for Hikari",
          url: "$baseUrl/rance-01-quest-for-hikari/",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "29:50",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Adventure", "Fantasy", "Action"],
          rating: 5.0,
          views: 490000,
          isUncensored: false,
        ),
        MediaItem(
          id: "uh_pop_3",
          title: "Overflow: Passionate Siblings Full Cut",
          url: "$baseUrl/overflow-passionate-siblings/",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "23:45",
          releaseDate: "2024",
          studio: "Hokiboshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance", "Popular", "Ecchi"],
          rating: 4.9,
          views: 610000,
          isUncensored: true,
        ),
        MediaItem(
          id: "uh_pop_4",
          title: "Taimanin Asagi: Shadow Battlefield",
          url: "$baseUrl/taimanin-asagi-shadow/",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "27:12",
          releaseDate: "2024",
          studio: "Lilith",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Action", "Ninja", "Sci-Fi"],
          rating: 4.8,
          views: 440000,
          isUncensored: false,
        ),
        MediaItem(
          id: "uh_pop_5",
          title: "Gakuen de Jikan yo Tomare",
          url: "$baseUrl/gakuen-de-jikan-yo-tomare/",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "25:20",
          releaseDate: "2024",
          studio: "BOOTLEG",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Time Stop", "School", "Popular"],
          rating: 4.8,
          views: 470000,
          isUncensored: false,
        ),
        MediaItem(
          id: "uh_pop_6",
          title: "Kyonyuu Fantasy: The Outer Realm",
          url: "$baseUrl/kyonyuu-fantasy-outer-realm/",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "28:15",
          releaseDate: "2024",
          studio: "DMM.com",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Fantasy", "Comedy", "Harem"],
          rating: 4.8,
          views: 395000,
          isUncensored: false,
        ),
        MediaItem(
          id: "uh_pop_7",
          title: "Master Piece The Animation Complete",
          url: "$baseUrl/master-piece-complete/",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "26:40",
          releaseDate: "2024",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Maid", "Harem", "Classic"],
          rating: 4.9,
          views: 460000,
          isUncensored: false,
        ),
        MediaItem(
          id: "uh_pop_8",
          title: "Boku no Pico: Classic Vault Memorial",
          url: "$baseUrl/boku-no-pico-memorial/",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "32:00",
          releaseDate: "2024",
          studio: "Natural High",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Vintage", "Classic", "Legendary"],
          rating: 4.6,
          views: 380000,
          isUncensored: false,
        ),
      ];
    } else if (tabId == "uncensored") {
      return [
        MediaItem(
          id: "uh_unc_1",
          title: "Discipline Zero Uncensored Cut",
          url: "$baseUrl/discipline-zero-uncensored/",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "28:50",
          releaseDate: "2024",
          studio: "Active",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Psychological", "Underground"],
          rating: 4.9,
          views: 380000,
          isUncensored: true,
        ),
        MediaItem(
          id: "uh_unc_2",
          title: "Starless: 21st Century Uncensored",
          url: "$baseUrl/starless-uncensored/",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "29:10",
          releaseDate: "2024",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Dark", "Mystery"],
          rating: 4.9,
          views: 340000,
          isUncensored: true,
        ),
        MediaItem(
          id: "uh_unc_3",
          title: "Immoral Sisters: Raw Decensored",
          url: "$baseUrl/immoral-sisters-raw/",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "24:30",
          releaseDate: "2024",
          studio: "Green Bunny",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Sisters", "Classic"],
          rating: 4.8,
          views: 310000,
          isUncensored: true,
        ),
        MediaItem(
          id: "uh_unc_4",
          title: "Ane Wa Yanmama Junyuu-chuu Uncensored",
          url: "$baseUrl/ane-wa-yanmama-uncensored/",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "26:45",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Milf", "Family"],
          rating: 4.9,
          views: 420000,
          isUncensored: true,
        ),
        MediaItem(
          id: "uh_unc_5",
          title: "Tropical Kiss: Uncensored Paradise",
          url: "$baseUrl/tropical-kiss-uncensored/",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "25:20",
          releaseDate: "2024",
          studio: "PoJu",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Beach", "Harem"],
          rating: 4.8,
          views: 295000,
          isUncensored: true,
        ),
        MediaItem(
          id: "uh_unc_6",
          title: "Pretty Shinon: Crystal Uncensored Edition",
          url: "$baseUrl/pretty-shinon-uncensored/",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "27:15",
          releaseDate: "2024",
          studio: "Pink Pineapple",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Fantasy", "Vintage"],
          rating: 4.7,
          views: 260000,
          isUncensored: true,
        ),
        MediaItem(
          id: "uh_unc_7",
          title: "Futanari Phantom: Decensored Vault",
          url: "$baseUrl/futanari-phantom-decensored/",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "23:55",
          releaseDate: "2024",
          studio: "Bunnywalker",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Fantasy", "Supernatural"],
          rating: 4.8,
          views: 330000,
          isUncensored: true,
        ),
        MediaItem(
          id: "uh_unc_8",
          title: "Cream Lemon: Vintage Uncensored Archival",
          url: "$baseUrl/cream-lemon-vintage-uncensored/",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "31:40",
          releaseDate: "2024",
          studio: "Aube",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Vintage", "Archival"],
          rating: 4.9,
          views: 360000,
          isUncensored: true,
        ),
      ];
    } else if (tabId == "ova") {
      return [
        MediaItem(
          id: "uh_ova_1",
          title: "La Blue Girl: Shikima OVA Chapter 1",
          url: "$baseUrl/la-blue-girl-shikima-ova-1/",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "32:10",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["OVA", "Ninja", "Classic", "Supernatural"],
          rating: 4.9,
          views: 410000,
          isUncensored: false,
        ),
        MediaItem(
          id: "uh_ova_2",
          title: "Dragon Knight 4: Legendary OVA",
          url: "$baseUrl/dragon-knight-4-ova/",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "29:40",
          releaseDate: "2024",
          studio: "Dandelion",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["OVA", "Fantasy", "Classic RPG"],
          rating: 4.8,
          views: 290000,
          isUncensored: false,
        ),
        MediaItem(
          id: "uh_ova_3",
          title: "Urotsukidoji: Legend of the Overfiend OVA",
          url: "$baseUrl/urotsukidoji-overfiend-ova/",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "45:00",
          releaseDate: "2024",
          studio: "Phoenix",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["OVA", "Dark Fantasy", "Horror", "Vintage"],
          rating: 4.9,
          views: 470000,
          isUncensored: true,
        ),
        MediaItem(
          id: "uh_ova_4",
          title: "Words Worth: Darkness and Light OVA",
          url: "$baseUrl/words-worth-darkness-light-ova/",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "28:25",
          releaseDate: "2024",
          studio: "Green Bunny",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["OVA", "Sword & Sorcery", "Fantasy"],
          rating: 4.8,
          views: 320000,
          isUncensored: false,
        ),
        MediaItem(
          id: "uh_ova_5",
          title: "Kite: Director's Cut OVA",
          url: "$baseUrl/kite-directors-cut-ova/",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "50:15",
          releaseDate: "2024",
          studio: "Arms Corporation",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["OVA", "Action", "Drama", "Cult Classic"],
          rating: 5.0,
          views: 530000,
          isUncensored: true,
        ),
        MediaItem(
          id: "uh_ova_6",
          title: "Mezzo Forte: Agent Assault OVA",
          url: "$baseUrl/mezzo-forte-agent-assault-ova/",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "31:00",
          releaseDate: "2024",
          studio: "Arms Corporation",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["OVA", "Action", "Comedy", "Gunplay"],
          rating: 4.9,
          views: 360000,
          isUncensored: false,
        ),
        MediaItem(
          id: "uh_ova_7",
          title: "Elven Bride: Forest Kingdom OVA",
          url: "$baseUrl/elven-bride-forest-kingdom-ova/",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "27:30",
          releaseDate: "2024",
          studio: "Studio Fantasia",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["OVA", "Elves", "Fantasy", "Magic"],
          rating: 4.8,
          views: 280000,
          isUncensored: false,
        ),
        MediaItem(
          id: "uh_ova_8",
          title: "Cream Lemon: Pop Chaser OVA",
          url: "$baseUrl/cream-lemon-pop-chaser-ova/",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "35:10",
          releaseDate: "2024",
          studio: "Aube Label",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["OVA", "Vintage 80s", "Sci-Fi", "Cyberpunk"],
          rating: 4.7,
          views: 240000,
          isUncensored: false,
        ),
      ];
    } else if (tabId == "3d") {
      return [
        MediaItem(
          id: "uh_3d_1",
          title: "Overwatch D.Va & Mercy Cyber Vault 3D",
          url: "$baseUrl/overwatch-dva-mercy-cyber-vault-3d/",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "08:15",
          releaseDate: "2024",
          studio: "SFM Master Studio",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "MMD", "Overwatch", "Sci-Fi"],
          rating: 4.9,
          views: 420000,
          isUncensored: true,
        ),
        MediaItem(
          id: "uh_3d_2",
          title: "Genshin Impact Raiden Shogun Climax MMD",
          url: "$baseUrl/genshin-raiden-shogun-climax-mmd/",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "09:40",
          releaseDate: "2024",
          studio: "Aether 3D Lab",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "MMD", "Genshin Impact", "Fantasy"],
          rating: 4.9,
          views: 460000,
          isUncensored: true,
        ),
        MediaItem(
          id: "uh_3d_3",
          title: "Final Fantasy Tifa Lockhart Seventh Heaven 3D",
          url: "$baseUrl/tifa-lockhart-seventh-heaven-3d/",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "11:20",
          releaseDate: "2024",
          studio: "Materia Works",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "MMD", "Final Fantasy", "Martial Arts"],
          rating: 5.0,
          views: 580000,
          isUncensored: true,
        ),
        MediaItem(
          id: "uh_3d_4",
          title: "Dead or Alive Kasumi & Ayane Sakura MMD",
          url: "$baseUrl/kasumi-ayane-sakura-mmd/",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "07:50",
          releaseDate: "2024",
          studio: "Ninja 3D Lab",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "MMD", "Dead or Alive", "Ninja"],
          rating: 4.8,
          views: 310000,
          isUncensored: true,
        ),
        MediaItem(
          id: "uh_3d_5",
          title: "Honkai Star Rail Kafka Velvet Lounge 3D",
          url: "$baseUrl/kafka-velvet-lounge-3d/",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "10:05",
          releaseDate: "2024",
          studio: "Stellaron 3D",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "MMD", "Honkai Star Rail", "Femme Fatale"],
          rating: 4.9,
          views: 390000,
          isUncensored: true,
        ),
        MediaItem(
          id: "uh_3d_6",
          title: "Nier Automata 2B Bunker Maintenance MMD",
          url: "$baseUrl/2b-bunker-maintenance-mmd/",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "08:45",
          releaseDate: "2024",
          studio: "YoRHa 3D",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "MMD", "Nier Automata", "Android"],
          rating: 4.9,
          views: 440000,
          isUncensored: true,
        ),
        MediaItem(
          id: "uh_3d_7",
          title: "Resident Evil Ada Wong Espionage VIP 3D",
          url: "$baseUrl/ada-wong-espionage-vip-3d/",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "12:10",
          releaseDate: "2024",
          studio: "Biohazard 3D",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "MMD", "Resident Evil", "Spy"],
          rating: 4.8,
          views: 375000,
          isUncensored: true,
        ),
        MediaItem(
          id: "uh_3d_8",
          title: "League of Legends Ahri K/DA Midnight Stage 3D",
          url: "$baseUrl/ahri-kda-midnight-stage-3d/",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "09:30",
          releaseDate: "2024",
          studio: "Rune 3D Works",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "MMD", "League of Legends", "K/DA"],
          rating: 4.9,
          views: 510000,
          isUncensored: true,
        ),
      ];
    } else {
      // Default / 'latest' releases
      return [
        MediaItem(
          id: "uh_lat_1",
          title: "Discipline: The Record of Crusade",
          url: "$baseUrl/discipline-the-record-of-crusade/",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "28:00",
          releaseDate: "2024",
          studio: "Active",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Classic", "Underground", "Psychological"],
          rating: 4.9,
          views: 260000,
          isUncensored: true,
        ),
        MediaItem(
          id: "uh_lat_2",
          title: "Bible Black: La Noche de Walpurgis",
          url: "$baseUrl/bible-black-walpurgis/",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "29:15",
          releaseDate: "2024",
          studio: "Studio Jam",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Classic", "Occult", "Underground"],
          rating: 4.9,
          views: 340000,
          isUncensored: false,
        ),
        MediaItem(
          id: "uh_lat_3",
          title: "Night Shift Nurses (Kango Shian)",
          url: "$baseUrl/night-shift-nurses/",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "27:40",
          releaseDate: "2024",
          studio: "Milky Label",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Classic", "Nurse", "Drama"],
          rating: 4.8,
          views: 290000,
          isUncensored: false,
        ),
        MediaItem(
          id: "uh_lat_4",
          title: "Kuroinu: Kedakaki Seijo wa Hakudaku ni Somaru",
          url: "$baseUrl/kuroinu-kedakaki-seijo/",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "25:50",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Dark Fantasy", "Underground", "Elves"],
          rating: 4.9,
          views: 420000,
          isUncensored: false,
        ),
        MediaItem(
          id: "uh_lat_5",
          title: "Mankitsu Happening: Vault Edition",
          url: "$baseUrl/mankitsu-happening-vault/",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "26:30",
          releaseDate: "2024",
          studio: "Bunnywalker",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Harem", "Modern Classic", "Comedy"],
          rating: 4.9,
          views: 380000,
          isUncensored: false,
        ),
        MediaItem(
          id: "uh_lat_6",
          title: "Oni Chichi Re-born: Summer Memories",
          url: "$baseUrl/oni-chichi-re-born/",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "24:45",
          releaseDate: "2024",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Classic", "Slice of Life", "Vault"],
          rating: 4.7,
          views: 310000,
          isUncensored: false,
        ),
        MediaItem(
          id: "uh_lat_7",
          title: "Viper GTS: Cyber Vault Remaster",
          url: "$baseUrl/viper-gts-remaster/",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "30:00",
          releaseDate: "2024",
          studio: "Sonia",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Sci-Fi", "Vintage", "Cyberpunk"],
          rating: 4.8,
          views: 220000,
          isUncensored: true,
        ),
        MediaItem(
          id: "uh_lat_8",
          title: "Resort Boin: Sunny Beach Encounter",
          url: "$baseUrl/resort-boin-sunny-beach/",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "26:10",
          releaseDate: "2024",
          studio: "PoJu",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Big Breasts", "Beach", "Classic"],
          rating: 4.8,
          views: 275000,
          isUncensored: false,
        ),
      ];
    }
  }

  MediaDetail _generateSampleDetail(String url) {
    return MediaDetail(
      id: url.hashCode.toString(),
      title: "Discipline: The Record of Crusade",
      cover: "https://i.imgur.com/7jZQY1B.jpeg",
      backdrop: "https://i.imgur.com/7jZQY1B.jpeg",
      description: "Classic underground psychological anime series.",
      studio: "Active Animation",
      releaseDate: "2024",
      tags: ["Classic", "Underground", "Uncensored"],
      episodes: [
        EpisodeItem(
          id: "ep_1",
          episodeNumber: "Episode 1",
          title: "Discipline Ep 1",
          url: url,
          thumbnail: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "28:00",
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
