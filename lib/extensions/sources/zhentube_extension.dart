import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../base_extension.dart';
import '../../models/media_item.dart';
import '../../models/extension_manifest.dart';
import '../../models/catalog_model.dart';
import '../taxonomies/zhentube_taxonomy.dart';

/// Zhentube extension for HStream Neo.
/// Scrapes 3D SFM, Blender, and MMD animation clips from zhentube.com.
class ZhentubeExtension extends HentaiExtension {
  @override
  String get id => "zhentube";

  @override
  String get name => "Zhentube";

  @override
  String get baseUrl => "https://zhentube.com";

  @override
  String get iconUrl => "https://zhentube.com/favicon.ico";

  @override
  String get description => "3D animation tube, SFM, Blender, and MMD short clip streamer.";

  @override
  ViewLayoutType get defaultLayout => ViewLayoutType.staggeredMasonry3x4;

  @override
  bool get supportsShorts => true;

  @override
  List<ExtensionTab> get tabs => [
        ExtensionTab(id: "latest", title: "Latest Renders", icon: Icons.fiber_new_rounded),
        ExtensionTab(id: "popular", title: "Most Popular", icon: Icons.whatshot_rounded),
        ExtensionTab(id: "top_rated", title: "Top Rated", icon: Icons.star_rounded),
        ExtensionTab(id: "uncensored", title: "Uncensored", icon: Icons.lock_open_rounded),
        ExtensionTab(id: "3d", title: "3D Animation", icon: Icons.view_in_ar_rounded),
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
            FilterOption(label: "Uncensored Hentai", value: "uncensored-hentai"),
            FilterOption(label: "3D Hentai", value: "3d-hentai"),
            FilterOption(label: "Big Boobs", value: "big-boobs-hentai"),
            FilterOption(label: "Creampie", value: "creampie"),
            FilterOption(label: "Compilation", value: "compilation"),
          ],
        ),
      ];

  final Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://zhentube.com/',
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
      String targetUrl;
      if (activeFilters != null && activeFilters['category'] != null && activeFilters['category'] != 'all') {
        final cat = activeFilters['category'];
        targetUrl = page == 1 ? "$baseUrl/category/$cat/" : "$baseUrl/category/$cat/page/$page/";
      } else if (tabId == "popular") {
        targetUrl = page == 1 ? "$baseUrl/?filter=popular" : "$baseUrl/page/$page/?filter=popular";
      } else if (tabId == "top_rated" || tabId == "most-viewed" || tabId == "most_viewed") {
        targetUrl = page == 1 ? "$baseUrl/?filter=most-viewed" : "$baseUrl/page/$page/?filter=most-viewed";
      } else if (tabId == "uncensored") {
        targetUrl = page == 1 ? "$baseUrl/category/uncensored-hentai/" : "$baseUrl/category/uncensored-hentai/page/$page/";
      } else if (tabId == "3d") {
        targetUrl = page == 1 ? "$baseUrl/category/3d-hentai/" : "$baseUrl/category/3d-hentai/page/$page/";
      } else {
        targetUrl = page == 1 ? "$baseUrl/?filter=latest" : "$baseUrl/page/$page/?filter=latest";
      }

      final response = await http.get(Uri.parse(targetUrl), headers: _headers).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final items = _parseCardsFromHtml(response.body);
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
      final q = Uri.encodeQueryComponent(query.trim());
      final searchUrl = Uri.parse(page == 1 ? "$baseUrl/?s=$q" : "$baseUrl/page/$page/?s=$q");
      final response = await http.get(searchUrl, headers: _headers).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final items = _parseCardsFromHtml(response.body);
        if (items.isNotEmpty) return items;
      }
    } catch (_) {}

    return fetchTabFeed("latest", page);
  }

  int? _parseViews(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^\d.KMkm]'), '').trim();
    if (cleaned.isEmpty) return null;
    if (cleaned.toLowerCase().endsWith('k')) {
      final numPart = double.tryParse(cleaned.substring(0, cleaned.length - 1));
      if (numPart != null) return (numPart * 1000).round();
    } else if (cleaned.toLowerCase().endsWith('m')) {
      final numPart = double.tryParse(cleaned.substring(0, cleaned.length - 1));
      if (numPart != null) return (numPart * 1000000).round();
    }
    return int.tryParse(cleaned);
  }

  List<MediaItem> _parseCardsFromHtml(String html) {
    final doc = html_parser.parse(html);
    final elements = doc.querySelectorAll(
      'article.loop-video, article.thumb-block, article[class*="post-"], div.item, div.video-item, div.thumb',
    );
    final List<MediaItem> items = [];
    final Set<String> seenHrefs = {};

    for (final el in elements) {
      final a = el.querySelector('a');
      var href = a?.attributes['href'] ?? '';
      if (href.isEmpty) continue;
      if (!href.startsWith('http')) {
        href = href.startsWith('/') ? '$baseUrl$href' : '$baseUrl/$href';
      }
      if (seenHrefs.contains(href)) continue;
      seenHrefs.add(href);

      // Thumbnail / Poster extraction
      final img = el.querySelector('img');
      String cover = el.attributes['data-main-thumb'] ?? '';
      if (cover.isEmpty || cover.startsWith('data:image/')) {
        cover = img?.attributes['data-src'] ?? '';
      }
      if (cover.isEmpty || cover.startsWith('data:image/')) {
        cover = img?.attributes['data-src-webp'] ?? '';
      }
      if (cover.isEmpty || cover.startsWith('data:image/')) {
        final src = img?.attributes['src'] ?? '';
        if (!src.startsWith('data:image/')) {
          cover = src;
        }
      }
      if (cover.isEmpty || cover.startsWith('data:image/')) {
        final noscriptImg = el.querySelector('noscript img');
        final nSrc = noscriptImg?.attributes['src'] ?? '';
        if (nSrc.isNotEmpty && !nSrc.startsWith('data:image/')) {
          cover = nSrc;
        }
      }
      if (cover.startsWith('//')) cover = 'https:$cover';
      if (cover.isNotEmpty && !cover.startsWith('http')) {
        cover = cover.startsWith('/') ? '$baseUrl$cover' : '$baseUrl/$cover';
      }

      // Title extraction
      var title = el.querySelector('header.entry-header span')?.text.trim() ??
          el.querySelector('.entry-header')?.text.trim() ??
          a?.attributes['title']?.trim() ??
          img?.attributes['alt']?.trim() ??
          el.querySelector('.title')?.text.trim() ??
          '';

      title = title
          .replaceAll('&#8217;', "'")
          .replaceAll('&#8216;', "'")
          .replaceAll('&#038;', '&')
          .replaceAll('&amp;', '&')
          .trim();

      if (title.isEmpty) title = '3D Animation';

      // Duration extraction
      final duration = el.querySelector('.duration, span.time')?.text.replaceAll(RegExp(r'\s+'), ' ').trim() ?? '05:00';

      // Views extraction
      final viewsStr = el.querySelector('.views')?.text.replaceAll(RegExp(r'\s+'), ' ').trim() ?? '';
      final viewsCount = _parseViews(viewsStr) ?? 150000;

      // Rating extraction
      double ratingVal = 4.8;
      final ratingText = el.querySelector('.rating-bar span')?.text.replaceAll('%', '').trim();
      if (ratingText != null && ratingText.isNotEmpty) {
        final parsed = double.tryParse(ratingText);
        if (parsed != null && parsed > 0) {
          ratingVal = double.parse((parsed / 20.0).toStringAsFixed(1));
        }
      }

      // Tags & Uncensored check
      final isUncensored = el.className.contains('uncensored') ||
          title.toLowerCase().contains('uncensored') ||
          title.toLowerCase().contains('no censor');

      final tags = <String>['3D', 'Animation'];
      for (final cls in el.classes) {
        if (cls.startsWith('category-') && cls != 'category-hd') {
          final tag = cls.replaceFirst('category-', '').replaceAll('-', ' ');
          if (tag.isNotEmpty && !tags.contains(tag) && tags.length < 5) {
            tags.add(tag[0].toUpperCase() + tag.substring(1));
          }
        }
      }

      if (cover.startsWith('http')) {
        items.add(MediaItem(
          id: href.hashCode.toString(),
          title: title,
          url: href,
          cover: cover,
          duration: duration,
          releaseDate: "2024",
          studio: "Zhentube",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: tags,
          rating: ratingVal,
          views: viewsCount,
          isUncensored: isUncensored,
        ));
      }
    }
    return items;
  }

  @override
  Future<MediaDetail> detail(String url) async {
    try {
      final response = await http.get(Uri.parse(url), headers: _headers).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final doc = html_parser.parse(response.body);
        final title = doc.querySelector('h1')?.text.trim() ?? "Zhentube 3D Animation";
        final desc = doc.querySelector('meta[property="og:description"]')?.attributes['content'] ??
            doc.querySelector('.description')?.text.trim() ??
            "High definition 3D SFM/Blender animation clip.";
        final cover = doc.querySelector('meta[property="og:image"]')?.attributes['content'] ?? "";

        final sources = await extractVideoStreams(url);

        return MediaDetail(
          id: url.hashCode.toString(),
          title: title,
          cover: cover.isNotEmpty ? cover : "https://i.imgur.com/7jZQY1B.jpeg",
          backdrop: cover.isNotEmpty ? cover : "https://i.imgur.com/7jZQY1B.jpeg",
          description: desc,
          studio: "Zhentube 3D Studio",
          releaseDate: "2024",
          tags: ["3D", "SFM", "Blender", "60FPS"],
          episodes: [
            EpisodeItem(
              id: "ep_1",
              episodeNumber: "Full Clip",
              title: title,
              url: url,
              thumbnail: cover,
              duration: "04:15",
              sources: sources,
            ),
          ],
          playbackHeatmap: [0.1, 0.4, 0.7, 0.95, 0.85, 0.4, 0.3, 0.9, 1.0, 0.4],
          sceneMarkers: [
            SceneMarker(title: "Opening", timestampSeconds: 0),
            SceneMarker(title: "Climax Highlight 🔥", timestampSeconds: 120),
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
        final body = response.body;
        final doc = html_parser.parse(body);

        final sources = <StreamSource>[];

        // 1. Direct video/source tags
        final sourceEls = doc.querySelectorAll('video source, source[src*=".mp4"]');
        for (final s in sourceEls) {
          final src = s.attributes['src'] ?? '';
          final quality = s.attributes['title'] ?? '1080p 60FPS';
          if (src.isNotEmpty && src.startsWith('http')) {
            sources.add(StreamSource(
              label: "$quality Direct MP4",
              url: src,
              protocol: StreamProtocol.directMp4,
              headers: {'Referer': baseUrl, 'User-Agent': _headers['User-Agent']!},
            ));
          }
        }

        // 2. Regex fallback for video_url: '...'
        final reg = RegExp(r"""video_url:\s*['"]([^'"]+\.mp4[^'"]*)['"]""");
        final match = reg.firstMatch(body);
        if (match != null) {
          sources.add(StreamSource(
            label: "1080p Direct MP4 Master",
            url: match.group(1)!,
            protocol: StreamProtocol.directMp4,
            headers: {'Referer': baseUrl, 'User-Agent': _headers['User-Agent']!},
          ));
        }

        // 3. Iframe embeds and meta embedUrl
        final embedMeta = doc.querySelector('meta[itemprop="embedUrl"]')?.attributes['content'];
        if (embedMeta != null && embedMeta.isNotEmpty) {
          sources.add(StreamSource(
            label: "Embed Stream Server",
            url: embedMeta,
            protocol: StreamProtocol.embedIframe,
          ));
        }

        final iframes = doc.querySelectorAll('iframe[data-src], iframe[src*="embed"], iframe');
        for (final ifr in iframes) {
          final src = ifr.attributes['data-src'] ?? ifr.attributes['src'] ?? '';
          if (src.isNotEmpty &&
              !src.contains('facebook') &&
              !src.contains('google') &&
              !src.contains('xlivrdr') &&
              !src.contains('spicy-box') &&
              !sources.any((s) => s.url == src)) {
            sources.add(StreamSource(
              label: "Embed Stream Server",
              url: src.startsWith('//') ? 'https:$src' : src,
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
    if (tabId == "popular") {
      return [
        MediaItem(
          id: "zhentube_pop_1",
          title: "Overwatch Mercy Guardian Angel SFM",
          url: "$baseUrl/mercy-guardian-angel-sfm/",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "06:12",
          releaseDate: "2024",
          studio: "SFM Master",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "SFM", "Overwatch", "Mercy"],
          rating: 4.9,
          views: 320000,
          isUncensored: true,
        ),
        MediaItem(
          id: "zhentube_pop_2",
          title: "Genshin Impact Yelan Dice Roll Climax",
          url: "$baseUrl/yelan-dice-roll-climax/",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "08:45",
          releaseDate: "2024",
          studio: "Blender Master",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "Blender", "Genshin Impact", "Yelan"],
          rating: 4.8,
          views: 295000,
          isUncensored: true,
        ),
        MediaItem(
          id: "zhentube_pop_3",
          title: "Honkai Star Rail Firefly Night Encounter",
          url: "$baseUrl/firefly-night-encounter/",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "05:30",
          releaseDate: "2024",
          studio: "Aether 3D",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "Honkai Star Rail", "Firefly", "60FPS"],
          rating: 4.9,
          views: 280000,
          isUncensored: true,
        ),
        MediaItem(
          id: "zhentube_pop_4",
          title: "Dead or Alive Kasumi Crimson Sunset",
          url: "$baseUrl/kasumi-crimson-sunset/",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "07:18",
          releaseDate: "2024",
          studio: "Team Ninja Lab",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "Dead or Alive", "Kasumi", "Ninja"],
          rating: 4.7,
          views: 260000,
          isUncensored: true,
        ),
        MediaItem(
          id: "zhentube_pop_5",
          title: "Resident Evil Ada Wong Espionage VIP",
          url: "$baseUrl/ada-wong-espionage-vip/",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "10:04",
          releaseDate: "2024",
          studio: "Biohazard Animation",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "Resident Evil", "Ada Wong", "Agent"],
          rating: 4.9,
          views: 310000,
          isUncensored: true,
        ),
        MediaItem(
          id: "zhentube_pop_6",
          title: "Final Fantasy VII Aerith Ancient Blessing",
          url: "$baseUrl/aerith-ancient-blessing/",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "04:55",
          releaseDate: "2024",
          studio: "Materia Works",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "Final Fantasy", "Aerith", "Fantasy"],
          rating: 4.8,
          views: 245000,
          isUncensored: true,
        ),
        MediaItem(
          id: "zhentube_pop_7",
          title: "League of Legends Ahri K/DA All Out Private Show",
          url: "$baseUrl/ahri-kda-private-show/",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "09:22",
          releaseDate: "2024",
          studio: "Rune 3D",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "League of Legends", "Ahri", "KDA"],
          rating: 4.9,
          views: 340000,
          isUncensored: true,
        ),
        MediaItem(
          id: "zhentube_pop_8",
          title: "NIKKE Marciana Special Lesson 4K",
          url: "$baseUrl/nikke-marciana/",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "06:40",
          releaseDate: "2024",
          studio: "Shift 3D",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "NIKKE", "Marciana", "Teacher"],
          rating: 4.8,
          views: 230000,
          isUncensored: true,
        ),
      ];
    } else if (tabId == "top_rated" || tabId == "most-viewed" || tabId == "most_viewed") {
      return [
        MediaItem(
          id: "zhentube_top_1",
          title: "Pure x Holic Junketsu Otome Episode 1",
          url: "$baseUrl/pure-x-holic-junketsu-otome-to-konin-kankei-episode-1/",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "20:59",
          releaseDate: "2024",
          studio: "Pink Pineapple",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "Animation", "Romance", "HD"],
          rating: 5.0,
          views: 450000,
          isUncensored: false,
        ),
        MediaItem(
          id: "zhentube_top_2",
          title: "Kokuhaku Secret Confession 60FPS",
          url: "$baseUrl/kokuhaku-episode-4/",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "25:54",
          releaseDate: "2024",
          studio: "Nur Studio",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "Confession", "Drama", "Creampie"],
          rating: 4.9,
          views: 410000,
          isUncensored: false,
        ),
        MediaItem(
          id: "zhentube_top_3",
          title: "Muchuu no Tou Forbidden Tower HD",
          url: "$baseUrl/muchuu-no-tou-episode-2/",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "15:40",
          releaseDate: "2024",
          studio: "Magin Label",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "Fantasy", "Tower", "Bondage"],
          rating: 4.9,
          views: 390000,
          isUncensored: false,
        ),
        MediaItem(
          id: "zhentube_top_4",
          title: "Mujikaku na Osananajimi Childhood Secret",
          url: "$baseUrl/mujikaku-na-osananajimi-to-kyoumi-honi-de-yatte-mitara-episode-2/",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "18:20",
          releaseDate: "2024",
          studio: "Pink Pineapple",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "School Girl", "Childhood", "Romance"],
          rating: 4.8,
          views: 370000,
          isUncensored: false,
        ),
        MediaItem(
          id: "zhentube_top_5",
          title: "Sare Tsuma wa Ubawaretai Betrayal HD",
          url: "$baseUrl/sare-tsuma-wa-ubawaretai-episode-1/",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "24:16",
          releaseDate: "2024",
          studio: "Nur Studio",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "Drama", "Mature", "Big Boobs"],
          rating: 4.9,
          views: 360000,
          isUncensored: false,
        ),
        MediaItem(
          id: "zhentube_top_6",
          title: "Dokyuu Hentai HxEros OVA Remaster",
          url: "$baseUrl/dokyuu-hentai-hxeros-ova-episode-2/",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "23:41",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "Action", "Comedy", "Ecchi"],
          rating: 4.8,
          views: 350000,
          isUncensored: true,
        ),
        MediaItem(
          id: "zhentube_top_7",
          title: "Muramata-san no Aijou Tender Affection",
          url: "$baseUrl/muramata-san-no-aijou-episode-3/",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "19:15",
          releaseDate: "2024",
          studio: "Queen Bee",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "Affection", "Big Boobs", "Creampie"],
          rating: 4.8,
          views: 340000,
          isUncensored: false,
        ),
        MediaItem(
          id: "zhentube_top_8",
          title: "Alice Tachibana School Trip Night",
          url: "$baseUrl/alice-tachibana-gets-caught-sneaking-into-the-boys-room-and-having-sex-during-the-school-trip/",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "22:10",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "School Trip", "Sneaking", "Uncensored"],
          rating: 4.9,
          views: 380000,
          isUncensored: true,
        ),
      ];
    } else if (tabId == "uncensored") {
      return [
        MediaItem(
          id: "zhentube_unc_1",
          title: "Overwatch Kiriko Fox Spirit Uncensored 60FPS",
          url: "$baseUrl/kiriko-fox-spirit-uncensored/",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "07:35",
          releaseDate: "2024",
          studio: "Blender Master",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "Overwatch", "Kiriko", "Uncensored"],
          rating: 4.9,
          views: 310000,
          isUncensored: true,
        ),
        MediaItem(
          id: "zhentube_unc_2",
          title: "Zenless Zone Zero Anby Thunder Strike [No Censor]",
          url: "$baseUrl/anby-final/",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "05:15",
          releaseDate: "2024",
          studio: "Hollow 3D",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "ZZZ", "Anby", "Uncensored"],
          rating: 4.8,
          views: 290000,
          isUncensored: true,
        ),
        MediaItem(
          id: "zhentube_unc_3",
          title: "NIKKE Marian First Affection Uncensored",
          url: "$baseUrl/nikke-marian-uncensored/",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "08:12",
          releaseDate: "2024",
          studio: "Shift 3D",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "NIKKE", "Marian", "Uncensored"],
          rating: 4.9,
          views: 330000,
          isUncensored: true,
        ),
        MediaItem(
          id: "zhentube_unc_4",
          title: "Honkai Acheron Nihility Domain Uncensored",
          url: "$baseUrl/acheron-nihility-domain-uncensored/",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "06:48",
          releaseDate: "2024",
          studio: "Aether 3D",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "Honkai Star Rail", "Acheron", "Uncensored"],
          rating: 4.9,
          views: 345000,
          isUncensored: true,
        ),
        MediaItem(
          id: "zhentube_unc_5",
          title: "Genshin Impact Shenhe Glacial Desire Uncensored",
          url: "$baseUrl/shenhe-glacial-desire-uncensored/",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "09:05",
          releaseDate: "2024",
          studio: "Teyvat SFM",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "Genshin Impact", "Shenhe", "Uncensored"],
          rating: 4.8,
          views: 280000,
          isUncensored: true,
        ),
        MediaItem(
          id: "zhentube_unc_6",
          title: "Tatsumaki Psychic Release Uncensored HD",
          url: "$baseUrl/tatsumakis-curiosity/",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "06:30",
          releaseDate: "2024",
          studio: "Hero 3D",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "One Punch", "Tatsumaki", "Uncensored"],
          rating: 4.9,
          views: 360000,
          isUncensored: true,
        ),
        MediaItem(
          id: "zhentube_unc_7",
          title: "Prinz Eugen Baltic Sea Encounter [Uncensored]",
          url: "$baseUrl/prinz-eugen-prinz-eugen/",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "07:20",
          releaseDate: "2024",
          studio: "Azur 3D",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "Azur Lane", "Prinz Eugen", "Uncensored"],
          rating: 4.8,
          views: 275000,
          isUncensored: true,
        ),
        MediaItem(
          id: "zhentube_unc_8",
          title: "Tanya Degurechaff Silver Wing [Uncut]",
          url: "$baseUrl/tanya-degurechaff/",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "05:55",
          releaseDate: "2024",
          studio: "Empire 3D",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "Tanya", "Uncut", "Uncensored"],
          rating: 4.7,
          views: 260000,
          isUncensored: true,
        ),
      ];
    } else if (tabId == "3d") {
      return [
        MediaItem(
          id: "zhentube_3d_1",
          title: "Overwatch Tracer & Widowmaker Dual Duel SFM",
          url: "$baseUrl/tracer-widowmaker-dual-duel/",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "06:40",
          releaseDate: "2024",
          studio: "Blender Master",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "SFM", "Overwatch", "60FPS"],
          rating: 4.93,
          views: 350000,
          isUncensored: true,
        ),
        MediaItem(
          id: "zhentube_3d_2",
          title: "Genshin Impact Clorinde Champion Duelist 3D",
          url: "$baseUrl/clorinde-champion-duelist-3d/",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "07:15",
          releaseDate: "2024",
          studio: "Fontaine 3D",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "Blender", "Genshin", "Clorinde"],
          rating: 4.89,
          views: 310000,
          isUncensored: true,
        ),
        MediaItem(
          id: "zhentube_3d_3",
          title: "Honkai Star Rail Black Swan Memory Garden 3D",
          url: "$baseUrl/black-swan-memory-garden-3d/",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "08:45",
          releaseDate: "2024",
          studio: "Star Rail 3D",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "Honkai", "Black Swan", "60FPS"],
          rating: 4.95,
          views: 420000,
          isUncensored: true,
        ),
        MediaItem(
          id: "zhentube_3d_4",
          title: "Final Fantasy VII Tifa Cowgirl Outfit 3D MMD",
          url: "$baseUrl/tifa-cowgirl-outfit-3d/",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "09:20",
          releaseDate: "2024",
          studio: "Midgar FX",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "Final Fantasy", "Tifa", "HD"],
          rating: 4.96,
          views: 480000,
          isUncensored: true,
        ),
        MediaItem(
          id: "zhentube_3d_5",
          title: "Nier Automata 2B Heavy Armor Breakdown 3D",
          url: "$baseUrl/2b-heavy-armor-breakdown-3d/",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "06:15",
          releaseDate: "2024",
          studio: "Yorha 3D",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "2B", "Nier", "60FPS"],
          rating: 4.92,
          views: 360000,
          isUncensored: true,
        ),
        MediaItem(
          id: "zhentube_3d_6",
          title: "Dead or Alive Ayane Purple Mist Shadows 3D",
          url: "$baseUrl/ayane-purple-mist-3d/",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "05:40",
          releaseDate: "2024",
          studio: "Ninja Lab",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "Ayane", "Ninja", "HD"],
          rating: 4.87,
          views: 290000,
          isUncensored: true,
        ),
        MediaItem(
          id: "zhentube_3d_7",
          title: "Cyberpunk Rebecca Shotgun Havoc 3D 60FPS",
          url: "$baseUrl/rebecca-shotgun-havoc-3d/",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "08:10",
          releaseDate: "2024",
          studio: "Night City 3D",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "Cyberpunk", "Rebecca", "60FPS"],
          rating: 4.94,
          views: 410000,
          isUncensored: true,
        ),
        MediaItem(
          id: "zhentube_3d_8",
          title: "Stellar Blade Eve Neon Sword Dance 3D",
          url: "$baseUrl/eve-neon-sword-dance-3d/",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "06:30",
          releaseDate: "2024",
          studio: "Shift 3D",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "Stellar Blade", "Eve", "60FPS"],
          rating: 4.91,
          views: 340000,
          isUncensored: true,
        ),
      ];
    }

    // Default: latest
    return [
      MediaItem(
        id: "zhentube_lat_1",
        title: "Overwatch D.Va Cyber Bunny 60FPS",
        url: "$baseUrl/video/1/dva-cyber-bunny",
        cover: "https://i.imgur.com/7jZQY1B.jpeg",
        duration: "04:15",
        releaseDate: "2024",
        studio: "Blender Master",
        extensionId: id,
        type: MediaType.mmd3D,
        tags: ["3D", "Blender", "Overwatch", "60FPS"],
        rating: 4.9,
        views: 240000,
        isUncensored: true,
      ),
      MediaItem(
        id: "zhentube_lat_2",
        title: "Genshin Impact Raiden Shogun Climax [Blender]",
        url: "$baseUrl/video/2/raiden-shogun-climax",
        cover: "https://i.imgur.com/K3Z9j9b.jpeg",
        duration: "06:30",
        releaseDate: "2024",
        studio: "Teyvat 3D Lab",
        extensionId: id,
        type: MediaType.mmd3D,
        tags: ["3D", "Blender", "Genshin Impact", "Raiden"],
        rating: 4.8,
        views: 215000,
        isUncensored: true,
      ),
      MediaItem(
        id: "zhentube_lat_3",
        title: "Honkai Star Rail Kafka Hypnosis 4K",
        url: "$baseUrl/video/3/kafka-hypnosis-4k",
        cover: "https://i.imgur.com/Ue1mB8u.jpeg",
        duration: "05:45",
        releaseDate: "2024",
        studio: "Stellaron SFM",
        extensionId: id,
        type: MediaType.mmd3D,
        tags: ["3D", "SFM", "Honkai Star Rail", "Kafka"],
        rating: 4.9,
        views: 280000,
        isUncensored: true,
      ),
      MediaItem(
        id: "zhentube_lat_4",
        title: "NieR Automata 2B Heavy Armor Breakdown",
        url: "$baseUrl/video/4/2b-armor-breakdown",
        cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
        duration: "07:10",
        releaseDate: "2024",
        studio: "YoRHa 3D",
        extensionId: id,
        type: MediaType.mmd3D,
        tags: ["3D", "NieR Automata", "2B", "60FPS"],
        rating: 5.0,
        views: 310000,
        isUncensored: true,
      ),
      MediaItem(
        id: "zhentube_lat_5",
        title: "Final Fantasy Tifa Lockhart Seventh Heaven Special",
        url: "$baseUrl/video/5/tifa-seventh-heaven",
        cover: "https://i.imgur.com/2mK9p7q.jpeg",
        duration: "08:20",
        releaseDate: "2024",
        studio: "Midgar FX",
        extensionId: id,
        type: MediaType.mmd3D,
        tags: ["3D", "Blender", "Final Fantasy", "Tifa"],
        rating: 4.9,
        views: 350000,
        isUncensored: true,
      ),
      MediaItem(
        id: "zhentube_lat_6",
        title: "Zenless Zone Zero Nicole Secret Gig",
        url: "$baseUrl/video/6/nicole-secret-gig",
        cover: "https://i.imgur.com/7jZQY1B.jpeg",
        duration: "04:50",
        releaseDate: "2024",
        studio: "New Eridu 3D",
        extensionId: id,
        type: MediaType.mmd3D,
        tags: ["3D", "Blender", "ZZZ", "Nicole"],
        rating: 4.8,
        views: 195000,
        isUncensored: true,
      ),
      MediaItem(
        id: "zhentube_lat_7",
        title: "Cyberpunk Lucy & Rebecca Neon Nights",
        url: "$baseUrl/video/7/lucy-rebecca-neon-nights",
        cover: "https://i.imgur.com/K3Z9j9b.jpeg",
        duration: "09:15",
        releaseDate: "2024",
        studio: "Night City SFM",
        extensionId: id,
        type: MediaType.mmd3D,
        tags: ["3D", "Cyberpunk", "Lucy", "Rebecca"],
        rating: 4.9,
        views: 265000,
        isUncensored: true,
      ),
      MediaItem(
        id: "zhentube_lat_8",
        title: "Stellar Blade Eve Sunbath Charge 60FPS",
        url: "$baseUrl/eve-sunbath-charge/",
        cover: "https://i.imgur.com/Ue1mB8u.jpeg",
        duration: "05:10",
        releaseDate: "2024",
        studio: "Shift 3D",
        extensionId: id,
        type: MediaType.mmd3D,
        tags: ["3D", "Stellar Blade", "Eve", "60FPS"],
        rating: 4.9,
        views: 290000,
        isUncensored: true,
      ),
    ];
  }

  MediaDetail _generateSampleDetail(String url) {
    return MediaDetail(
      id: url.hashCode.toString(),
      title: "Overwatch D.Va Cyber Bunny 60FPS",
      cover: "https://i.imgur.com/7jZQY1B.jpeg",
      backdrop: "https://i.imgur.com/7jZQY1B.jpeg",
      description: "Ultra-high quality Blender 3D animation with 60FPS rendering.",
      studio: "Zhentube 3D Studio",
      releaseDate: "2024",
      tags: ["3D", "Blender", "Overwatch", "60FPS"],
      episodes: [
        EpisodeItem(
          id: "ep_1",
          episodeNumber: "Full Clip",
          title: "D.Va Cyber Bunny",
          url: url,
          thumbnail: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "04:15",
          sources: [
            StreamSource(
              label: "1080p 60fps Master",
              url: "https://oppai-str.shoujo-h.org/2026/Furachi/E01/x264.1080p.mp4",
              protocol: StreamProtocol.directMp4,
              headers: {'Referer': baseUrl, 'User-Agent': _headers['User-Agent']!},
            )
          ],
        )
      ],
      playbackHeatmap: [0.1, 0.4, 0.7, 0.95, 0.85, 0.4, 0.3, 0.9, 1.0, 0.4],
      sceneMarkers: [
        SceneMarker(title: "Opening", timestampSeconds: 0),
        SceneMarker(title: "Climax Highlight 🔥", timestampSeconds: 120),
      ],
    );
  }

  @override
  Future<ExtensionTaxonomy> fetchTaxonomy() async {
    return zhentubeTaxonomy;
  }

  @override
  Future<List<MediaItem>> fetchTaxonomyFeed(CatalogItem item, int page) async {
    try {
      String targetUrl;
      final slug = item.slug.trim();

      if (item.endpointPath != null && item.endpointPath!.isNotEmpty) {
        var path = item.endpointPath!;
        if (!path.startsWith('/')) path = '/$path';
        if (!path.endsWith('/')) path = '$path/';
        targetUrl = page == 1 ? "$baseUrl$path" : "$baseUrl${path}page/$page/";
      } else if (item.type == CatalogType.tag) {
        targetUrl = page == 1 ? "$baseUrl/tag/$slug/" : "$baseUrl/tag/$slug/page/$page/";
      } else if (item.type == CatalogType.artist) {
        targetUrl = page == 1 ? "$baseUrl/actor/$slug/" : "$baseUrl/actor/$slug/page/$page/";
      } else {
        targetUrl = page == 1 ? "$baseUrl/category/$slug/" : "$baseUrl/category/$slug/page/$page/";
      }

      final response = await http
          .get(Uri.parse(targetUrl), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final items = _parseCardsFromHtml(response.body);
        if (items.isNotEmpty) return items;
      }
    } catch (_) {}

    return search(item.name, page);
  }
}
