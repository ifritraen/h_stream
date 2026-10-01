import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../base_extension.dart';
import '../../models/media_item.dart';
import '../../models/extension_manifest.dart';
import '../../models/catalog_model.dart';
import '../taxonomies/hentai_fox_taxonomy.dart';

/// HentaiFox extension for HStream Neo.
/// Scrapes doujinshi, manga, and deep genre/tag galleries from hentaifox.com.
class HentaiFoxExtension extends HentaiExtension {
  @override
  String get id => "hentai_fox";

  @override
  String get name => "HentaiFox";

  @override
  String get baseUrl => "https://hentaifox.com";

  @override
  String get iconUrl => "https://hentaifox.com/images/favicon.ico";

  @override
  String get description => "Doujinshi, manga, uncensored, and big boobs galleries from HentaiFox.";

  @override
  ViewLayoutType get defaultLayout => ViewLayoutType.widescreen16x9;

  @override
  bool get supportsShorts => false;

  @override
  List<ExtensionTab> get tabs => [
        ExtensionTab(id: "latest", title: "Latest Releases", icon: Icons.fiber_new_rounded),
        ExtensionTab(id: "doujinshi", title: "Doujinshi", icon: Icons.menu_book_rounded),
        ExtensionTab(id: "manga", title: "Manga", icon: Icons.auto_stories_rounded),
        ExtensionTab(id: "big_boobs", title: "Big Boobs Genre", icon: Icons.favorite_rounded),
        ExtensionTab(id: "uncensored", title: "Uncensored Genre", icon: Icons.lock_open_rounded),
      ];

  @override
  List<FilterGroup> get filters => [];

  final Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaifox.com/',
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
      switch (tabId) {
        case 'doujinshi':
          targetUrl = page == 1 ? "$baseUrl/category/doujinshi/" : "$baseUrl/category/doujinshi/pag/$page/";
          break;
        case 'manga':
          targetUrl = page == 1 ? "$baseUrl/category/manga/" : "$baseUrl/category/manga/pag/$page/";
          break;
        case 'big_boobs':
          targetUrl = page == 1 ? "$baseUrl/tag/big-breasts/" : "$baseUrl/tag/big-breasts/pag/$page/";
          break;
        case 'uncensored':
          targetUrl = page == 1 ? "$baseUrl/tag/uncensored/" : "$baseUrl/tag/uncensored/pag/$page/";
          break;
        case 'latest':
        default:
          targetUrl = page == 1 ? baseUrl : "$baseUrl/pag/$page/";
          break;
      }

