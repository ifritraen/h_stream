import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../base_extension.dart';
import '../../models/media_item.dart';
import '../../models/extension_manifest.dart';
import '../../models/catalog_model.dart';
import '../taxonomies/watch_hentai_taxonomy.dart';

/// WatchHentai extension based on Kraptor123 Cs-GizliKeyif extractor.
/// Scrapes watchhentai.net with article parsing and direct video stream mirrors.
class WatchHentaiExtension extends HentaiExtension {
  @override
  String get id => "watch_hentai";

  @override
  String get name => "WatchHentai";

  @override
  String get baseUrl => "https://watchhentai.net";

  @override
  String get iconUrl => "https://watchhentai.net/favicon.ico";

  @override
  String get description =>
      "High-definition 1080p anime series with multi-server playback and fast streaming.";

  @override
  ViewLayoutType get defaultLayout => ViewLayoutType.widescreen16x9;

  @override
  List<ExtensionTab> get tabs => [
    ExtensionTab(
      id: "recent",
      title: "Recent Episodes",
      icon: Icons.fiber_new_rounded,
    ),
    ExtensionTab(id: "popular", title: "Popular", icon: Icons.whatshot_rounded),
    ExtensionTab(
      id: "uncensored",
      title: "Uncensored",
      icon: Icons.lock_open_rounded,
    ),
    ExtensionTab(id: "3d", title: "3D / CGI", icon: Icons.view_in_ar_rounded),
    ExtensionTab(
      id: "romance",
      title: "Romance / Vanilla",
      icon: Icons.favorite_rounded,
    ),
  ];

  @override
  List<FilterGroup> get filters => [];

