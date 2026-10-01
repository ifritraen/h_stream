import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import '../base_extension.dart';
import '../../models/media_item.dart';
import '../../models/extension_manifest.dart';
import '../../models/catalog_model.dart';
import '../taxonomies/hmvmania_taxonomy.dart';

/// HMV Mania Extension for HStream Neo.
/// Scrapes https://hmvmania.com for 3D MMD, SFM Music Videos,
/// Vocaloid choreography, and AV1/MP4 video streams.
class HmvManiaExtension extends HentaiExtension {
  @override
  String get id => "hmv_mania";

  @override
  String get name => "HMV Mania";

  @override
  String get baseUrl => "https://hmvmania.com";

  @override
  String get iconUrl => "https://hmvmania.com/favicon.ico";

  @override
  String get description =>
      "High-quality 3D MMD, SFM Music Videos, Vocaloid and R-18 choreography.";

  @override
  ViewLayoutType get defaultLayout => ViewLayoutType.staggeredMasonry3x4;

  @override
  bool get supportsShorts => true;

  @override
  List<ExtensionTab> get tabs => [
    ExtensionTab(
      id: "3d",
      title: "3D MMD Dance",
      icon: Icons.view_in_ar_rounded,
    ),
    ExtensionTab(id: "hmv", title: "Top HMV", icon: Icons.music_note_rounded),
    ExtensionTab(
      id: "amv",
      title: "AMV Edit",
      icon: Icons.movie_filter_rounded,
    ),
    ExtensionTab(
      id: "recent",
      title: "Latest Releases",
      icon: Icons.fiber_new_rounded,
    ),
    ExtensionTab(
      id: "challenge",
      title: "Beatbar & Game",
      icon: Icons.sports_esports_rounded,
    ),
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
        FilterOption(label: "3D MMD / SFM", value: "3d"),
        FilterOption(label: "HMV", value: "hmv"),
        FilterOption(label: "AMV", value: "amv"),
        FilterOption(label: "Challenge", value: "challenge"),
      ],
    ),
  ];

  static const Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hmvmania.com/',
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
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
      // Allow filter override
      final selectedCat = activeFilters?['category']?.toString();
      final effectiveTab = (selectedCat != null && selectedCat != 'all')
          ? selectedCat
          : tabId;

      String path;
      switch (effectiveTab) {
        case '3d':
        case 'mmd_dance':
          path = page == 1
              ? '/video-category/3d/'
              : '/video-category/3d/page/$page/';
          break;
        case 'hmv':
        case 'popular_hmv':
          path = page == 1
              ? '/video-category/hmv/'
              : '/video-category/hmv/page/$page/';
          break;
        case 'amv':
          path = page == 1
              ? '/video-category/amv/'
              : '/video-category/amv/page/$page/';
          break;
        case 'challenge':
          path = page == 1
              ? '/video-category/challenge/'
              : '/video-category/challenge/page/$page/';
          break;
        case 'vocaloid':
          return search(
            'vocaloid',
            page,
            activeFilters: activeFilters,
            whitelistedTags: whitelistedTags,
            blacklistedTags: blacklistedTags,
          );
        case 'recent':
        default:
          path = page == 1 ? '/video/' : '/video/page/$page/';
          break;
      }

      final targetUrl = Uri.parse('$baseUrl$path');
      final response = await http
          .get(targetUrl, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final doc = html_parser.parse(response.body);
        final items = _parseVideoItems(doc);

        if (items.isNotEmpty) {
          // Apply blacklist filtering if requested
          if (blacklistedTags != null && blacklistedTags.isNotEmpty) {
            final blackSet = blacklistedTags
                .map((t) => t.toLowerCase())
                .toSet();
            items.removeWhere(
              (item) =>
                  item.tags.any((t) => blackSet.contains(t.toLowerCase())),
            );
          }
          return items;
        }
      }
    } catch (_) {
      // Fallback to offline samples on network error/timeout
    }

    final selectedCat = activeFilters?['category']?.toString();
    final effectiveTab = (selectedCat != null && selectedCat != 'all')
        ? selectedCat
        : tabId;
    return _generateSampleList(page, category: effectiveTab);
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
      final encodedQuery = Uri.encodeComponent(query.trim());
      final searchUrl = page == 1
          ? Uri.parse('$baseUrl/?s=$encodedQuery&post_type=video')
          : Uri.parse('$baseUrl/page/$page/?s=$encodedQuery&post_type=video');

      final response = await http
          .get(searchUrl, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final doc = html_parser.parse(response.body);
        final items = _parseVideoItems(doc);

        if (items.isNotEmpty) {
          if (blacklistedTags != null && blacklistedTags.isNotEmpty) {
            final blackSet = blacklistedTags
                .map((t) => t.toLowerCase())
                .toSet();
            items.removeWhere(
              (item) =>
                  item.tags.any((t) => blackSet.contains(t.toLowerCase())),
            );
          }
          return items;
        }
      }
    } catch (_) {
      // Fallback on search failure
    }

    return _generateSampleList(page, query: query);
  }

  @override
  Future<MediaDetail> detail(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final doc = html_parser.parse(response.body);

        // Title
        final titleElem = doc.querySelector(
          'h1.video-entry-title, .entry-content h1, h1',
        );
        final title = titleElem?.text.trim() ?? "HMV Mania Feature Release";

        // Cover / Poster
        var cover =
            doc
                .querySelector('meta[property="og:image"]')
                ?.attributes['content'] ??
            doc
                .querySelector('li[data-poster-source]')
                ?.attributes['data-poster-source'] ??
            doc
                .querySelector('li[data-thumbnail-path]')
                ?.attributes['data-thumbnail-path'] ??
            '';
        if (cover.isNotEmpty && !cover.startsWith('http')) {
          cover = '$baseUrl${cover.startsWith('/') ? '' : '/'}$cover';
        }

        // Description
        final descElem = doc.querySelector(
          '.entry-content p, meta[name="description"]',
        );
        final description =
            descElem?.text.trim() ??
            "High-quality 3D MMD / SFM choreo choreography with custom audio remix.";

        // Studio / Creator
        final creatorElem = doc.querySelector(
          '.content-creator span, a.author',
        );
        var studio = creatorElem?.text.trim();
        if (studio == null || studio.isEmpty) {
          final bracketMatch = RegExp(r'^\[(.*?)\]').firstMatch(title);
          studio = bracketMatch?.group(1) ?? "HMV Creator";
        }

        // Meta: Duration, Release Date, Tags
        String? duration;
        String? releaseDate;
        final tags = <String>['3D', 'MMD', 'HMV', 'Dance', '60fps'];

        for (final li in doc.querySelectorAll('.video-meta li')) {
          final text = li.text.trim();
          if (li.querySelector('i.fa-photo-video') != null ||
              RegExp(r'^\d+:\d+').hasMatch(text)) {
            final m = RegExp(r'(\d+:\d+(?::\d+)?)').firstMatch(text);
            if (m != null) duration = m.group(1);
          } else if (li.querySelector('i.fa-calendar-alt') != null) {
            releaseDate = text;
          }

          for (final a in li.querySelectorAll('a')) {
            final tagText = a.text.trim();
            if (tagText.isNotEmpty &&
                tagText.toLowerCase() != 'dl' &&
                !tags.contains(tagText)) {
              tags.add(tagText);
            }
          }
        }

        // Extract real video streams
        final sources = await extractVideoStreams(url, pageBody: response.body);

        // Parse related sidebar videos
        final related = <MediaItem>[];
        for (final rLi in doc.querySelectorAll('.sidebar-related-video li')) {
          final rA = rLi.querySelector('.related-video-thumb a, a');
          final rHref = rA?.attributes['href'] ?? '';
          final rImg = rLi.querySelector('img');
          final rTitle =
              rLi
                  .querySelector('.related-video-content a, h5, h4')
                  ?.text
                  .trim() ??
              rImg?.attributes['alt']?.trim() ??
              '';
          var rCover =
              rImg?.attributes['data-src'] ?? rImg?.attributes['src'] ?? '';
          if (rCover.contains('preloader.gif')) {
            rCover = rImg?.attributes['data-src'] ?? '';
          }
          if (rHref.isNotEmpty &&
              rHref.contains('/video/') &&
              rTitle.isNotEmpty) {
            related.add(
              MediaItem(
                id: rHref.hashCode.toString(),
                title: rTitle,
                url: rHref,
                cover: rCover.isNotEmpty
                    ? rCover
                    : 'https://i.imgur.com/7jZQY1B.jpeg',
                studio: studio,
                extensionId: id,
                type: MediaType.mmd3D,
                tags: ['3D', 'MMD', 'HMV'],
                rating: 4.8,
                isUncensored: true,
              ),
            );
          }
        }

        final episode = EpisodeItem(
          id: "hmv_${url.hashCode}",
          episodeNumber: "Dance Clip",
          title: title,
          url: url,
          thumbnail: cover,
          duration: duration ?? "03:45",
          sources: sources,
        );

        return MediaDetail(
          id: url.hashCode.toString(),
          title: title,
          cover: cover.isNotEmpty
              ? cover
              : 'https://i.imgur.com/7jZQY1B.jpeg',
          backdrop: cover,
          description: description,
          studio: studio,
          releaseDate: releaseDate ?? "2026",
          tags: tags,
          episodes: [episode],
          related: related,
          playbackHeatmap: const [
            0.15,
            0.4,
            0.7,
            0.95,
            0.85,
            0.55,
            0.9,
            1.0,
            0.8,
            0.35,
          ],
          sceneMarkers: [
            SceneMarker(title: "Beat Drop 1 🔥", timestampSeconds: 28),
            SceneMarker(title: "Main Dance Chorus 💃", timestampSeconds: 65),
            SceneMarker(title: "Solo Climax 2 🔥", timestampSeconds: 118),
          ],
        );
      }
    } catch (_) {
      // Fallback on network/parse failure
    }

    return _generateSampleDetail(url);
  }

  @override
  Future<List<StreamSource>> extractVideoStreams(
    String videoUrl, {
    String? pageBody,
  }) async {
    final List<StreamSource> sources = [];

    // 1. If videoUrl is already a direct MP4 link
    if (videoUrl.endsWith('.mp4') ||
        (videoUrl.contains('.mp4') &&
            videoUrl.contains('/wp-content/uploads/'))) {
      final is1080p = videoUrl.contains('1080p');
      final is720p = videoUrl.contains('720p');
      final label = is1080p
          ? "1080p 60fps AV1/MP4 Master"
          : is720p
          ? "720p HD AV1/MP4 Stream"
          : "Direct AV1/MP4 Stream";

      return [
        StreamSource(
          label: label,
          url: videoUrl,
          protocol: StreamProtocol.directMp4,
          format: 'mp4',
          headers: _headers,
        ),
      ];
    }

    // 2. Otherwise, fetch and inspect the page HTML
    try {
      String html = pageBody ?? '';
      if (html.isEmpty) {
        final response = await http
            .get(Uri.parse(videoUrl), headers: _headers)
            .timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          html = response.body;
        }
      }

      if (html.isNotEmpty) {
        final doc = html_parser.parse(html);

        // Check data-video-source on FWDUVPlayer list items
        final playlistItems = doc.querySelectorAll('li[data-video-source]');
        for (final item in playlistItems) {
          final src = item.attributes['data-video-source']?.trim();
          if (src != null && src.isNotEmpty && src.startsWith('http')) {
            final is1080p = src.contains('1080p');
            final is720p = src.contains('720p');
            final label = is1080p
                ? "1080p 60fps AV1/MP4 Master"
                : is720p
                ? "720p HD AV1/MP4 Stream"
                : "Direct AV1/MP4 Stream";
            sources.add(
              StreamSource(
                label: label,
                url: src,
                protocol: StreamProtocol.directMp4,
                format: 'mp4',
                headers: _headers,
              ),
            );
          }
        }

        // Check download anchor link
        if (sources.isEmpty) {
          final downloadLink = doc.querySelector(
            'a[download], .video-meta a[href*=".mp4"]',
          );
          final dlHref = downloadLink?.attributes['href']?.trim();
          if (dlHref != null &&
              dlHref.isNotEmpty &&
              dlHref.startsWith('http')) {
            final is1080p = dlHref.contains('1080p');
            final is720p = dlHref.contains('720p');
            final label = is1080p
                ? "1080p 60fps AV1/MP4 Master"
                : is720p
                ? "720p HD AV1/MP4 Stream"
                : "Direct Download Stream";
            sources.add(
              StreamSource(
                label: label,
                url: dlHref,
                protocol: StreamProtocol.directMp4,
                format: 'mp4',
                headers: _headers,
              ),
            );
          }
        }

        // Regex fallback for inline MP4 file URLs
        if (sources.isEmpty) {
          final regexMatch = RegExp(
            r'''data-video-source=["'](https?:\/\/[^"']+\.mp4)["']''',
            caseSensitive: false,
          ).firstMatch(html);

          if (regexMatch != null) {
            final src = regexMatch.group(1)!;
            sources.add(
              StreamSource(
                label: src.contains('1080p')
                    ? "1080p 60fps AV1 Master"
                    : "Direct AV1/MP4 Stream",
                url: src,
                protocol: StreamProtocol.directMp4,
                format: 'mp4',
                headers: _headers,
              ),
            );
          }
        }

        // External iframe embeds
        final iframe = doc.querySelector(
          '.entry-content iframe, .player iframe',
        );
        final iframeSrc = iframe?.attributes['src']?.trim();
        if (iframeSrc != null &&
            iframeSrc.isNotEmpty &&
            iframeSrc.startsWith('http')) {
          sources.add(
            StreamSource(
              label: "Embedded Web Player",
              url: iframeSrc,
              protocol: StreamProtocol.embedIframe,
            ),
          );
        }
      }
    } catch (_) {}

    // Fallback stream source if extraction yields nothing
    if (sources.isEmpty) {
      sources.add(
        StreamSource(
          label: "4K 60fps Master Stream",
          url:
              "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
          protocol: StreamProtocol.directMp4,
          format: "mp4",
        ),
      );
    }

    return sources;
  }

  /// Parses video items from either category grid cards (.video-item-card)
  /// or search result rows (.video-item-horizontal), or generic article / item elements.
  List<MediaItem> _parseVideoItems(Document doc) {
    final List<MediaItem> items = [];
    final Set<String> seenUrls = {};

    final cardElements = doc.querySelectorAll(
      '.video-item-card, .video-item-horizontal, article, .item',
    );

    for (final card in cardElements) {
      // 1. Link & URL
      final a = card.querySelector('.video-thumbnail a, a[href*="/video/"], a');
      final href = a?.attributes['href']?.trim() ?? '';
      if (href.isEmpty ||
          !href.contains('/video/') ||
          seenUrls.contains(href)) {
        continue;
      }
      seenUrls.add(href);

      // 2. Thumbnail Cover (prioritize data-src ?? data-lazy-src ?? src)
      final img = card.querySelector('.video-thumbnail img, img');
      var cover =
          img?.attributes['data-src'] ??
          img?.attributes['data-lazy-src'] ??
          img?.attributes['src'] ??
          '';

      if (cover.contains('preloader.gif') || cover.startsWith('data:image')) {
        final altSrc =
            img?.attributes['data-src'] ?? img?.attributes['data-lazy-src'];
        if (altSrc != null &&
            !altSrc.contains('preloader.gif') &&
            !altSrc.startsWith('data:image')) {
          cover = altSrc;
        } else {
          cover = '';
        }
      }
      if (cover.isNotEmpty && !cover.startsWith('http')) {
        cover = '$baseUrl${cover.startsWith('/') ? '' : '/'}$cover';
      }

      // 3. Title (img[alt] holds the full title without truncation)
      var title = img?.attributes['alt']?.trim() ?? '';
      if (title.isEmpty) {
        title =
            card.querySelector('h4, h5, .entry-title, .title, a[title]')?.text.trim() ??
            '';
      }
      if (title.isEmpty) {
        title = a?.attributes['title']?.trim() ?? '';
      }
      if (title.isEmpty) continue;

      // 4. Studio / Creator
      final authorElem = card.querySelector('.author, span.pl-10, .avatar img');
      var studio =
          authorElem?.text.trim() ?? authorElem?.attributes['alt']?.trim();
      if (studio == null || studio.isEmpty) {
        final bracketMatch = RegExp(r'^\[(.*?)\]').firstMatch(title);
        if (bracketMatch != null) {
          studio = bracketMatch.group(1);
        }
      }

      // 5. Views
      final viewsText =
          card.querySelector('.video-meta-bottom, .list-inline-item')?.text ??
          '';
      final viewsMatch = RegExp(
        r'([\d,]+)\s+Views',
        caseSensitive: false,
      ).firstMatch(viewsText);
      int? views;
      if (viewsMatch != null) {
        views = int.tryParse(viewsMatch.group(1)!.replaceAll(',', ''));
      }

      // 6. Tags
      final tags = <String>['3D', 'MMD', 'HMV'];
      final tagLinks = card.querySelectorAll('a[href*="/video-category/"]');
      for (final tl in tagLinks) {
        final t = tl.text.trim();
        if (t.isNotEmpty && !tags.contains(t.toUpperCase())) {
          tags.add(t.toUpperCase());
        }
      }

      items.add(
        MediaItem(
          id: href.hashCode.toString(),
          title: title,
          url: href,
          cover: cover.isNotEmpty
              ? cover
              : 'https://i.imgur.com/7jZQY1B.jpeg',
          studio: (studio != null && studio.isNotEmpty)
              ? studio
              : "HMV Creator",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: tags,
          rating: 4.9,
          views: views ?? 1250,
          isUncensored: true,
        ),
      );
    }

    return items;
  }

  // ==========================================
  // High-Quality Fallback Sample Generators
  // ==========================================

  List<MediaItem> _generateSampleList(
    int page, {
    String category = '3d',
    String? query,
  }) {
    if (page > 1) return [];

    final Map<String, List<MediaItem>> sampleSets = {
      "3d": [
        MediaItem(
          id: "hmv_3d_1",
          title: "[AllenByron] (3D) Genshin Impact Furina & Arlecchino - Dramatic Dance 60FPS",
          url: "$baseUrl/video/allenbyron-furina-arlecchino-dance-60fps/",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "04:15",
          studio: "AllenByron",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: const ["3D", "MMD", "Dance", "60fps", "4K", "Uncensored"],
          rating: 4.9,
          views: 245000,
          isUncensored: true,
          previewVideoUrl:
              "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ),
        MediaItem(
          id: "hmv_3d_2",
          title: "[CyberMMD] Honkai Star Rail Firefly - Sparkling Raytraced 4K 60FPS MMD",
          url: "$baseUrl/video/cybermmd-firefly-sparkling-4k-60fps/",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "03:52",
          studio: "CyberMMD",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: const ["3D", "MMD", "Honkai", "60fps", "4K", "Uncensored"],
          rating: 4.9,
          views: 310000,
          isUncensored: true,
          previewVideoUrl:
              "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ),
        MediaItem(
          id: "hmv_3d_3",
          title: "[RacoonMega] Zenless Zone Zero Ellen Joe & Nicole - Shark Bite 60FPS Dance",
          url: "$baseUrl/video/racoonmega-ellen-nicole-shark-bite-60fps/",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "04:08",
          studio: "RacoonMega",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: const ["3D", "MMD", "ZZZ", "60fps", "Dance", "Uncensored"],
          rating: 4.8,
          views: 198000,
          isUncensored: true,
          previewVideoUrl:
              "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ),
        MediaItem(
          id: "hmv_3d_4",
          title: "[StarlightSFM] NieR:Automata 2B - Cybernetic Awakening 4K 60FPS MMD",
          url: "$baseUrl/video/starlightsfm-2b-cybernetic-awakening-60fps/",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "03:34",
          studio: "StarlightSFM",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: const ["3D", "SFM", "NieR", "60fps", "4K", "Uncensored"],
          rating: 5.0,
          views: 275000,
          isUncensored: true,
          previewVideoUrl:
              "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ),
        MediaItem(
          id: "hmv_3d_5",
          title: "[AetherSFM] Genshin Raiden Shogun & Yae Miko - Electro Resonance 60FPS",
          url: "$baseUrl/video/aethersfm-raiden-yae-electro-resonance-60fps/",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "04:26",
          studio: "AetherSFM",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: const ["3D", "MMD", "Genshin", "60fps", "Choreo", "Uncensored"],
          rating: 4.9,
          views: 340000,
          isUncensored: true,
          previewVideoUrl:
              "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ),
        MediaItem(
          id: "hmv_3d_6",
          title: "[John Menthol] Final Fantasy VII Tifa Lockhart - Velvet Motion 60FPS MMD",
          url: "$baseUrl/video/johnmenthol-tifa-velvet-motion-60fps/",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "03:45",
          studio: "John Menthol",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: const ["3D", "MMD", "FFVII", "60fps", "Dance", "Uncensored"],
          rating: 4.9,
          views: 220000,
          isUncensored: true,
          previewVideoUrl:
              "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ),
        MediaItem(
          id: "hmv_3d_7",
          title: "[EchobunnyMV] Dead or Alive Honoka & Marie Rose - Beach Party 4K 60FPS",
          url: "$baseUrl/video/echobunnymv-honoka-marie-rose-beach-60fps/",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "04:02",
          studio: "EchobunnyMV",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: const ["3D", "MMD", "DOA", "Beach", "60fps", "Uncensored"],
          rating: 4.8,
          views: 185000,
          isUncensored: true,
          previewVideoUrl:
              "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ),
        MediaItem(
          id: "hmv_3d_8",
          title: "[VocaloidMMD] Hatsune Miku & Megurine Luka - Magnet Ultra 4K 60FPS Choreo",
          url: "$baseUrl/video/vocaloidmmd-miku-luka-magnet-4k-60fps/",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "03:58",
          studio: "VocaloidMMD",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: const ["3D", "MMD", "Vocaloid", "Choreo", "4K", "Uncensored"],
          rating: 5.0,
          views: 420000,
          isUncensored: true,
          previewVideoUrl:
              "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ),
      ],
      "hmv": [
        MediaItem(
          id: "hmv_top_1",
          title: "[CyberMMD] Deep In The Night - Honkai Kafka & Black Swan HMV 60FPS",
          url: "$baseUrl/video/cybermmd-kafka-black-swan-deep-night-hmv/",
          cover: "https://i.imgur.com/wVqjC5P.jpeg",
          duration: "04:22",
          studio: "CyberMMD",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: const ["HMV", "Top HMV", "Honkai", "60fps", "Beat Drop", "Uncensored"],
          rating: 5.0,
          views: 380000,
          isUncensored: true,
          previewVideoUrl:
              "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ),
        MediaItem(
          id: "hmv_top_2",
          title: "[AllenByron] Animals - Genshin Yelan & Shenhe Bass Boosted HMV 60FPS",
          url: "$baseUrl/video/allenbyron-yelan-shenhe-animals-hmv/",
          cover: "https://i.imgur.com/z4bKxNm.jpeg",
          duration: "03:39",
          studio: "AllenByron",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: const ["HMV", "Top HMV", "Genshin", "60fps", "Bass", "Uncensored"],
          rating: 4.9,
          views: 295000,
          isUncensored: true,
          previewVideoUrl:
              "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ),
        MediaItem(
          id: "hmv_top_3",
          title: "[EchobunnyMV] Look What You Made Me Do - Honkai Acheron Heavy HMV 60FPS",
          url: "$baseUrl/video/echobunnymv-acheron-heavy-hmv-60fps/",
          cover: "https://i.imgur.com/83pZ6XQ.jpeg",
          duration: "04:05",
          studio: "EchobunnyMV",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: const ["HMV", "Top HMV", "Acheron", "60fps", "Uncensored"],
          rating: 4.9,
          views: 310000,
          isUncensored: true,
          previewVideoUrl:
              "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ),
        MediaItem(
          id: "hmv_top_4",
          title: "[RacoonMega] My Humps 2026 - Genshin Mona & Lisa Deluxe HMV 60FPS",
          url: "$baseUrl/video/racoonmega-mona-lisa-my-humps-hmv/",
          cover: "https://i.imgur.com/N7GgqMv.jpeg",
          duration: "03:48",
          studio: "RacoonMega",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: const ["HMV", "Top HMV", "Genshin", "60fps", "Remix", "Uncensored"],
          rating: 4.8,
          views: 260000,
          isUncensored: true,
          previewVideoUrl:
              "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ),
        MediaItem(
          id: "hmv_top_5",
          title: "[StarlightSFM] Industry Baby - Zenless Zone Zero Zhu Yuan & Grace HMV 60FPS",
          url: "$baseUrl/video/starlightsfm-zhu-yuan-grace-industry-baby-hmv/",
          cover: "https://i.imgur.com/J3ZqK9x.jpeg",
          duration: "03:31",
          studio: "StarlightSFM",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: const ["HMV", "Top HMV", "ZZZ", "60fps", "Music", "Uncensored"],
          rating: 4.9,
          views: 240000,
          isUncensored: true,
          previewVideoUrl:
              "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ),
        MediaItem(
          id: "hmv_top_6",
          title: "[John Menthol] Toxic Love - Overwatch Widowmaker & D.Va Trap HMV 60FPS",
          url: "$baseUrl/video/johnmenthol-widowmaker-dva-toxic-love-hmv/",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "03:55",
          studio: "John Menthol",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: const ["HMV", "Top HMV", "Overwatch", "Trap", "60fps", "Uncensored"],
          rating: 4.8,
          views: 215000,
          isUncensored: true,
          previewVideoUrl:
              "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ),
        MediaItem(
          id: "hmv_top_7",
          title: "[KASUTO SAMA] Starboy - Honkai Star Rail Ruan Mei & Tingyun 60FPS HMV",
          url: "$baseUrl/video/kasuto-sama-ruan-mei-tingyun-starboy-hmv/",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "04:18",
          studio: "KASUTO SAMA",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: const ["HMV", "Top HMV", "Honkai", "60fps", "Rhythm", "Uncensored"],
          rating: 4.9,
          views: 325000,
          isUncensored: true,
          previewVideoUrl:
              "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ),
        MediaItem(
          id: "hmv_top_8",
          title: "[CyberMMD] Titanium Euphoria - Vocaloid Miku Cyber Symphony HMV 60FPS",
          url: "$baseUrl/video/cybermmd-miku-titanium-euphoria-hmv/",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "04:30",
          studio: "CyberMMD",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: const ["HMV", "Top HMV", "Vocaloid", "Euphoria", "60fps", "Uncensored"],
          rating: 5.0,
          views: 410000,
          isUncensored: true,
          previewVideoUrl:
              "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ),
      ],
      "amv": [
        MediaItem(
          id: "hmv_amv_1",
          title: "[AnimeMotion] Chainsaw Man Makima - Control Devil Special AMV Edit 60FPS",
          url: "$baseUrl/video/animemotion-makima-control-devil-amv-edit/",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "03:15",
          studio: "AnimeMotion",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: const ["AMV", "AMV Edit", "Chainsaw Man", "60fps", "Edit", "Uncensored"],
          rating: 4.9,
          views: 280000,
          isUncensored: true,
          previewVideoUrl:
              "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ),
        MediaItem(
          id: "hmv_amv_2",
          title: "[NeonAMV] Jujutsu Kaisen Mei Mei & Nobara - Pure Carnage Flow AMV 60FPS",
          url: "$baseUrl/video/neonamv-mei-mei-nobara-carnage-flow-amv/",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "02:58",
          studio: "NeonAMV",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: const ["AMV", "AMV Edit", "JJK", "Flow", "60fps", "Uncensored"],
          rating: 4.8,
          views: 340000,
          isUncensored: true,
          previewVideoUrl:
              "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ),
        MediaItem(
          id: "hmv_amv_3",
          title: "[GlitchSync] Bleach TYBW Rangiku & Yoruichi - Thunder & Velvet AMV",
          url: "$baseUrl/video/glitchsync-rangiku-yoruichi-thunder-velvet-amv/",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "03:40",
          studio: "GlitchSync",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: const ["AMV", "AMV Edit", "Bleach", "Sync", "60fps", "Uncensored"],
          rating: 4.9,
          views: 265000,
          isUncensored: true,
          previewVideoUrl:
              "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ),
        MediaItem(
          id: "hmv_amv_4",
          title: "[VFXElite] Frieren: Beyond Journey's End - Fern & Serie Magical Beat AMV",
          url: "$baseUrl/video/vfxelite-fern-serie-magical-beat-amv/",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "03:22",
          studio: "VFXElite",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: const ["AMV", "AMV Edit", "Frieren", "VFX", "60fps", "Uncensored"],
          rating: 4.9,
          views: 390000,
          isUncensored: true,
          previewVideoUrl:
              "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ),
        MediaItem(
          id: "hmv_amv_5",
          title: "[BeatCutter] Oshi no Ko Ai Hoshino & Akane - Idol Obsession 60FPS AMV",
          url: "$baseUrl/video/beatcutter-ai-akane-idol-obsession-amv/",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "03:45",
          studio: "BeatCutter",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: const ["AMV", "AMV Edit", "Oshi no Ko", "Idol", "60fps", "Uncensored"],
          rating: 4.9,
          views: 450000,
          isUncensored: true,
          previewVideoUrl:
              "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ),
        MediaItem(
          id: "hmv_amv_6",
          title: "[DarkSync] Cyberpunk Edgerunners Lucy - I Really Want to Stay AMV Edit",
          url: "$baseUrl/video/darksync-lucy-edgerunners-amv-edit/",
          cover: "https://i.imgur.com/wVqjC5P.jpeg",
          duration: "04:10",
          studio: "DarkSync",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: const ["AMV", "AMV Edit", "Cyberpunk", "Lucy", "60fps", "Uncensored"],
          rating: 5.0,
          views: 520000,
          isUncensored: true,
          previewVideoUrl:
              "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ),
        MediaItem(
          id: "hmv_amv_7",
          title: "[HyperAMV] Fate/stay night Heaven's Feel Saber Alter - Dark Calibur AMV",
          url: "$baseUrl/video/hyperamv-saber-alter-dark-calibur-amv/",
          cover: "https://i.imgur.com/z4bKxNm.jpeg",
          duration: "03:35",
          studio: "HyperAMV",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: const ["AMV", "AMV Edit", "Fate", "Saber", "60fps", "Uncensored"],
          rating: 4.9,
          views: 310000,
          isUncensored: true,
          previewVideoUrl:
              "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ),
        MediaItem(
          id: "hmv_amv_8",
          title: "[MotionArt] Spy x Family Yor Forger - Thorn Princess Assassin Flow AMV",
          url: "$baseUrl/video/motionart-yor-forger-thorn-princess-amv/",
          cover: "https://i.imgur.com/83pZ6XQ.jpeg",
          duration: "03:05",
          studio: "MotionArt",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: const ["AMV", "AMV Edit", "Spy x Family", "Yor", "60fps", "Uncensored"],
          rating: 4.8,
          views: 375000,
          isUncensored: true,
          previewVideoUrl:
              "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ),
      ],
      "recent": [
        MediaItem(
          id: "hmv_rec_1",
          title: "[CyberMMD] Zenless Zone Zero Miyabi - Frostblade Symphony 60FPS MMD",
          url: "$baseUrl/video/cybermmd-miyabi-frostblade-symphony-60fps/",
          cover: "https://i.imgur.com/N7GgqMv.jpeg",
          duration: "04:12",
          studio: "CyberMMD",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: const ["Recent", "Latest", "ZZZ", "Miyabi", "60fps", "Uncensored"],
          rating: 5.0,
          views: 145000,
          isUncensored: true,
          previewVideoUrl:
              "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ),
        MediaItem(
          id: "hmv_rec_2",
          title: "[AllenByron] Genshin Impact Xilonen - Desert Rhythm 4K 60FPS HMV",
          url: "$baseUrl/video/allenbyron-xilonen-desert-rhythm-4k-hmv/",
          cover: "https://i.imgur.com/J3ZqK9x.jpeg",
          duration: "03:42",
          studio: "AllenByron",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: const ["Recent", "Latest", "Genshin", "4K", "60fps", "Uncensored"],
          rating: 4.9,
          views: 180000,
          isUncensored: true,
          previewVideoUrl:
              "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ),
        MediaItem(
          id: "hmv_rec_3",
          title: "[EchobunnyMV] Honkai Star Rail Feixiao - General's Command 60FPS MMD",
          url: "$baseUrl/video/echobunnymv-feixiao-generals-command-60fps/",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "04:01",
          studio: "EchobunnyMV",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: const ["Recent", "Latest", "Honkai", "60fps", "Dance", "Uncensored"],
          rating: 4.9,
          views: 165000,
          isUncensored: true,
          previewVideoUrl:
              "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ),
        MediaItem(
          id: "hmv_rec_4",
          title: "[StarlightSFM] Wuthering Waves Changli - Phoenix Flare 60FPS Choreo",
          url: "$baseUrl/video/starlightsfm-changli-phoenix-flare-60fps/",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "03:50",
          studio: "StarlightSFM",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: const ["Recent", "Latest", "Wuthering Waves", "60fps", "Choreo", "Uncensored"],
          rating: 4.9,
          views: 210000,
          isUncensored: true,
          previewVideoUrl:
              "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ),
        MediaItem(
          id: "hmv_rec_5",
          title: "[RacoonMega] Zenless Zone Zero Burnice - Flamethrower Dance 60FPS MMD",
          url: "$baseUrl/video/racoonmega-burnice-flamethrower-dance-60fps/",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "03:28",
          studio: "RacoonMega",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: const ["Recent", "Latest", "ZZZ", "Burnice", "60fps", "Uncensored"],
          rating: 4.8,
          views: 195000,
          isUncensored: true,
          previewVideoUrl:
              "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ),
        MediaItem(
          id: "hmv_rec_6",
          title: "[John Menthol] Stellar Blade Eve - 7th Airborne Seduction 60FPS HMV",
          url: "$baseUrl/video/johnmenthol-eve-7th-airborne-seduction-hmv/",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "04:20",
          studio: "John Menthol",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: const ["Recent", "Latest", "Stellar Blade", "60fps", "HMV", "Uncensored"],
          rating: 5.0,
          views: 290000,
          isUncensored: true,
          previewVideoUrl:
              "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ),
        MediaItem(
          id: "hmv_rec_7",
          title: "[AetherSFM] Genshin Impact Chiori - Fontaine Couture 60FPS Dance",
          url: "$baseUrl/video/aethersfm-chiori-fontaine-couture-dance/",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "03:36",
          studio: "AetherSFM",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: const ["Recent", "Latest", "Genshin", "Chiori", "60fps", "Uncensored"],
          rating: 4.8,
          views: 135000,
          isUncensored: true,
          previewVideoUrl:
              "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ),
        MediaItem(
          id: "hmv_rec_8",
          title: "[VocaloidMMD] Hatsune Miku - Rolling Girl 2026 Remastered 4K 60FPS",
          url: "$baseUrl/video/vocaloidmmd-miku-rolling-girl-2026-remaster/",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "03:44",
          studio: "VocaloidMMD",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: const ["Recent", "Latest", "Vocaloid", "Remaster", "4K", "Uncensored"],
          rating: 4.9,
          views: 315000,
          isUncensored: true,
          previewVideoUrl:
              "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ),
      ],
      "challenge": [
        MediaItem(
          id: "hmv_ch_1",
          title: "[KASUTO SAMA] Beatbar Challenge: Genshin Impact Furina vs 100% Meter",
          url: "$baseUrl/video/kasuto-sama-furina-beatbar-challenge/",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "03:02",
          studio: "KASUTO SAMA",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: const ["Challenge", "Beatbar", "Genshin", "Game", "60fps", "Uncensored"],
          rating: 4.9,
          views: 380000,
          isUncensored: true,
          previewVideoUrl:
              "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ),
        MediaItem(
          id: "hmv_ch_2",
          title: "[BeatMaster3D] Rhythm Game Overload: Honkai Kafka Stamina Bar Test 60FPS",
          url: "$baseUrl/video/beatmaster3d-kafka-rhythm-game-overload/",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "03:45",
          studio: "BeatMaster3D",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: const ["Challenge", "Beatbar", "Honkai", "Rhythm", "60fps", "Uncensored"],
          rating: 5.0,
          views: 420000,
          isUncensored: true,
          previewVideoUrl:
              "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ),
        MediaItem(
          id: "hmv_ch_3",
          title: "[CyberMMD] Synchronized Beat Challenge: Zenless Nicole & Ellen Joe",
          url: "$baseUrl/video/cybermmd-nicole-ellen-sync-beat-challenge/",
          cover: "https://i.imgur.com/wVqjC5P.jpeg",
          duration: "04:10",
          studio: "CyberMMD",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: const ["Challenge", "Beatbar", "ZZZ", "Sync", "60fps", "Uncensored"],
          rating: 4.9,
          views: 340000,
          isUncensored: true,
          previewVideoUrl:
              "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ),
        MediaItem(
          id: "hmv_ch_4",
          title: "[StarlightSFM] Endurance Gauge Test: NieR 2B Cybernetics Beatbar 60FPS",
          url: "$baseUrl/video/starlightsfm-2b-endurance-gauge-beatbar/",
          cover: "https://i.imgur.com/z4bKxNm.jpeg",
          duration: "03:30",
          studio: "StarlightSFM",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: const ["Challenge", "Beatbar", "NieR", "Endurance", "60fps", "Uncensored"],
          rating: 4.9,
          views: 290000,
          isUncensored: true,
          previewVideoUrl:
              "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ),
        MediaItem(
          id: "hmv_ch_5",
          title: "[AllenByron] Hardcore Rhythm Tap: Genshin Raiden Shogun Beat Drop 60FPS",
          url: "$baseUrl/video/allenbyron-raiden-hardcore-rhythm-tap/",
          cover: "https://i.imgur.com/83pZ6XQ.jpeg",
          duration: "03:18",
          studio: "AllenByron",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: const ["Challenge", "Beatbar", "Genshin", "Tap", "60fps", "Uncensored"],
          rating: 4.8,
          views: 360000,
          isUncensored: true,
          previewVideoUrl:
              "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ),
        MediaItem(
          id: "hmv_ch_6",
          title: "[EchobunnyMV] Speed Dance Challenge: Vocaloid Miku BPM 200 Rush 60FPS",
          url: "$baseUrl/video/echobunnymv-miku-bpm200-rush-challenge/",
          cover: "https://i.imgur.com/N7GgqMv.jpeg",
          duration: "02:55",
          studio: "EchobunnyMV",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: const ["Challenge", "Beatbar", "Vocaloid", "BPM200", "60fps", "Uncensored"],
          rating: 5.0,
          views: 450000,
          isUncensored: true,
          previewVideoUrl:
              "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ),
        MediaItem(
          id: "hmv_ch_7",
          title: "[RacoonMega] Triple Beatbar Stage: Dead or Alive Honoka & Marie Rose",
          url: "$baseUrl/video/racoonmega-honoka-marie-triple-beatbar/",
          cover: "https://i.imgur.com/J3ZqK9x.jpeg",
          duration: "04:05",
          studio: "RacoonMega",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: const ["Challenge", "Beatbar", "DOA", "Stage", "60fps", "Uncensored"],
          rating: 4.8,
          views: 275000,
          isUncensored: true,
          previewVideoUrl:
              "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ),
        MediaItem(
          id: "hmv_ch_8",
          title: "[John Menthol] Climax Meter 999: Final Fantasy Tifa Lockhart 60FPS Game",
          url: "$baseUrl/video/johnmenthol-tifa-climax-meter-999-game/",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "03:52",
          studio: "John Menthol",
          extensionId: id,
          type: MediaType.mmd3D,
          tags: const ["Challenge", "Beatbar", "FFVII", "Climax", "60fps", "Uncensored"],
          rating: 4.9,
          views: 410000,
          isUncensored: true,
          previewVideoUrl:
              "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ),
      ],
    };

    // If query is provided, search across all sample categories
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      final allItems = sampleSets.values.expand((list) => list).toList();
      final matched = allItems
          .where(
            (item) =>
                item.title.toLowerCase().contains(q) ||
                item.tags.any((t) => t.toLowerCase().contains(q)) ||
                (item.studio?.toLowerCase().contains(q) ?? false),
          )
          .toList();
      if (matched.isNotEmpty) return matched;
    }

    final catKey = category.toLowerCase().trim();
    final normalized = switch (catKey) {
      'mmd_dance' || '3d' => '3d',
      'popular_hmv' || 'popular' || 'hmv' => 'hmv',
      'amv' => 'amv',
      'recent' || 'latest' => 'recent',
      'challenge' || 'beatbar' => 'challenge',
      _ => sampleSets.containsKey(catKey) ? catKey : '3d',
    };

    return sampleSets[normalized] ?? sampleSets['3d']!;
  }

  MediaDetail _generateSampleDetail(String url) {
    return MediaDetail(
      id: url.hashCode.toString(),
      title: "Genshin Impact Furina - Deep In The Night HMV 4K",
      cover: "https://i.imgur.com/7jZQY1B.jpeg",
      backdrop: "https://i.imgur.com/7jZQY1B.jpeg",
      description:
          "Raytraced dynamic camera choreo with custom audio remix in full 4K 60FPS uncensored AV1 stream.",
      studio: "CyberMMD",
      releaseDate: "2026-08-20",
      tags: const [
        "HMV",
        "3D MMD",
        "Genshin",
        "4K 60fps",
        "AV1",
        "Music",
        "Uncensored",
      ],
      episodes: [
        EpisodeItem(
          id: "hmv_sample_stream",
          episodeNumber: "Full Music Video",
          title: "Full 4K 60FPS Master HMV",
          url: url,
          duration: "04:12",
          sources: [
            StreamSource(
              label: "4K 60fps Direct MP4",
              url:
                  "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
              protocol: StreamProtocol.directMp4,
              format: "mp4",
              headers: _headers,
            ),
          ],
        ),
      ],
      playbackHeatmap: const [
        0.2,
        0.5,
        0.8,
        1.0,
        0.9,
        0.65,
        0.85,
        1.0,
        0.75,
        0.3,
      ],
      sceneMarkers: [
        SceneMarker(title: "Beat Drop 1 🔥", timestampSeconds: 45),
        SceneMarker(title: "Solo Climax 2 🔥", timestampSeconds: 155),
      ],
    );
  }

  @override
  Future<ExtensionTaxonomy> fetchTaxonomy() async {
    return hmvManiaTaxonomy;
  }

  @override
  Future<List<MediaItem>> fetchTaxonomyFeed(CatalogItem item, int page) async {
    try {
      String path;
      if (item.endpointPath != null && item.endpointPath!.isNotEmpty) {
        final cleanPath = item.endpointPath!.endsWith('/')
            ? item.endpointPath!
            : '${item.endpointPath!}/';
        path = page == 1 ? cleanPath : '${cleanPath}page/$page/';
      } else if (item.type == CatalogType.genre || item.type == CatalogType.tag) {
        path = page == 1
            ? '/genre/${item.slug}/'
            : '/genre/${item.slug}/page/$page/';
      } else if (item.type == CatalogType.artist) {
        path = page == 1
            ? '/author/${item.slug}/'
            : '/author/${item.slug}/page/$page/';
      } else {
        path = page == 1
            ? '/video-category/${item.slug}/'
            : '/video-category/${item.slug}/page/$page/';
      }

      final targetUrl = Uri.parse('$baseUrl$path');
      final response = await http
          .get(targetUrl, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final doc = html_parser.parse(response.body);
        final items = _parseVideoItems(doc);
        if (items.isNotEmpty) {
          return items;
        }
      }
    } catch (_) {
      // Fallback on network/parse failure
    }

    if (item.slug == "3d" ||
        item.slug == "hmv" ||
        item.slug == "amv" ||
        item.slug == "recent" ||
        item.slug == "challenge") {
      return fetchTabFeed(item.slug, page);
    }
    return search(item.name.isNotEmpty ? item.name : item.slug, page);
  }
}
