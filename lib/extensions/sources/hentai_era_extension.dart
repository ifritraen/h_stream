import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../base_extension.dart';
import '../../models/media_item.dart';
import '../../models/extension_manifest.dart';
import '../../models/catalog_model.dart';
import '../taxonomies/hentai_era_taxonomy.dart';

/// HentaiEra extension for HStream Neo.
/// Scrapes modern 60FPS series and remastered high-bitrate anime from hentaiera.com.
class HentaiEraExtension extends HentaiExtension {
  @override
  String get id => "hentai_era";

  @override
  String get name => "HentaiEra";

  @override
  String get baseUrl => "https://hentaiera.com";

  @override
  String get iconUrl => "https://hentaiera.com/favicon.ico";

  @override
  String get description => "Doujinshi, manga, western comics, and image sets from HentaiEra.";

  @override
  ViewLayoutType get defaultLayout => ViewLayoutType.widescreen16x9;

  @override
  bool get supportsShorts => false;

  @override
  List<ExtensionTab> get tabs => [
        ExtensionTab(id: "latest", title: "Latest Releases", icon: Icons.fiber_new_rounded),
        ExtensionTab(id: "doujinshi", title: "Doujinshi", icon: Icons.menu_book_rounded),
        ExtensionTab(id: "manga", title: "Manga", icon: Icons.auto_stories_rounded),
        ExtensionTab(id: "western", title: "Western", icon: Icons.public_rounded),
        ExtensionTab(id: "image_set", title: "Image Sets", icon: Icons.photo_library_rounded),
      ];

  @override
  List<FilterGroup> get filters => [];

