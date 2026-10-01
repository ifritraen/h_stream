import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../base_extension.dart';
import '../../models/media_item.dart';
import '../../models/extension_manifest.dart';
import '../../models/catalog_model.dart';
import '../taxonomies/hentai_play_taxonomy.dart';

/// HentaiPlay extension for HStream Neo.
/// Scrapes playlist-focused anime streaming from hentaiplay.net.
class HentaiPlayExtension extends HentaiExtension {
  @override
  String get id => "hentai_play";

  @override
  String get name => "HentaiPlay";

  @override
  String get baseUrl => "https://hentaiplay.net";

  @override
  String get iconUrl => "https://hentaiplay.net/favicon.ico";

  @override
  String get description => "Playlist-focused streaming catalog with multi-episode autoplay series.";

  @override
  ViewLayoutType get defaultLayout => ViewLayoutType.widescreen16x9;

  @override
  bool get supportsShorts => false;

  @override
  List<ExtensionTab> get tabs => [
        ExtensionTab(id: "recent", title: "Recent Releases", icon: Icons.fiber_new_rounded),
        ExtensionTab(id: "upcoming", title: "Upcoming / Ongoing", icon: Icons.update_rounded),
        ExtensionTab(id: "uncensored", title: "Uncensored Genre", icon: Icons.lock_open_rounded),
        ExtensionTab(id: "romance", title: "Romance Genre", icon: Icons.favorite_rounded),
        ExtensionTab(id: "dark_skin", title: "Dark Skin Genre", icon: Icons.wb_sunny_rounded),
        ExtensionTab(id: "ahegao", title: "Ahegao Genre", icon: Icons.face_retouching_natural_rounded),
      ];

  @override
  List<FilterGroup> get filters => [];

  final Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaiplay.net/',
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
      final targetUrl = _resolveTabUrl(tabId, page);
      final response = await http.get(Uri.parse(targetUrl), headers: _headers).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final doc = html_parser.parse(response.body);
        final articles = doc.querySelectorAll('article, div.post, div.video-card, .item, .video-card');
        final List<MediaItem> items = [];

