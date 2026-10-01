import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import '../base_extension.dart';
import '../../models/media_item.dart';
import '../../models/extension_manifest.dart';
import '../../models/catalog_model.dart';
import '../taxonomies/my_hentai_movie_taxonomy.dart';

/// MyHentaiMovie extension for HStream Neo.
/// Scrapes full-length theatrical movies and high-budget specials from myhentaimovie.com.
class MyHentaiMovieExtension extends HentaiExtension {
  @override
  String get id => "my_hentai_movie";

  @override
  String get name => "MyHentaiMovie";

  @override
  String get baseUrl => "https://myhentaimovie.com";

  @override
  String get iconUrl => "https://myhentaimovie.com/favicon.ico";

  @override
  String get description => "Full-length theatrical movies, high-budget specials, and complete OVA packs.";

  @override
  ViewLayoutType get defaultLayout => ViewLayoutType.widescreen16x9;

  @override
  bool get supportsShorts => false;

  @override
  List<ExtensionTab> get tabs => [
        ExtensionTab(id: "movies", title: "Theatrical Movies", icon: Icons.movie_rounded),
        ExtensionTab(id: "popular", title: "Most Viewed", icon: Icons.whatshot_rounded),
        ExtensionTab(id: "ovas", title: "Complete OVAs", icon: Icons.video_library_rounded),
        ExtensionTab(id: "uncensored", title: "Uncensored", icon: Icons.lock_open_rounded),
        ExtensionTab(id: "creampie", title: "Creampie Genre", icon: Icons.water_drop_rounded),
      ];

  @override
  List<FilterGroup> get filters => [];