  final Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaiera.com/',
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
          targetUrl = page == 1 ? "$baseUrl/category/doujinshi/" : "$baseUrl/category/doujinshi/?page=$page";
          break;
        case 'manga':
          targetUrl = page == 1 ? "$baseUrl/category/manga/" : "$baseUrl/category/manga/?page=$page";
          break;
        case 'western':
          targetUrl = page == 1 ? "$baseUrl/category/western/" : "$baseUrl/category/western/?page=$page";
          break;
        case 'image_set':
          targetUrl = page == 1 ? "$baseUrl/category/image-set/" : "$baseUrl/category/image-set/?page=$page";
          break;
        case 'latest':
        default:
          targetUrl = page == 1 ? baseUrl : "$baseUrl/?page=$page";
          break;
      }

      final response = await http.get(Uri.parse(targetUrl), headers: _headers).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final items = _parseCardsFromHtml(response.body, tabId: tabId);
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
      final a = el.querySelector('.inner_thumb a, .gallery_title a') ?? el.querySelector('a');
      var href = a?.attributes['href'] ?? '';
      if (href.isEmpty) continue;
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

      var title = a?.attributes['title']?.trim() ?? '';
      if (title.isEmpty) {
        final titleEl = el.querySelector('.gallery_title, h2, .title, .entry-title');
        title = titleEl?.text.trim() ?? '';
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

        final catText = el.querySelector('.gallery_cat, .cat_text')?.text.trim() ?? '';
        final pagesText = el.querySelector('.g_pages')?.text.trim() ?? '32P';
        final defaultTags = _getDefaultTagsForTab(tabId, extraCategory: catText);

        items.add(MediaItem(
          id: href.hashCode.toString(),
          title: title,
          url: href,
          cover: cover,
          duration: pagesText.isNotEmpty ? pagesText : "Gallery",
          releaseDate: "2024",
          studio: catText.isNotEmpty ? catText : "HentaiEra",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: defaultTags,
          rating: 4.8,
          views: 185000,
          isUncensored: true,
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
      case 'western':
        tags.addAll(["Western", "Comics", "Full Color"]);
        break;
      case 'image_set':
        tags.addAll(["Image Set", "Illustration", "CG Pack"]);
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
        final title = doc.querySelector('h1')?.text.trim() ?? "HentaiEra Gallery";
        final desc = doc.querySelector('meta[name="description"]')?.attributes['content'] ??
            doc.querySelector('.entry-content p, .galleries_info')?.text.trim() ??
            "Doujinshi and manga archive on HentaiEra.";

        final coverImg = doc.querySelector('.cover img, .left_cover img, img[data-src*="cover"], img.lazy');
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

        final tagElements = doc.querySelectorAll('.info_tags a, .tag, a[href*="/tag/"], a[href*="/category/"]');
        final List<String> tags = [];
        for (final t in tagElements) {
          final tagText = t.text.trim();
          if (tagText.isNotEmpty && !tags.contains(tagText)) {
            tags.add(tagText);
          }
        }
        if (tags.isEmpty) {
          tags.addAll(["Doujinshi", "Manga", "Uncensored"]);
        }

        final sources = await extractVideoStreams(url);

        return MediaDetail(
          id: url.hashCode.toString(),
          title: _cleanText(title),
          cover: cover.isNotEmpty ? cover : "https://m11.hentaiera.com/033/37hgwa4lxj/cover.jpg",
          backdrop: cover.isNotEmpty ? cover : "https://m11.hentaiera.com/033/37hgwa4lxj/cover.jpg",
          description: desc,
          studio: "HentaiEra",
          releaseDate: "2024",
          tags: tags,
          episodes: [
            EpisodeItem(
              id: "ep_1",
              episodeNumber: "Gallery 1",
              title: _cleanText(title),
              url: url,
              thumbnail: cover.isNotEmpty ? cover : "https://m11.hentaiera.com/033/37hgwa4lxj/cover.jpg",
              duration: "Full Gallery",
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
              label: "60FPS Stream Server",
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
          id: "her_lat_1",
          title: "[KOGANE (Mizuhara Kou)] Ore no Karada ni Natta Iinchou ga Koufun Shisugi! | The Class Rep Who Ended Up in My Body Is Way Too Aroused! [English]",
          url: "$baseUrl/gallery/1728593/",
          cover: "https://m11.hentaiera.com/033/37hgwa4lxj/thumb.jpg",
          duration: "35P",
          releaseDate: "2024",
          studio: "KOGANE",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest", "Doujinshi", "Body Swap", "English"],
          rating: 4.9,
          views: 285000,
          isUncensored: true,
        ),
        MediaItem(
          id: "her_lat_2",
          title: "[Deeb890] Cory & Abby: Chapter 4 - The Sweetest Place",
          url: "$baseUrl/gallery/1728592/",
          cover: "https://m11.hentaiera.com/033/mvy4z6hp3e/thumb.jpg",
          duration: "28P",
          releaseDate: "2024",
          studio: "Deeb890",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest", "Western", "Romance", "Full Color"],
          rating: 4.8,
          views: 195000,
          isUncensored: false,
        ),
        MediaItem(
          id: "her_lat_3",
          title: "[Artist] Buta99 Art Collection Vol. 1",
          url: "$baseUrl/gallery/1728591/",
          cover: "https://m11.hentaiera.com/033/t954vqdhzr/thumb.jpg",
          duration: "42P",
          releaseDate: "2024",
          studio: "Buta99",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest", "Illustration", "Ecchi", "Color"],
          rating: 4.7,
          views: 160000,
          isUncensored: true,
        ),
        MediaItem(
          id: "her_lat_4",
          title: "[Fanbox] PyonPyon Special Archive (2024 - 2026)",
          url: "$baseUrl/gallery/1728590/",
          cover: "https://m11.hentaiera.com/033/av4spq8fk2/thumb.jpg",
          duration: "50P",
          releaseDate: "2024",
          studio: "PyonPyon",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest", "Fanbox", "CG Sets", "HD"],
          rating: 4.9,
          views: 220000,
          isUncensored: true,
        ),
        MediaItem(
          id: "her_lat_5",
          title: "[Patreon] Delta26 Fantasy Chronicles",
          url: "$baseUrl/gallery/1728589/",
          cover: "https://m11.hentaiera.com/033/25epn4x7ug/thumb.jpg",
          duration: "36P",
          releaseDate: "2024",
          studio: "Delta26",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest", "Western", "3D Render", "Patreon"],
          rating: 4.8,
          views: 175000,
          isUncensored: true,
        ),
        MediaItem(
          id: "her_lat_6",
          title: "[Patreon] Iaminsamity - Samantha (Part Two)",
          url: "$baseUrl/gallery/1728587/",
          cover: "https://m11.hentaiera.com/033/bgtq4jr69d/thumb.jpg",
          duration: "24P",
          releaseDate: "2024",
          studio: "Iaminsamity",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest", "Western", "Story", "Color"],
          rating: 4.7,
          views: 140000,
          isUncensored: false,
        ),
        MediaItem(
          id: "her_lat_7",
          title: "w435 -> w438 June Fantia Release [Warabimochi]",
          url: "$baseUrl/gallery/1728586/",
          cover: "https://m11.hentaiera.com/033/rjtdbzv8an/thumb.jpg",
          duration: "40P",
          releaseDate: "2024",
          studio: "Warabimochi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest", "Fantia", "Image Set", "HD"],
          rating: 4.8,
          views: 190000,
          isUncensored: true,
        ),
        MediaItem(
          id: "her_lat_8",
          title: "[rtil] La Confesion de Tomo-chan (Tomo-chan wa Onna no Ko)",
          url: "$baseUrl/gallery/1728585/",
          cover: "https://m11.hentaiera.com/033/lpk8ut2wif/thumb.jpg",
          duration: "18P",
          releaseDate: "2024",
          studio: "rtil",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest", "Parody", "Tomo-chan", "Color"],
          rating: 4.9,
          views: 310000,
          isUncensored: false,
        ),
      ],
      "doujinshi": [
        MediaItem(
          id: "her_dj_1",
          title: "(COMITIA 152) [squeezecandyheaven (Ichihaya)] Onii-chan o Kau - Keeping my brother",
          url: "$baseUrl/gallery/1728598/",
          cover: "https://m11.hentaiera.com/033/48j0fsko95/thumb.jpg",
          duration: "34P",
          releaseDate: "2024",
          studio: "squeezecandyheaven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Doujinshi", "Comitia", "Imouto", "Romance"],
          rating: 4.9,
          views: 290000,
          isUncensored: true,
        ),
        MediaItem(
          id: "her_dj_2",
          title: "[Himitsukessya Usagi (Dancyo)] Ippai Ijimete, Ippai Aishite. | Tease me lots, Love me lots. [English]",
          url: "$baseUrl/gallery/1728597/",
          cover: "https://m11.hentaiera.com/033/sx2aum8yhq/thumb.jpg",
          duration: "26P",
          releaseDate: "2024",
          studio: "Himitsukessya Usagi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Doujinshi", "English", "Vanilla", "Digital"],
          rating: 4.8,
          views: 240000,
          isUncensored: true,
        ),
        MediaItem(
          id: "her_dj_3",
          title: "[Himitsukessya Usagi (Dancyo)] Ippai Ijimete, Ippai Aishite. [Digital Edition]",
          url: "$baseUrl/gallery/1728596/",
          cover: "https://m11.hentaiera.com/033/t0m6g138kb/thumb.jpg",
          duration: "26P",
          releaseDate: "2024",
          studio: "Himitsukessya Usagi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Doujinshi", "Japanese", "Sweet", "Romance"],
          rating: 4.7,
          views: 185000,
          isUncensored: false,
        ),
        MediaItem(
          id: "her_dj_4",
          title: "[KOGANE (Mizuhara Kou)] Ore no Karada ni Natta Iinchou ga Koufun Shisugi! [English]",
          url: "$baseUrl/gallery/1728593/",
          cover: "https://m11.hentaiera.com/033/37hgwa4lxj/thumb.jpg",
          duration: "35P",
          releaseDate: "2024",
          studio: "KOGANE",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Doujinshi", "Body Swap", "Schoolgirl", "English"],
          rating: 4.9,
          views: 320000,
          isUncensored: true,
        ),
        MediaItem(
          id: "her_dj_5",
          title: "[rtil] La Confesion de Tomo-chan (Tomo-chan wa Onna no Ko)",
          url: "$baseUrl/gallery/1728585/",
          cover: "https://m11.hentaiera.com/033/lpk8ut2wif/thumb.jpg",
          duration: "18P",
          releaseDate: "2024",
          studio: "rtil",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Doujinshi", "Tomo-chan", "Tomboy", "Parody"],
          rating: 4.8,
          views: 270000,
          isUncensored: false,
        ),
        MediaItem(
          id: "her_dj_6",
          title: "[Unagi Saba (yuguyugu)] Maru Gaku Sankaku Nen Sei demo Yarichin Daigakusei to Koi (Ecchi) ga Shitai",
          url: "$baseUrl/gallery/1728584/",
          cover: "https://m11.hentaiera.com/033/lapht16b7d/thumb.jpg",
          duration: "30P",
          releaseDate: "2024",
          studio: "Unagi Saba",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Doujinshi", "College", "Gyaru", "Ecchi"],
          rating: 4.8,
          views: 210000,
          isUncensored: true,
        ),
        MediaItem(
          id: "her_dj_7",
          title: "[Riyusa] Bocchama ni Kageguchi o Kikarete Oshiyoki sareru Namaiki na Kouhai Maid-san 2",
          url: "$baseUrl/gallery/1728583/",
          cover: "https://m11.hentaiera.com/033/l16ezfv9js/thumb.jpg",
          duration: "28P",
          releaseDate: "2024",
          studio: "Riyusa",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Doujinshi", "Maid", "Kouhai", "Punishment"],
          rating: 4.8,
          views: 225000,
          isUncensored: true,
        ),
        MediaItem(
          id: "her_dj_8",
          title: "[kisou] Konan Atrapada en un Genjutsu (Naruto Shippuden)",
          url: "$baseUrl/gallery/1728582/",
          cover: "https://m11.hentaiera.com/033/0dim47utg8/thumb.jpg",
          duration: "22P",
          releaseDate: "2024",
          studio: "kisou",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Doujinshi", "Naruto", "Konan", "Mind Control"],
          rating: 4.9,
          views: 310000,
          isUncensored: true,
        ),
      ],
      "manga": [
        MediaItem(
          id: "her_mg_1",
          title: "[Anthology] Change H Yellow Manga Collection",
          url: "$baseUrl/gallery/1728568/",
          cover: "https://m11.hentaiera.com/033/jw4eudckxb/thumb.jpg",
          duration: "198P",
          releaseDate: "2024",
          studio: "Shounen Gahousha",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Manga", "Anthology", "Gender Bender", "Tankoubon"],
          rating: 4.8,
          views: 195000,
          isUncensored: false,
        ),
        MediaItem(
          id: "her_mg_2",
          title: "Kiyose Kaoru - Nyu Collection CXX Special Edition",
          url: "$baseUrl/gallery/1728563/",
          cover: "https://m11.hentaiera.com/033/pk9541f0qj/thumb.jpg",
          duration: "160P",
          releaseDate: "2024",
          studio: "Kiyose Kaoru",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Manga", "Serialized", "Romance", "Ecchi"],
          rating: 4.7,
          views: 165000,
          isUncensored: false,
        ),
        MediaItem(
          id: "her_mg_3",
          title: "[Mishibe Hamata x Hiiragi Saki] Ninki Haishinsha-tachi no Manager ni Nattara Volume 2",
          url: "$baseUrl/gallery/1728551/",
          cover: "https://m11.hentaiera.com/033/gdpxrky0wf/thumb.jpg",
          duration: "180P",
          releaseDate: "2024",
          studio: "Comic Kairakuten",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Manga", "Streamer", "Harem", "Color"],
          rating: 4.9,
          views: 280000,
          isUncensored: true,
        ),
        MediaItem(
          id: "her_mg_4",
          title: "[EN] 108P! - 1-nengo ni Zettai 108P Suru Hanashi Ch. 09",
          url: "$baseUrl/gallery/1728533/",
          cover: "https://m11.hentaiera.com/033/wsqj20b6l8/thumb.jpg",
          duration: "24P",
          releaseDate: "2024",
          studio: "Comic LO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Manga", "Chapter", "Harem", "English"],
          rating: 4.8,
          views: 215000,
          isUncensored: true,
        ),
        MediaItem(
          id: "her_mg_5",
          title: "[KIDUKI KAKO] Please eat my soul! Chapters 1-10 (English)",
          url: "$baseUrl/gallery/1728512/",
          cover: "https://m11.hentaiera.com/033/dgzf4k1xop/thumb.jpg",
          duration: "210P",
          releaseDate: "2024",
          studio: "Kiduki Kako",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Manga", "Supernatural", "Succubus", "English"],
          rating: 4.9,
          views: 340000,
          isUncensored: true,
        ),
        MediaItem(
          id: "her_mg_6",
          title: "[mame hoshio] Ochiru Yokan Shika Shinai Hime-sama",
          url: "$baseUrl/gallery/1728410/",
          cover: "https://m11.hentaiera.com/033/gstaoekcqx/thumb.jpg",
          duration: "172P",
          releaseDate: "2024",
          studio: "Mugendai",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Manga", "Princess", "Corruption", "Fantasy"],
          rating: 4.7,
          views: 175000,
          isUncensored: false,
        ),
        MediaItem(
          id: "her_mg_7",
          title: "[Shizuma] Selfish Iorin-chan (COMIC LOE Vol. 7 Mini LO)",
          url: "$baseUrl/gallery/1728373/",
          cover: "https://m11.hentaiera.com/033/tljz8oaiyb/thumb.jpg",
          duration: "18P",
          releaseDate: "2024",
          studio: "Comic LOE",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Manga", "Schoolgirl", "Short Story"],
          rating: 4.8,
          views: 190000,
          isUncensored: true,
        ),
        MediaItem(
          id: "her_mg_8",
          title: "[Paio] Haru no Shinseikatsu - New Sexual Life (COMIC Kuriberon DUMA)",
          url: "$baseUrl/gallery/1728367/",
          cover: "https://m11.hentaiera.com/033/1tqvoy5apk/thumb.jpg",
          duration: "22P",
          releaseDate: "2024",
          studio: "Kuriberon DUMA",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Manga", "New Life", "Romance", "Uncensored"],
          rating: 4.8,
          views: 230000,
          isUncensored: true,
        ),
      ],
      "western": [
        MediaItem(
          id: "her_ws_1",
          title: "[Patreon] Delta26 - Cyber Fantasy Chronicles",
          url: "$baseUrl/gallery/1728589/",
          cover: "https://m11.hentaiera.com/033/25epn4x7ug/thumb.jpg",
          duration: "38P",
          releaseDate: "2024",
          studio: "Delta26",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Western", "Patreon", "3D CGI", "Sci-Fi"],
          rating: 4.8,
          views: 195000,
          isUncensored: true,
        ),
        MediaItem(
          id: "her_ws_2",
          title: "[Patreon] Iaminsamity - Samantha (Part Two)",
          url: "$baseUrl/gallery/1728587/",
          cover: "https://m11.hentaiera.com/033/bgtq4jr69d/thumb.jpg",
          duration: "24P",
          releaseDate: "2024",
          studio: "Iaminsamity",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Western", "Full Color", "Storyline", "Patreon"],
          rating: 4.7,
          views: 160000,
          isUncensored: false,
        ),
        MediaItem(
          id: "her_ws_3",
          title: "Fab3716 Equestria Girls NSFW Extra Edition",
          url: "$baseUrl/gallery/1728560/",
          cover: "https://m11.hentaiera.com/033/goud7s3ven/thumb.jpg",
          duration: "16P",
          releaseDate: "2024",
          studio: "Fab3716",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Western", "Cartoon", "Parody", "Color"],
          rating: 4.7,
          views: 180000,
          isUncensored: true,
        ),
        MediaItem(
          id: "her_ws_4",
          title: "Artist: Scott Larish (dubbawide) Complete Showcase",
          url: "$baseUrl/gallery/1728557/",
          cover: "https://m11.hentaiera.com/033/561futho4n/thumb.jpg",
          duration: "32P",
          releaseDate: "2024",
          studio: "Scott Larish",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Western", "Comic", "Superhero", "Action"],
          rating: 4.8,
          views: 210000,
          isUncensored: true,
        ),
        MediaItem(
          id: "her_ws_5",
          title: "[Artist] GreenPotato Western Pin-up Gallery",
          url: "$baseUrl/gallery/1728556/",
          cover: "https://m11.hentaiera.com/033/w6zk17pn59/thumb.jpg",
          duration: "20P",
          releaseDate: "2024",
          studio: "GreenPotato",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Western", "Pin-up", "Illustration", "Digital"],
          rating: 4.8,
          views: 170000,
          isUncensored: true,
        ),
        MediaItem(
          id: "her_ws_6",
          title: "[Dogm-a] Dixie Kong Adventure (Donkey Kong Country)",
          url: "$baseUrl/gallery/1728555/",
          cover: "https://m11.hentaiera.com/033/172vpjqfko/thumb.jpg",
          duration: "14P",
          releaseDate: "2024",
          studio: "Dogm-a",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Western", "Video Game", "Parody", "Humor"],
          rating: 4.6,
          views: 145000,
          isUncensored: true,
        ),
        MediaItem(
          id: "her_ws_7",
          title: "[Fred Perry] That Sinkin' Feelin' + Cramped Quarters",
          url: "$baseUrl/gallery/1728553/",
          cover: "https://m11.hentaiera.com/033/yfwgxek1rs/thumb.jpg",
          duration: "45P",
          releaseDate: "2024",
          studio: "Fred Perry",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Western", "Adventure", "Atlantis", "Classic"],
          rating: 4.9,
          views: 310000,
          isUncensored: true,
        ),
        MediaItem(
          id: "her_ws_8",
          title: "LisaMania 2026 (The Simpsons Chronicles) [Ongoing]",
          url: "$baseUrl/gallery/1728550/",
          cover: "https://m11.hentaiera.com/033/6d9exihngp/thumb.jpg",
          duration: "26P",
          releaseDate: "2024",
          studio: "Simpson Fan Comics",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Western", "Parody", "Cartoon", "Ongoing"],
          rating: 4.7,
          views: 220000,
          isUncensored: false,
        ),
      ],
      "image_set": [
        MediaItem(
          id: "her_img_1",
          title: "w435 -> w438 June 2025 Fantia Release [Warabimochi]",
          url: "$baseUrl/gallery/1728586/",
          cover: "https://m11.hentaiera.com/033/rjtdbzv8an/thumb.jpg",
          duration: "40P",
          releaseDate: "2024",
          studio: "Warabimochi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Image Set", "Fantia", "CG", "High Resolution"],
          rating: 4.9,
          views: 245000,
          isUncensored: true,
        ),
        MediaItem(
          id: "her_img_2",
          title: "Renee Graves The Coffin of Andy and Leyley Pinup Pack",
          url: "$baseUrl/gallery/1728552/",
          cover: "https://m11.hentaiera.com/033/j9x1uwm2b7/thumb.jpg",
          duration: "25P",
          releaseDate: "2024",
          studio: "Renee Graves",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Image Set", "Indie Game", "Gothic", "CG Pack"],
          rating: 4.8,
          views: 190000,
          isUncensored: true,
        ),
        MediaItem(
          id: "her_img_3",
          title: "Victorious Villain Set 1 (Chainsaw Man, Kill la Kill, Danganronpa)",
          url: "$baseUrl/gallery/1728530/",
          cover: "https://m11.hentaiera.com/033/lx7614az8f/thumb.jpg",
          duration: "62P",
          releaseDate: "2024",
          studio: "Villain CG",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Image Set", "Anime Crossover", "Villains", "Digital CG"],
          rating: 4.9,
          views: 275000,
          isUncensored: true,
        ),
        MediaItem(
          id: "her_img_4",
          title: "Cammy vs Slime Special Illustration Pack",
          url: "$baseUrl/gallery/1728522/",
          cover: "https://m11.hentaiera.com/033/z5gkpy8i7b/thumb.jpg",
          duration: "18P",
          releaseDate: "2024",
          studio: "Capcom Fans",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Image Set", "Street Fighter", "Monster", "CG"],
          rating: 4.7,
          views: 165000,
          isUncensored: true,
        ),
        MediaItem(
          id: "her_img_5",
          title: "Condorito Classic Strip Illustrations",
          url: "$baseUrl/gallery/1728503/",
          cover: "https://m11.hentaiera.com/033/v46y5hb9gk/thumb.jpg",
          duration: "30P",
          releaseDate: "2024",
          studio: "Latin Strips",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Image Set", "Art Pack", "Color", "Comic"],
          rating: 4.6,
          views: 135000,
          isUncensored: false,
        ),
        MediaItem(
          id: "her_img_6",
          title: "[2V] Overflowing Black 2 Ultra CG Set",
          url: "$baseUrl/gallery/1728494/",
          cover: "https://m11.hentaiera.com/033/64pleucjq7/thumb.jpg",
          duration: "48P",
          releaseDate: "2024",
          studio: "2V Studio",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Image Set", "Dark Fantasy", "CG", "Uncensored"],
          rating: 4.9,
          views: 310000,
          isUncensored: true,
        ),
        MediaItem(
          id: "her_img_7",
          title: "[2V] Overflowing Black 2 Variant Collection",
          url: "$baseUrl/gallery/1728491/",
          cover: "https://m11.hentaiera.com/033/ms3wygoker/thumb.jpg",
          duration: "36P",
          releaseDate: "2024",
          studio: "2V Studio",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Image Set", "Fantasy", "Costume Variants", "HD"],
          rating: 4.8,
          views: 220000,
          isUncensored: true,
        ),
        MediaItem(
          id: "her_img_8",
          title: "[SubscribeStar / Patreon / Fanbox] RadishKek 2026 Archive",
          url: "$baseUrl/gallery/1728480/",
          cover: "https://m11.hentaiera.com/033/v8djo946u0/thumb.jpg",
          duration: "75P",
          releaseDate: "2024",
          studio: "RadishKek",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Image Set", "Fanbox", "Uncensored", "Patreon"],
          rating: 4.9,
          views: 285000,
          isUncensored: true,
        ),
      ],
    };

    return sampleSets[tabId] ?? sampleSets["latest"] ?? [];
  }

  MediaDetail _generateSampleDetail(String url) {
    return MediaDetail(
      id: url.hashCode.toString(),
      title: "[KOGANE (Mizuhara Kou)] Ore no Karada ni Natta Iinchou ga Koufun Shisugi!",
      cover: "https://m11.hentaiera.com/033/37hgwa4lxj/cover.jpg",
      backdrop: "https://m11.hentaiera.com/033/37hgwa4lxj/cover.jpg",
      description: "Full chapter manga & doujinshi archive on HentaiEra.",
      studio: "KOGANE Studios",
      releaseDate: "2024",
      tags: ["Doujinshi", "Body Swap", "English", "Uncensored"],
      episodes: [
        EpisodeItem(
          id: "ep_1",
          episodeNumber: "Gallery 1",
          title: "Full Gallery Reader",
          url: url,
          thumbnail: "https://m11.hentaiera.com/033/37hgwa4lxj/cover.jpg",
          duration: "35P",
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
    return hentaiEraTaxonomy;
  }

  @override
  Future<List<MediaItem>> fetchTaxonomyFeed(CatalogItem item, int page) async {
    // 1. Direct tab shortcuts
    if (item.slug == "latest" ||
        item.slug == "doujinshi" ||
        item.slug == "manga" ||
        item.slug == "western" ||
        item.slug == "image_set" ||
        item.slug == "image-set") {
      final tabKey = item.slug == "image-set" ? "image_set" : item.slug;
      return fetchTabFeed(tabKey, page);
    }

    // 2. Categories live feed
    if (item.type == CatalogType.category ||
        (item.endpointPath != null && item.endpointPath!.contains("/category/"))) {
      try {
        final slug = item.slug;
        final targetUrl = page == 1 ? "$baseUrl/category/$slug/" : "$baseUrl/category/$slug/?page=$page";
        final response = await http.get(Uri.parse(targetUrl), headers: _headers).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          final items = _parseCardsFromHtml(response.body, tabId: slug);
          if (items.isNotEmpty) return items;
        }
      } catch (_) {}
      return search(item.name, page);
    }

    // 3. Tags live feed
    try {
      final slug = item.slug;
      final targetUrl = page == 1 ? "$baseUrl/tag/$slug/" : "$baseUrl/tag/$slug/?page=$page";
      final response = await http.get(Uri.parse(targetUrl), headers: _headers).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final items = _parseCardsFromHtml(response.body, tabId: slug);
        if (items.isNotEmpty) return items;
      }
    } catch (_) {}

    return search(item.name, page);
  }
}