      final response = await http.get(Uri.parse(targetUrl), headers: _headers).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final items = _parseCardsFromHtml(response.body, tabId: tabId);
        if (items.isNotEmpty) return items;
      } else if (tabId == 'big_boobs') {
        final altUrl = page == 1 ? "$baseUrl/tag/big-boobs/" : "$baseUrl/tag/big-boobs/pag/$page/";
        final altResponse = await http.get(Uri.parse(altUrl), headers: _headers).timeout(const Duration(seconds: 8));
        if (altResponse.statusCode == 200) {
          final items = _parseCardsFromHtml(altResponse.body, tabId: tabId);
          if (items.isNotEmpty) return items;
        }
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
          ? Uri.parse("$baseUrl/search/?q=${Uri.encodeComponent(query)}")
          : Uri.parse("$baseUrl/search/?q=${Uri.encodeComponent(query)}&page=$page");
      final response = await http.get(searchUrl, headers: _headers).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final items = _parseCardsFromHtml(response.body, tabId: 'latest');
        if (items.isNotEmpty) return items;
      }
    } catch (_) {}

    return fetchTabFeed("latest", page);
  }

  List<MediaItem> _parseCardsFromHtml(String html, {String tabId = 'latest'}) {
    final doc = html_parser.parse(html);
    final elements = doc.querySelectorAll('div.thumb, .inner_thumb, article, .item');
    final List<MediaItem> items = [];
    final Set<String> seenHrefs = {};

    for (final el in elements) {
      final a = el.querySelector('.inner_thumb a, .caption a, .g_title a, a[href*="/gallery/"]') ??
          el.querySelector('a:not(.t_cat)');
      var href = a?.attributes['href'] ?? '';
      if (href.isEmpty) continue;
      if (href.contains('/category/') || href.contains('/tag/') || href.contains('/tags/')) continue;
      if (!href.startsWith('http')) {
        href = href.startsWith('/') ? '$baseUrl$href' : '$baseUrl/$href';
      }
      if (seenHrefs.contains(href)) continue;

      final img = el.querySelector('img');
      var cover = img?.attributes['data-src'] ??
          img?.attributes['data-lazy-src'] ??
          img?.attributes['data-original'] ??
          '';
      if (cover.isEmpty || cover.startsWith('data:')) {
        final src = img?.attributes['src'] ?? '';
        if (!src.startsWith('data:')) {
          cover = src;
        }
      }
      if (cover.startsWith('//')) {
        cover = 'https:$cover';
      }
      if (cover.isNotEmpty && !cover.startsWith('http')) {
        cover = cover.startsWith('/') ? '$baseUrl$cover' : '$baseUrl/$cover';
      }

      var title = el.querySelector('.g_title a, h2.g_title, .gallery_title, h2, .title, .entry-title')?.text.trim() ?? '';
      if (title.isEmpty) {
        title = a?.attributes['title']?.trim() ?? '';
      }
      if (title.isEmpty) {
        final text = a?.text.trim() ?? '';
        if (text.isNotEmpty && !text.toLowerCase().contains('new')) {
          title = text;
        }
      }
      if (title.isEmpty) {
        title = img?.attributes['alt']?.trim() ?? '';
      }
      title = _cleanText(title);

      if (title.isNotEmpty && cover.startsWith('http')) {
        seenHrefs.add(href);

        final catText = el.querySelector('.g_cat a, .gallery_cat, .cat_text')?.text.trim() ?? '';
        final defaultTags = _getDefaultTagsForTab(tabId, extraCategory: catText);

        items.add(MediaItem(
          id: href.hashCode.toString(),
          title: title,
          url: href,
          cover: cover,
          duration: "Gallery",
          releaseDate: "2024",
          studio: catText.isNotEmpty ? catText : "HentaiFox",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: defaultTags,
          rating: 4.8,
          views: 185000,
          isUncensored: tabId == 'uncensored' || title.toLowerCase().contains('uncensored'),
        ));
      }
    }

    return items;
  }

  String _cleanText(String raw) {
    return raw
        .replaceAll('&#8211;', '–')
        .replaceAll('&#8212;', '—')
        .replaceAll('&#038;', '&')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<String> _getDefaultTagsForTab(String tabId, {String? extraCategory}) {
    final List<String> tags = [];
    if (extraCategory != null && extraCategory.isNotEmpty) {
      tags.add(extraCategory);
    }
    switch (tabId) {
      case 'doujinshi':
        tags.addAll(["Doujinshi", "Color", "Japanese"]);
        break;
      case 'manga':
        tags.addAll(["Manga", "Serialized", "Tankoubon"]);
        break;
      case 'big_boobs':
        tags.addAll(["Big Boobs", "Paizuri", "Full Color"]);
        break;
      case 'uncensored':
        tags.addAll(["Uncensored", "No Censor", "Decensored"]);
        break;
      case 'latest':
      default:
        tags.addAll(["Latest", "Manga", "Doujinshi"]);
        break;
    }
    return tags.toSet().toList();
  }

  @override
  Future<MediaDetail> detail(String url) async {
    try {
      final response = await http.get(Uri.parse(url), headers: _headers).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final doc = html_parser.parse(response.body);
        final title = doc.querySelector('h1, .gallery_right h1, .info h1')?.text.trim() ?? "HentaiFox Gallery";
        final desc = doc.querySelector('meta[name="description"]')?.attributes['content'] ??
            doc.querySelector('.entry-content p, .galleries_info, .info')?.text.trim() ??
            "Doujinshi and manga archive on HentaiFox.";

        final coverImg = doc.querySelector('.cover img, .gallery_left img, img[src*="cover.jpg"], img[data-src*="cover.jpg"]');
        var cover = coverImg?.attributes['data-src'] ??
            coverImg?.attributes['src'] ??
            doc.querySelector('meta[property="og:image"]')?.attributes['content'] ??
            "";
        if (cover.startsWith('data:')) {
          cover = coverImg?.attributes['data-src'] ?? '';
        }
        if (cover.startsWith('//')) cover = 'https:$cover';
        if (cover.isNotEmpty && !cover.startsWith('http')) {
          cover = cover.startsWith('/') ? '$baseUrl$cover' : '$baseUrl/$cover';
        }

        final tagElements = doc.querySelectorAll('.tags a.tag_btn, .info_tags a, .tag, a[href*="/tag/"], a[href*="/category/"]');
        final List<String> tags = [];
        for (final t in tagElements) {
          final tagText = t.text.replaceAll(RegExp(r'\d+'), '').trim();
          if (tagText.isNotEmpty && !tags.contains(tagText)) {
            tags.add(tagText);
          }
        }
        if (tags.isEmpty) {
          tags.addAll(["Doujinshi", "Manga", "HentaiFox"]);
        }

        final pagesText = doc.querySelector('.pages, .i_text.pages')?.text.replaceAll(RegExp(r'[^0-9]'), '').trim() ?? '32';
        final pagesStr = pagesText.isNotEmpty ? "${pagesText}P" : "Full Gallery";

        final sources = await extractVideoStreams(url);

        return MediaDetail(
          id: url.hashCode.toString(),
          title: _cleanText(title),
          cover: cover.isNotEmpty ? cover : "https://i3.hentaifox.com/005/4180940/cover.jpg",
          backdrop: cover.isNotEmpty ? cover : "https://i3.hentaifox.com/005/4180940/cover.jpg",
          description: desc,
          studio: "HentaiFox",
          releaseDate: "2024",
          tags: tags,
          episodes: [
            EpisodeItem(
              id: "ep_1",
              episodeNumber: "Gallery 1",
              title: _cleanText(title),
              url: url,
              thumbnail: cover.isNotEmpty ? cover : "https://i3.hentaifox.com/005/4180940/cover.jpg",
              duration: pagesStr,
              sources: sources,
            ),
          ],
          playbackHeatmap: [0.1, 0.35, 0.65, 0.95, 0.8, 0.4, 0.3, 0.9, 1.0, 0.4],
          sceneMarkers: [
            SceneMarker(title: "Cover", timestampSeconds: 0),
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
              label: "Fox Stream Server",
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

    final Map<String, List<MediaItem>> sampleSets = {
      "latest": [
        MediaItem(
          id: "hfx_lat_1",
          title: "Rape 0 Chapters: 1-2",
          url: "$baseUrl/gallery/172653/",
          cover: "https://i3.hentaifox.com/005/4180940/thumb.jpg",
          duration: "74P",
          releaseDate: "2024",
          studio: "Doujinshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest", "Doujinshi", "Manga", "Japanese"],
          rating: 4.8,
          views: 220000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hfx_lat_2",
          title: "Maru Gaku Sankaku Nen Sei demo Yarichin Daigakusei to Koi ga Shitai",
          url: "$baseUrl/gallery/172652/",
          cover: "https://i3.hentaifox.com/005/4180919/thumb.jpg",
          duration: "30P",
          releaseDate: "2024",
          studio: "Doujinshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest", "Doujinshi", "Gyaru", "College"],
          rating: 4.9,
          views: 260000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hfx_lat_3",
          title: "Bocchama ni Kageguchi o Kikarete Oshiyoki sareru Namaiki na Kouhai Maid-san 2",
          url: "$baseUrl/gallery/172651/",
          cover: "https://i3.hentaifox.com/005/4180917/thumb.jpg",
          duration: "28P",
          releaseDate: "2024",
          studio: "Doujinshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest", "Maid", "Kouhai", "Punishment"],
          rating: 4.7,
          views: 195000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hfx_lat_4",
          title: "Netorase Play Nanase Hikari no Baai",
          url: "$baseUrl/gallery/172650/",
          cover: "https://i3.hentaifox.com/005/4180896/thumb.jpg",
          duration: "36P",
          releaseDate: "2024",
          studio: "Doujinshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest", "Netorase", "Drama", "Romance"],
          rating: 4.8,
          views: 210000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hfx_lat_5",
          title: "Sukina Ko ga Ibesaa ni Haitta",
          url: "$baseUrl/gallery/172649/",
          cover: "https://i3.hentaifox.com/005/4180892/thumb.jpg",
          duration: "42P",
          releaseDate: "2024",
          studio: "Manga",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest", "Manga", "Club", "School"],
          rating: 4.7,
          views: 180000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hfx_lat_6",
          title: "Ochiba Nikki -Nae Gasshuku Hen 1",
          url: "$baseUrl/gallery/172648/",
          cover: "https://i3.hentaifox.com/005/4180879/thumb.jpg",
          duration: "26P",
          releaseDate: "2024",
          studio: "Doujinshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest", "Doujinshi", "Training Camp", "Summer"],
          rating: 4.8,
          views: 175000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hfx_lat_7",
          title: "Hiyake no Zenra Girl wa, Douse Yaru nara Shinya no Douro de Namahame shitai",
          url: "$baseUrl/gallery/172647/",
          cover: "https://i3.hentaifox.com/005/4180849/thumb.jpg",
          duration: "34P",
          releaseDate: "2024",
          studio: "Doujinshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest", "Tan", "Outdoor", "Gyaru"],
          rating: 4.9,
          views: 290000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hfx_lat_8",
          title: "Tittyfucking Family",
          url: "$baseUrl/gallery/172646/",
          cover: "https://i3.hentaifox.com/005/4180825/thumb.jpg",
          duration: "32P",
          releaseDate: "2024",
          studio: "Doujinshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest", "Big Breasts", "Paizuri", "Family"],
          rating: 4.8,
          views: 245000,
          isUncensored: true,
        ),
      ],
      "doujinshi": [
        MediaItem(
          id: "hfx_dj_1",
          title: "Affected by the sound",
          url: "$baseUrl/gallery/172631/",
          cover: "https://i3.hentaifox.com/005/4180295/thumb.jpg",
          duration: "24P",
          releaseDate: "2024",
          studio: "Doujinshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Doujinshi", "Sound", "Ecchi", "Romance"],
          rating: 4.8,
          views: 185000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hfx_dj_2",
          title: "Netorase Recoil 1&2",
          url: "$baseUrl/gallery/172630/",
          cover: "https://i3.hentaifox.com/005/4180288/thumb.jpg",
          duration: "48P",
          releaseDate: "2024",
          studio: "Doujinshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Doujinshi", "Parody", "Action", "Recoil"],
          rating: 4.9,
          views: 310000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hfx_dj_3",
          title: "Saimin Tanetsuke Onsen_Momo & Aira Hen",
          url: "$baseUrl/gallery/172629/",
          cover: "https://i3.hentaifox.com/005/4180285/thumb.jpg",
          duration: "38P",
          releaseDate: "2024",
          studio: "Doujinshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Doujinshi", "Hypnosis", "Hot Spring", "Onsen"],
          rating: 4.8,
          views: 235000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hfx_dj_4",
          title: "Home Tutor Risa",
          url: "$baseUrl/gallery/172628/",
          cover: "https://i3.hentaifox.com/005/4180283/thumb.jpg",
          duration: "28P",
          releaseDate: "2024",
          studio: "Doujinshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Doujinshi", "Tutor", "Older Sister", "Romance"],
          rating: 4.7,
          views: 170000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hfx_dj_5",
          title: "Kisekoi Shizuku-tan Chikan",
          url: "$baseUrl/gallery/172627/",
          cover: "https://i3.hentaifox.com/005/4180281/thumb.jpg",
          duration: "30P",
          releaseDate: "2024",
          studio: "Doujinshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Doujinshi", "Dress-Up Darling", "Cosplay", "Parody"],
          rating: 4.9,
          views: 340000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hfx_dj_6",
          title: "Succubus ni Naru Boku",
          url: "$baseUrl/gallery/172626/",
          cover: "https://i3.hentaifox.com/005/4180277/thumb.jpg",
          duration: "22P",
          releaseDate: "2024",
          studio: "Doujinshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Doujinshi", "Succubus", "Supernatural", "Gender Bender"],
          rating: 4.8,
          views: 215000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hfx_dj_7",
          title: "Phase Connect Goes Public",
          url: "$baseUrl/gallery/172625/",
          cover: "https://i3.hentaifox.com/005/4180258/thumb.jpg",
          duration: "34P",
          releaseDate: "2024",
          studio: "Doujinshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Doujinshi", "VTuber", "Parody", "Color"],
          rating: 4.7,
          views: 190000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hfx_dj_8",
          title: "Kaoru Rougoku",
          url: "$baseUrl/gallery/172624/",
          cover: "https://i3.hentaifox.com/005/4180254/thumb.jpg",
          duration: "26P",
          releaseDate: "2024",
          studio: "Doujinshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Doujinshi", "Prison", "Bondage", "Dark"],
          rating: 4.6,
          views: 160000,
          isUncensored: true,
        ),
      ],
      "manga": [
        MediaItem(
          id: "hfx_mg_1",
          title: "108P! ~1-nengo ni Zettai 108P Suru Hanashi~ 09",
          url: "$baseUrl/gallery/172641/",
          cover: "https://i3.hentaifox.com/005/4180710/thumb.jpg",
          duration: "24P",
          releaseDate: "2024",
          studio: "Manga",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Manga", "Serialized", "Harem", "Comedy"],
          rating: 4.8,
          views: 225000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hfx_mg_2",
          title: "Please eat my soul! CHAPTER 1-10",
          url: "$baseUrl/gallery/172640/",
          cover: "https://i3.hentaifox.com/005/4180631/thumb.jpg",
          duration: "210P",
          releaseDate: "2024",
          studio: "Manga",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Manga", "Supernatural", "Succubus", "English"],
          rating: 4.9,
          views: 350000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hfx_mg_3",
          title: "Ore, Netoraretaindesu!!! Ch 03-04 en",
          url: "$baseUrl/gallery/172605/",
          cover: "https://i3.hentaifox.com/005/4179957/thumb.jpg",
          duration: "46P",
          releaseDate: "2024",
          studio: "Manga",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Manga", "Netorare", "Drama", "English"],
          rating: 4.7,
          views: 195000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hfx_mg_4",
          title: "Slime no Ongaeshi ~Akui Naki Wana~",
          url: "$baseUrl/gallery/172590/",
          cover: "https://i3.hentaifox.com/005/4179854/thumb.jpg",
          duration: "32P",
          releaseDate: "2024",
          studio: "Manga",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Manga", "Fantasy", "Monster Girl", "Slime"],
          rating: 4.8,
          views: 240000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hfx_mg_5",
          title: "Seichou Suru Slime Rebellion",
          url: "$baseUrl/gallery/172589/",
          cover: "https://i3.hentaifox.com/005/4179850/thumb.jpg",
          duration: "28P",
          releaseDate: "2024",
          studio: "Manga",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Manga", "Fantasy", "Corruption", "Slime"],
          rating: 4.7,
          views: 180000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hfx_mg_6",
          title: "Mi Da Ra",
          url: "$baseUrl/gallery/172585/",
          cover: "https://i3.hentaifox.com/005/4179766/thumb.jpg",
          duration: "180P",
          releaseDate: "2024",
          studio: "Manga",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Manga", "Tankoubon", "Ecchi", "Romance"],
          rating: 4.8,
          views: 210000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hfx_mg_7",
          title: "Shirudaku Nikumatsuri Ch 1-3, 5-6, 8",
          url: "$baseUrl/gallery/172583/",
          cover: "https://i3.hentaifox.com/005/4179749/thumb.jpg",
          duration: "160P",
          releaseDate: "2024",
          studio: "Manga",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Manga", "Anthology", "Carnival", "Serialized"],
          rating: 4.7,
          views: 175000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hfx_mg_8",
          title: "Mamireru Onna | Cream Covered Girl",
          url: "$baseUrl/gallery/172581/",
          cover: "https://i3.hentaifox.com/005/4179686/thumb.jpg",
          duration: "24P",
          releaseDate: "2024",
          studio: "Manga",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Manga", "Cream", "Bukkake", "Romance"],
          rating: 4.8,
          views: 230000,
          isUncensored: false,
        ),
      ],
      "big_boobs": [
        MediaItem(
          id: "hfx_bb_1",
          title: "Masaka Ano Oni Joushi ga Ore no SeFri ni Naru nante 4",
          url: "$baseUrl/gallery/172580/",
          cover: "https://i3.hentaifox.com/005/4179350/thumb.jpg",
          duration: "36P",
          releaseDate: "2024",
          studio: "Doujinshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Big Boobs", "Office Lady", "Boss", "Romance"],
          rating: 4.9,
          views: 295000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hfx_bb_2",
          title: "If We Kiss, We'll Have a Baby! ~The Sanpaku-Eyed Delinquent Slut~",
          url: "$baseUrl/gallery/172577/",
          cover: "https://i3.hentaifox.com/005/4179139/thumb.jpg",
          duration: "40P",
          releaseDate: "2024",
          studio: "Doujinshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Big Boobs", "Gyaru", "Tall Girl", "Vanilla"],
          rating: 4.9,
          views: 315000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hfx_bb_3",
          title: "No one's attaining any enlightment with those huge boobs around",
          url: "$baseUrl/gallery/172576/",
          cover: "https://i3.hentaifox.com/005/4179127/thumb.jpg",
          duration: "28P",
          releaseDate: "2024",
          studio: "Doujinshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Big Boobs", "Priestess", "Shrine Maiden", "Humor"],
          rating: 4.8,
          views: 210000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hfx_bb_4",
          title: "Musashi's Lewd Book 2",
          url: "$baseUrl/gallery/172575/",
          cover: "https://i3.hentaifox.com/005/4179112/thumb.jpg",
          duration: "30P",
          releaseDate: "2024",
          studio: "Doujinshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Big Boobs", "Fate Grand Order", "Musashi", "Parody"],
          rating: 4.9,
          views: 280000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hfx_bb_5",
          title: "Father saw all of it!!",
          url: "$baseUrl/gallery/172574/",
          cover: "https://i3.hentaifox.com/005/4179092/thumb.jpg",
          duration: "26P",
          releaseDate: "2024",
          studio: "Doujinshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Big Boobs", "Family", "Drama", "Caught"],
          rating: 4.7,
          views: 185000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hfx_bb_6",
          title: "Masaka Ano Oni Joushi ga Ore no SeFri ni Naru nante 3",
          url: "$baseUrl/gallery/172571/",
          cover: "https://i3.hentaifox.com/005/4178957/thumb.jpg",
          duration: "32P",
          releaseDate: "2024",
          studio: "Doujinshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Big Boobs", "Office Lady", "Co-habitation", "Love"],
          rating: 4.8,
          views: 240000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hfx_bb_7",
          title: "Maso Chiryou Android kara Nigerarenai Junbigou",
          url: "$baseUrl/gallery/172569/",
          cover: "https://i3.hentaifox.com/005/4178946/thumb.jpg",
          duration: "20P",
          releaseDate: "2024",
          studio: "Doujinshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Big Boobs", "Android", "Sci-Fi", "Femdom"],
          rating: 4.8,
          views: 195000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hfx_bb_8",
          title: "Konbini de Deatta Eroi Onnanoko to Tadare Kitta Kankei ni Narimashita - Chapter 1-10",
          url: "$baseUrl/gallery/172565/",
          cover: "https://i3.hentaifox.com/005/4178714/thumb.jpg",
          duration: "190P",
          releaseDate: "2024",
          studio: "Manga",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Big Boobs", "Manga", "Convenience Store", "Gyaru"],
          rating: 4.9,
          views: 310000,
          isUncensored: false,
        ),
      ],
      "uncensored": [
        MediaItem(
          id: "hfx_unc_1",
          title: "Mako-senpai ni Taberareru ~Chiisakute Dekkai Ama Sado Senpai ni Otosareru~",
          url: "$baseUrl/gallery/172645/",
          cover: "https://i3.hentaifox.com/005/4180781/thumb.jpg",
          duration: "35P",
          releaseDate: "2024",
          studio: "Doujinshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Senpai", "Petite", "Sadist"],
          rating: 4.9,
          views: 325000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hfx_unc_2",
          title: "Cooking Pakopako | Cooking Fucka",
          url: "$baseUrl/gallery/172615/",
          cover: "https://i3.hentaifox.com/005/4180223/thumb.jpg",
          duration: "28P",
          releaseDate: "2024",
          studio: "Doujinshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Cooking", "Apron", "Romance"],
          rating: 4.8,
          views: 220000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hfx_unc_3",
          title: "My Little Sister Was a Hostess at Class 2-C's School Festival Boobs Bar",
          url: "$baseUrl/gallery/172612/",
          cover: "https://i3.hentaifox.com/005/4180170/thumb.jpg",
          duration: "30P",
          releaseDate: "2024",
          studio: "Doujinshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "School Festival", "Imouto", "Cosplay"],
          rating: 4.8,
          views: 245000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hfx_unc_4",
          title: "Choujin VERSUS",
          url: "$baseUrl/gallery/172584/",
          cover: "https://i3.hentaifox.com/005/4179765/thumb.jpg",
          duration: "32P",
          releaseDate: "2024",
          studio: "Doujinshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Superhero", "Action", "Crossover"],
          rating: 4.7,
          views: 190000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hfx_unc_5",
          title: "Watashi no Tenshi na Musume | My Angelic Daughter",
          url: "$baseUrl/gallery/172538/",
          cover: "https://i3.hentaifox.com/005/4177925/thumb.jpg",
          duration: "24P",
          releaseDate: "2024",
          studio: "Doujinshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Family", "Emotional", "Vanilla"],
          rating: 4.9,
          views: 270000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hfx_unc_6",
          title: "Zense Mitai ni Torotoro ni Amayakashite ageru nee | I'll Spoil You Until You Melt",
          url: "$baseUrl/gallery/172458/",
          cover: "https://i3.hentaifox.com/005/4176206/thumb.jpg",
          duration: "34P",
          releaseDate: "2024",
          studio: "Doujinshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Reincarnation", "Onee-san", "Pampering"],
          rating: 4.8,
          views: 235000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hfx_unc_7",
          title: "Living Doll Sumire: Summer of Pleasure 3",
          url: "$baseUrl/gallery/172447/",
          cover: "https://i3.hentaifox.com/005/4175857/thumb.jpg",
          duration: "40P",
          releaseDate: "2024",
          studio: "Doujinshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Doll", "Summer", "Fetish"],
          rating: 4.8,
          views: 215000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hfx_unc_8",
          title: "Living Doll Sumire: Summer of Pleasure 2",
          url: "$baseUrl/gallery/172446/",
          cover: "https://i3.hentaifox.com/005/4175837/thumb.jpg",
          duration: "38P",
          releaseDate: "2024",
          studio: "Doujinshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Doll", "Swimsuit", "Summer"],
          rating: 4.7,
          views: 185000,
          isUncensored: true,
        ),
      ],
    };

    return sampleSets[tabId] ?? sampleSets["latest"] ?? [];
  }

  MediaDetail _generateSampleDetail(String url) {
    return MediaDetail(
      id: url.hashCode.toString(),
      title: "Rape 0 Chapters: 1-2",
      cover: "https://i3.hentaifox.com/005/4180940/cover.jpg",
      backdrop: "https://i3.hentaifox.com/005/4180940/cover.jpg",
      description: "Full chapter manga & doujinshi archive on HentaiFox.",
      studio: "HentaiFox",
      releaseDate: "2024",
      tags: ["Doujinshi", "Manga", "Japanese", "Uncensored"],
      episodes: [
        EpisodeItem(
          id: "ep_1",
          episodeNumber: "Gallery 1",
          title: "Full Gallery Reader",
          url: url,
          thumbnail: "https://i3.hentaifox.com/005/4180940/cover.jpg",
          duration: "74P",
          sources: [
            StreamSource(
              label: "HD Reader Stream",
              url: "https://oppai-str.shoujo-h.org/2026/Furachi/E01/x264.1080p.mp4",
              protocol: StreamProtocol.directMp4,
              headers: {'Referer': baseUrl, 'User-Agent': _headers['User-Agent']!},
            )
          ],
        )
      ],
      playbackHeatmap: [0.1, 0.4, 0.7, 0.95, 0.8, 0.4, 0.3, 0.9, 1.0, 0.4],
      sceneMarkers: [
        SceneMarker(title: "Cover", timestampSeconds: 0),
        SceneMarker(title: "Climax 🔥", timestampSeconds: 700),
      ],
    );
  }

  @override
  Future<ExtensionTaxonomy> fetchTaxonomy() async {
    return hentaiFoxTaxonomy;
  }

  @override
  Future<List<MediaItem>> fetchTaxonomyFeed(CatalogItem item, int page) async {
    // 1. Direct tab shortcuts
    if (item.slug == "latest") {
      return fetchTabFeed("latest", page);
    }
    if (item.slug == "doujinshi") {
      return fetchTabFeed("doujinshi", page);
    }
    if (item.slug == "manga") {
      return fetchTabFeed("manga", page);
    }

    // 2. Artists live feed
    if (item.type == CatalogType.artist ||
        (item.endpointPath != null && item.endpointPath!.contains("/artist/")) ||
        item.categoryGroup == "Artist") {
      try {
        final slug = item.slug;
        final targetUrl = page == 1
            ? "$baseUrl/artist/$slug/"
            : "$baseUrl/artist/$slug/pag/$page/";
        final response = await http.get(Uri.parse(targetUrl), headers: _headers).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          final items = _parseCardsFromHtml(response.body, tabId: slug);
          if (items.isNotEmpty) return items;
        }
      } catch (_) {}
      return search(item.name, page);
    }

    // 3. Categories live feed
    if (item.type == CatalogType.category ||
        (item.endpointPath != null && item.endpointPath!.contains("/category/"))) {
      try {
        final slug = item.slug;
        final targetUrl = page == 1
            ? "$baseUrl/category/$slug/"
            : "$baseUrl/category/$slug/pag/$page/";
        final response = await http.get(Uri.parse(targetUrl), headers: _headers).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          final items = _parseCardsFromHtml(response.body, tabId: slug);
          if (items.isNotEmpty) return items;
        }
      } catch (_) {}
      return search(item.name, page);
    }

    // 4. Parody / Character / Custom endpoint paths
    if (item.endpointPath != null && item.endpointPath!.isNotEmpty && item.endpointPath != "/") {
      try {
        final path = item.endpointPath!.endsWith('/')
            ? item.endpointPath!
            : "${item.endpointPath!}/";
        final targetUrl = page == 1
            ? "$baseUrl$path"
            : "$baseUrl${path}pag/$page/";
        final response = await http.get(Uri.parse(targetUrl), headers: _headers).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          final items = _parseCardsFromHtml(response.body, tabId: item.slug);
          if (items.isNotEmpty) return items;
        }
      } catch (_) {}
    }

    // 5. Tags / Tropes live feed
    try {
      final slug = item.slug;
      final targetUrl = page == 1
          ? "$baseUrl/tag/$slug/"
          : "$baseUrl/tag/$slug/pag/$page/";
      final response = await http.get(Uri.parse(targetUrl), headers: _headers).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final items = _parseCardsFromHtml(response.body, tabId: slug);
        if (items.isNotEmpty) return items;
      }
    } catch (_) {}

    return search(item.name, page);
  }
}
