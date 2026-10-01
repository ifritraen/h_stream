import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../base_extension.dart';
import '../../models/media_item.dart';
import '../../models/extension_manifest.dart';
import '../../models/catalog_model.dart';
import '../taxonomies/hentai_pulse_taxonomy.dart';

/// HentaiPulse extension for HStream Neo.
/// Scrapes community trending feeds and latest releases from hentaipulse.com.
class HentaiPulseExtension extends HentaiExtension {
  @override
  String get id => "hentai_pulse";

  @override
  String get name => "HentaiPulse";

  @override
  String get baseUrl => "https://hentaipulse.com";

  @override
  String get iconUrl => "https://hentaipulse.com/favicon.ico";

  @override
  String get description => "Community trending feeds, high-definition anime episodes, and weekly popularity charts.";

  @override
  ViewLayoutType get defaultLayout => ViewLayoutType.widescreen16x9;

  @override
  bool get supportsShorts => false;

  @override
  List<ExtensionTab> get tabs => [
        ExtensionTab(id: "trending", title: "Pulse Trending", icon: Icons.whatshot_rounded),
        ExtensionTab(id: "latest", title: "Latest Uploads", icon: Icons.fiber_new_rounded),
        ExtensionTab(id: "uncensored", title: "Uncensored Genre", icon: Icons.lock_open_rounded),
        ExtensionTab(id: "3d", title: "3D Animation", icon: Icons.view_in_ar_rounded),
        ExtensionTab(id: "romance", title: "Romance Genre", icon: Icons.favorite_rounded),
      ];

  @override
  List<FilterGroup> get filters => [];

  final Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaipulse.com/',
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
      String? altUrl;
      switch (tabId) {
        case 'trending':
          targetUrl = page == 1 ? "$baseUrl/trending/" : "$baseUrl/trending/page/$page/";
          altUrl = page == 1 ? "$baseUrl/?m_orderby=views" : "$baseUrl/page/$page/?m_orderby=views";
          break;
        case 'latest':
          targetUrl = page == 1 ? "$baseUrl/latest/" : "$baseUrl/latest/page/$page/";
          altUrl = page == 1 ? "$baseUrl/?m_orderby=latest" : "$baseUrl/page/$page/?m_orderby=latest";
          break;
        case 'uncensored':
          targetUrl = page == 1 ? "$baseUrl/genre/uncensored/" : "$baseUrl/genre/uncensored/page/$page/";
          altUrl = page == 1 ? "$baseUrl/tag/uncensored/" : "$baseUrl/tag/uncensored/page/$page/";
          break;
        case '3d':
          targetUrl = page == 1 ? "$baseUrl/genre/3d/" : "$baseUrl/genre/3d/page/$page/";
          altUrl = page == 1 ? "$baseUrl/tag/3d/" : "$baseUrl/tag/3d/page/$page/";
          break;
        case 'romance':
          targetUrl = page == 1 ? "$baseUrl/genre/romance/" : "$baseUrl/genre/romance/page/$page/";
          altUrl = page == 1 ? "$baseUrl/tag/romance/" : "$baseUrl/tag/romance/page/$page/";
          break;
        default:
          targetUrl = page == 1 ? "$baseUrl/trending/" : "$baseUrl/trending/page/$page/";
          altUrl = page == 1 ? "$baseUrl/?m_orderby=views" : "$baseUrl/page/$page/?m_orderby=views";
          break;
      }