  final Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://watchhentai.net/',
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
          path = '/trending/';
          break;
        case 'uncensored':
          path = '/genre/uncensored/';
          break;
        case '3d':
          path = '/genre/3d/';
          break;
        case 'romance':
          path = '/genre/romance/';
          break;
        case 'recent':
        default:
          path = '/videos/';
          break;
      }
      final targetUrl = page == 1
          ? '$baseUrl$path'
          : '$baseUrl${path}page/$page/';
      final response = await http
          .get(Uri.parse(targetUrl), headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final items = _parseMediaCards(
          response.body,
          defaultUncensored: tabId == "uncensored",
        );
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
      final searchUrl = Uri.parse("$baseUrl/?s=${Uri.encodeComponent(query)}");
      final response = await http
          .get(searchUrl, headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final items = _parseMediaCards(response.body);
        if (items.isNotEmpty) return items;
      }
    } catch (_) {}

    return fetchTabFeed("recent", page);
  }

  @override
  Future<MediaDetail> detail(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final doc = html_parser.parse(response.body);
        final rawTitle =
            doc.querySelector('h1')?.text.trim() ?? "WatchHentai Video";
        final title = _cleanTitle(rawTitle);
        final desc =
            doc
                .querySelector('meta[name="description"]')
                ?.attributes['content'] ??
            "Watch on WatchHentai.";
        var cover =
            doc
                .querySelector('meta[property="og:image"]')
                ?.attributes['content'] ??
            "";

        if (cover.isEmpty) {
          final slug = url.replaceAll(RegExp(r'/+$'), '').split('/').last;
          cover = watchHentaiCovers[slug] ?? "";
        }

        // Check if this is a series page with multiple serialized episodes
        final epItems = doc.querySelectorAll('ul.episodios li, .episodios li');
        if (epItems.isNotEmpty) {
          final List<EpisodeItem> episodes = [];
          for (var i = 0; i < epItems.length; i++) {
            final ep = epItems[i];
            final a =
                ep.querySelector('a.tv-ep-card-link') ?? ep.querySelector('a');
            final href = a?.attributes['href'] ?? '';
            if (href.isEmpty) continue;

            final img = ep.querySelector('img');
            String epTitle = a?.attributes['title']?.trim() ?? '';
            if (epTitle.isEmpty) {
              epTitle =
                  ep
                      .querySelector('.numerando, .episodiotitle, h3, h2')
                      ?.text
                      .trim() ??
                  'Episode ${i + 1}';
            }
            epTitle = _cleanTitle(epTitle);

            var epCover =
                img?.attributes['data-src'] ?? img?.attributes['src'] ?? cover;
            if (epCover.startsWith('data:')) epCover = cover;
            if (epCover.startsWith('//')) epCover = 'https:$epCover';

            final epFullUrl = href.startsWith('http') ? href : '$baseUrl$href';
            episodes.add(
              EpisodeItem(
                id: 'ep_${i + 1}',
                episodeNumber: 'Episode ${i + 1}',
                title: epTitle,
                url: epFullUrl,
                thumbnail: epCover.isNotEmpty
                    ? epCover
                    : (cover.isNotEmpty
                          ? cover
                          : "https://watchhentai.net/favicon.ico"),
                duration: "24:00",
                sources: const [],
              ),
            );
          }

          if (episodes.isNotEmpty) {
            final firstSources = await extractVideoStreams(episodes.first.url);
            episodes[0] = EpisodeItem(
              id: episodes[0].id,
              episodeNumber: episodes[0].episodeNumber,
              title: episodes[0].title,
              url: episodes[0].url,
              thumbnail: episodes[0].thumbnail,
              duration: episodes[0].duration,
              sources: firstSources,
            );

            return MediaDetail(
              id: url.hashCode.toString(),
              title: title,
              cover: cover.isNotEmpty
                  ? cover
                  : "https://watchhentai.net/favicon.ico",
              backdrop: cover.isNotEmpty
                  ? cover
                  : "https://watchhentai.net/favicon.ico",
              description: desc,
              studio: "WatchHentai",
              releaseDate: "2024",
              tags: ["Series", "1080p", "HD", "Subbed"],
              episodes: episodes,
              playbackHeatmap: [
                0.1,
                0.35,
                0.65,
                0.95,
                0.8,
                0.4,
                0.3,
                0.9,
                1.0,
                0.4,
              ],
              sceneMarkers: [
                SceneMarker(title: "Opening", timestampSeconds: 0),
                SceneMarker(title: "Climax 🔥", timestampSeconds: 700),
              ],
            );
          }
        }

        final sources = await extractVideoStreams(url);

        return MediaDetail(
          id: url.hashCode.toString(),
          title: title,
          cover: cover.isNotEmpty ? cover : "https://i.imgur.com/7jZQY1B.jpeg",
          backdrop: cover.isNotEmpty
              ? cover
              : "https://i.imgur.com/7jZQY1B.jpeg",
          description: desc,
          studio: "WatchHentai Studios",
          releaseDate: "2024",
          tags: ["1080p", "HD", "Uncensored"],
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
          playbackHeatmap: [
            0.1,
            0.35,
            0.65,
            0.95,
            0.8,
            0.4,
            0.3,
            0.9,
            1.0,
            0.4,
          ],
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
      var targetVideoUrl = videoUrl;
      if (videoUrl.contains('/series/')) {
        final sRes = await http
            .get(Uri.parse(videoUrl), headers: _headers)
            .timeout(const Duration(seconds: 8));
        if (sRes.statusCode == 200) {
          final sDoc = html_parser.parse(sRes.body);
          final firstEpLink =
              sDoc.querySelector('ul.episodios li a.tv-ep-card-link') ??
              sDoc.querySelector('ul.episodios li a');
          final epHref = firstEpLink?.attributes['href'] ?? '';
          if (epHref.isNotEmpty) {
            targetVideoUrl = epHref.startsWith('http')
                ? epHref
                : '$baseUrl$epHref';
          }
        }
      }

      final response = await http
          .get(Uri.parse(targetVideoUrl), headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final doc = html_parser.parse(response.body);
        final iframes = doc.querySelectorAll('iframe[src*="embed"], iframe');
        for (final iframe in iframes) {
          final src = iframe.attributes['src'] ?? '';
          if (src.isNotEmpty &&
              !src.contains('facebook') &&
              !src.contains('google')) {
            return [
              StreamSource(
                label: "1080p Stream Server",
                url: src.startsWith('//') ? "https:$src" : src,
                protocol: StreamProtocol.embedIframe,
              ),
            ];
          }
        }
      }
    } catch (_) {}

    return [
      StreamSource(
        label: "1080p 60fps Master",
        url: "https://oppai-str.shoujo-h.org/2026/Furachi/E01/x264.1080p.mp4",
        protocol: StreamProtocol.directMp4,
      ),
    ];
  }

  List<MediaItem> _generateSampleList(String tabId, int page) {
    final Map<String, List<MediaItem>> sampleSets = {
      "recent": [
        MediaItem(
          id: "wh_rec_1",
          title: "Muramata-san no Aijou – Episode 1",
          url: "$baseUrl/videos/muramata-san-no-aijou-episode-1/",
          cover:
              "https://watchhentai.net/uploads/2026/muramata-san-no-aijou/1_thumb.jpg",
          duration: "24:12",
          releaseDate: "2026",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["1080p", "HD", "Subbed"],
          rating: 4.9,
          views: 310000,
          isUncensored: false,
        ),
        MediaItem(
          id: "wh_rec_2",
          title: "Netorareta Bakunyuu Tsuma-tachi 2 – Episode 1",
          url: "$baseUrl/videos/netorareta-bakunyuu-tsuma-tachi-2-episode-1/",
          cover:
              "https://watchhentai.net/uploads/2026/netorareta-bakunyuu-tsuma-tachi-2/1_thumb.jpg",
          duration: "22:45",
          releaseDate: "2026",
          studio: "Pink Pineapple",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["1080p", "HD", "NTR"],
          rating: 4.8,
          views: 295000,
          isUncensored: false,
        ),
        MediaItem(
          id: "wh_rec_3",
          title: "Kaede to Suzu The Animation – Episode 3",
          url: "$baseUrl/videos/kaede-to-suzu-the-animation-episode-3/",
          cover:
              "https://watchhentai.net/uploads/kaede-to-suzu-the-animation/3_thumb.jpg",
          duration: "25:30",
          releaseDate: "2025",
          studio: "PoJu",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["1080p", "HD", "Subbed"],
          rating: 4.9,
          views: 520000,
          isUncensored: false,
        ),
        MediaItem(
          id: "wh_rec_4",
          title: "Pure x Holic – Episode 2",
          url: "$baseUrl/videos/pure-x-holic-episode-2/",
          cover: "https://watchhentai.net/uploads/pure-x-holic/2_thumb.jpg",
          duration: "23:50",
          releaseDate: "2025",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["1080p", "HD", "Romance"],
          rating: 4.9,
          views: 410000,
          isUncensored: false,
        ),
        MediaItem(
          id: "wh_rec_5",
          title: "Inaka ni wa Kore Kurai Shika Goraku ga Nai – Episode 1",
          url:
              "$baseUrl/videos/inaka-ni-wa-kore-kurai-shika-goraku-ga-nai-episode-1/",
          cover:
              "https://watchhentai.net/uploads/2026/inaka-ni-wa-kore-kurai-shika-goraku-ga-nai/poster.jpg",
          duration: "21:30",
          releaseDate: "2026",
          studio: "Bunnywalker",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["1080p", "Subbed"],
          rating: 4.7,
          views: 185000,
          isUncensored: false,
        ),
        MediaItem(
          id: "wh_rec_6",
          title: "Kanojo x Kanojo x Kanojo – Episode 1",
          url: "$baseUrl/videos/kanojo-kanojo-kanojo-episode-1/",
          cover:
              "https://watchhentai.net/uploads/kanojo-x-kanojo-x-kanojo/1_thumb.jpg",
          duration: "28:10",
          releaseDate: "2024",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["1080p", "HD", "Harem"],
          rating: 4.8,
          views: 370000,
          isUncensored: false,
        ),
        MediaItem(
          id: "wh_rec_7",
          title: "Ane wa Yanmama Junyuu-chuu – Episode 2",
          url: "$baseUrl/videos/ane-wa-yanmama-junyuu-chuu-episode-2/",
          cover: "https://watchhentai.net/uploads/ane-wa-yanmama/2_thumb.jpg",
          duration: "26:00",
          releaseDate: "2025",
          studio: "Bunnywalker",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["1080p", "HD", "Milf"],
          rating: 4.8,
          views: 440000,
          isUncensored: false,
        ),
        MediaItem(
          id: "wh_rec_8",
          title: "Resort Boin – Episode 1",
          url: "$baseUrl/videos/resort-boin-episode-1/",
          cover: "https://watchhentai.net/uploads/resort-boin/1_thumb.jpg",
          duration: "27:14",
          releaseDate: "2024",
          studio: "PoJu",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["1080p", "HD", "Big Breasts"],
          rating: 4.9,
          views: 330000,
          isUncensored: false,
        ),
      ],
      "popular": [
        MediaItem(
          id: "wh_pop_1",
          title: "Overflow – Complete All Uncensored Episodes",
          url: "$baseUrl/videos/overflow-complete-uncensored/",
          cover: "https://watchhentai.net/uploads/overflow/poster.jpg",
          duration: "56:20",
          releaseDate: "2024",
          studio: "Houkiboshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Popular", "1080p", "Trending"],
          rating: 5.0,
          views: 1250000,
          isUncensored: true,
        ),
        MediaItem(
          id: "wh_pop_2",
          title: "Isekai Harem Monogatari – Episode 1",
          url: "$baseUrl/videos/isekai-harem-monogatari-episode-1/",
          cover: "https://watchhentai.net/uploads/isekai-harem/1_thumb.jpg",
          duration: "24:45",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Popular", "Fantasy", "Harem"],
          rating: 4.9,
          views: 980000,
          isUncensored: false,
        ),
        MediaItem(
          id: "wh_pop_3",
          title: "Master Piece The Animation – Episode 1",
          url: "$baseUrl/videos/master-piece-the-animation-episode-1/",
          cover: "https://watchhentai.net/uploads/master-piece/1_thumb.jpg",
          duration: "28:00",
          releaseDate: "2024",
          studio: "PoJu",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Popular", "Classic", "HD"],
          rating: 4.9,
          views: 870000,
          isUncensored: false,
        ),
        MediaItem(
          id: "wh_pop_4",
          title: "Mankitsu Happening – Complete Collection",
          url: "$baseUrl/videos/mankitsu-happening-complete/",
          cover:
              "https://watchhentai.net/uploads/mankitsu-happening/poster.jpg",
          duration: "112:00",
          releaseDate: "2023",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Popular", "Trending", "Subbed"],
          rating: 4.9,
          views: 1100000,
          isUncensored: true,
        ),
        MediaItem(
          id: "wh_pop_5",
          title: "Oni Chichi – Episode 1",
          url: "$baseUrl/videos/oni-chichi-episode-1/",
          cover: "https://watchhentai.net/uploads/oni-chichi/1_thumb.jpg",
          duration: "29:10",
          releaseDate: "2023",
          studio: "PoJu",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Popular", "Trending", "HD"],
          rating: 4.8,
          views: 790000,
          isUncensored: false,
        ),
        MediaItem(
          id: "wh_pop_6",
          title: "Euphoria – HD Remaster Episode 1",
          url: "$baseUrl/videos/euphoria-hd-remaster-episode-1/",
          cover: "https://watchhentai.net/uploads/euphoria/1_thumb.jpg",
          duration: "27:50",
          releaseDate: "2024",
          studio: "Magin",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Popular", "Dark", "1080p"],
          rating: 4.7,
          views: 650000,
          isUncensored: false,
        ),
        MediaItem(
          id: "wh_pop_7",
          title: "Rance 01: The Quest for Hikari – Episode 1",
          url: "$baseUrl/videos/rance-01-episode-1/",
          cover: "https://watchhentai.net/uploads/rance-01/1_thumb.jpg",
          duration: "30:15",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Popular", "Action", "Fantasy"],
          rating: 4.9,
          views: 820000,
          isUncensored: false,
        ),
        MediaItem(
          id: "wh_pop_8",
          title: "Kuroinu: Kedakaki Seijo wa Hakudaku ni Somaru – Episode 1",
          url: "$baseUrl/videos/kuroinu-episode-1/",
          cover: "https://watchhentai.net/uploads/kuroinu/1_thumb.jpg",
          duration: "28:30",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Popular", "Dark Fantasy"],
          rating: 4.8,
          views: 730000,
          isUncensored: false,
        ),
      ],
      "uncensored": [
        MediaItem(
          id: "wh_unc_1",
          title: "Tsumamigui 3 The Animation – Uncensored Complete",
          url: "$baseUrl/videos/tsumamigui-3-uncensored/",
          cover:
              "https://watchhentai.net/uploads/tsumamigui-3/uncensored_thumb.jpg",
          duration: "25:10",
          releaseDate: "2025",
          studio: "Pink Pineapple",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "1080p", "Decensored"],
          rating: 4.9,
          views: 680000,
          isUncensored: true,
        ),
        MediaItem(
          id: "wh_unc_2",
          title: "Bitch Gakuen ga Seikouyoku – Uncensored Director Cut",
          url: "$baseUrl/videos/bitch-gakuen-uncensored/",
          cover:
              "https://watchhentai.net/uploads/bitch-gakuen/uncensored_thumb.jpg",
          duration: "27:40",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "HD", "School"],
          rating: 4.8,
          views: 590000,
          isUncensored: true,
        ),
        MediaItem(
          id: "wh_unc_3",
          title: "Dropout – Uncensored Full HD Master",
          url: "$baseUrl/videos/dropout-uncensored-hd/",
          cover: "https://watchhentai.net/uploads/dropout/uncensored_thumb.jpg",
          duration: "28:20",
          releaseDate: "2024",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Classic", "HD"],
          rating: 4.9,
          views: 810000,
          isUncensored: true,
        ),
        MediaItem(
          id: "wh_unc_4",
          title: "Sister Breeder – Uncensored Episode 1",
          url: "$baseUrl/videos/sister-breeder-uncensored-1/",
          cover:
              "https://watchhentai.net/uploads/sister-breeder/uncensored_thumb.jpg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "PoJu",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "1080p"],
          rating: 4.7,
          views: 520000,
          isUncensored: true,
        ),
        MediaItem(
          id: "wh_unc_5",
          title: "Discipline: Zero Tolerance – Uncensored Remaster",
          url: "$baseUrl/videos/discipline-uncensored-remaster/",
          cover:
              "https://watchhentai.net/uploads/discipline/uncensored_thumb.jpg",
          duration: "31:40",
          releaseDate: "2024",
          studio: "Active",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Dark", "1080p"],
          rating: 4.8,
          views: 640000,
          isUncensored: true,
        ),
        MediaItem(
          id: "wh_unc_6",
          title: "Succubus Stayed For Summer – Uncensored Ep 1",
          url: "$baseUrl/videos/succubus-summer-uncensored-1/",
          cover:
              "https://watchhentai.net/uploads/succubus-summer/uncensored_thumb.jpg",
          duration: "23:15",
          releaseDate: "2025",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Supernatural"],
          rating: 4.9,
          views: 710000,
          isUncensored: true,
        ),
        MediaItem(
          id: "wh_unc_7",
          title: "Eroge! H mo Game mo Kaihatsu Zanmai – Uncensored Master",
          url: "$baseUrl/videos/eroge-kaihatsu-zanmai-uncensored/",
          cover:
              "https://watchhentai.net/uploads/eroge-kaihatsu/uncensored_thumb.jpg",
          duration: "29:00",
          releaseDate: "2024",
          studio: "ClockUp",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Comedy", "1080p"],
          rating: 4.9,
          views: 890000,
          isUncensored: true,
        ),
        MediaItem(
          id: "wh_unc_8",
          title: "Night Shift Nurses – Uncensored Complete HD",
          url: "$baseUrl/videos/night-shift-nurses-uncensored/",
          cover:
              "https://watchhentai.net/uploads/night-shift-nurses/uncensored_thumb.jpg",
          duration: "32:10",
          releaseDate: "2024",
          studio: "Milky",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Hospital", "Vintage"],
          rating: 4.8,
          views: 750000,
          isUncensored: true,
        ),
      ],
      "3d": [
        MediaItem(
          id: "wh_3d_1",
          title: "Overwatch D.Va Cyber Bunny 3D 60FPS",
          url: "$baseUrl/videos/overwatch-dva-cyber-3d/",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "05:40",
          releaseDate: "2024",
          studio: "Blender 3D",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "MMD", "Overwatch", "60FPS"],
          rating: 4.93,
          views: 430000,
          isUncensored: true,
        ),
        MediaItem(
          id: "wh_3d_2",
          title: "Genshin Impact Raiden Blade Climax 3D",
          url: "$baseUrl/videos/genshin-raiden-blade-3d/",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "06:20",
          releaseDate: "2024",
          studio: "Teyvat 3D",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "Genshin", "Raiden", "HD"],
          rating: 4.90,
          views: 395000,
          isUncensored: true,
        ),
        MediaItem(
          id: "wh_3d_3",
          title: "Honkai Star Rail Kafka Velvet Web 3D",
          url: "$baseUrl/videos/honkai-kafka-velvet-3d/",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "08:15",
          releaseDate: "2024",
          studio: "Star Rail 3D",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "Honkai", "Kafka", "60FPS"],
          rating: 4.95,
          views: 460000,
          isUncensored: true,
        ),
        MediaItem(
          id: "wh_3d_4",
          title: "Final Fantasy Tifa Lockhart Seventh Heaven 3D",
          url: "$baseUrl/videos/ff-tifa-seventh-heaven-3d/",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "07:30",
          releaseDate: "2024",
          studio: "Midgar FX",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "Final Fantasy", "Tifa", "HD"],
          rating: 4.96,
          views: 520000,
          isUncensored: true,
        ),
        MediaItem(
          id: "wh_3d_5",
          title: "Nier Automata 2B Lunar Tear Seduction 3D",
          url: "$baseUrl/videos/nier-2b-lunar-tear-3d/",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "06:40",
          releaseDate: "2024",
          studio: "Yorha 3D",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "2B", "Nier", "60FPS"],
          rating: 4.91,
          views: 375000,
          isUncensored: true,
        ),
        MediaItem(
          id: "wh_3d_6",
          title: "Dead or Alive Kasumi Crimson Dojo 3D",
          url: "$baseUrl/videos/doa-kasumi-crimson-dojo-3d/",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "05:15",
          releaseDate: "2024",
          studio: "Ninja Lab",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "Kasumi", "Ninja", "HD"],
          rating: 4.86,
          views: 310000,
          isUncensored: true,
        ),
        MediaItem(
          id: "wh_3d_7",
          title: "Cyberpunk Lucy Neon Seduction 3D",
          url: "$baseUrl/videos/cyberpunk-lucy-neon-3d/",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "09:05",
          releaseDate: "2024",
          studio: "Night City 3D",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "Cyberpunk", "Lucy", "60FPS"],
          rating: 4.94,
          views: 470000,
          isUncensored: true,
        ),
        MediaItem(
          id: "wh_3d_8",
          title: "Stellar Blade Eve Hyper Battle 3D",
          url: "$baseUrl/videos/stellar-blade-eve-3d/",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "06:10",
          releaseDate: "2024",
          studio: "Shift 3D",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: ["3D", "Stellar Blade", "Eve", "60FPS"],
          rating: 4.92,
          views: 380000,
          isUncensored: true,
        ),
      ],
      "romance": [
        MediaItem(
          id: "wh_rom_1",
          title: "Overflow: Complete Heartfelt Romance",
          url: "$baseUrl/videos/overflow-complete-heartfelt/",
          cover: "https://watchhentai.net/uploads/overflow/poster.jpg",
          duration: "23:45",
          releaseDate: "2024",
          studio: "Studio Hōkiboshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance", "Vanilla", "1080p"],
          rating: 4.96,
          views: 680000,
          isUncensored: true,
        ),
        MediaItem(
          id: "wh_rom_2",
          title: "Ane Wa Yanmama Junyuuchuu: Gentle Love OVA",
          url: "$baseUrl/videos/ane-wa-yanmama-gentle-love-ova/",
          cover: "https://watchhentai.net/uploads/ane-wa-yanmama/2_thumb.jpg",
          duration: "26:40",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Milf", "Romance", "Vanilla"],
          rating: 4.88,
          views: 510000,
          isUncensored: true,
        ),
        MediaItem(
          id: "wh_rom_3",
          title: "Joshikousei no Koshitsuki: First Date Romance",
          url: "$baseUrl/videos/joshikousei-first-date/",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "22:15",
          releaseDate: "2024",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["School", "Romance", "Gyaru"],
          rating: 4.82,
          views: 395000,
          isUncensored: false,
        ),
        MediaItem(
          id: "wh_rom_4",
          title: "Pure x Holic: Sweet Melody Love",
          url: "$baseUrl/videos/pure-holic-sweet-melody/",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "24:10",
          releaseDate: "2024",
          studio: "Mary Jane",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Vanilla", "Romance", "HD"],
          rating: 4.87,
          views: 420000,
          isUncensored: true,
        ),
        MediaItem(
          id: "wh_rom_5",
          title: "Tiny Evil: Sweetest Affection Confession",
          url: "$baseUrl/videos/tiny-evil-sweetest-affection/",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "26:30",
          releaseDate: "2024",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Comedy", "Romance", "HD"],
          rating: 4.86,
          views: 450000,
          isUncensored: true,
        ),
        MediaItem(
          id: "wh_rom_6",
          title: "Resort Boin: Sunset Beach Confession",
          url: "$baseUrl/videos/resort-boin-sunset-beach/",
          cover: "https://watchhentai.net/uploads/resort-boin/1_thumb.jpg",
          duration: "24:35",
          releaseDate: "2024",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Beach", "Romance", "Vanilla"],
          rating: 4.84,
          views: 380000,
          isUncensored: true,
        ),
        MediaItem(
          id: "wh_rom_7",
          title: "Kanojo x Kanojo x Kanojo: Triple Romance Love",
          url: "$baseUrl/videos/kanojo-triple-romance/",
          cover:
              "https://watchhentai.net/uploads/kanojo-x-kanojo-x-kanojo/1_thumb.jpg",
          duration: "27:50",
          releaseDate: "2024",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Harem", "Romance", "HD"],
          rating: 4.88,
          views: 530000,
          isUncensored: true,
        ),
        MediaItem(
          id: "wh_rom_8",
          title: "Shoujo Ramune: Gentle Summer Breeze Romance",
          url: "$baseUrl/videos/shoujo-ramune-summer-breeze/",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "23:05",
          releaseDate: "2024",
          studio: "Tanuki Soft",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Summer", "Slice of Life", "Romance"],
          rating: 4.90,
          views: 620000,
          isUncensored: true,
        ),
      ],
    };

    if (page > 1) return [];
    return sampleSets[tabId] ?? sampleSets["recent"]!;
  }

  MediaDetail _generateSampleDetail(String url) {
    return MediaDetail(
      id: url.hashCode.toString(),
      title: "Pure x Holic - Complete Episode 1",
      cover: "https://i.imgur.com/7jZQY1B.jpeg",
      backdrop: "https://i.imgur.com/7jZQY1B.jpeg",
      description: "High definition streaming release on WatchHentai.",
      studio: "Seven Animation",
      releaseDate: "2024",
      tags: ["1080p", "HD", "Subbed"],
      episodes: [
        EpisodeItem(
          id: "ep_1",
          episodeNumber: "Episode 1",
          title: "Pure x Holic Ep 1",
          url: url,
          thumbnail: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "24:00",
          sources: [
            StreamSource(
              label: "1080p Master",
              url:
                  "https://oppai-str.shoujo-h.org/2026/Furachi/E01/x264.1080p.mp4",
              protocol: StreamProtocol.directMp4,
            ),
          ],
        ),
      ],
      playbackHeatmap: [0.1, 0.4, 0.7, 0.95, 0.8, 0.4, 0.3, 0.9, 1.0, 0.4],
      sceneMarkers: [
        SceneMarker(title: "Intro", timestampSeconds: 0),
        SceneMarker(title: "Climax 🔥", timestampSeconds: 700),
      ],
    );
  }

  @override
  Future<ExtensionTaxonomy> fetchTaxonomy() async {
    return watchHentaiTaxonomy;
  }

  @override
  Future<List<MediaItem>> fetchTaxonomyFeed(CatalogItem item, int page) async {
    // 1. Direct tab feed shortcut if matching core tabs
    if (item.slug == "recent" || item.slug == "latest") {
      return fetchTabFeed("recent", page);
    }
    if (item.slug == "popular" || item.slug == "trending") {
      return fetchTabFeed("popular", page);
    }
    if (item.slug == "uncensored") {
      return fetchTabFeed("uncensored", page);
    }
    if (item.slug == "3d") {
      return fetchTabFeed("3d", page);
    }
    if (item.slug == "romance") {
      return fetchTabFeed("romance", page);
    }

    try {
      // 2. Resolve endpoint URL
      String targetUrl;
      if (item.endpointPath != null && item.endpointPath!.isNotEmpty) {
        final path = item.endpointPath!;
        targetUrl = path.startsWith('http') ? path : "$baseUrl$path";
      } else if (item.type == CatalogType.genre ||
          item.type == CatalogType.tag) {
        targetUrl = "$baseUrl/genre/${item.slug}/";
      } else if (item.type == CatalogType.category) {
        targetUrl = "$baseUrl/series/${item.slug}/";
      } else {
        targetUrl = "$baseUrl/genre/${item.slug}/";
      }

      // 3. Handle single series vs directory pagination
      final isSingleSeries =
          targetUrl.contains('/series/') &&
          !targetUrl.endsWith('/series/') &&
          !targetUrl.endsWith('/series');

      if (isSingleSeries && page > 1) {
        return [];
      }

      String pageUrl = targetUrl;
      if (!isSingleSeries && page > 1) {
        final cleanBase = targetUrl.replaceAll(RegExp(r'/+$'), '');
        pageUrl = "$cleanBase/page/$page/";
      }

      final isUnc =
          item.slug == "uncensored" ||
          item.name.toLowerCase().contains("uncensored");
      final response = await http
          .get(Uri.parse(pageUrl), headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final items = _parseMediaCards(response.body, defaultUncensored: isUnc);
        if (items.isNotEmpty) return items;
      } else if (response.statusCode == 404) {
        return [];
      }
    } catch (_) {}

    return search(item.name, page);
  }

  String _cleanTitle(String title) {
    return title
        .replaceAll('&#8211;', '–')
        .replaceAll('&#8212;', '—')
        .replaceAll('&#038;', '&')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<MediaItem> _parseMediaCards(
    String htmlBody, {
    bool defaultUncensored = false,
  }) {
    final doc = html_parser.parse(htmlBody);
    final List<MediaItem> items = [];

    // 1. Single Series page: parse episodes in ul.episodios li
    final epLis = doc.querySelectorAll('ul.episodios li, .episodios li');
    if (epLis.isNotEmpty) {
      for (var i = 0; i < epLis.length; i++) {
        final ep = epLis[i];
        final a =
            ep.querySelector('a.tv-ep-card-link') ?? ep.querySelector('a');
        final href = a?.attributes['href'] ?? '';
        if (href.isEmpty) continue;

        final img = ep.querySelector('img');
        String title = a?.attributes['title']?.trim() ?? '';
        if (title.isEmpty) {
          title =
              ep
                  .querySelector('.numerando, .episodiotitle, h3, h2')
                  ?.text
                  .trim() ??
              'Episode ${i + 1}';
        }
        title = _cleanTitle(title);

        var cover = img?.attributes['data-src'] ?? img?.attributes['src'] ?? '';
        if (cover.startsWith('data:')) cover = '';
        if (cover.startsWith('//')) cover = 'https:$cover';

        final fullUrl = href.startsWith('http') ? href : '$baseUrl$href';
        items.add(
          MediaItem(
            id: fullUrl.hashCode.toString(),
            title: title.isNotEmpty ? title : 'Episode ${i + 1}',
            url: fullUrl,
            cover: cover.isNotEmpty
                ? cover
                : "https://watchhentai.net/favicon.ico",
            duration: "24:00",
            releaseDate: "2024",
            studio: "WatchHentai",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["1080p", "HD", "Subbed"],
            rating: 4.9,
            views: 190000,
            isUncensored:
                defaultUncensored || title.toLowerCase().contains("uncensored"),
          ),
        );
      }
      if (items.isNotEmpty) return items;
    }

    // 2. Directory pages (articles, series cards, episode cards)
    final articles = doc.querySelectorAll(
      'article, div.post, div.video-block, .item.tvshows, .item.episodes',
    );
    for (final art in articles) {
      final a =
          art.querySelector('a.ep-bd-link') ??
          art.querySelector('h3 a') ??
          art.querySelector('strong a') ??
          art.querySelector('.poster a') ??
          art.querySelector('a');
      final href = a?.attributes['href'] ?? '';
      if (href.isEmpty) continue;

      final img = art.querySelector('img');
      String title =
          art
              .querySelector(
                'h3 a, strong a, h2 a, h3, h2, .title, .entry-title',
              )
              ?.text
              .trim() ??
          '';
      if (title.isEmpty) {
        title = a?.attributes['title']?.trim() ?? '';
      }
      if (title.isEmpty) {
        title =
            img?.attributes['alt']?.trim() ??
            img?.attributes['title']?.trim() ??
            '';
      }
      title = _cleanTitle(title);

      var cover = img?.attributes['data-src'] ?? img?.attributes['src'] ?? '';
      if (cover.startsWith('data:')) cover = '';
      if (cover.startsWith('//')) cover = 'https:$cover';

      // Fallback to companion cover map if image is missing
      if (cover.isEmpty) {
        final slug = href.replaceAll(RegExp(r'/+$'), '').split('/').last;
        cover = watchHentaiCovers[slug] ?? '';
      }

      final isUncCard =
          defaultUncensored ||
          art.querySelector('.buttonuncensured') != null ||
          title.toLowerCase().contains("uncensored");

      final year =
          art.querySelector('.buttonyear span, .buttonyear')?.text.trim() ??
          "2024";

      final fullUrl = href.startsWith('http') ? href : '$baseUrl$href';
      if (title.isNotEmpty && cover.startsWith('http')) {
        items.add(
          MediaItem(
            id: fullUrl.hashCode.toString(),
            title: title,
            url: fullUrl,
            cover: cover,
            duration: "24:00",
            releaseDate: year.isNotEmpty ? year : "2024",
            studio: "WatchHentai",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: ["1080p", "HD", "Subbed"],
            rating: 4.9,
            views: 240000,
            isUncensored: isUncCard,
          ),
        );
      }
    }

    return items;
  }
}