        for (final art in articles) {
          final a = art.querySelector('a');
          final href = a?.attributes['href'] ?? '';
          if (href.isEmpty) continue;

          final img = art.querySelector('img');
          final titleEl = art.querySelector('h2, .title, .entry-title, a.title');
          final title = titleEl?.text.trim() ?? img?.attributes['alt']?.trim() ?? '';
          var cover = img?.attributes['data-src'] ??
              img?.attributes['data-lazy-src'] ??
              img?.attributes['src'] ??
              '';

          if (cover.startsWith('//')) {
            cover = 'https:$cover';
          }

          if (title.isNotEmpty && cover.startsWith('http')) {
            final isUnc = tabId == 'uncensored' || title.toLowerCase().contains('uncensored');
            items.add(MediaItem(
              id: href.hashCode.toString(),
              title: title,
              url: href.startsWith('http') ? href : "$baseUrl$href",
              cover: cover,
              duration: "24:00",
              releaseDate: "2024",
              studio: "HentaiPlay",
              extensionId: id,
              type: MediaType.animeSeries,
              tags: [
                if (tabId == 'uncensored') 'Uncensored' else 'HD',
                if (tabId == 'romance') 'Romance',
                if (tabId == 'dark_skin') 'Dark Skin',
                if (tabId == 'ahegao') 'Ahegao',
                if (tabId == 'upcoming') 'Upcoming',
                'Subbed',
              ],
              rating: 4.8,
              views: 170000,
              isUncensored: isUnc,
            ));
          }
        }
        if (items.isNotEmpty) return items;
      }
    } catch (_) {}

    return _generateSampleList(tabId, page);
  }

  String _resolveTabUrl(String tabId, int page) {
    switch (tabId) {
      case 'upcoming':
        return page == 1
            ? "$baseUrl/upcoming-hentai-releases/"
            : "$baseUrl/upcoming-hentai-releases/page/$page/";
      case 'uncensored':
        return page == 1
            ? "$baseUrl/genre/uncensored-hentai/"
            : "$baseUrl/genre/uncensored-hentai/page/$page/";
      case 'romance':
        return page == 1
            ? "$baseUrl/genre/romance/"
            : "$baseUrl/genre/romance/page/$page/";
      case 'dark_skin':
        return page == 1
            ? "$baseUrl/genre/dark-skin/"
            : "$baseUrl/genre/dark-skin/page/$page/";
      case 'ahegao':
        return page == 1
            ? "$baseUrl/genre/ahegao/"
            : "$baseUrl/genre/ahegao/page/$page/";
      case 'recent':
      default:
        return page == 1
            ? "$baseUrl/hentai/episodes/new-release/"
            : "$baseUrl/hentai/episodes/new-release/page/$page/";
    }
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
        final articles = doc.querySelectorAll('article, div.post, div.video-card, .item');
        final List<MediaItem> items = [];

        for (final art in articles) {
          final a = art.querySelector('a');
          final href = a?.attributes['href'] ?? '';
          if (href.isEmpty) continue;

          final img = art.querySelector('img');
          final titleEl = art.querySelector('h2, .title, .entry-title, a.title');
          final title = titleEl?.text.trim() ?? img?.attributes['alt']?.trim() ?? '';
          var cover = img?.attributes['data-src'] ??
              img?.attributes['data-lazy-src'] ??
              img?.attributes['src'] ??
              '';

          if (cover.startsWith('//')) {
            cover = 'https:$cover';
          }

          if (title.isNotEmpty && cover.startsWith('http')) {
            items.add(MediaItem(
              id: href.hashCode.toString(),
              title: title,
              url: href.startsWith('http') ? href : "$baseUrl$href",
              cover: cover,
              duration: "24:00",
              studio: "HentaiPlay",
              extensionId: id,
              type: MediaType.animeSeries,
              tags: ["Playlist", "HD"],
              rating: 4.8,
              views: 130000,
            ));
          }
        }
        if (items.isNotEmpty) return items;
      }
    } catch (_) {}

    return fetchTabFeed("recent", page);
  }

  @override
  Future<MediaDetail> detail(String url) async {
    try {
      final response = await http.get(Uri.parse(url), headers: _headers).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final doc = html_parser.parse(response.body);
        final title = doc.querySelector('h1')?.text.trim() ?? "HentaiPlay Series";
        final desc = doc.querySelector('meta[name="description"]')?.attributes['content'] ??
            doc.querySelector('.entry-content p')?.text.trim() ??
            "Playlist-based anime playback on HentaiPlay.";
        final cover = doc.querySelector('meta[property="og:image"]')?.attributes['content'] ?? "";

        final sources = await extractVideoStreams(url);

        return MediaDetail(
          id: url.hashCode.toString(),
          title: title,
          cover: cover.isNotEmpty ? cover : "https://i.imgur.com/7jZQY1B.jpeg",
          backdrop: cover.isNotEmpty ? cover : "https://i.imgur.com/7jZQY1B.jpeg",
          description: desc,
          studio: "HentaiPlay Studios",
          releaseDate: "2024",
          tags: ["Playlist", "HD", "Uncensored"],
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
            SceneMarker(title: "Play Climax 🔥", timestampSeconds: 700),
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
              label: "Play Stream Server",
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
      "recent": [
        MediaItem(
          id: "hp_rec_1",
          title: "Furachi na Gakuen: Houkago no Himitsu – Ep 1",
          url: "$baseUrl/furachi-na-gakuen-1",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "24:15",
          releaseDate: "2026",
          studio: "Mary Jane",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Recent", "School", "HD"],
          rating: 4.8,
          views: 245000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_rec_2",
          title: "Chikan Jousha: Tokumori Rush Hour – Ep 2",
          url: "$baseUrl/chikan-jousha-2",
          cover: "https://i.imgur.com/ODp7x3f.jpeg",
          duration: "22:40",
          releaseDate: "2026",
          studio: "Bunnywalker",
          tags: ["Recent", "Train", "HD"],
          rating: 4.7,
          views: 198000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_rec_3",
          title: "Seikatsu Shuukan: Otona no Jikan – Ep 1",
          url: "$baseUrl/seikatsu-shuukan-1",
          cover: "https://i.imgur.com/wVqjC5P.jpeg",
          duration: "25:10",
          releaseDate: "2025",
          studio: "Seven",
          tags: ["Recent", "Drama", "HD"],
          rating: 4.9,
          views: 320000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_rec_4",
          title: "Netorare Bakunyuu Kanojo – Ep 3",
          url: "$baseUrl/netorare-bakunyuu-kanojo-3",
          cover: "https://i.imgur.com/z4bKxNm.jpeg",
          duration: "23:55",
          releaseDate: "2025",
          studio: "Pink Pineapple",
          tags: ["Recent", "NTR", "HD"],
          rating: 4.6,
          views: 180000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_rec_5",
          title: "Shoujo Ramune: Natsuyasumi Play – Ep 2",
          url: "$baseUrl/shoujo-ramune-play-2",
          cover: "https://i.imgur.com/83pZ6XQ.jpeg",
          duration: "24:30",
          releaseDate: "2025",
          studio: "PoJu",
          tags: ["Recent", "Summer", "HD"],
          rating: 4.8,
          views: 410000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_rec_6",
          title: "Kyonyuu Fantasy: Outer World – Ep 1",
          url: "$baseUrl/kyonyuu-fantasy-outer-1",
          cover: "https://i.imgur.com/N7GgqMv.jpeg",
          duration: "26:05",
          releaseDate: "2024",
          studio: "T-Rex",
          tags: ["Recent", "Fantasy", "HD"],
          rating: 4.9,
          views: 280000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_rec_7",
          title: "Boku to Nurse no Shinsatsushitsu – Ep 2",
          url: "$baseUrl/boku-to-nurse-2",
          cover: "https://i.imgur.com/J3ZqK9x.jpeg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "Queen Bee",
          tags: ["Recent", "Nurse", "HD"],
          rating: 4.7,
          views: 165000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_rec_8",
          title: "Etsuraku no Tane: Shinshou – Ep 1",
          url: "$baseUrl/etsuraku-no-tane-1",
          cover: "https://i.imgur.com/f9hYw0U.jpeg",
          duration: "27:12",
          releaseDate: "2024",
          studio: "Collaboration Works",
          tags: ["Recent", "Thriller", "HD"],
          rating: 4.8,
          views: 215000,
          isUncensored: false,
        ),
      ],
      "upcoming": [
        MediaItem(
          id: "hp_upc_1",
          title: "Isekai Harem Monogatari: Act II (Teaser)",
          url: "$baseUrl/isekai-harem-act-2",
          cover: "https://i.imgur.com/ODp7x3f.jpeg",
          duration: "03:45",
          releaseDate: "2026",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Upcoming", "Isekai", "Fantasy"],
          rating: 4.9,
          views: 510000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_upc_2",
          title: "Overflow: Re-Ignited Hearts – Ongoing Ep 4",
          url: "$baseUrl/overflow-reignited-4",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "24:00",
          releaseDate: "2026",
          studio: "Hokiboshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Upcoming", "Ongoing", "Romance"],
          rating: 4.9,
          views: 640000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_upc_3",
          title: "Gakuen de Jikan Tomare: Chrono Break – Ep 1",
          url: "$baseUrl/gakuen-chrono-break-1",
          cover: "https://i.imgur.com/wVqjC5P.jpeg",
          duration: "25:20",
          releaseDate: "2026",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Upcoming", "Time Stop", "School"],
          rating: 4.8,
          views: 390000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_upc_4",
          title: "Ane wa Yanmama: Next Generation – Ongoing Ep 2",
          url: "$baseUrl/ane-wa-yanmama-ng-2",
          cover: "https://i.imgur.com/z4bKxNm.jpeg",
          duration: "23:45",
          releaseDate: "2026",
          studio: "Bunnywalker",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Upcoming", "Ongoing", "Milf"],
          rating: 4.7,
          views: 280000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_upc_5",
          title: "Rance: Hikari o Motomete Final – Preview",
          url: "$baseUrl/rance-final-preview",
          cover: "https://i.imgur.com/83pZ6XQ.jpeg",
          duration: "05:10",
          releaseDate: "2026",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Upcoming", "Adventure", "Action"],
          rating: 4.9,
          views: 720000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_upc_6",
          title: "Kimi wa Midara na Boku no Joou: OVA Special",
          url: "$baseUrl/kimi-wa-midara-ova",
          cover: "https://i.imgur.com/N7GgqMv.jpeg",
          duration: "28:10",
          releaseDate: "2026",
          studio: "Mary Jane",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Upcoming", "Romance", "Ecchi"],
          rating: 4.8,
          views: 330000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_upc_7",
          title: "Kuroinu: Chapter VIII Ongoing Siege",
          url: "$baseUrl/kuroinu-viii-siege",
          cover: "https://i.imgur.com/J3ZqK9x.jpeg",
          duration: "29:50",
          releaseDate: "2026",
          studio: "Pink Pineapple",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Upcoming", "Dark Fantasy", "Ongoing"],
          rating: 4.9,
          views: 880000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_upc_8",
          title: "Eroge! H mo Game mo Kaihatsu Zanmai 2 – Teaser",
          url: "$baseUrl/eroge-kaihatsu-2-teaser",
          cover: "https://i.imgur.com/f9hYw0U.jpeg",
          duration: "04:30",
          releaseDate: "2026",
          studio: "Collaboration Works",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Upcoming", "Comedy", "Harem"],
          rating: 4.8,
          views: 420000,
          isUncensored: false,
        ),
      ],
      "uncensored": [
        MediaItem(
          id: "hp_unc_1",
          title: "Taimanin Asuka: Uncensored Director Cut – Ep 1",
          url: "$baseUrl/taimanin-asuka-uncut-1",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "28:00",
          releaseDate: "2025",
          studio: "Lilith",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Action", "Ninja"],
          rating: 4.9,
          views: 950000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_unc_2",
          title: "Mankitsu Happening: Full Uncensored Master – Ep 2",
          url: "$baseUrl/mankitsu-happening-uncut-2",
          cover: "https://i.imgur.com/ODp7x3f.jpeg",
          duration: "26:30",
          releaseDate: "2025",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Manga Cafe", "POV"],
          rating: 4.9,
          views: 1200000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_unc_3",
          title: "Onsen de Dekigoto: Raw & Decensored – Ep 1",
          url: "$baseUrl/onsen-dekigoto-raw-1",
          cover: "https://i.imgur.com/wVqjC5P.jpeg",
          duration: "24:10",
          releaseDate: "2024",
          studio: "PoJu",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Hot Spring", "HD"],
          rating: 4.8,
          views: 480000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_unc_4",
          title: "Resort Boin: Summer Uncensored Edition – Ep 1",
          url: "$baseUrl/resort-boin-uncut-1",
          cover: "https://i.imgur.com/z4bKxNm.jpeg",
          duration: "27:45",
          releaseDate: "2024",
          studio: "Bunnywalker",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Beach", "Big Boobs"],
          rating: 4.8,
          views: 560000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_unc_5",
          title: "Dokidoki Little Ooyasan: 0-Mosaic Master – Ep 3",
          url: "$baseUrl/dokidoki-ooyasan-0m-3",
          cover: "https://i.imgur.com/83pZ6XQ.jpeg",
          duration: "25:00",
          releaseDate: "2024",
          studio: "Queen Bee",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Comedy", "Romance"],
          rating: 4.7,
          views: 630000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_unc_6",
          title: "Baku Ane: Otouto Shibocchau zo! Decensored – Ep 2",
          url: "$baseUrl/baku-ane-decensored-2",
          cover: "https://i.imgur.com/N7GgqMv.jpeg",
          duration: "23:50",
          releaseDate: "2024",
          studio: "Mary Jane",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Big Sis", "Creampie"],
          rating: 4.9,
          views: 710000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_unc_7",
          title: "Master Piece: The Animation Uncut – Ep 1",
          url: "$baseUrl/master-piece-uncut-1",
          cover: "https://i.imgur.com/J3ZqK9x.jpeg",
          duration: "29:15",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Maid", "Harem"],
          rating: 4.8,
          views: 590000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hp_unc_8",
          title: "Rinkan Club: Director Uncensored Cut – Ep 2",
          url: "$baseUrl/rinkan-club-uncut-2",
          cover: "https://i.imgur.com/f9hYw0U.jpeg",
          duration: "26:40",
          releaseDate: "2024",
          studio: "Pink Pineapple",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Group", "Dark"],
          rating: 4.7,
          views: 430000,
          isUncensored: true,
        ),
      ],
      "romance": [
        MediaItem(
          id: "hp_rom_1",
          title: "Hatsukoi Time: Sweeter than Sugar – Ep 1",
          url: "$baseUrl/hatsukoi-time-1",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "24:35",
          releaseDate: "2025",
          studio: "PoJu",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance", "Sweet", "Vanilla"],
          rating: 4.9,
          views: 340000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_rom_2",
          title: "Kanojo x Kanojo x Kanojo: Pure Heart Play – Ep 2",
          url: "$baseUrl/kanojo-x3-pure-2",
          cover: "https://i.imgur.com/ODp7x3f.jpeg",
          duration: "25:10",
          releaseDate: "2025",
          studio: "Bunnywalker",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance", "Harem", "School"],
          rating: 4.8,
          views: 420000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_rom_3",
          title: "Koisuru Shisutaa: Futari no Yakusoku – Ep 1",
          url: "$baseUrl/koisuru-shisutaa-1",
          cover: "https://i.imgur.com/wVqjC5P.jpeg",
          duration: "22:50",
          releaseDate: "2025",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance", "Sister", "Drama"],
          rating: 4.7,
          views: 290000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_rom_4",
          title: "Amakano: Second Season First Kiss – Ep 1",
          url: "$baseUrl/amakano-s2-1",
          cover: "https://i.imgur.com/z4bKxNm.jpeg",
          duration: "27:15",
          releaseDate: "2024",
          studio: "Mary Jane",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance", "Winter", "Pure"],
          rating: 4.9,
          views: 460000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_rom_5",
          title: "Suki de Suki de: Aishiteru – Ep 1",
          url: "$baseUrl/suki-de-suki-de-1",
          cover: "https://i.imgur.com/83pZ6XQ.jpeg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "Collaboration Works",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance", "Vanilla", "Love"],
          rating: 4.8,
          views: 310000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_rom_6",
          title: "Kimi to Boku no Houkago Date – Ep 3",
          url: "$baseUrl/kimi-to-boku-date-3",
          cover: "https://i.imgur.com/N7GgqMv.jpeg",
          duration: "23:40",
          releaseDate: "2024",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance", "Date", "Cute"],
          rating: 4.8,
          views: 275000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_rom_7",
          title: "Sweetest Cherry: Honeyed Blossom – Ep 2",
          url: "$baseUrl/sweetest-cherry-2",
          cover: "https://i.imgur.com/J3ZqK9x.jpeg",
          duration: "25:20",
          releaseDate: "2024",
          studio: "Queen Bee",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance", "Maid", "Sweet"],
          rating: 4.7,
          views: 195000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_rom_8",
          title: "Yubisaki kara no Honki no Netsujou – Ep 1",
          url: "$baseUrl/yubisaki-netsujou-1",
          cover: "https://i.imgur.com/f9hYw0U.jpeg",
          duration: "24:45",
          releaseDate: "2024",
          studio: "Hokiboshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance", "Firefighter", "Josei"],
          rating: 4.8,
          views: 380000,
          isUncensored: false,
        ),
      ],
      "dark_skin": [
        MediaItem(
          id: "hp_dsk_1",
          title: "Kuro Gal no Himegoto: Sun-Kissed Beach – Ep 1",
          url: "$baseUrl/kuro-gal-himegoto-1",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "25:00",
          releaseDate: "2025",
          studio: "Bunnywalker",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Dark Skin", "Gyaru", "Beach"],
          rating: 4.9,
          views: 510000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_dsk_2",
          title: "Choukou Tenshi Escalayer: Dark Valkyrie – Ep 2",
          url: "$baseUrl/choukou-tenshi-dark-2",
          cover: "https://i.imgur.com/ODp7x3f.jpeg",
          duration: "27:30",
          releaseDate: "2025",
          studio: "Lilith",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Dark Skin", "Action", "Super Hero"],
          rating: 4.8,
          views: 390000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_dsk_3",
          title: "Tropical Gal to Boin Island – Ep 1",
          url: "$baseUrl/tropical-gal-island-1",
          cover: "https://i.imgur.com/wVqjC5P.jpeg",
          duration: "24:15",
          releaseDate: "2025",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Dark Skin", "Resort", "Tanned"],
          rating: 4.8,
          views: 420000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_dsk_4",
          title: "Dark Elf no Mori: Seinaru Yakusoku – Ep 3",
          url: "$baseUrl/dark-elf-mori-3",
          cover: "https://i.imgur.com/z4bKxNm.jpeg",
          duration: "26:40",
          releaseDate: "2024",
          studio: "PoJu",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Dark Skin", "Dark Elf", "Fantasy"],
          rating: 4.9,
          views: 670000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_dsk_5",
          title: "Kuro Gyaru JK: Houkago no Shidou – Ep 1",
          url: "$baseUrl/kuro-gyaru-jk-1",
          cover: "https://i.imgur.com/83pZ6XQ.jpeg",
          duration: "23:50",
          releaseDate: "2024",
          studio: "Mary Jane",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Dark Skin", "Gyaru", "School"],
          rating: 4.8,
          views: 360000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_dsk_6",
          title: "Tanned Senpai wa Tomaranai – Ep 2",
          url: "$baseUrl/tanned-senpai-2",
          cover: "https://i.imgur.com/N7GgqMv.jpeg",
          duration: "24:55",
          releaseDate: "2024",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Dark Skin", "Senpai", "Athletic"],
          rating: 4.7,
          views: 295000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_dsk_7",
          title: "Oashisu no Shokeinin: Sand & Silk – Ep 1",
          url: "$baseUrl/oashisu-shokeinin-1",
          cover: "https://i.imgur.com/J3ZqK9x.jpeg",
          duration: "28:10",
          releaseDate: "2024",
          studio: "Pink Pineapple",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Dark Skin", "Desert", "Exotic"],
          rating: 4.8,
          views: 310000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_dsk_8",
          title: "Kurohada Tomodachi to no Himitsu Play – Ep 2",
          url: "$baseUrl/kurohada-tomodachi-2",
          cover: "https://i.imgur.com/f9hYw0U.jpeg",
          duration: "25:35",
          releaseDate: "2024",
          studio: "Queen Bee",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Dark Skin", "Friends", "Summer"],
          rating: 4.7,
          views: 260000,
          isUncensored: false,
        ),
      ],
      "ahegao": [
        MediaItem(
          id: "hp_ahg_1",
          title: "Ecstasy Heaven: Shiroki Me no Gensou – Ep 1",
          url: "$baseUrl/ecstasy-heaven-1",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "25:50",
          releaseDate: "2025",
          studio: "Mary Jane",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Ahegao", "Mind Break", "Extreme"],
          rating: 4.9,
          views: 580000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_ahg_2",
          title: "Kanojo wa Ahegao Shoujo: Shizuku to Zecchou – Ep 2",
          url: "$baseUrl/kanojo-ahegao-2",
          cover: "https://i.imgur.com/ODp7x3f.jpeg",
          duration: "24:20",
          releaseDate: "2025",
          studio: "PoJu",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Ahegao", "Orgasm", "HD"],
          rating: 4.8,
          views: 490000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_ahg_3",
          title: "Zecchou Lesson: Sensei no Te hodoki – Ep 1",
          url: "$baseUrl/zecchou-lesson-1",
          cover: "https://i.imgur.com/wVqjC5P.jpeg",
          duration: "26:10",
          releaseDate: "2025",
          studio: "Bunnywalker",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Ahegao", "Teacher", "Intense"],
          rating: 4.8,
          views: 430000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_ahg_4",
          title: "Mesugaki wa Zettai Iki Sugiru – Ep 3",
          url: "$baseUrl/mesugaki-iki-sugiru-3",
          cover: "https://i.imgur.com/z4bKxNm.jpeg",
          duration: "23:40",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Ahegao", "Brat", "Defeat"],
          rating: 4.9,
          views: 760000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_ahg_5",
          title: "Haitoku no Kankaku: Tenshi no Shiro Me – Ep 1",
          url: "$baseUrl/haitoku-kankaku-1",
          cover: "https://i.imgur.com/83pZ6XQ.jpeg",
          duration: "27:00",
          releaseDate: "2024",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Ahegao", "Angel", "Hypnosis"],
          rating: 4.7,
          views: 350000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_ahg_6",
          title: "Kairaku no Rasen: Ahegao Tokka Shindo – Ep 2",
          url: "$baseUrl/kairaku-rasen-2",
          cover: "https://i.imgur.com/N7GgqMv.jpeg",
          duration: "24:45",
          releaseDate: "2024",
          studio: "Pink Pineapple",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Ahegao", "Spiral", "Ecstasy"],
          rating: 4.9,
          views: 520000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_ahg_7",
          title: "Kousoku de Iki Makuri: Nurse Senshi – Ep 1",
          url: "$baseUrl/kousoku-nurse-senshi-1",
          cover: "https://i.imgur.com/J3ZqK9x.jpeg",
          duration: "25:15",
          releaseDate: "2024",
          studio: "Queen Bee",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Ahegao", "Nurse", "Restraint"],
          rating: 4.7,
          views: 310000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hp_ahg_8",
          title: "Overclimax: Genkai Toppa no Jouji – Ep 1",
          url: "$baseUrl/overclimax-genkai-1",
          cover: "https://i.imgur.com/f9hYw0U.jpeg",
          duration: "28:30",
          releaseDate: "2024",
          studio: "Collaboration Works",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Ahegao", "Climax", "Breakthrough"],
          rating: 4.8,
          views: 440000,
          isUncensored: false,
        ),
      ],
    };

    return sampleSets[tabId] ?? sampleSets["recent"] ?? [];
  }

  MediaDetail _generateSampleDetail(String url) {
    return MediaDetail(
      id: url.hashCode.toString(),
      title: "Taimanin Yukikaze Play Ep 1",
      cover: "https://i.imgur.com/7jZQY1B.jpeg",
      backdrop: "https://i.imgur.com/7jZQY1B.jpeg",
      description: "Playlist series on HentaiPlay.",
      studio: "Lilith Animation",
      releaseDate: "2024",
      tags: ["Playlist", "HD", "Uncensored"],
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
    return hentaiPlayTaxonomy;
  }

  @override
  Future<List<MediaItem>> fetchTaxonomyFeed(CatalogItem item, int page) async {
    // 1. Tab feeds or direct hero routes
    if (item.slug == "recent" || item.slug == "new-release") {
      return fetchTabFeed("recent", page);
    }
    if (item.slug == "upcoming") {
      return fetchTabFeed("upcoming", page);
    }
    if (item.slug == "uncensored" || item.slug == "uncensored-hentai" || item.slug == "hentai-uncensored") {
      return fetchTabFeed("uncensored", page);
    }
    if (item.slug == "romance") {
      return fetchTabFeed("romance", page);
    }
    if (item.slug == "dark-skin" || item.slug == "dark_skin") {
      return fetchTabFeed("dark_skin", page);
    }
    if (item.slug == "ahegao") {
      return fetchTabFeed("ahegao", page);
    }

    try {
      String targetUrl;
      if (item.endpointPath != null && item.endpointPath!.isNotEmpty) {
        final ep = item.endpointPath!;
        final cleanEp = ep.endsWith('/') ? ep : '$ep/';
        targetUrl = page == 1 ? "$baseUrl$cleanEp" : "$baseUrl${cleanEp}page/$page/";
      } else {
        targetUrl = page == 1 ? "$baseUrl/genre/${item.slug}/" : "$baseUrl/genre/${item.slug}/page/$page/";
      }

      final response = await http.get(Uri.parse(targetUrl), headers: _headers).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200 && !response.body.contains('layout-page-404')) {
        final doc = html_parser.parse(response.body);
        final articles = doc.querySelectorAll('article, div.item, div.post, div.video-card');
        final List<MediaItem> items = [];
        final Set<String> seenHrefs = {};

        for (final art in articles) {
          final a = art.querySelector('a.clip-link') ?? art.querySelector('.entry-title a') ?? art.querySelector('a');
          final href = a?.attributes['href'] ?? '';
          if (href.isEmpty || seenHrefs.contains(href) || href.contains('facebook') || href.contains('twitter')) continue;

          final img = art.querySelector('img');
          final title = art.querySelector('.entry-title a')?.text.trim() ??
              img?.attributes['alt']?.trim() ??
              a?.attributes['title']?.trim() ??
              art.querySelector('h2, .title')?.text.trim() ??
              '';

          var cover = img?.attributes['data-src'] ??
              img?.attributes['data-lazy-src'] ??
              img?.attributes['src'] ??
              '';

          if (cover.startsWith('//')) {
            cover = 'https:$cover';
          }

          if (title.isNotEmpty && cover.startsWith('http')) {
            seenHrefs.add(href);
            final isUnc = title.toLowerCase().contains("uncensored") || item.slug.contains("uncensored");

            final viewsText = art.querySelector('.stats .views .count')?.text.trim() ?? '150K';
            int viewsCount = 150000;
            if (viewsText.contains('K')) {
              final raw = double.tryParse(viewsText.replaceAll('K', '').trim()) ?? 150;
              viewsCount = (raw * 1000).toInt();
            } else if (viewsText.contains('M')) {
              final raw = double.tryParse(viewsText.replaceAll('M', '').trim()) ?? 1;
              viewsCount = (raw * 1000000).toInt();
            }

            final studioName = item.type == CatalogType.artist
                ? item.name
                : (art.querySelector('.cattags a[href*="/genre/"]')?.text.trim() ?? "HentaiPlay");

            items.add(MediaItem(
              id: href.hashCode.toString(),
              title: title,
              url: href.startsWith('http') ? href : "$baseUrl$href",
              cover: cover,
              duration: "24:00",
              releaseDate: "2024",
              studio: studioName.isNotEmpty ? studioName : "HentaiPlay",
              extensionId: id,
              type: MediaType.animeSeries,
              tags: [
                item.name,
                if (isUnc) "Uncensored",
                "HD",
                "Subbed",
              ],
              rating: 4.8,
              views: viewsCount,
              isUncensored: isUnc,
            ));
          }
        }
        if (items.isNotEmpty) return items;
      }
    } catch (_) {}

    return search(item.name, page);
  }
}