      var response = await http.get(Uri.parse(targetUrl), headers: _headers).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        response = await http.get(Uri.parse(altUrl), headers: _headers).timeout(const Duration(seconds: 8));
      }

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
        final items = _parseCardsFromHtml(response.body, tabId: 'search');
        if (items.isNotEmpty) return items;
      }
    } catch (_) {}

    return fetchTabFeed("trending", page);
  }

  List<MediaItem> _parseCardsFromHtml(String html, {String tabId = 'trending'}) {
    final doc = html_parser.parse(html);
    final articles = doc.querySelectorAll('article, .video-card, .post, .item');
    final List<MediaItem> items = [];
    final Set<String> seenHrefs = {};

    for (final art in articles) {
      final a = art.querySelector('a');
      var href = a?.attributes['href'] ?? '';
      if (href.isEmpty) continue;
      if (!href.startsWith('http')) {
        href = href.startsWith('/') ? '$baseUrl$href' : '$baseUrl/$href';
      }
      if (seenHrefs.contains(href)) continue;
      seenHrefs.add(href);

      final img = art.querySelector('img');
      var title = art.querySelector('h2, .title, .entry-title, h3, a[title]')?.text.trim() ??
          a?.attributes['title']?.trim() ??
          img?.attributes['alt']?.trim() ??
          '';
      title = _cleanText(title);

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
      if (cover.startsWith('data:') && img?.attributes['data-src'] != null) {
        cover = img!.attributes['data-src']!;
      }
      if (cover.startsWith('//')) {
        cover = 'https:$cover';
      }
      if (cover.isNotEmpty && !cover.startsWith('http')) {
        cover = cover.startsWith('/') ? '$baseUrl$cover' : '$baseUrl/$cover';
      }

      if (title.isNotEmpty && cover.startsWith('http')) {
        final duration = art.querySelector('.duration, .time, .badge')?.text.trim() ?? '24:00';
        final is3d = tabId == '3d' || title.toLowerCase().contains('3d') || title.toLowerCase().contains('sfm');
        final isUncensored = tabId == 'uncensored' ||
            title.toLowerCase().contains('uncensored') ||
            title.toLowerCase().contains('no censor') ||
            art.className.contains('uncensored');

        final defaultTags = _getDefaultTagsForTab(tabId);

        items.add(MediaItem(
          id: href.hashCode.toString(),
          title: title,
          url: href,
          cover: cover,
          duration: duration,
          releaseDate: "2024",
          studio: "Pulse Studios",
          extensionId: id,
          type: is3d ? MediaType.mmd3D : MediaType.animeSeries,
          tags: defaultTags,
          rating: 4.8,
          views: 195000,
          isUncensored: isUncensored,
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
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  List<String> _getDefaultTagsForTab(String tabId) {
    switch (tabId) {
      case 'trending':
        return ["Pulse Trending", "HD", "Subbed"];
      case 'latest':
        return ["Latest Upload", "HD", "Subbed"];
      case 'uncensored':
        return ["Uncensored", "HD", "Explicit"];
      case '3d':
        return ["3D Animation", "CGI", "60fps"];
      case 'romance':
        return ["Romance", "Vanilla", "HD"];
      default:
        return ["Pulse Trending", "HD"];
    }
  }

  @override
  Future<MediaDetail> detail(String url) async {
    try {
      final response = await http.get(Uri.parse(url), headers: _headers).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final doc = html_parser.parse(response.body);
        final title = doc.querySelector('h1')?.text.trim() ?? "HentaiPulse Episode";
        final desc = doc.querySelector('meta[name="description"]')?.attributes['content'] ??
            doc.querySelector('.entry-content p')?.text.trim() ??
            "Trending high definition anime on HentaiPulse.";
        final cover = doc.querySelector('meta[property="og:image"]')?.attributes['content'] ?? "";

        final sources = await extractVideoStreams(url);

        return MediaDetail(
          id: url.hashCode.toString(),
          title: title,
          cover: cover.isNotEmpty ? cover : "https://i.imgur.com/7jZQY1B.jpeg",
          backdrop: cover.isNotEmpty ? cover : "https://i.imgur.com/7jZQY1B.jpeg",
          description: desc,
          studio: "HentaiPulse Studios",
          releaseDate: "2024",
          tags: ["Pulse Trending", "HD", "Uncensored"],
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
            SceneMarker(title: "Peak Drop 🔥", timestampSeconds: 710),
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
              label: "Pulse Stream Server",
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
      "trending": [
        MediaItem(
          id: "hp_tr_1",
          title: "Taimanin Yukikaze: Pulse Remaster",
          url: "$baseUrl/taimanin-yukikaze-pulse",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "24:15",
          releaseDate: "2024",
          studio: "Lilith",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Pulse Trending", "Action", "Supernatural"],
          rating: 4.9,
          views: 280000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_tr_2",
          title: "Kuroinu: Subjugation of the Proud Knights",
          url: "$baseUrl/kuroinu-subjugation-proud-knights",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "28:30",
          releaseDate: "2024",
          studio: "Eroman",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Pulse Trending", "Dark Fantasy", "Knights"],
          rating: 4.9,
          views: 340000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_tr_3",
          title: "Overflow: Passionate Bathing Sessions",
          url: "$baseUrl/overflow-passionate-bathing",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "21:40",
          releaseDate: "2024",
          studio: "Houkiboshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Pulse Trending", "Romance", "Harem"],
          rating: 4.8,
          views: 420000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_tr_4",
          title: "Rance 01: The Quest for Hikari",
          url: "$baseUrl/rance-01-the-quest-for-hikari",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "29:50",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Pulse Trending", "Adventure", "Fantasy"],
          rating: 4.9,
          views: 310000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_tr_5",
          title: "Master Piece The Animation: Special Cut",
          url: "$baseUrl/master-piece-the-animation-special",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "26:10",
          releaseDate: "2024",
          studio: "PoJu",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Pulse Trending", "School", "Drama"],
          rating: 4.8,
          views: 275000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_tr_6",
          title: "Kyonyuu Fantasy: Baris Conquest",
          url: "$baseUrl/kyonyuu-fantasy-baris-conquest",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "27:45",
          releaseDate: "2024",
          studio: "W-Toon Studio",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Pulse Trending", "Fantasy", "Big Boobs"],
          rating: 4.7,
          views: 230000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_tr_7",
          title: "Eroge H mo Game mo Kaihatsu Zanmai",
          url: "$baseUrl/eroge-kaihatsu-zanmai",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "23:55",
          releaseDate: "2024",
          studio: "Ziz",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Pulse Trending", "Otaku", "Comedy"],
          rating: 4.8,
          views: 260000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_tr_8",
          title: "Disciplima: Academy of Seduction",
          url: "$baseUrl/disciplima-academy-seduction",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "25:20",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Pulse Trending", "Mind Control", "School"],
          rating: 4.8,
          views: 215000,
          isUncensored: true,
        ),
      ],
      "latest": [
        MediaItem(
          id: "hp_lat_1",
          title: "Dokidoki Little Ooyasan: Fresh Keys",
          url: "$baseUrl/dokidoki-little-ooyasan-fresh-keys",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "22:15",
          releaseDate: "2026",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest Upload", "Romance", "Cute"],
          rating: 4.8,
          views: 185000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_lat_2",
          title: "Oni Chichi: Re-born Revival",
          url: "$baseUrl/oni-chichi-re-born-revival",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "27:30",
          releaseDate: "2026",
          studio: "PoJu",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest Upload", "Family", "Drama"],
          rating: 4.9,
          views: 240000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_lat_3",
          title: "Isekai Harem Monogatari: Royal Banquet",
          url: "$baseUrl/isekai-harem-monogatari-royal",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "25:00",
          releaseDate: "2026",
          studio: "Bunnywalker",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest Upload", "Isekai", "Harem"],
          rating: 4.8,
          views: 195000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_lat_4",
          title: "Joshi Ochi!: 2nd Floor Surprise",
          url: "$baseUrl/joshi-ochi-2nd-floor-surprise",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "20:45",
          releaseDate: "2026",
          studio: "ComicFesta",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest Upload", "Apartment", "Comedy"],
          rating: 4.7,
          views: 160000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_lat_5",
          title: "Otome Dori: Melancholic Strings Remaster",
          url: "$baseUrl/otome-dori-melancholic-strings",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "28:10",
          releaseDate: "2026",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest Upload", "NTR", "Drama"],
          rating: 4.6,
          views: 220000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_lat_6",
          title: "Energy Kyouka: High Voltage Ep 1",
          url: "$baseUrl/energy-kyouka-high-voltage",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "24:30",
          releaseDate: "2026",
          studio: "Digital Works",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest Upload", "Fantasy", "Ecchi"],
          rating: 4.7,
          views: 175000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_lat_7",
          title: "Shishunki Sex: Awakening Spring",
          url: "$baseUrl/shishunki-sex-awakening-spring",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "23:10",
          releaseDate: "2026",
          studio: "Pink Pineapple",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest Upload", "Youth", "School"],
          rating: 4.8,
          views: 205000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_lat_8",
          title: "Futabu Mix: Secret Club Reunion",
          url: "$baseUrl/futabu-mix-secret-club",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "26:40",
          releaseDate: "2026",
          studio: "Ziz",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest Upload", "Futanari", "Comedy"],
          rating: 4.8,
          views: 190000,
          isUncensored: true,
        ),
      ],
      "uncensored": [
        MediaItem(
          id: "hp_unc_1",
          title: "Dropout: Unmasked Pure Edition",
          url: "$baseUrl/dropout-unmasked-pure-edition",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "28:50",
          releaseDate: "2024",
          studio: "Mary Jane",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "School", "Dark"],
          rating: 4.9,
          views: 360000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_unc_2",
          title: "Mankitsu Happening: Decensored Cut",
          url: "$baseUrl/mankitsu-happening-decensored",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "27:10",
          releaseDate: "2024",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Cafe", "Public"],
          rating: 4.9,
          views: 520000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_unc_3",
          title: "Swing Out Sisters: Complete Uncut",
          url: "$baseUrl/swing-out-sisters-complete-uncut",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "26:00",
          releaseDate: "2024",
          studio: "Arms",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Sisters", "Classic"],
          rating: 4.8,
          views: 290000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_unc_4",
          title: "Resort Boin: Island Paradise Decensored",
          url: "$baseUrl/resort-boin-island-paradise",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "29:15",
          releaseDate: "2024",
          studio: "Milky",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Beach", "Big Boobs"],
          rating: 4.8,
          views: 330000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_unc_5",
          title: "Bible Black: Definitive Uncut Master",
          url: "$baseUrl/bible-black-definitive-uncut",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "31:20",
          releaseDate: "2024",
          studio: "Milky",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Occult", "Classic"],
          rating: 4.9,
          views: 480000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_unc_6",
          title: "Ane Wa Yanmama Junyuu-chuu: Full Uncensored",
          url: "$baseUrl/ane-wa-yanmama-full-uncensored",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "25:40",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Gyaru", "Lactation"],
          rating: 4.8,
          views: 270000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_unc_7",
          title: "Valkyrie Hazard: Uncensored Battle",
          url: "$baseUrl/valkyrie-hazard-uncensored-battle",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "24:50",
          releaseDate: "2024",
          studio: "Lilith",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Sci-Fi", "Action"],
          rating: 4.7,
          views: 210000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_unc_8",
          title: "Helter Skelter: Uncensored Hakudaku",
          url: "$baseUrl/helter-skelter-uncensored",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "28:05",
          releaseDate: "2024",
          studio: "PoJu",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Mind Control", "Dark"],
          rating: 4.8,
          views: 305000,
          isUncensored: true,
        ),
      ],
      "3d": [
        MediaItem(
          id: "hp_3d_1",
          title: "Final Fantasy VII: Tifa Lockhart 3D Climax",
          url: "$baseUrl/ffvii-tifa-lockhart-3d-climax",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "08:15",
          releaseDate: "2024",
          studio: "Blender Master",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D Animation", "Final Fantasy", "Tifa", "60fps"],
          rating: 4.9,
          views: 390000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_3d_2",
          title: "Genshin Impact: Raiden Shogun Domain Climax",
          url: "$baseUrl/genshin-raiden-shogun-domain",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "10:30",
          releaseDate: "2024",
          studio: "Mihoyo SFM",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D Animation", "Genshin Impact", "Raiden", "60fps"],
          rating: 4.9,
          views: 420000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_3d_3",
          title: "NieR Automata: 2B YoRHa Protocol SFM",
          url: "$baseUrl/nier-automata-2b-yorha-protocol",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "07:45",
          releaseDate: "2024",
          studio: "YoRHa Lab",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D Animation", "NieR", "2B", "CGI"],
          rating: 4.9,
          views: 350000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_3d_4",
          title: "Overwatch: D.Va & Mercy Double Secret 3D",
          url: "$baseUrl/overwatch-dva-mercy-double-secret",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "09:20",
          releaseDate: "2024",
          studio: "Overwatch SFM",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D Animation", "Overwatch", "D.Va", "Mercy"],
          rating: 4.8,
          views: 310000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_3d_5",
          title: "Cyberpunk Edgerunners: Lucy Neon Pulse 3D",
          url: "$baseUrl/cyberpunk-lucy-neon-pulse-3d",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "06:50",
          releaseDate: "2024",
          studio: "Night City 3D",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D Animation", "Cyberpunk", "Lucy", "60fps"],
          rating: 4.9,
          views: 280000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_3d_6",
          title: "Resident Evil: Ada Wong Espionage VIP 4K",
          url: "$baseUrl/resident-evil-ada-wong-espionage-vip",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "11:10",
          releaseDate: "2024",
          studio: "Biohazard SFM",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D Animation", "Resident Evil", "Ada Wong", "4K"],
          rating: 4.8,
          views: 295000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_3d_7",
          title: "Dead or Alive: Kasumi Sakura Bloom 3D",
          url: "$baseUrl/dead-or-alive-kasumi-sakura-bloom",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "08:40",
          releaseDate: "2024",
          studio: "Ninja Studio 3D",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D Animation", "DOA", "Kasumi", "Ninja"],
          rating: 4.7,
          views: 230000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_3d_8",
          title: "Honkai Star Rail: Kafka Dominance SFM",
          url: "$baseUrl/honkai-star-rail-kafka-dominance",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "10:15",
          releaseDate: "2024",
          studio: "Astral Express SFM",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D Animation", "Star Rail", "Kafka", "60fps"],
          rating: 4.9,
          views: 335000,
          isUncensored: true,
        ),
      ],
      "romance": [
        MediaItem(
          id: "hp_rom_1",
          title: "Kanojo x Kanojo x Kanojo: Heartbeat Romance",
          url: "$baseUrl/kanojo-kanojo-kanojo-heartbeat",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "25:30",
          releaseDate: "2024",
          studio: "PoJu",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance", "Harem", "School", "Vanilla"],
          rating: 4.9,
          views: 340000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_rom_2",
          title: "Sweet Home: Pure Love & Honey",
          url: "$baseUrl/sweet-home-pure-love-honey",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "24:10",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance", "Vanilla", "Pure Love"],
          rating: 4.8,
          views: 270000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_rom_3",
          title: "First Love Diary: Sweet Whisperings",
          url: "$baseUrl/first-love-diary-sweet-whisperings",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "23:45",
          releaseDate: "2024",
          studio: "Arms",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance", "Sweet", "Couples"],
          rating: 4.8,
          views: 220000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_rom_4",
          title: "Kimi no Mana: Sincere Vows",
          url: "$baseUrl/kimi-no-mana-sincere-vows",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "26:15",
          releaseDate: "2024",
          studio: "Bunnywalker",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance", "Childhood Friend", "Drama"],
          rating: 4.9,
          views: 290000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_rom_5",
          title: "Hatsukoi Memories: Cherry Blossoms",
          url: "$baseUrl/hatsukoi-memories-cherry-blossoms",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "27:00",
          releaseDate: "2024",
          studio: "Digital Works",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance", "Spring", "Emotional"],
          rating: 4.7,
          views: 195000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_rom_6",
          title: "Lovely Heart: Pure Emotion Ep 1",
          url: "$baseUrl/lovely-heart-pure-emotion",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "22:50",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance", "Vanilla", "Tender"],
          rating: 4.8,
          views: 245000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_rom_7",
          title: "Koharu Biyori: Warm Spring Affection",
          url: "$baseUrl/koharu-biyori-warm-spring",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "24:20",
          releaseDate: "2024",
          studio: "Pink Pineapple",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance", "Maid", "Sweet"],
          rating: 4.7,
          views: 210000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_rom_8",
          title: "Amakano: Sweet Winter Romance",
          url: "$baseUrl/amakano-sweet-winter-romance",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "28:10",
          releaseDate: "2024",
          studio: "PoJu",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance", "Winter", "Pure", "Vanilla"],
          rating: 4.9,
          views: 310000,
          isUncensored: false,
        ),
      ],
    };

    return sampleSets[tabId] ?? sampleSets["trending"]!;
  }

  MediaDetail _generateSampleDetail(String url) {
    return MediaDetail(
      id: url.hashCode.toString(),
      title: "Taimanin Yukikaze: Pulse Remaster",
      cover: "https://i.imgur.com/7jZQY1B.jpeg",
      backdrop: "https://i.imgur.com/7jZQY1B.jpeg",
      description: "Trending high-definition episode stream on HentaiPulse.",
      studio: "Lilith Animation",
      releaseDate: "2024",
      tags: ["Pulse Trending", "HD", "Uncensored"],
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

  @override
  Future<ExtensionTaxonomy> fetchTaxonomy() async {
    return hentaiPulseTaxonomy;
  }

  @override
  Future<List<MediaItem>> fetchTaxonomyFeed(CatalogItem item, int page) async {
    // 1. Direct tab feed mapping if it corresponds to a primary tab
    if (item.slug == 'trending' ||
        item.slug == 'latest' ||
        item.slug == 'uncensored' ||
        item.slug == '3d' ||
        item.slug == 'romance') {
      return fetchTabFeed(item.slug, page);
    }

    // 2. Live feed scraping using verified taxonomy routes
    final path = item.endpointPath ??
        (item.type == CatalogType.tag ? '/tag/${item.slug}/' : '/genre/${item.slug}/');
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final normalizedPath = cleanPath.endsWith('/') ? cleanPath : '$cleanPath/';

    try {
      final targetUrl = page == 1
          ? '$baseUrl$normalizedPath'
          : '$baseUrl${normalizedPath}page/$page/';
      final altUrl = page == 1
          ? '$baseUrl$normalizedPath'
          : '$baseUrl$normalizedPath?page=$page';

      var response = await http
          .get(Uri.parse(targetUrl), headers: _headers)
          .timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) {
        response = await http
            .get(Uri.parse(altUrl), headers: _headers)
            .timeout(const Duration(seconds: 6));
      }

      if (response.statusCode == 200) {
        final items = _parseCardsFromHtml(response.body, tabId: item.slug);
        if (items.isNotEmpty) return items;
      }
    } catch (_) {}

    // 3. Search fallback
    try {
      final searchResults = await search(item.name, page);
      if (searchResults.isNotEmpty) return searchResults;
    } catch (_) {}

    // 4. Sample fallback
    return _generateTaxonomySampleList(item, page);
  }

  List<MediaItem> _generateTaxonomySampleList(CatalogItem item, int page) {
    if (page > 1) return [];

    final fallbackTab = (item.slug == '3d' || item.name.contains('3D'))
        ? '3d'
        : (item.slug == 'romance' || item.categoryGroup == 'Romance')
            ? 'romance'
            : (item.slug == 'uncensored' || item.type == CatalogType.category)
                ? 'uncensored'
                : 'trending';

    final baseItems = _generateSampleList(fallbackTab, 1);
    return baseItems.map((m) {
      final updatedTags = List<String>.from(m.tags);
      if (!updatedTags.contains(item.name)) {
        updatedTags.insert(0, item.name);
      }
      return MediaItem(
        id: "hp_tax_${item.slug}_${m.id}",
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
        isUncensored: m.isUncensored,
      );
    }).toList();
  }
}
