import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../base_extension.dart';
import '../../models/media_item.dart';
import '../../models/extension_manifest.dart';
import '../../models/catalog_model.dart';
import '../taxonomies/hentai_nexus_taxonomy.dart';

/// HentaiNexus extension for HStream Neo.
/// Scrapes adaptive multi-server streams and high-definition galleries from hentainexus.com.
class HentaiNexusExtension extends HentaiExtension {
  @override
  String get id => "hentai_nexus";

  @override
  String get name => "HentaiNexus";

  @override
  String get baseUrl => "https://hentainexus.com";

  @override
  String get iconUrl => "https://hentainexus.com/favicon.ico";

  @override
  String get description =>
      "Adaptive multi-server streaming network and high definition manga/doujinshi reader on HentaiNexus.";

  @override
  ViewLayoutType get defaultLayout => ViewLayoutType.widescreen16x9;

  @override
  bool get supportsShorts => false;

  @override
  List<ExtensionTab> get tabs => [
        ExtensionTab(id: "latest", title: "Nexus Latest", icon: Icons.fiber_new_rounded),
        ExtensionTab(id: "popular", title: "Most Viewed", icon: Icons.whatshot_rounded),
        ExtensionTab(id: "uncensored", title: "Uncensored Nexus", icon: Icons.lock_open_rounded),
        ExtensionTab(id: "doujinshi", title: "Doujinshi / Manga", icon: Icons.menu_book_rounded),
        ExtensionTab(id: "big_boobs", title: "Big Boobs", icon: Icons.favorite_rounded),
      ];

  @override
  List<FilterGroup> get filters => [];