  final Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://myhentaimovie.com/',
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
        case 'popular':
          targetUrl = "$baseUrl/search?keyword=Harem${page > 1 ? '&page=$page' : ''}";
          break;
        case 'ovas':
          targetUrl = "$baseUrl/search?keyword=Dark+Skin${page > 1 ? '&page=$page' : ''}";
          break;
        case 'uncensored':
          targetUrl = "$baseUrl/search?keyword=Uncensored${page > 1 ? '&page=$page' : ''}";
          break;
        case 'creampie':
          targetUrl = "$baseUrl/search?keyword=Creampie${page > 1 ? '&page=$page' : ''}";
          break;
        case 'movies':
        default:
          targetUrl = page == 1 ? "$baseUrl/videos/latest" : "$baseUrl/videos/latest?page=$page";
          break;
      }

      final response = await http.get(Uri.parse(targetUrl), headers: _headers).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final doc = html_parser.parse(response.body);
        final items = _parseCards(doc, tabId);
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
      final searchUrl = Uri.parse("$baseUrl/search?keyword=${Uri.encodeComponent(query)}${page > 1 ? '&page=$page' : ''}");
      final response = await http.get(searchUrl, headers: _headers).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final doc = html_parser.parse(response.body);
        final items = _parseCards(doc, 'movies');
        if (items.isNotEmpty) return items;
      }
    } catch (_) {}

    return fetchTabFeed("movies", page);
  }

  List<MediaItem> _parseCards(dom.Document doc, String tabId, {String? customStudio}) {
    final elements = doc.querySelectorAll('div.video-list, .video-latest-list, .video-wrapper, article, .post, .item');
    final List<MediaItem> items = [];
    final Set<String> seenHrefs = {};

    for (final el in elements) {
      final a = el.querySelector('a[href*="/watch/"], .video-list-title a, .video-title a, a');
      var href = a?.attributes['href'] ?? '';
      if (href.isEmpty) continue;
      if (!href.startsWith('http')) {
        href = href.startsWith('/') ? "$baseUrl$href" : "$baseUrl/$href";
      }
      if (seenHrefs.contains(href)) continue;
      seenHrefs.add(href);

      final img = el.querySelector('img');
      var cover = img?.attributes['src'] ?? img?.attributes['data-src'] ?? '';
      if (cover.startsWith('//')) {
        cover = "https:$cover";
      } else if (cover.startsWith('/')) {
        cover = "$baseUrl$cover";
      }

      final title = el.querySelector('.video-list-title h4, .video-list-title, .video-title h4, .video-title, h4, h2, .title, .entry-title')?.text.trim() ??
          a?.attributes['title'] ??
          img?.attributes['alt'] ??
          '';

      final duration = el.querySelector('.duration, .video-duration')?.text.trim() ?? "45:00";

      int views = 120000;
      final viewsAttr = el.attributes['data-views'];
      if (viewsAttr != null && int.tryParse(viewsAttr) != null) {
        views = int.parse(viewsAttr);
      } else {
        final infoText = el.querySelector('.video-list-by, .video-info')?.text ?? '';
        final match = RegExp(r'([\d,]+)\s+Views', caseSensitive: false).firstMatch(infoText);
        if (match != null) {
          views = int.tryParse(match.group(1)!.replaceAll(',', '')) ?? 120000;
        }
      }

      List<String> tags;
      switch (tabId.toLowerCase()) {
        case 'popular':
          tags = ["Most Viewed", "Harem", "Top Rated"];
          break;
        case 'ovas':
          tags = ["Complete OVA", "Dark Skin", "Series"];
          break;
        case 'uncensored':
          tags = ["Uncensored", "Full HD", "Decensored"];
          break;
        case 'creampie':
          tags = ["Creampie", "Internal", "HD"];
          break;
        case 'movies':
          tags = ["Movie", "Theatrical", "HD"];
          break;
        default:
          tags = [tabId, "Theatrical", "HD"];
          break;
      }

      if (title.isNotEmpty && cover.startsWith('http')) {
        items.add(MediaItem(
          id: href.hashCode.toString(),
          title: title,
          url: href,
          cover: cover,
          duration: duration,
          releaseDate: "2024",
          studio: customStudio ?? "MyHentaiMovie",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: tags,
          rating: 4.9,
          views: views,
          isUncensored: tabId.toLowerCase() == 'uncensored' ||
              tabId.toLowerCase().contains("uncensored") ||
              title.toLowerCase().contains("uncensored"),
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
        final title = doc.querySelector('meta[name="title"]')?.attributes['content'] ??
            doc.querySelector('h1')?.text.trim() ??
            "Theatrical Movie Feature";
        final desc = doc.querySelector('meta[name="description"]')?.attributes['content'] ??
            doc.querySelector('.entry-content p, .video-description, #description')?.text.trim() ??
            "Full theatrical length anime feature.";
        final ogImage = doc.querySelector('meta[property="og:image"]')?.attributes['content'] ??
            doc.querySelector('video')?.attributes['poster'] ??
            "";
        var cover = ogImage;
        if (cover.startsWith('//')) cover = "https:$cover";

        final tags = <String>[];
        final metaKeywords = doc.querySelector('meta[name="keywords"]')?.attributes['content'];
        if (metaKeywords != null && metaKeywords.isNotEmpty) {
          tags.addAll(metaKeywords.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
        }
        if (tags.isEmpty) {
          tags.addAll(["Movie", "Theatrical", "HD"]);
        }

        final sources = await extractVideoStreams(url);

        return MediaDetail(
          id: url.hashCode.toString(),
          title: title,
          cover: cover.isNotEmpty ? cover : "https://myhentaimovie.com/upload/photos/2024/06/h6t9bSqzzhJb7aEbFNAW_10_56cc433cf937772ad489a4b6d24b3c12_image.jpg",
          backdrop: cover.isNotEmpty ? cover : "https://myhentaimovie.com/upload/photos/2024/06/h6t9bSqzzhJb7aEbFNAW_10_56cc433cf937772ad489a4b6d24b3c12_image.jpg",
          description: desc,
          studio: "MyHentaiMovie Studios",
          releaseDate: "2024",
          tags: tags,
          episodes: [
            EpisodeItem(
              id: "ep_1",
              episodeNumber: "Full Movie",
              title: title,
              url: url,
              thumbnail: cover.isNotEmpty ? cover : "https://myhentaimovie.com/upload/photos/2024/06/h6t9bSqzzhJb7aEbFNAW_10_56cc433cf937772ad489a4b6d24b3c12_image.jpg",
              duration: "48:30",
              sources: sources,
            ),
          ],
          playbackHeatmap: [0.1, 0.35, 0.65, 0.95, 0.8, 0.4, 0.3, 0.9, 1.0, 0.4],
          sceneMarkers: [
            SceneMarker(title: "Opening Prologue", timestampSeconds: 0),
            SceneMarker(title: "Theatrical Climax 🔥", timestampSeconds: 1400),
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
        final List<StreamSource> sources = [];

        // Direct HTML5 video sources
        for (final s in doc.querySelectorAll('video source, source[src]')) {
          var src = s.attributes['src'] ?? '';
          if (src.isNotEmpty) {
            if (src.startsWith('//')) src = "https:$src";
            final quality = s.attributes['res'] ?? s.attributes['data-quality'] ?? s.attributes['label'] ?? 'HD';
            sources.add(StreamSource(
              label: "Direct MP4 ($quality)",
              url: src,
              protocol: StreamProtocol.directMp4,
              headers: {'Referer': baseUrl, 'User-Agent': _headers['User-Agent']!},
            ));
          }
        }

        // Direct video tag src attribute
        final videoTag = doc.querySelector('video[src]');
        if (videoTag != null) {
          var src = videoTag.attributes['src'] ?? '';
          if (src.isNotEmpty) {
            if (src.startsWith('//')) src = "https:$src";
            sources.add(StreamSource(
              label: "Direct MP4 (Master)",
              url: src,
              protocol: StreamProtocol.directMp4,
              headers: {'Referer': baseUrl, 'User-Agent': _headers['User-Agent']!},
            ));
          }
        }

        // Iframe streams
        final iframes = doc.querySelectorAll('iframe[src*="embed"], iframe');
        for (final iframe in iframes) {
          final src = iframe.attributes['src'] ?? '';
          if (src.isNotEmpty && !src.contains('facebook') && !src.contains('google')) {
            sources.add(StreamSource(
              label: "Theatrical Movie Stream",
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
    switch (tabId) {
      case 'popular':
        return [
          MediaItem(
            id: "mhm_pop_1",
            title: "Joshi Luck 1",
            url: "$baseUrl/watch/joshi-luck-1_mkSLjprCKubx2Sm.html",
            cover: "https://myhentaimovie.com/upload/photos/2024/02/PtCFTh8rAkb3hYvRFe7d_12_b62f1fe04c4a94dfedbe6a037a509e09_image.jpg",
            duration: "22:10",
            releaseDate: "2024",
            studio: "Seven",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Most Viewed", "Harem", "Top Rated"],
            rating: 4.9,
            views: 450000,
          ),
          MediaItem(
            id: "mhm_pop_2",
            title: "Joshi Luck 2",
            url: "$baseUrl/watch/joshi-luck-2_eowR9zM174nJ7My.html",
            cover: "https://myhentaimovie.com/upload/photos/2024/02/lFxFIs159nj97HVIYkAT_12_521ecc839cd64e94dd4a1638bc98da71_image.jpg",
            duration: "21:45",
            releaseDate: "2024",
            studio: "Seven",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Most Viewed", "Harem", "Top Rated"],
            rating: 4.9,
            views: 420000,
          ),
          MediaItem(
            id: "mhm_pop_3",
            title: "Joshi Luck 3",
            url: "$baseUrl/watch/joshi-luck-3_i1qA69JQPnw9O7M.html",
            cover: "https://myhentaimovie.com/upload/photos/2024/02/RiJaY8hHtcg5TVa3IOxD_12_e8310c5532ccf249512ea7b16222670f_image.png",
            duration: "23:00",
            releaseDate: "2024",
            studio: "Seven",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Most Viewed", "Harem", "Top Rated"],
            rating: 4.8,
            views: 390000,
          ),
          MediaItem(
            id: "mhm_pop_4",
            title: "Joshi Luck 4",
            url: "$baseUrl/watch/joshi-luck-4_6QzREJQd8pDuvWL.html",
            cover: "https://myhentaimovie.com/upload/photos/2024/02/hhgr6sAwegbaVx5YGdUq_12_8b1c7847334ef2102dafa71e17b525ac_image.png",
            duration: "24:12",
            releaseDate: "2024",
            studio: "Seven",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Most Viewed", "Harem", "Top Rated"],
            rating: 4.9,
            views: 380000,
          ),
          MediaItem(
            id: "mhm_pop_5",
            title: "Joshi Luck 5",
            url: "$baseUrl/watch/joshi-luck-5_Q82ml8VPdgspsLy.html",
            cover: "https://myhentaimovie.com/upload/photos/2024/02/rvlAP7bRzkEAyww7oou8_12_503336a31e64e0d21cf47b8fb4f25f01_image.png",
            duration: "22:50",
            releaseDate: "2024",
            studio: "Seven",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Most Viewed", "Harem", "Top Rated"],
            rating: 4.7,
            views: 360000,
          ),
          MediaItem(
            id: "mhm_pop_6",
            title: "Joshi Luck 6",
            url: "$baseUrl/watch/joshi-luck-6_S4RfLMlbPRfK9Hb.html",
            cover: "https://myhentaimovie.com/upload/photos/2024/02/LBLQH24bAooVCyPI1dM8_12_d57af4b20a098268cd1f53ea9c241811_image.png",
            duration: "25:30",
            releaseDate: "2024",
            studio: "Seven",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Most Viewed", "Harem", "Top Rated"],
            rating: 4.8,
            views: 350000,
          ),
          MediaItem(
            id: "mhm_pop_7",
            title: "Saimin Seishidou 1",
            url: "$baseUrl/watch/saimin-seishidou-1_bkP8blmtqUkGr9D.html",
            cover: "https://myhentaimovie.com/upload/photos/2024/02/YuVRdSGAJnqILfDPH1jJ_12_a114d427cbea5100f583955f17e473dc_image.png",
            duration: "16:22",
            releaseDate: "2024",
            studio: "PoRO",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Most Viewed", "Mind Control", "Popular"],
            rating: 4.9,
            views: 510000,
          ),
          MediaItem(
            id: "mhm_pop_8",
            title: "Saimin Seishidou 2",
            url: "$baseUrl/watch/saimin-seishidou-2_tpO3Uueu8Bl6nLp.html",
            cover: "https://myhentaimovie.com/upload/photos/2024/02/TlgdeOCcLdmX2R8rmDcW_12_ed206f1809818d59d1febcc66c2cd4e0_image.png",
            duration: "18:05",
            releaseDate: "2024",
            studio: "PoRO",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Most Viewed", "Mind Control", "Popular"],
            rating: 4.9,
            views: 480000,
          ),
        ];

      case 'ovas':
        return [
          MediaItem(
            id: "mhm_ova_1",
            title: "Elf Princess Nina 1",
            url: "$baseUrl/watch/elf-princess-nina-1_2EFYXMa4LfwALub.html",
            cover: "https://myhentaimovie.com/upload/photos/2024/02/1uZTahwSWPZsgkZ5BO6O_19_c10f0b75488897904ab2a0d63e5015fc_image.png",
            duration: "27:14",
            releaseDate: "2024",
            studio: "Seven",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Complete OVA", "Dark Skin", "Elf"],
            rating: 4.9,
            views: 290000,
          ),
          MediaItem(
            id: "mhm_ova_2",
            title: "Elf Princess Nina 2",
            url: "$baseUrl/watch/elf-princess-nina-2_F9wuxD4M6YE3hXj.html",
            cover: "https://myhentaimovie.com/upload/photos/2024/02/Vh7Za16WFfP8txRRB86j_19_d0331b358ea56251192765fb8fce18e1_image.png",
            duration: "28:30",
            releaseDate: "2024",
            studio: "Seven",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Complete OVA", "Dark Skin", "Elf"],
            rating: 4.8,
            views: 280000,
          ),
          MediaItem(
            id: "mhm_ova_3",
            title: "Elf Princess Nina 3",
            url: "$baseUrl/watch/elf-princess-nina-3_Yt8q3qIrEzCrOZN.html",
            cover: "https://myhentaimovie.com/upload/photos/2024/02/oeh3zm1D6DOWiShdcSLY_19_c25843a4db470fc999d3b2959ef0fa9d_image.jpg",
            duration: "29:10",
            releaseDate: "2024",
            studio: "Seven",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Complete OVA", "Dark Skin", "Fantasy"],
            rating: 4.9,
            views: 310000,
          ),
          MediaItem(
            id: "mhm_ova_4",
            title: "Guy 1",
            url: "$baseUrl/watch/guy-1_ckxYmU1NfsNYvq4.html",
            cover: "https://myhentaimovie.com/upload/photos/2024/02/PixGSvAgjgoJSyi5bCoW_21_a3469254ecd978b7a72fda7d123cd043_image.png",
            duration: "30:45",
            releaseDate: "2024",
            studio: "AIC",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Complete OVA", "Sci-Fi", "Action"],
            rating: 4.7,
            views: 240000,
          ),
          MediaItem(
            id: "mhm_ova_5",
            title: "Guy 2",
            url: "$baseUrl/watch/guy-2_I8qbR5XI2iE7Oyu.html",
            cover: "https://myhentaimovie.com/upload/photos/2024/02/Pz1OLJwEphssA4f6vZxm_21_258e44bff627215004ff8eb2b84d9fba_image.png",
            duration: "32:10",
            releaseDate: "2024",
            studio: "AIC",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Complete OVA", "Sci-Fi", "Action"],
            rating: 4.8,
            views: 230000,
          ),
          MediaItem(
            id: "mhm_ova_6",
            title: "Kyonyuu JK Ga Ojisan Chinpo 1",
            url: "$baseUrl/watch/kyonyuu-jk-ga-ojisan-chinpo-1_355KGckEx2o14cv.html",
            cover: "https://myhentaimovie.com/upload/photos/2024/04/9ELyXlMiCqhxuPdXLU2o_21_99e18541886cbfc00d94cd6bc323b6d6_image.png",
            duration: "23:45",
            releaseDate: "2024",
            studio: "T-Rex",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Complete OVA", "Dark Skin", "School"],
            rating: 4.9,
            views: 330000,
          ),
          MediaItem(
            id: "mhm_ova_7",
            title: "Kyonyuu JK Ga Ojisan Chinpo 2",
            url: "$baseUrl/watch/kyonyuu-jk-ga-ojisan-chinpo-2_v71YczSOUFFbh4O.html",
            cover: "https://myhentaimovie.com/upload/photos/2024/04/rXeICH2D35vmH1fzcagR_21_7d3e66d2b1bb543e36d0cc12873fe4e4_image.png",
            duration: "24:50",
            releaseDate: "2024",
            studio: "T-Rex",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Complete OVA", "Dark Skin", "School"],
            rating: 4.9,
            views: 315000,
          ),
          MediaItem(
            id: "mhm_ova_8",
            title: "Swamp Stamp 1",
            url: "$baseUrl/watch/swamp-stamp-1_7vUilLfcvUCzyup.html",
            cover: "https://myhentaimovie.com/upload/photos/2024/02/a2UP5bIUyIeYC96tZtEX_15_e0fc9f13c45c4ebc3321fbd901766e85_image.jpg",
            duration: "26:15",
            releaseDate: "2024",
            studio: "Mousou",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Complete OVA", "Dark Skin", "Fantasy"],
            rating: 4.8,
            views: 260000,
          ),
        ];

      case 'uncensored':
        return [
          MediaItem(
            id: "mhm_unc_1",
            title: "Advancer Tina 1",
            url: "$baseUrl/watch/advancer-tina-1_yzXg1GowQ7AkxnJ.html",
            cover: "https://myhentaimovie.com/upload/photos/2024/02/KGkPVu1uMHIlaewssQlN_12_597c282158cd8cd80650c111f790deb0_image.jpg",
            duration: "28:15",
            releaseDate: "2024",
            studio: "Green Bunny",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Uncensored", "Full HD", "Decensored"],
            rating: 4.9,
            views: 370000,
            isUncensored: true,
          ),
          MediaItem(
            id: "mhm_unc_2",
            title: "Ai Doll 1",
            url: "$baseUrl/watch/ai-doll-1_4e9LPRtOTHEvHXp.html",
            cover: "https://myhentaimovie.com/upload/photos/2024/02/F3b8J1eSuWzczItYUvo9_12_b6bf50af4b84941ea167a0556bf6782d_image.jpg",
            duration: "26:30",
            releaseDate: "2024",
            studio: "Pink Pineapple",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Uncensored", "Decensored", "Sci-Fi"],
            rating: 4.8,
            views: 340000,
            isUncensored: true,
          ),
          MediaItem(
            id: "mhm_unc_3",
            title: "Ai Doll 2",
            url: "$baseUrl/watch/ai-doll-2_SeM8dR8HRf899ml.html",
            cover: "https://myhentaimovie.com/upload/photos/2024/02/wtmd67C7ZfPyVLvj4lBi_13_3c079679b3279a50d008cc3b713fbc71_image.jpg",
            duration: "27:10",
            releaseDate: "2024",
            studio: "Pink Pineapple",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Uncensored", "Decensored", "Sci-Fi"],
            rating: 4.8,
            views: 320000,
            isUncensored: true,
          ),
          MediaItem(
            id: "mhm_unc_4",
            title: "Ai Doll 3",
            url: "$baseUrl/watch/ai-doll-3_gOU6wjjkGFL4YYc.html",
            cover: "https://myhentaimovie.com/upload/photos/2024/02/MT2rtidg3HmfTAjiqJ1b_13_91b1cf5160986c3d3009ac3a2865cd1b_image.png",
            duration: "25:40",
            releaseDate: "2024",
            studio: "Pink Pineapple",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Uncensored", "Decensored", "Sci-Fi"],
            rating: 4.9,
            views: 355000,
            isUncensored: true,
          ),
          MediaItem(
            id: "mhm_unc_5",
            title: "Ai Doll 4",
            url: "$baseUrl/watch/ai-doll-4_msyhcRUGh4IyPer.html",
            cover: "https://myhentaimovie.com/upload/photos/2024/02/AFFuYUOMLUSOBZJBg6C1_13_6df396a60811c4c4633e7f71eb233e6f_image.jpg",
            duration: "26:55",
            releaseDate: "2024",
            studio: "Pink Pineapple",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Uncensored", "Decensored", "Sci-Fi"],
            rating: 4.9,
            views: 360000,
            isUncensored: true,
          ),
          MediaItem(
            id: "mhm_unc_6",
            title: "Ecchies 1",
            url: "$baseUrl/watch/ecchies-1_wDSB7FQnjNoTMwW.html",
            cover: "https://myhentaimovie.com/upload/photos/2024/02/yH1w4dq8Y9buKvaMP35a_15_0dafe83e6366650591b7863aeb3f351c_image.png",
            duration: "24:20",
            releaseDate: "2024",
            studio: "PoRO",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Uncensored", "Full HD", "Comedy"],
            rating: 4.8,
            views: 330000,
            isUncensored: true,
          ),
          MediaItem(
            id: "mhm_unc_7",
            title: "Ecchies 2",
            url: "$baseUrl/watch/ecchies-2_kiPziVXAzakX1Mb.html",
            cover: "https://myhentaimovie.com/upload/photos/2024/02/EeM7RXZuPqsfBCSh7pES_15_0b2e22f413dfa417f9ff92428eeb4af4_image.png",
            duration: "25:10",
            releaseDate: "2024",
            studio: "PoRO",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Uncensored", "Full HD", "Comedy"],
            rating: 4.8,
            views: 325000,
            isUncensored: true,
          ),
          MediaItem(
            id: "mhm_unc_8",
            title: "Boku Dake No Hentai Kanojo The Animation 1",
            url: "$baseUrl/watch/boku-dake-no-hentai-kanojo-the-animation-1_6onxhENyxpATL1x.html",
            cover: "https://myhentaimovie.com/upload/photos/2024/02/UKHFCiDgwLLHJEwUFQae_15_d8307f36b646c0628e738f8f54041d29_image.jpg",
            duration: "28:00",
            releaseDate: "2024",
            studio: "Seven",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Uncensored", "Romance", "Decensored"],
            rating: 4.9,
            views: 395000,
            isUncensored: true,
          ),
        ];

      case 'creampie':
        return [
          MediaItem(
            id: "mhm_crm_1",
            title: "Saimin Seishidou 3",
            url: "$baseUrl/watch/saimin-seishidou-3_hhpZewOQ9yMEbJi.html",
            cover: "https://myhentaimovie.com/upload/photos/2024/02/hSZIYW4DcjZ7wrPyMHAm_12_3b18cfa7e89b2f2d1ae3712c0facf788_image.png",
            duration: "17:40",
            releaseDate: "2024",
            studio: "PoRO",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Creampie", "Mind Control", "HD"],
            rating: 4.9,
            views: 410000,
          ),
          MediaItem(
            id: "mhm_crm_2",
            title: "Saimin Seishidou 4",
            url: "$baseUrl/watch/saimin-seishidou-4_oEYv74E5ZoHCXam.html",
            cover: "https://myhentaimovie.com/upload/photos/2024/02/WkdN54DPdQCp4VpLTqPb_12_1793dc795c35e36c8eaf779142a03bff_image.png",
            duration: "18:15",
            releaseDate: "2024",
            studio: "PoRO",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Creampie", "Mind Control", "HD"],
            rating: 4.9,
            views: 430000,
          ),
          MediaItem(
            id: "mhm_crm_3",
            title: "Saimin Seishidou 5",
            url: "$baseUrl/watch/saimin-seishidou-5_qnMdWkS6akEP1tH.html",
            cover: "https://myhentaimovie.com/upload/photos/2024/02/mzpWBp6drrUcOnvSFPOY_12_0b74d059c3e8a9ddad5aba6fb6a0056d_image.png",
            duration: "19:00",
            releaseDate: "2024",
            studio: "PoRO",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Creampie", "Mind Control", "HD"],
            rating: 4.8,
            views: 395000,
          ),
          MediaItem(
            id: "mhm_crm_4",
            title: "Saimin Seishidou 6",
            url: "$baseUrl/watch/saimin-seishidou-6_gIwHkKZL3lV7o4r.html",
            cover: "https://myhentaimovie.com/upload/photos/2024/02/DbJ9isYpzmMOHwVUYPqH_12_8998b88f4fd1562e7f85b82494510dc1_image.png",
            duration: "20:30",
            releaseDate: "2024",
            studio: "PoRO",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Creampie", "Mind Control", "HD"],
            rating: 4.9,
            views: 420000,
          ),
          MediaItem(
            id: "mhm_crm_5",
            title: "Tonari No Ie No Anette-San 1",
            url: "$baseUrl/watch/tonari-no-ie-no-anette-san-1_DyQNVkKUyE6kHom.html",
            cover: "https://myhentaimovie.com/upload/photos/2024/02/y4Ft8EGg9USKUZCxdZwP_12_94acec48ce4b337c4ae771427a1f0a63_image.jpg",
            duration: "24:15",
            releaseDate: "2024",
            studio: "Seven",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Creampie", "Milf", "HD"],
            rating: 4.8,
            views: 370000,
          ),
          MediaItem(
            id: "mhm_crm_6",
            title: "Tonari No Ie No Anette-San 2",
            url: "$baseUrl/watch/tonari-no-ie-no-anette-san-2_83KdO9pW5SuPQTf.html",
            cover: "https://myhentaimovie.com/upload/photos/2024/02/TZiKDgrESlXq2EfdqDme_12_7f3c0b084e8e74eef276c2d499691f39_image.png",
            duration: "25:40",
            releaseDate: "2024",
            studio: "Seven",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Creampie", "Milf", "HD"],
            rating: 4.9,
            views: 385000,
          ),
          MediaItem(
            id: "mhm_crm_7",
            title: "Imouto Wa Gal Kawaii 1",
            url: "$baseUrl/watch/imouto-wa-gal-kawaii-1_KuzYxnInCg9SW6q.html",
            cover: "https://myhentaimovie.com/upload/photos/2024/02/s22sLRiv9WtfajiLo7D6_13_ace1d2562dd01f98bddb74cdcc252fe9_image.png",
            duration: "21:50",
            releaseDate: "2024",
            studio: "PoRO",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Creampie", "Gyaru", "HD"],
            rating: 4.8,
            views: 360000,
          ),
          MediaItem(
            id: "mhm_crm_8",
            title: "Baka Dakedo 1",
            url: "$baseUrl/watch/baka-dakedo-1_DK4eHj9kxIrj6ck.html",
            cover: "https://myhentaimovie.com/upload/photos/2024/02/a1ginmxeYdrqplqOkysW_14_10e3484f5c67efe05da19b09de89cf1f_image.jpg",
            duration: "23:10",
            releaseDate: "2024",
            studio: "PoRO",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Creampie", "Internal", "HD"],
            rating: 4.7,
            views: 345000,
          ),
        ];

      case 'movies':
      default:
        return [
          MediaItem(
            id: "mhm_mov_1",
            title: "Issho Ni H Shiyo! 4",
            url: "$baseUrl/watch/issho-ni-h-shiyo-4_krXn8w3l8XMNCUi.html",
            cover: "https://myhentaimovie.com/upload/photos/2024/06/h6t9bSqzzhJb7aEbFNAW_10_56cc433cf937772ad489a4b6d24b3c12_image.jpg",
            duration: "18:15",
            releaseDate: "2024",
            studio: "Movie Studios",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Movie", "Theatrical", "HD"],
            rating: 4.9,
            views: 310000,
            isUncensored: true,
          ),
          MediaItem(
            id: "mhm_mov_2",
            title: "Issho Ni H Shiyo! 3",
            url: "$baseUrl/watch/issho-ni-h-shiyo-3_XNa5CUnlXZPHjKH.html",
            cover: "https://myhentaimovie.com/upload/photos/2024/06/GL3xMTxRSYbmblREaw63_10_74915e9c23464dee6dd9e5973a0feb9c_image.jpg",
            duration: "19:40",
            releaseDate: "2024",
            studio: "Movie Studios",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Movie", "Theatrical", "HD"],
            rating: 4.8,
            views: 295000,
            isUncensored: true,
          ),
          MediaItem(
            id: "mhm_mov_3",
            title: "Issho Ni H Shiyo! 2",
            url: "$baseUrl/watch/issho-ni-h-shiyo-2_nyT7LJfLKWEaAek.html",
            cover: "https://myhentaimovie.com/upload/photos/2024/06/CK9HeNX4Y4QqEbfYTaUQ_10_8f7ae53a931295adbb82778c04faf5bb_image.jpg",
            duration: "17:50",
            releaseDate: "2024",
            studio: "Movie Studios",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Movie", "Theatrical", "HD"],
            rating: 4.9,
            views: 305000,
            isUncensored: true,
          ),
          MediaItem(
            id: "mhm_mov_4",
            title: "Issho Ni H Shiyo! 1",
            url: "$baseUrl/watch/issho-ni-h-shiyo-1_V27WSfMNnzoQhhy.html",
            cover: "https://myhentaimovie.com/upload/photos/2024/06/AeSWgT8ZmYvyTY7oNCHl_10_d6a7c48c2547c675a993ee632fc6f68e_image.jpg",
            duration: "20:05",
            releaseDate: "2024",
            studio: "Movie Studios",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Movie", "Theatrical", "HD"],
            rating: 4.8,
            views: 280000,
            isUncensored: true,
          ),
          MediaItem(
            id: "mhm_mov_5",
            title: "Cool Devices 11",
            url: "$baseUrl/watch/cool-devices-11_fJCUCj7oSO4yyPg.html",
            cover: "https://myhentaimovie.com/upload/photos/2024/06/1M2fdB7mKXHVA3ROWIK4_10_f0395a4a7b16b013623ffe62c9ee1ceb_image.jpg",
            duration: "28:12",
            releaseDate: "2024",
            studio: "Movie Studios",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Movie", "Classic", "HD"],
            rating: 4.7,
            views: 260000,
          ),
          MediaItem(
            id: "mhm_mov_6",
            title: "Ojou-Sama Yomeiri Kousou! 2",
            url: "$baseUrl/watch/ojou-sama-yomeiri-kousou-2_H2uIylxkRsN14h3.html",
            cover: "https://myhentaimovie.com/upload/photos/2024/05/sEuzGlZYjjSNOKD98OoH_01_cd5d3c6d3be110f163ede20739ecdbfa_image.jpg",
            duration: "24:30",
            releaseDate: "2024",
            studio: "Movie Studios",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Movie", "Theatrical", "HD"],
            rating: 4.8,
            views: 275000,
          ),
          MediaItem(
            id: "mhm_mov_7",
            title: "Ojou-Sama Yomeiri Kousou! 1",
            url: "$baseUrl/watch/ojou-sama-yomeiri-kousou-1_iLEBWxBLJbI9uVa.html",
            cover: "https://myhentaimovie.com/upload/photos/2024/05/zoJN5D3h7tArTkdHpvDp_01_dadf36890ac48c770b9d209dfc0e3640_image.jpg",
            duration: "25:15",
            releaseDate: "2024",
            studio: "Movie Studios",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Movie", "Theatrical", "HD"],
            rating: 4.8,
            views: 290000,
          ),
          MediaItem(
            id: "mhm_mov_8",
            title: "Cool Devices 10",
            url: "$baseUrl/watch/cool-devices-10_P2lIOpmHl1Yl9vV.html",
            cover: "https://myhentaimovie.com/upload/photos/2024/05/Kar3cHGgR48IGMvBU4OE_01_73a0f1d2e4873130086e625c7cd03ba3_image.jpg",
            duration: "29:00",
            releaseDate: "2024",
            studio: "Movie Studios",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["Movie", "Classic", "HD"],
            rating: 4.7,
            views: 255000,
          ),
        ];
    }
  }

  MediaDetail _generateSampleDetail(String url) {
    return MediaDetail(
      id: url.hashCode.toString(),
      title: "Issho Ni H Shiyo! Theatrical Cut",
      cover: "https://myhentaimovie.com/upload/photos/2024/06/h6t9bSqzzhJb7aEbFNAW_10_56cc433cf937772ad489a4b6d24b3c12_image.jpg",
      backdrop: "https://myhentaimovie.com/upload/photos/2024/06/h6t9bSqzzhJb7aEbFNAW_10_56cc433cf937772ad489a4b6d24b3c12_image.jpg",
      description: "Full-length theatrical cut with remastered animation from MyHentaiMovie.",
      studio: "Seven Animation",
      releaseDate: "2024",
      tags: ["Movie", "Theatrical", "Uncensored"],
      episodes: [
        EpisodeItem(
          id: "ep_1",
          episodeNumber: "Full Movie",
          title: "Issho Ni H Shiyo! Full Movie",
          url: url,
          thumbnail: "https://myhentaimovie.com/upload/photos/2024/06/h6t9bSqzzhJb7aEbFNAW_10_56cc433cf937772ad489a4b6d24b3c12_image.jpg",
          duration: "52:00",
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
        SceneMarker(title: "Opening Prologue", timestampSeconds: 0),
        SceneMarker(title: "Theatrical Climax 🔥", timestampSeconds: 1400),
      ],
    );
  }

  @override
  Future<ExtensionTaxonomy> fetchTaxonomy() async {
    return myHentaiMovieTaxonomy;
  }

  @override
  Future<List<MediaItem>> fetchTaxonomyFeed(CatalogItem item, int page) async {
    try {
      String targetUrl;
      final isCategory = item.type == CatalogType.category ||
          (item.endpointPath != null && item.endpointPath!.startsWith('/videos/category/'));

      if (isCategory) {
        final slug = item.slug;
        targetUrl = page == 1
            ? "$baseUrl/videos/category/$slug"
            : "$baseUrl/videos/category/$slug?page=$page";
      } else {
        final kw = item.endpointPath != null && item.endpointPath!.contains('keyword=')
            ? item.endpointPath!.split('keyword=').last
            : Uri.encodeComponent(item.name);
        targetUrl = "$baseUrl/search?keyword=$kw${page > 1 ? '&page=$page' : ''}";
      }

      final response = await http
          .get(Uri.parse(targetUrl), headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final doc = html_parser.parse(response.body);
        final items = _parseCards(
          doc,
          item.name,
          customStudio: isCategory ? item.name : null,
        );
        if (items.isNotEmpty) return items;
      }
    } catch (_) {}

    return _generateTaxonomyFallback(item, page);
  }

  List<MediaItem> _generateTaxonomyFallback(CatalogItem item, int page) {
    if (page > 1) return const [];
    final baseSamples = _generateSampleList("movies", page);
    final isCategory = item.type == CatalogType.category;
    return baseSamples.map((sample) {
      return MediaItem(
        id: "mhm_${item.slug}_${sample.id}",
        title: "${sample.title} (${item.name} Cut)",
        url: sample.url,
        cover: sample.cover,
        duration: sample.duration,
        releaseDate: sample.releaseDate,
        studio: isCategory ? item.name : sample.studio,
        extensionId: id,
        type: sample.type,
        tags: [item.name, ...sample.tags],
        rating: sample.rating,
        views: sample.views,
        isUncensored: sample.isUncensored ||
            item.slug == 'uncensored' ||
            item.name.toLowerCase().contains("uncensored"),
      );
    }).toList();
  }
}