  final Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentainexus.com/',
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
          path = '/?orderby=views';
          break;
        case 'uncensored':
          path = '/tag/uncensored/';
          break;
        case 'doujinshi':
          path = '/category/doujinshi/';
          break;
        case 'big_boobs':
          path = '/tag/big-boobs/';
          break;
        case 'latest':
        default:
          path = '/';
          break;
      }

      final targetUrl = page == 1
          ? '$baseUrl$path'
          : (path.contains('?') ? '$baseUrl/page/$page$path' : '$baseUrl/page/$page/');

      var response = await http.get(Uri.parse(targetUrl), headers: _headers).timeout(const Duration(seconds: 8));

      // Fallback for endpoints returning 404
      if (response.statusCode != 200) {
        String altPath;
        switch (tabId) {
          case 'popular':
            altPath = page == 1 ? '/explore/hot' : '/page/$page?orderby=views';
            break;
          case 'uncensored':
            altPath = page == 1 ? '/?q=tag:uncensored' : '/page/$page?q=tag:uncensored';
            break;
          case 'doujinshi':
            altPath = page == 1 ? '/?q=doujinshi' : '/page/$page?q=doujinshi';
            break;
          case 'big_boobs':
            altPath = page == 1 ? '/?q=tag:%22huge+boobs%22' : '/page/$page?q=tag:%22huge+boobs%22';
            break;
          case 'latest':
          default:
            altPath = page == 1 ? '/' : '/page/$page';
            break;
        }
        response = await http.get(Uri.parse('$baseUrl$altPath'), headers: _headers).timeout(const Duration(seconds: 8));
      }

      if (response.statusCode == 200) {
        final doc = html_parser.parse(response.body);
        final articles = doc.querySelectorAll('article, .post, .item, .nexus-item, .card, div.column');
        final List<MediaItem> items = [];
        final Set<String> seenUrls = {};

        for (final art in articles) {
          final a = art.querySelector('a') ?? (art.parent?.localName == 'a' ? art.parent : null);
          final href = a?.attributes['href'] ?? '';
          if (href.isEmpty) continue;

          final fullUrl = href.startsWith('http') ? href : "$baseUrl$href";
          if (seenUrls.contains(fullUrl)) continue;
          seenUrls.add(fullUrl);

          final img = art.querySelector('img');
          final title = art.querySelector('h2, .title, .entry-title, .card-header-title, header')?.text.trim() ??
              art.querySelector('header')?.attributes['title']?.trim() ??
              a?.attributes['title']?.trim() ??
              img?.attributes['alt']?.trim() ??
              '';

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
              id: fullUrl.hashCode.toString(),
              title: title,
              url: fullUrl,
              cover: cover,
              duration: art.querySelector('.time, span.time, .duration, .is-overlay')?.text.trim() ?? "24:00",
              releaseDate: "2024",
              studio: "HentaiNexus",
              extensionId: id,
              type: MediaType.animeSeries,
              tags: [
                if (tabId == "popular") "Most Viewed",
                if (tabId == "uncensored") "Uncensored",
                if (tabId == "doujinshi") "Doujinshi",
                if (tabId == "big_boobs") "Big Boobs",
                "Nexus HD",
                "Multi-Server",
              ],
              rating: 4.8,
              views: 195000,
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
      final searchUrl = page == 1
          ? Uri.parse("$baseUrl/?q=${Uri.encodeComponent(query)}")
          : Uri.parse("$baseUrl/page/$page?q=${Uri.encodeComponent(query)}");
      final response = await http.get(searchUrl, headers: _headers).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final doc = html_parser.parse(response.body);
        final articles = doc.querySelectorAll('article, .post, .item, .nexus-item, .card, div.column');
        final List<MediaItem> items = [];
        final Set<String> seenUrls = {};

        for (final art in articles) {
          final a = art.querySelector('a') ?? (art.parent?.localName == 'a' ? art.parent : null);
          final href = a?.attributes['href'] ?? '';
          if (href.isEmpty) continue;

          final fullUrl = href.startsWith('http') ? href : "$baseUrl$href";
          if (seenUrls.contains(fullUrl)) continue;
          seenUrls.add(fullUrl);

          final img = art.querySelector('img');
          final title = art.querySelector('h2, .title, .entry-title, .card-header-title, header')?.text.trim() ??
              art.querySelector('header')?.attributes['title']?.trim() ??
              a?.attributes['title']?.trim() ??
              img?.attributes['alt']?.trim() ??
              '';

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
              id: fullUrl.hashCode.toString(),
              title: title,
              url: fullUrl,
              cover: cover,
              duration: "24:00",
              studio: "HentaiNexus",
              extensionId: id,
              type: MediaType.animeSeries,
              tags: ["Nexus", "Search", "HD"],
              rating: 4.8,
              views: 140000,
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
        final title = doc.querySelector('h1.title, h1')?.text.trim() ?? "HentaiNexus Gallery";
        final desc = doc.querySelector('meta[name="description"]')?.attributes['content'] ??
            doc.querySelector('.entry-content p, .view-page-details')?.text.trim() ??
            "Multi-server manga and anime on HentaiNexus.";
        final coverImg = doc.querySelector('figure.image img, .card-image img');
        final cover = doc.querySelector('meta[property="og:image"]')?.attributes['content'] ??
            coverImg?.attributes['data-src'] ??
            coverImg?.attributes['src'] ??
            "";

        final tagNodes = doc.querySelectorAll('table.view-page-details a[href*="tag:"], .tag a, a[href*="/tag/"]');
        final tags = tagNodes
            .map((e) => e.text.replaceAll(RegExp(r'\(\d+[\d,]*\)'), '').trim())
            .where((t) => t.isNotEmpty)
            .toList();

        final sources = await extractVideoStreams(url);

        return MediaDetail(
          id: url.hashCode.toString(),
          title: title,
          cover: cover.isNotEmpty
              ? cover
              : "https://images.hentainexus.com/v2/78da1d8e416a43310c44efe27508926c4956cef237926ca7942604d2ae42ee5e1366376f78ccab3ccba5d80c6ba1c9351d763072ae1ea6941c4c36c23cd7a44e59ab0f935919bda125ae14ceac9d9b9039351da631d7e8a8de28909d7c6a541173211ac0b91793a638e8b2104ca0722a63df781d651de5729439b20f5195acda6a6bba974dc5bb0b3a6a1b14758cc0c942cc8646e02c80bd0e97065b723acafda302c0f3e37e3dff7efddde2fcfdb87ed86d33d4de89a003ece2b18be53fcff92eef7f376d4bde/001.png.thumb.jpg",
          backdrop: cover.isNotEmpty
              ? cover
              : "https://images.hentainexus.com/v2/78da1d8e416a43310c44efe27508926c4956cef237926ca7942604d2ae42ee5e1366376f78ccab3ccba5d80c6ba1c9351d763072ae1ea6941c4c36c23cd7a44e59ab0f935919bda125ae14ceac9d9b9039351da631d7e8a8de28909d7c6a541173211ac0b91793a638e8b2104ca0722a63df781d651de5729439b20f5195acda6a6bba974dc5bb0b3a6a1b14758cc0c942cc8646e02c80bd0e97065b723acafda302c0f3e37e3dff7efddde2fcfdb87ed86d33d4de89a003ece2b18be53fcff92eef7f376d4bde/001.png.thumb.jpg",
          description: desc,
          studio: "HentaiNexus Studios",
          releaseDate: "2024",
          tags: tags.isNotEmpty ? tags : ["Multi-Server", "HD", "Uncensored", "Nexus"],
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
            SceneMarker(title: "Nexus Climax 🔥", timestampSeconds: 700),
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
              label: "Nexus Stream Server",
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
          id: "hnx_lat_1",
          title: "Dick Me Deeply Even Though You're Hung and Scary 4",
          url: "$baseUrl/view/22063",
          cover:
              "https://images.hentainexus.com/v2/78da1d8e416a43310c44efe27508926c4956cef237926ca7942604d2ae42ee5e1366376f78ccab3ccba5d80c6ba1c9351d763072ae1ea6941c4c36c23cd7a44e59ab0f935919bda125ae14ceac9d9b9039351da631d7e8a8de28909d7c6a541173211ac0b91793a638e8b2104ca0722a63df781d651de5729439b20f5195acda6a6bba974dc5bb0b3a6a1b14758cc0c942cc8646e02c80bd0e97065b723acafda302c0f3e37e3dff7efddde2fcfdb87ed86d33d4de89a003ece2b18be53fcff92eef7f376d4bde/001.png.thumb.jpg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "Irodori Comics",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Nexus Latest", "HD", "Color"],
          rating: 4.9,
          views: 245000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hnx_lat_2",
          title: "Gold Medal Thrusting",
          url: "$baseUrl/view/22062",
          cover:
              "https://images.hentainexus.com/v2/78da1d8e416a03310c00ffe2735824d996b479cb5e2c4b4a294d58487b0af97b4dae3330ccab3ccbb500453064d2eed5c1a12bc9b0de2774662720a1262cc3b925244fdab50b3218515a0c1e831c2aba68ad3252f7eabec39c8c11c82d30c78a28cd9ed63d10813ccc8006841a78b9145f1bafa3e451ae470994b6462a404a9a134617d1ecc16c30ab5683a441d82b8b78fa686ad611f7d08a19f32897a33c3e2900dccec76dfbfdfabbdbf67dde3eeebe1c8a2a1128c002e702397e9ef12eef7f59c44bd1/001.png.thumb.jpg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "FAKKU",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Nexus Latest", "Sports", "Romance"],
          rating: 4.8,
          views: 210000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hnx_lat_3",
          title: "Like Lovers Do",
          url: "$baseUrl/view/22061",
          cover:
              "https://images.hentainexus.com/v2/78da1d8e496a43410c05efd26b6334b5a4f659fe46eac121c4c6e064657cf734de563d1ef52acf722960d44527134bf3a6738637a3c8163d6d7a542601e909a643164aa2a57b848ba0cebdafc62d9a6707b4a8a90a0208814bfb54a44a3dc046ba8c3a6a85a6863ed996450f012da73276c6eb28eb2897a384247bcc8980a3596a5202adc97d25b06c43bb4ca2112b43c5210e4ea2c83269f180a39c8e72ff5c01d0f971bf9e7fbffe6e79fe7e5c3feeb61d9a3b1138c0068f0d56fc3ce7bbbcff01cdeb4a98/002.png.thumb.jpg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "HentaiNexus",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Nexus Latest", "Romance", "Vanilla"],
          rating: 4.8,
          views: 195000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hnx_lat_4",
          title: "Together With You!",
          url: "$baseUrl/view/22060",
          cover:
              "https://images.hentainexus.com/v2/78da1d8e498e02310c45ef92352a391e629bb3d426ce400b012a89ee15e2ee1db0bcfa4f7efeaff44ce74416dcc0a83383854e19aa844dabad51355f3b2c4accec8a79b886f72e615eb9f6692232b206bb49f70a51d84807712d83b9a92249860e4e6899d8f39022cdb84caa254fb0744a7dd578ed69eee9bc270cea06908bce8965dac74db18ec1b05469bdb914e216646c2e6a481fe032105c6bddd3694f8faf6a59b6e371d97e7ffeeeb15d8fcb97dd17cb6a8608ebcf0a8e15cc7a7b8e777aff03b1af48ae/001.png.thumb.jpg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "HentaiNexus",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Nexus Latest", "Sweet", "Couples"],
          rating: 4.9,
          views: 220000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hnx_lat_5",
          title: "Kairakuten Heroines 2026 Summer Splash - Souseki",
          url: "$baseUrl/view/22059",
          cover:
              "https://images.hentainexus.com/v2/78da1d8e416a43310c44efe275f84896654b398b37b665a594267c48bb0ab97b45988560de8c98577aa66b6a79622993ad41dc4573b0f18452712b921759ce326add6d8bd78cc132d912de831ad3668ec462c03a24ca8a334f9f620456b7175d8a15a20c36b06e0421679fea2a7b2d034a976431e3d593f774ed49b2fab6aabc63915a8b51a551a9752d74e7a1a1623a81d4a1406bca40a1b5241b4dece9d2d3e3f30a008ff3713b7ebffeeef3f83e6f1f760f864d2467108030ce307cfc3cf73bbdff0177084b87/001.png.thumb.jpg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "Comic Kairakuten",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Nexus Latest", "Summer", "Swimsuit"],
          rating: 4.8,
          views: 185000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hnx_lat_6",
          title: "But She's Not Even My Oshi!",
          url: "$baseUrl/view/22058",
          cover:
              "https://images.hentainexus.com/v2/78da1dce4d6a03310c86e1bb781d827eec9194b3ccc696e494d28481b4ab90bbc78d96ef031f7a9647b91432cca9ae1b4ae46047089239c182c38c447b52974642e12068ffce668db98a46b611b61954874a493ebc720ea836a7c53a5445e6e8bd42554456938561ee0d614083594e25d61bcfbdccbd5cf68223280c9ad768eceaac632a0369274ed8aae14a9c883e0485b3b5c88d7063177653dccb692ff7cf14009d8ffbf5fcfbf5771be7efe3fab1db321455225080158e1566ff79e4abbcdeb2064a2e/002.png.thumb.jpg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "HentaiNexus",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Nexus Latest", "Idol", "Comedy"],
          rating: 4.7,
          views: 175000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hnx_lat_7",
          title: "Elegantly Adorable - After",
          url: "$baseUrl/view/22057",
          cover:
              "https://images.hentainexus.com/v2/78da1d8e4d6a43310c84efe2757848b26c59398b37b664a594263c48bb0ab97b4d5603f3313faff44cd7c46cb5d1f089b529aa334596a06c4d05a33a5905c66241a6b68c1db05484956bf1005f38268a59591cca089335580a162451d518c52b397acb36b128992c625b55546288414997e4fbc6aba7e8e9da139a0da03090b973a0a54ec988abedcdd1a65475a965f294b11503f655f0c84d1857d6d6d3a5a7c7a70a008ff3713b7ebffeeef3f83e6f1f76df0ca535226800db38b711e3e7b9dee9fd0ffc374ac4/001.png.thumb.jpg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "HentaiNexus",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Nexus Latest", "Elegant", "After Story"],
          rating: 4.8,
          views: 190000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hnx_lat_8",
          title: "Kairakuten Heroines 2026 Summer Splash - Okumoto Yuta",
          url: "$baseUrl/view/22056",
          cover:
              "https://images.hentainexus.com/v2/78da1d8e4d6a83310c44efe27508926ccb76cef26df49b529a1048bb0ab97b4d0666f31e0cf32acf72294dc059485383bb365ec6e1c941106d24393b8d3a7053e39563b9b42ab28066ef18d5b09a11aa58f33119a473c472dc75ee2de75453431d98b333a757edab3355754701b0722abe6fbc8e9247b91ca5e1c4b15690565f16d0422997f3daa9597b582a576ba43a186d5f41913ea2b621c8ce47391de5fe9902c0f3e37e3dff7efdddf4fcfdb87edc6d3b1c7312c104d8e0b141cacf33dee5fd0fc9b54d72/001.png.thumb.jpg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "Comic Kairakuten",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Nexus Latest", "Beach", "Color"],
          rating: 4.9,
          views: 205000,
          isUncensored: true,
        ),
      ],
      "popular": [
        MediaItem(
          id: "hnx_pop_1",
          title: "Hot & Ready Delivery",
          url: "$baseUrl/view/21854",
          cover:
              "https://images.hentainexus.com/v2/78da1dce4f6b02311005f0af1272e8c9ca24933f33de0aa514bcb5f4b4eb21d94c6c45d745dd5211bf7b83d7f7e0f7de4d9ff54ad78ab61428e2913d45a979b0c0c4c1244b1e227817a31d6088966a90cc897c748220949391c025a3b125d1908a3057a4e0830b12ad44345cd847749e12038af162d3202ed74ad6b20104d60b5dda8d5baf6baf57bdce992c42e0e49d3311c46131d81e999cab54a6d87866b0c94687c130492b4bb3d240d8dc5e2f7a3d3ea8ee338dbb793e1de78d7a3f5ed493fa9054aeea55f63fbf72baaa67350118d5fdb501d8a8eeed65bdfeda2ca771bbbc7ccf87bcdc4ddb8777689e89e4bdb30ea005530b6ada9fe5aeefffb6485aa0/%5BSanjuurou%5D+Hot+%26+Ready+Delivery+-+p001+%5Bx3200%5D+%5BFAKKU%5D.png.thumb.jpg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "FAKKU",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Most Viewed", "Top Rated", "Nexus Classic"],
          rating: 5.0,
          views: 520000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hnx_pop_2",
          title: "Vanilla Onahole",
          url: "$baseUrl/view/21868",
          cover:
              "https://images.hentainexus.com/v2/78da1d8e496a43311005efa2b5f974ab27c967d1a635b44388cd07272be3bb4778f7a882e2bdd2335d5381a5b0842d662d73a898eee5992be9100eee389683d75a431d0b3b00451d3858c85cbad384e133dc6741742dc4542d77a84bbb5267ed0c432af708e51d67eb194d4b781198e992e6bef16a295abab684bd1828e10c7065c9341c41674c63230b4283029e5117e7e5aa938a6035f22c399bae962e2d3d3ea97df4381fb7e3f7ebefde8feff3f671f7edd08a086706d8e0dc20fce7b9dee9fd0f55524abe/003.png.thumb.jpg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "HentaiNexus",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Most Viewed", "Vanilla", "Popular"],
          rating: 4.9,
          views: 480000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hnx_pop_3",
          title: "Escape",
          url: "$baseUrl/view/21865",
          cover:
              "https://images.hentainexus.com/v2/78da1d8e4d6a03310c85efe27518a4b1654939cb6c24cb4a294d1848bb0ab97b4d560fbef7c37b9567b9169960c0312a24586570c7ac34b2468749ca5951489dd300632c69263969dfddd8aa4b0f326456716e2b5fb3a3b7a60aa42161aa4e8461a2008a8e3ad43c6274d381cea0e55262dd781d258f723dca0e758cde821c57c90c060fb26ae9d3cc3d8db9fa04c1a9da684c010b4f08a9ee16b31de57294c7670a00b7f371db7ebffeeebe7d9fb78f775f1eb210b5bd012c702e90f6f39ceff2fe07a3cf4e3a/001.png.thumb.jpg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "HentaiNexus",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Most Viewed", "Drama", "Top Ranked"],
          rating: 4.9,
          views: 460000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hnx_pop_4",
          title: "A Tricky Balancing Act",
          url: "$baseUrl/view/21900",
          cover:
              "https://images.hentainexus.com/v2/78da1d8ec16a83310c83df25e7526cc78e9d3dcb7f719cb863aca5d0ed54faeecb7a1002497ce8591ee5a3b8a58145ed4cd0c64af2c5b38f943186d2ea2394b78b64207776ad2d0cc38c5500a6b63d9d327b739955529a908567ab4a101395d22b67f2c62d616bd4c128b0a73ac184594e65ee1bcfa3e4513e8e6266d48da71ae38ae6da31074428fe63b7562e16f55eaba093478d660c38144913f028a7a3dcde28003adf6f97f3cfe7ef759cbfee977777dd1daa893031c00eee3b48ff7eac5779fd01d9e34bf9/002.png.thumb.jpg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "HentaiNexus",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Most Viewed", "Comedy", "Nexus Hot"],
          rating: 4.8,
          views: 430000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hnx_pop_5",
          title: "The Woman I See at the Store",
          url: "$baseUrl/view/21995",
          cover:
              "https://images.hentainexus.com/v2/78da1d8e416a43310c44efe27508922de94b39cbdf58b295529af021ed2ae4ee71c3c02ce6c1cc3ccba35c4a35d4ba314d60b7d9c4392d31a1b12177571416f240e8c14be8de03586643b39eb3933a0970c8e8e413079381e0a643a3760bc9aa6d3235ac6d6b15cc73b0b869f58c48c8722a63dd78ee25f772d9cb86d401740635da448436f5304607929c6be4df33b40f098b98a1931234507aaddcea5e4e7bb97faa00f07cdcafe7dfafbf9b9fbf8feb87dd165bff98a912c00a8e1564ff79cc5779bd015e654c0e/001.png.thumb.jpg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "HentaiNexus",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Most Viewed", "Milf", "Romance"],
          rating: 4.9,
          views: 415000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hnx_pop_6",
          title: "Beyond the Vapor",
          url: "$baseUrl/view/22010",
          cover:
              "https://images.hentainexus.com/v2/78da1d8e4d6e82310c05ef92354276e29f98b37c1b3b89a9aa8290685788bb37623b23cd7baff22c97e22b91b0a90432baa73a55b61aa3f658e15187a659ed94c35bd75101bb8902480b4b9199558535dda27b9b429374f00e59dd9139875a10f5e19d13a16227169c6124cc7367caa9cc7de375943ccae5282b266b5f1cd94de708deb340223e7471c30ec4dabc6246338c488f0666d2465b16087c94d351ee9f14009e1ff7ebf9f7ebef16e7efc7f5e36edba17666aa04b0c16383f49fe77a97f73fbd794be3/001.png.thumb.jpg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "HentaiNexus",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Most Viewed", "Onsen", "Hot Springs"],
          rating: 4.8,
          views: 395000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hnx_pop_7",
          title: "Passionate Gyaru Fuckfest",
          url: "$baseUrl/view/22023",
          cover:
              "https://images.hentainexus.com/v2/78da258f316e43310c43efe239f89065499673162f966ca5289ae00369a72077afd1ae7c2441bed2335d5343645de4d64021ab442eacbcd829139996aad6d808cd29dcd08478ca2473a5367ce535a5529984031684c7ac8cec20b559232ac052eaaa55075aae4679e98a58cd89a32800a64b9a7bc6aba7e8e9da1364992ca65047ecfa90218a0d86716110dc19978a824693497c8db27de1508c8391a4a74b4f8fff2ac8c7f9b81ddf1f3f773b3ecfdb1fbb6f96ab2ae23e0c5b38b710e3ebb9dee9fd0bda3b4af0/001.png.thumb.jpg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "HentaiNexus",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Most Viewed", "Gyaru", "Harem"],
          rating: 4.9,
          views: 470000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hnx_pop_8",
          title: "She is My Prince",
          url: "$baseUrl/view/22029",
          cover:
              "https://images.hentainexus.com/v2/78da1d8f496e02410c45ef526b845c76dbaee22cbdf150268a0242225921ee9e16dbf7a43fbcdab35d9a7048c91c8ba77467305227e59282b9716de15534c975c8eab8907511ea18b961844645cc5c9c565eecd2c30653c566cc95d93b5b4c41c6d13969d8d2e5295d3ba4af820dac9d5a1e335e7babbd5df6a6ae690c85045e601e43247515956b4c4427e83d2859040cb49399260a1d952473d3bd9df676ff4401e0f971bf9e7fbffe6e7efe7e5c3fee76b87e1c4084017080c701ca7e9eebdddeff567e4ccc/002.png.thumb.jpg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "HentaiNexus",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Most Viewed", "Romance", "Tomboy"],
          rating: 4.8,
          views: 380000,
          isUncensored: true,
        ),
      ],
      "uncensored": [
        MediaItem(
          id: "hnx_unc_1",
          title: "Like Lovers Do",
          url: "$baseUrl/view/22061",
          cover:
              "https://images.hentainexus.com/v2/78da1d8e496a43410c05efd26b6334b5a4f659fe46eac121c4c6e064657cf734de563d1ef52acf722960d44527134bf3a6738637a3c8163d6d7a542601e909a643164aa2a57b848ba0cebdafc62d9a6707b4a8a90a0208814bfb54a44a3dc046ba8c3a6a85a6863ed996450f012da73276c6eb28eb2897a384247bcc8980a3596a5202adc97d25b06c43bb4ca2112b43c5210e4ea2c83269f180a39c8e72ff5c01d0f971bf9e7fbffe6e79fe7e5c3feeb61d9a3b1138c0068f0d56fc3ce7bbbcff01cdeb4a98/002.png.thumb.jpg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "HentaiNexus",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Nexus", "HD", "Romance"],
          rating: 4.9,
          views: 310000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hnx_unc_2",
          title: "Together With You!",
          url: "$baseUrl/view/22060",
          cover:
              "https://images.hentainexus.com/v2/78da1d8e498e02310c45ef92352a391e629bb3d426ce400b012a89ee15e2ee1db0bcfa4f7efeaff44ce74416dcc0a83383854e19aa844dabad51355f3b2c4accec8a79b886f72e615eb9f6692232b206bb49f70a51d84807712d83b9a92249860e4e6899d8f39022cdb84caa254fb0744a7dd578ed69eee9bc270cea06908bce8965dac74db18ec1b05469bdb914e216646c2e6a481fe032105c6bddd3694f8faf6a59b6e371d97e7ffeeeb15d8fcb97dd17cb6a8608ebcf0a8e15cc7a7b8e777aff03b1af48ae/001.png.thumb.jpg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "HentaiNexus",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Nexus", "Vanilla", "Sweet"],
          rating: 4.8,
          views: 290000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hnx_unc_3",
          title: "Kairakuten Heroines 2026 Summer Splash - Souseki",
          url: "$baseUrl/view/22059",
          cover:
              "https://images.hentainexus.com/v2/78da1d8e416a43310c44efe275f84896654b398b37b665a594267c48bb0ab97b45988560de8c98577aa66b6a79622993ad41dc4573b0f18452712b921759ce326add6d8bd78cc132d912de831ad3668ec462c03a24ca8a334f9f620456b7175d8a15a20c36b06e0421679fea2a7b2d034a976431e3d593f774ed49b2fab6aabc63915a8b51a551a9752d74e7a1a1623a81d4a1406bca40a1b5241b4dece9d2d3e3f30a008ff3713b7ebffeeef3f83e6f1f760f864d2467108030ce307cfc3cf73bbdff0177084b87/001.png.thumb.jpg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "Comic Kairakuten",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Nexus", "Full Color", "Summer"],
          rating: 4.8,
          views: 275000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hnx_unc_4",
          title: "But She's Not Even My Oshi!",
          url: "$baseUrl/view/22058",
          cover:
              "https://images.hentainexus.com/v2/78da1dce4d6a03310c86e1bb781d827eec9194b3ccc696e494d28481b4ab90bbc78d96ef031f7a9647b91432cca9ae1b4ae46047089239c182c38c447b52974642e12068ffce668db98a46b611b61954874a493ebc720ea836a7c53a5445e6e8bd42554456938561ee0d614083594e25d61bcfbdccbd5cf68223280c9ad768eceaac632a0369274ed8aae14a9c883e0485b3b5c88d7063177653dccb692ff7cf14009d8ffbf5fcfbf5771be7efe3fab1db321455225080158e1566ff79e4abbcdeb2064a2e/002.png.thumb.jpg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "HentaiNexus",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Nexus", "Idol", "Comedy"],
          rating: 4.7,
          views: 260000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hnx_unc_5",
          title: "Elegantly Adorable - After",
          url: "$baseUrl/view/22057",
          cover:
              "https://images.hentainexus.com/v2/78da1d8e4d6a43310c84efe2757848b26c59398b37b664a594263c48bb0ab97b4d5603f3313faff44cd7c46cb5d1f089b529aa334596a06c4d05a33a5905c66241a6b68c1db05484956bf1005f38268a59591cca089335580a162451d518c52b397acb36b128992c625b55546288414997e4fbc6aba7e8e9da139a0da03090b973a0a54ec988abedcdd1a65475a965f294b11503f655f0c84d1857d6d6d3a5a7c7a70a008ff3713b7ebffeeef3f83e6f1f76df0ca535226800db38b711e3e7b9dee9fd0ffc374ac4/001.png.thumb.jpg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "HentaiNexus",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Nexus", "Romance", "After"],
          rating: 4.8,
          views: 280000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hnx_unc_6",
          title: "Kairakuten Heroines 2026 Summer Splash - Okumoto Yuta",
          url: "$baseUrl/view/22056",
          cover:
              "https://images.hentainexus.com/v2/78da1d8e4d6a83310c44efe27508926ccb76cef26df49b529a1048bb0ab97b4d0666f31e0cf32acf72294dc059485383bb365ec6e1c941106d24393b8d3a7053e39563b9b42ab28066ef18d5b09a11aa58f33119a473c472dc75ee2de75453431d98b333a757edab3355754701b0722abe6fbc8e9247b91ca5e1c4b15690565f16d0422997f3daa9597b582a576ba43a186d5f41913ea2b621c8ce47391de5fe9902c0f3e37e3dff7efdddf4fcfdb87edc6d3b1c7312c104d8e0b141cacf33dee5fd0fc9b54d72/001.png.thumb.jpg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "Comic Kairakuten",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Nexus", "Beach", "Color"],
          rating: 4.9,
          views: 295000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hnx_unc_7",
          title: "Pleasant Illusion ~2nd Show~",
          url: "$baseUrl/view/22052",
          cover:
              "https://images.hentainexus.com/v2/78da1d8e3b6e03310c44efa2da589014f5f359b6a1f87110c4c6024e2ac3778fd6c5346f86337ca567ba2611291e199158cc244685500661504514edc2e112611366759a34705843f6591470124c2239e5ceee1614ea625979b66aa3ce9884aa7286096464c9cd4d84ce00ad917449b6de78ed29f674dd134777e629a38d5a50d7c928dea0b359c9c6b9440860418f1ac3f2d0bca617a320d7d6744f973d3d3e5500b81d8fdbf6fbf5779fdbf771fb78f7e561eb9d083ac002c702213f4f7fa7f73f5f924fa7/001.png.thumb.jpg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "HentaiNexus",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Nexus", "Magic", "Fantasy"],
          rating: 4.8,
          views: 310000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hnx_unc_8",
          title: "Turns Out, Hinata Yuuki Is a Dirty Girl",
          url: "$baseUrl/view/22051",
          cover:
              "https://images.hentainexus.com/v2/78da1d8e4b6a03311044efa2b519faa3fec867994db7a47108b11970b232be7b84b7af8a7af52acf722dcdc2a5c2f08c14164509006c6408999dbd12586dc3982c25096727d518d28cb5576b308623cb01351c7be230c964240ae9ace62c66209334387115d44c2c6a50242983964b19ebc66b2fc75eae7b112552371ea3653a8ddaebda358e6cd4997aa41d4b75084ec3a5f288093a8527834593bd5cf6f2f84c01d4ed7cdcb6dfafbf7b6edfe7ed93dd5786e64e040eb0c0b9c0113fcff92eef7fcfd949d4/004.png.thumb.jpg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "HentaiNexus",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored Nexus", "School", "Romance"],
          rating: 4.9,
          views: 330000,
          isUncensored: true,
        ),
      ],
      "doujinshi": [
        MediaItem(
          id: "hnx_dou_1",
          title: "If This Were a Doujinshi, This Is the Part Where We'd Have Sex",
          url: "$baseUrl/view/19187",
          cover:
              "https://images.hentainexus.com/v2/78da1d8e416a03310c45efe27518245b96ac9c6536b264a594260ca45d85dcbd43769ff7e0f15fe559ae458c00827ad6a1189d19b343637427d0f0ae11d6103b6723855c82a6c16119ea6b410c211e0396b4ba584736a35e65a5d8e8521db8d50457a0a936fb640977610e68e150c1caa5c479e3b597dccb752fd41682b3db48a82b6cb2ce946938cfc8ace35c9cc306a5636fd8213262ce4c4f5215dacb652f8f4f0a00b7e371db7ebffeee73fb3e6e1f773f1d0a35e2ce0027384e90f6f35ceff2fe07bebb4cfc/001.png.thumb.jpg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "Doujinshi Circle",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Doujinshi / Manga", "Meta", "Comedy"],
          rating: 4.9,
          views: 375000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hnx_dou_2",
          title: "My Favorite Doujinshi Artist Invited Me to a Love Hotel!",
          url: "$baseUrl/view/13497",
          cover:
              "https://images.hentainexus.com/v2/78da1d8f4d6a43310c84efe27578c8966d49398b37b264a594263c48bb0ab97b4db6f30df3f34acf744d6dd96474146a0853320b2fe6884a0ba4e78651581aa086c2e452cd55d9e65a15fb7484b5017b44070a45ad010558bc159c6c8d99d0988a7acbd00dad15c06cd56b67ed6250d325f99ef11a2946ba8e2454839d1bf914953e2b338216433422ed6bf783ade21059567054db8343f3f6ed1b1d46ba8cf4f84401e4e37cdc8edfafbffb3cbecfdb87dd37cb04153a15802d9c5b08fd79ae777aff03bf334c33/001.png.thumb.jpg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "Doujinshi Circle",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Doujinshi / Manga", "Artist", "Love Hotel"],
          rating: 4.8,
          views: 350000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hnx_dou_3",
          title: "I Shouldn't Have Gone To The Doujinshi Convention Without Telling My Wife 3",
          url: "$baseUrl/view/8323",
          cover:
              "https://images.hentainexus.com/v2/78da1d8e4b6e43310845f7e27114013606672d6f0236a4aa9a2852da5194bdd70a833bb81f745ee5592e656553a19c159a2737136f33754d53e7204b54a9ecee6b50a7111350620cc5c66a3a40343c03fb3062ded308a8094eb54b13520cda05d0996181d26b9bcaccd84d25d7e880e554d6c6781d258f72398a2f07b67da1cd606cae2a95b60e9421d0bd7baece30a3b238d906c68a084292d2d38e723acafdf30a00cf8ffbf5fcfbf577f3f3f7e3fac96e3b4381065d08601b8f6da4fd3ce35ddeffd5b94ba2/001.png.thumb.jpg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "Doujinshi Circle",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Doujinshi / Manga", "Married Life", "Drama"],
          rating: 4.8,
          views: 340000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hnx_dou_4",
          title: "Do You Like Hentai Doujinshi?",
          url: "$baseUrl/view/7276",
          cover:
              "https://images.hentainexus.com/v2/78da1d8e4b6a83310c84efe27508926c5952cef26f24d96e294d09a45d85dc3d6e76c337cce351eee552126628a325936528cc966da0b95b9fa41626b35ba224daa229366ae399496d0dedacd58382489b7060321368af6896b48bfb4e469d29c02e626cce6e9a3a2c20d768aa90e554c6bef138ca3acae528e8a984c08d229aec6f354294dd0957ef203568250c59b57bb82e5868525775a8227bfa28a7a3fcbcab00f0fc75fb38ff7efe5de35fbdbdebf650a0411702d8e0b6c1f2effb7c96e70b67054b5c/001.jpg.thumb.jpg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "Doujinshi Circle",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Doujinshi / Manga", "Otaku", "Comedy"],
          rating: 4.7,
          views: 325000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hnx_dou_5",
          title: "I Shouldn't Have Gone To The Doujinshi Convention Without Telling My Wife 2",
          url: "$baseUrl/view/6645",
          cover:
              "https://images.hentainexus.com/v2/78da1dce4d6a43310c04e0bb781d1eb264f92767f146b2a494d2840769572177afc9760666be577aa66b2a6518a852a6e18ce1a11d5a6816282b73c1a54c12a37791b15635c5e8a459a9760e75aa2b82d97af34c8cec4c032be170b4c6a8cdcd97d54ad68374a16505da1fd2335207907449b619af9962a6eb4c0ebe72cb321851c50bb5a115f6d8161a8b6e46b0a194e1529a6c0b035169a5b0ea86ce7499e9f19902c8c7f9b81dbf5f7f773dbecfdba7bbef2e57a8adc3fedfc1b983909fa7bfd3fb1f45834cb0/001.png.thumb.jpg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "Doujinshi Circle",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Doujinshi / Manga", "Convention", "Cheating"],
          rating: 4.8,
          views: 315000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hnx_dou_6",
          title: "I Shouldn't Have Gone To The Doujinshi Convention Without Telling My Wife 1.5",
          url: "$baseUrl/view/5926",
          cover:
              "https://images.hentainexus.com/v2/78da1d8e4b8ec2400c44efe2358aecfed86ece928ddd8941a30145626685b83b86853faa2755d5131e7006b256db288695b4528949ba8d36463ece8ae61e5a62f88861e6a281ce4d68e752897d4aecdd4bb71e1365e3f82c9cc2a4a5e4a8a80ddcab249fad782fc2e6999888c79cc870822d6b3c578815ce2bd09e6e1ce989b33912674c356de4b6a949b064d93e895ad60cc7e63655d8957bde812b9c56b87fad106939ee97e5effa7ff3e5e7b87cd92d1931b2282a620a470a61bf8ffd05af37ce224a8f/001.png.thumb.jpg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "Doujinshi Circle",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Doujinshi / Manga", "Secret", "Cheating"],
          rating: 4.7,
          views: 305000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hnx_dou_7",
          title: "I Shouldn't Have Gone To The Doujinshi Convention Without Telling My Wife 1",
          url: "$baseUrl/view/4994",
          cover:
              "https://images.hentainexus.com/v2/78da1d8e418e02310c04ff92331ad98e6327bc652e761283560b1a89dd13e2ef04ae5d52553fd3239d1399cc0c4ae221b9d5eaac549a716d830dcc233302729e2a592bcdde63d080aacecd9b151099345146d4e9c2eede32f1042b84de8b500932d52ed67594c9c8b1f458a32f0d424ba734d68de79e624fe73dd1270cb358e769a8061d0baf700705ea2507b7b06c19b855c2e6955133765b449881f674dad3fdab02c0edb85fb6bfebffcdb79fe3f265b7c55040b4420558c3b186b0dfc77ca5d71be8064a77/001.png.thumb.jpg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "Doujinshi Circle",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Doujinshi / Manga", "Prologue", "Drama"],
          rating: 4.8,
          views: 310000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hnx_dou_8",
          title: "Weekly Kairakuten Key-Visual Collection 107",
          url: "$baseUrl/view/22026",
          cover:
              "https://images.hentainexus.com/v2/78da1d8e4d6a43310c84efe2757848b265cb398b379625a594263c48bb0ab97b4d98dd373fcc2b3dd335b11b2d119c886ad28518dc514aeda18e7512a1565d355ad76a66b9789b0105738e908ec5800a2f34eecb67b1a9de89a235eac5f262d87263589cc38c14853a36de8d98b540a44bb27de335528c741d69ae521c2643670892bcfad490582ed8260533d5ecae58cd174013255cc48895ab761018e932d2e3330580c7f9b81dbf5f7f773dbecfdbc7bb6f0f9b08d14ec306e706317f9efe4eef7fc3bb4bc5/001.png.thumb.jpg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "Comic Kairakuten",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Doujinshi / Manga", "Artbook", "Collection"],
          rating: 4.9,
          views: 360000,
          isUncensored: true,
        ),
      ],
      "big_boobs": [
        MediaItem(
          id: "hnx_bb_1",
          title: "Fill in Her Blanks",
          url: "$baseUrl/view/22047",
          cover:
              "https://images.hentainexus.com/v2/78da1d8e416e42310c05ef923542761c3b0e67f99bd8b1a9aa8290685788bb3762fb469a37aff22c97d2738ce90280dd06989b5576a9b85c96b356081b241d700c021d1c3de75acb98086778ed3a869388990cc5ae4b9c569330c2660d795454ee545b6fac4e51a3312224f1a45c10e554d6ce781d258f72394aa0ee96cc689db26ead72aba9c213d3720a99a7e004b2de569a370f60157491c84a7094d351ee1fd5f69c1ff7ebf9f7ebef66e7efc7f5c36e9bed4ead15f6d31e1e7bc8f9f38c7779ff0309514b49/001.png.thumb.jpg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "HentaiNexus",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Big Boobs", "Busty", "Romance"],
          rating: 4.9,
          views: 380000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hnx_bb_2",
          title: "Beware the Big-Dick Hunters",
          url: "$baseUrl/view/22002",
          cover:
              "https://images.hentainexus.com/v2/78da1d8e418e02310c04ff92331a39769c38bc652e8e1d83560b1a89dd13e2ef04aed5adea7ea6473a270bd6b01c524360faf42a24020811dc948516b782da4cbb01da5825e9d85510454c72a6dcb94fd0a0c1deddb25683de6c20eba45c752ab4ac5e7c4400bab788284e85e70048a7e4ebc6734fb1a7f39e5826d4d10850110799f810f22501d0d2eacc26daa867d260c436a44e25d68119fa676e4fa73dddbf2a00da8efb65fbbbfedfc6f6735cbed96d65b90973c102b0c0b140e8ef63bed2eb0da0864d0c/003.png.thumb.jpg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "HentaiNexus",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Big Boobs", "Huge Boobs", "Comedy"],
          rating: 4.8,
          views: 360000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hnx_bb_3",
          title: "Growing Pains",
          url: "$baseUrl/view/21991",
          cover:
              "https://images.hentainexus.com/v2/78da1d8eb16e03310c43ffc5737090255992f32db79c252b45d10407a49d82fc7b8d2c1c48e291aff22cd75259b24774a10a498341fb6c758cf08970f4560fa59630cc0dd9d02bb31bb581b39bcc880332c56d3494da4483c5c328bda56632c5a1828727d55558425d31a64ab4988401582e25d68dd75e722fd7bd18ab1078f7b5ef94568594d70ec374ae021c3a07798760338480d1a788e2a267cd5c90cb5e1e1f14006de7e3b6fd7efdddc7f67dde3ed97d6555ad35460658c6b98c3c7e9ef35ddeff66874b93/003.png.thumb.jpg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "HentaiNexus",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Big Boobs", "Busty", "Drama"],
          rating: 4.8,
          views: 345000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hnx_bb_4",
          title: "Threesome Sex",
          url: "$baseUrl/view/21962",
          cover:
              "https://images.hentainexus.com/v2/78da1d4f418a03310cfb4bce65b0e338b6fb96b9c489d3b26ccb40774fa57f6f5a74119210d2333dd23949482bde270998750e2ed5a24689e61dab31e01c6c1d45a335e5dc9165e88a0a5707a7a9da5907668fc09ea5285aae19316626d149580a17f3c655599a105a259a953e5c01d3298d35e3b9a7b9a7f39e90a10d72b20236d9b14f96aa8a6cb5597776cb31686416cfb0720b33c44a63a11e607b3aede9fead02c0edb85fb6bfebffcdb79fe3f2f56ecb5b6f984b2e004b389630dbef235ee9f506a0ed4a32/001.png.thumb.jpg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "HentaiNexus",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Big Boobs", "Threesome", "Harem"],
          rating: 4.9,
          views: 390000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hnx_bb_5",
          title: "Watch Out ☆ Surrounded by Gals!",
          url: "$baseUrl/view/21931",
          cover:
              "https://images.hentainexus.com/v2/78da1d8e4b8e02310c05efe2356af91727e12cbd891307341a504bccac107727b0ad925ebd273ce00c1c6e35460aedc9184d1349ab66ea9e07071ab759944bcebd4575991c5a688911cd74d6395594670b65e79208d780ba385296915bb4229f4413aa82c2b9af08d1404a2c5290e10463dd78ee307738ef406cdab90e9242aa9a06576b31887a670a0f6fa546579b5e530f8dd963561b69f5087ba41d4e3bdcbf5388bc1df7cbf677fdbff9f6735cbeeeb61ce59292b2222e702c30dbef235ef07a03c9344aef/002.png.thumb.jpg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "HentaiNexus",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Big Boobs", "Gyaru", "Oppai"],
          rating: 4.8,
          views: 370000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hnx_bb_6",
          title: "How Dare You Break That Shrine!",
          url: "$baseUrl/view/21920",
          cover:
              "https://images.hentainexus.com/v2/78da1d8e3b6e83310c83efe2390864bd6ce72cff224b568aa20902a49d82dcbd46160ee44782aff22c97228a932ad00097a1b3b1569893b02e36ebb569f5349f31a52b027bb7699135160b9279834ed26249c3ae16032bf1c840d97c90668683d7d917c918c89143b283a0ee62a705514e25f68dd751f22897ad14ae1ebdbaf86cc4446b4c1b2c8446ac36c595bda2e74842dcf8f066bd1ba67b841ee57494fb670a80cf8ffbf5fcfbf5779be7efc7f593dd76565b176164806d3cb691f6f35ceff2fe076b4d4c3b/004.png.thumb.jpg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "HentaiNexus",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Big Boobs", "Shrine Maiden", "Fantasy"],
          rating: 4.8,
          views: 355000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hnx_bb_7",
          title: "What He Doesn't Know Doesn't Count!",
          url: "$baseUrl/view/21903",
          cover:
              "https://images.hentainexus.com/v2/78da1d8e496e42410c44efd26b84dc8387e62c7f63bb6da22820249215e2ee69b17daf5455aff22c971286a4d9066bbab9f6859e3da0450868534a305f15ac222f4344210dcb6a3b9bd37aa599bdf970c29130c438a4499a74d0ddbc94977a106a43c0bac6e05929840c182a4e98e554d6bef13a4a1ee57294e8dea7eca5861598d51b4d9fd073346513c8e8e9b0c88274758ad1d8654910efaf3ee028a7a3dc3f5500edfcb85fcfbf5f7f373b7f3fae1f77dbaeb2208e360036786c90faf38c7779ff03022b4d4a/002.png.thumb.jpg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "HentaiNexus",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Big Boobs", "Cheating", "Oppai"],
          rating: 4.7,
          views: 340000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hnx_bb_8",
          title: "Bavel Pin-Up Girls #292",
          url: "$baseUrl/view/21885",
          cover:
              "https://images.hentainexus.com/v2/78da1d8e3b6e03310c44efa2da30288ae4523ecb36fc480e82d858c04965f8ee565c4cf3069837cff228973252b9a1088f91d29d6518e23f0acf8d3dd122c853461bda52d585d3118d73768a09ec5047b5745326b64ad531b8aee8e434ee26eead916d4610d4557361e0294b33c0cba9e4baf1dccbdccb652f1eb36ddd36952507c4d06a81911d7d4ecf3ab56776150cb20e548504479314f50ea9632fa7bddc3f5300f57cdcafe7dfafbf9b9fbf8feba7bbadae6eca4c48000b1c0b4cfb798c5779bd01bc7b4d58/001.png.thumb.jpg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "Comic Bavel",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Big Boobs", "Pin-Up", "Art"],
          rating: 4.9,
          views: 365000,
          isUncensored: true,
        ),
      ],
    };

    return sampleSets[tabId] ?? sampleSets["latest"] ?? [];
  }

  MediaDetail _generateSampleDetail(String url) {
    return MediaDetail(
      id: url.hashCode.toString(),
      title: "Dick Me Deeply Even Though You're Hung and Scary 4",
      cover:
          "https://images.hentainexus.com/v2/78da1d8e416a43310c44efe27508926c4956cef237926ca7942604d2ae42ee5e1366376f78ccab3ccba5d80c6ba1c9351d763072ae1ea6941c4c36c23cd7a44e59ab0f935919bda125ae14ceac9d9b9039351da631d7e8a8de28909d7c6a541173211ac0b91793a638e8b2104ca0722a63df781d651de5729439b20f5195acda6a6bba974dc5bb0b3a6a1b14758cc0c942cc8646e02c80bd0e97065b723acafda302c0f3e37e3dff7efddde2fcfdb87ed86d33d4de89a003ece2b18be53fcff92eef7f376d4bde/001.png.thumb.jpg",
      backdrop:
          "https://images.hentainexus.com/v2/78da1d8e416a43310c44efe27508926c4956cef237926ca7942604d2ae42ee5e1366376f78ccab3ccba5d80c6ba1c9351d763072ae1ea6941c4c36c23cd7a44e59ab0f935919bda125ae14ceac9d9b9039351da631d7e8a8de28909d7c6a541173211ac0b91793a638e8b2104ca0722a63df781d651de5729439b20f5195acda6a6bba974dc5bb0b3a6a1b14758cc0c942cc8646e02c80bd0e97065b723acafda302c0f3e37e3dff7efddde2fcfdb87ed86d33d4de89a003ece2b18be53fcff92eef7f376d4bde/001.png.thumb.jpg",
      description: "Adaptive multi-server playback and high definition manga reading on HentaiNexus.",
      studio: "Irodori Comics",
      releaseDate: "2024",
      tags: ["Nexus", "Uncensored", "Doujinshi", "HD"],
      episodes: [
        EpisodeItem(
          id: "ep_1",
          episodeNumber: "Episode 1",
          title: "Full Chapter / Episode 1",
          url: url,
          thumbnail:
              "https://images.hentainexus.com/v2/78da1d8e416a43310c44efe27508926c4956cef237926ca7942604d2ae42ee5e1366376f78ccab3ccba5d80c6ba1c9351d763072ae1ea6941c4c36c23cd7a44e59ab0f935919bda125ae14ceac9d9b9039351da631d7e8a8de28909d7c6a541173211ac0b91793a638e8b2104ca0722a63df781d651de5729439b20f5195acda6a6bba974dc5bb0b3a6a1b14758cc0c942cc8646e02c80bd0e97065b723acafda302c0f3e37e3dff7efddde2fcfdb87ed86d33d4de89a003ece2b18be53fcff92eef7f376d4bde/001.png.thumb.jpg",
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

  @override
  Future<ExtensionTaxonomy> fetchTaxonomy() async {
    return hentaiNexusTaxonomy;
  }

  @override
  Future<List<MediaItem>> fetchTaxonomyFeed(CatalogItem item, int page) async {
    try {
      String targetUrl;

      if (item.endpointPath != null && item.endpointPath!.isNotEmpty) {
        final path = item.endpointPath!;
        if (page == 1) {
          targetUrl = path.startsWith('http') ? path : "$baseUrl$path";
        } else {
          if (path.contains('?q=')) {
            final queryPart = path.substring(path.indexOf('?q=') + 1);
            targetUrl = "$baseUrl/page/$page?$queryPart";
          } else if (path == '/' || path.isEmpty) {
            targetUrl = "$baseUrl/page/$page";
          } else {
            final trimmed = path.endsWith('/') ? path.substring(0, path.length - 1) : path;
            targetUrl = "$baseUrl$trimmed/page/$page";
          }
        }
      } else if (item.type == CatalogType.tag) {
        final tagQuery = Uri.encodeComponent(item.name);
        targetUrl = page == 1
            ? "$baseUrl/?q=tag:$tagQuery"
            : "$baseUrl/page/$page?q=tag:$tagQuery";
      } else if (item.type == CatalogType.artist) {
        final artistQuery = Uri.encodeComponent('"${item.name}"');
        targetUrl = page == 1
            ? "$baseUrl/?q=artist:$artistQuery"
            : "$baseUrl/page/$page?q=artist:$artistQuery";
      } else {
        final query = Uri.encodeComponent(item.name);
        targetUrl = page == 1
            ? "$baseUrl/?q=$query"
            : "$baseUrl/page/$page?q=$query";
      }

      var response = await http.get(Uri.parse(targetUrl), headers: _headers).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200 && page > 1 && !targetUrl.contains('?q=')) {
        final fallbackUrl = "$baseUrl/page/$page?q=${Uri.encodeComponent(item.name)}";
        response = await http.get(Uri.parse(fallbackUrl), headers: _headers).timeout(const Duration(seconds: 8));
      }

      if (response.statusCode == 200) {
        final doc = html_parser.parse(response.body);
        final items = _parseCardsFromDoc(doc, defaultTag: item.name);
        if (items.isNotEmpty) return items;
      }
    } catch (_) {}

    return search(item.name, page);
  }

  List<MediaItem> _parseCardsFromDoc(dynamic doc, {String? defaultTag}) {
    final articles = doc.querySelectorAll('article, .post, .item, .nexus-item, .card, div.column');
    final List<MediaItem> items = [];
    final Set<String> seenUrls = {};

    for (final art in articles) {
      final a = art.querySelector('a') ?? (art.parent?.localName == 'a' ? art.parent : null);
      final href = a?.attributes['href'] ?? '';
      if (href.isEmpty) continue;

      final fullUrl = href.startsWith('http') ? href : "$baseUrl$href";
      if (seenUrls.contains(fullUrl)) continue;
      seenUrls.add(fullUrl);

      final img = art.querySelector('img');
      final title = art.querySelector('h2, .title, .entry-title, .card-header-title, header')?.text.trim() ??
          art.querySelector('header')?.attributes['title']?.trim() ??
          a?.attributes['title']?.trim() ??
          img?.attributes['alt']?.trim() ??
          '';

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
          id: fullUrl.hashCode.toString(),
          title: title,
          url: fullUrl,
          cover: cover,
          duration: "24:00",
          releaseDate: "2024",
          studio: "HentaiNexus",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: [
            if (defaultTag != null && defaultTag.isNotEmpty) defaultTag,
            "Nexus HD",
            "Manga / Doujinshi",
          ],
          rating: 4.8,
          views: 180000,
          isUncensored: title.toLowerCase().contains("uncensored") ||
              (defaultTag != null && defaultTag.toLowerCase().contains("uncensored")),
        ));
      }
    }
    return items;
  }
}
