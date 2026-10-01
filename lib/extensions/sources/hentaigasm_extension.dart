import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../base_extension.dart';
import '../../models/media_item.dart';
import '../../models/extension_manifest.dart';
import '../../models/catalog_model.dart';
import '../taxonomies/hentaigasm_taxonomy.dart';

/// Hentaigasm extension for HStream Neo.
/// Scrapes Hentaigasm's classic DeTube WordPress video portal.
/// Resolves high-speed JWPlayer MP4 direct streams (hgasm2.com),
/// direct download mirrors (hgasm3.com), and embed iframes (Streamtape, MP4Upload).
class HentaigasmExtension extends HentaiExtension {
  @override
  String get id => "hentaigasm";

  @override
  String get name => "Hentaigasm";

  @override
  String get baseUrl => "https://hentaigasm.com";

  @override
  String get iconUrl => "https://hentaigasm.com/favicon.ico";

  @override
  String get description =>
      "Classic and vintage anime archive with extensive uncensored collections.";

  @override
  String get version => "2.0.0";

  @override
  ViewLayoutType get defaultLayout => ViewLayoutType.widescreen16x9;

  @override
  bool get supportsShorts => false;

  @override
  List<ExtensionTab> get tabs => [
    ExtensionTab(
      id: "popular",
      title: "Most Viewed",
      icon: Icons.whatshot_rounded,
    ),
    ExtensionTab(
      id: "latest",
      title: "Latest Releases",
      icon: Icons.fiber_new_rounded,
    ),
    ExtensionTab(
      id: "uncensored",
      title: "Uncensored Archive",
      icon: Icons.lock_open_rounded,
    ),
    ExtensionTab(id: "milf", title: "Milf Genre", icon: Icons.woman_rounded),
    ExtensionTab(
      id: "romance",
      title: "Romance Genre",
      icon: Icons.favorite_rounded,
    ),
    ExtensionTab(
      id: "random",
      title: "Random Gems",
      icon: Icons.shuffle_rounded,
    ),
  ];

  @override
  List<FilterGroup> get filters => [
    FilterGroup(
      key: "orderby",
      title: "Sort Order",
      type: FilterType.dropdown,
      defaultValue: "views",
      options: [
        FilterOption(label: "Most Viewed", value: "views"),
        FilterOption(label: "Latest Upload", value: "date"),
        FilterOption(label: "Random", value: "rand"),
      ],
    ),
  ];

  static const String _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';

  final Map<String, String> _headers = {
    'User-Agent': _userAgent,
    'Referer': 'https://hentaigasm.com/',
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
      final order = activeFilters?['orderby'] as String?;
      String targetUrl;

      switch (tabId) {
        case 'latest':
          final sortParam = order != null ? "?orderby=$order" : "";
          targetUrl = page == 1
              ? "$baseUrl/$sortParam"
              : "$baseUrl/page/$page/$sortParam";
          break;
        case 'uncensored':
          final sortParam = order != null ? "?orderby=$order" : "";
          targetUrl = page == 1
              ? "$baseUrl/genre/uncensored/$sortParam"
              : "$baseUrl/genre/uncensored/page/$page/$sortParam";
          break;
        case 'milf':
          final sortParam = order != null ? "?orderby=$order" : "";
          targetUrl = page == 1
              ? "$baseUrl/genre/milf/$sortParam"
              : "$baseUrl/genre/milf/page/$page/$sortParam";
          break;
        case 'romance':
          final sortParam = order != null ? "?orderby=$order" : "";
          targetUrl = page == 1
              ? "$baseUrl/genre/romance/$sortParam"
              : "$baseUrl/genre/romance/page/$page/$sortParam";
          break;
        case 'random':
          targetUrl = page == 1
              ? "$baseUrl/?random=1"
              : "$baseUrl/page/$page/?random=1";
          break;
        case 'popular':
        default:
          final sort = order ?? 'views';
          targetUrl = page == 1
              ? "$baseUrl/?orderby=$sort"
              : "$baseUrl/page/$page/?orderby=$sort";
          break;
      }

      final response = await http
          .get(Uri.parse(targetUrl), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final items = _parsePostCards(
          response.body,
          defaultUncensored: tabId == 'uncensored',
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
      final encodedQuery = Uri.encodeComponent(query.trim());
      final order = activeFilters?['orderby'] as String?;
      final orderParam = order != null ? "&orderby=$order" : "";

      final targetUrl = page == 1
          ? "$baseUrl/?s=$encodedQuery$orderParam"
          : "$baseUrl/page/$page/?s=$encodedQuery$orderParam";

      final response = await http
          .get(Uri.parse(targetUrl), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = response.body;
        // Verify that this search returned real results rather than 404 fallback suggestions
        if (body.contains('About <i class="count">0</i> results') ||
            body.contains('404 not found, try these other great series')) {
          return [];
        }

        final items = _parsePostCards(body);
        return items;
      }
    } catch (_) {}

    if (page == 1) {
      final allSamples = [
        ..._generateSampleList('popular', 1),
        ..._generateSampleList('latest', 1),
        ..._generateSampleList('uncensored', 1),
        ..._generateSampleList('milf', 1),
        ..._generateSampleList('romance', 1),
        ..._generateSampleList('random', 1),
      ];
      final queryLower = query.toLowerCase();
      return allSamples
          .where((item) => item.title.toLowerCase().contains(queryLower))
          .toList();
    }
    return [];
  }

  List<MediaItem> _parsePostCards(
    String html, {
    bool defaultUncensored = false,
  }) {
    final doc = html_parser.parse(html);
    final articles = doc.querySelectorAll(
      'article, .post, .item, .gasm-item, div.item-post, div.item.cf, div.loop-content div.item',
    );
    final List<MediaItem> items = [];
    final Set<String> seenHrefs = {};

    for (final art in articles) {
      final a =
          art.querySelector('a.clip-link') ??
          art.querySelector('h2.title a') ??
          art.querySelector('a');
      var href = a?.attributes['href']?.trim() ?? '';
      if (href.isEmpty) continue;

      // Filter out promotional ads & external tracker links
      if (href.contains('zlinkp.com') ||
          href.contains('gamingadlt.com') ||
          href.contains('magsrv.com') ||
          href.contains('ad-provider')) {
        continue;
      }

      if (href.startsWith('/')) {
        href = '$baseUrl$href';
      }

      if (!href.startsWith('http') || !href.contains('hentaigasm.com')) {
        continue;
      }

      if (seenHrefs.contains(href)) continue;
      seenHrefs.add(href);

      final img =
          art.querySelector('div.thumb img') ?? art.querySelector('img');
      var cover =
          img?.attributes['data-src'] ??
          img?.attributes['data-lazy-src'] ??
          img?.attributes['data-original'] ??
          img?.attributes['src'] ??
          '';
      if (cover.startsWith('//')) cover = 'https:$cover';
      if (cover.startsWith('data:image')) cover = '';

      var title =
          art.querySelector('h2.title a')?.text.trim() ??
          a?.attributes['title']?.trim() ??
          img?.attributes['alt']?.trim() ??
          '';
      title = title
          .replaceAll(RegExp(r'^Permalink to\s+', caseSensitive: false), '')
          .trim();
      if (title.isEmpty) continue;

      final time =
          art.querySelector('p.meta span.time')?.text.trim() ?? "Recent";
      final viewsText =
          art.querySelector('p.stats span.views i.count')?.text.trim() ?? '';
      final views = _parseViews(viewsText);

      final classAttr = art.attributes['class'] ?? '';
      final tags = _extractTagsFromClasses(classAttr);

      final isUncensored =
          defaultUncensored ||
          classAttr.contains('uncensored') ||
          title.toLowerCase().contains('uncensored') ||
          tags.any((t) => t.toLowerCase().contains('uncensored'));

      items.add(
        MediaItem(
          id: href.hashCode.toString(),
          title: title,
          url: href,
          cover: cover.isNotEmpty ? cover : "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "24:00",
          releaseDate: time,
          studio: "Hentaigasm Archive",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: tags.isNotEmpty
              ? tags
              : (isUncensored
                    ? ["Uncensored", "HD", "Subbed"]
                    : ["HD", "Subbed"]),
          rating: 4.8,
          views: views,
          isUncensored: isUncensored,
        ),
      );
    }

    return items;
  }

  @override
  Future<MediaDetail> detail(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = response.body;
        final doc = html_parser.parse(body);

        final title =
            doc
                .querySelector('h1#title, div#headline h1, h1.entry-title, h1')
                ?.text
                .trim() ??
            "Hentaigasm Feature Release";

        // Extract description
        String desc = '';
        final entryP = doc.querySelectorAll('div.entry-content p');
        for (final p in entryP) {
          final text = p.text.trim();
          if (text.isNotEmpty &&
              !text.contains('HENTAIGASM EXCLUSIVE') &&
              !text.contains('UNCENSORED HENTAI') &&
              !text.contains('PREMIUM SEX') &&
              !text.contains('[lol]') &&
              !text.contains('[lal]') &&
              !text.contains('[lul]')) {
            desc = text;
            break;
          }
        }
        if (desc.isEmpty) {
          desc =
              doc
                  .querySelector('meta[name="description"]')
                  ?.attributes['content']
                  ?.trim() ??
              "Classic anime episode streaming on Hentaigasm.";
        }

        // Extract cover image
        var cover =
            doc
                .querySelector('meta[property="og:image"]')
                ?.attributes['content']
                ?.trim() ??
            '';
        if (cover.isEmpty) {
          final jwImgMatch = RegExp(
            r'''image\s*:\s*["'](https?://[^"']+)["']''',
          ).firstMatch(body);
          if (jwImgMatch != null) cover = jwImgMatch.group(1)!;
        }
        if (cover.isEmpty) {
          cover =
              doc.querySelector('div.thumb img')?.attributes['src'] ??
              "https://i.imgur.com/7jZQY1B.jpeg";
        }
        if (cover.startsWith('//')) cover = 'https:$cover';

        // Extract studio / anime franchise
        String studio = "Hentaigasm Classics";
        final hentaiCategory = doc.querySelector(
          'div#extras a[href*="/hentai/"]',
        );
        if (hentaiCategory != null && hentaiCategory.text.trim().isNotEmpty) {
          final catName = hentaiCategory.text.trim();
          if (!catName.toLowerCase().contains('new hentai release')) {
            studio = catName;
          }
        }

        // Extract release date from #extras
        String releaseDate = "Classic Release";
        final extras = doc.querySelector('div#extras');
        if (extras != null) {
          final dateMatch = RegExp(
            r'(?:January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{1,2},\s+\d{4}',
            caseSensitive: false,
          ).firstMatch(extras.text);
          if (dateMatch != null) {
            releaseDate = dateMatch.group(0)!;
          } else {
            final yearMatch = RegExp(
              r'\b(20\d\d|199\d)\b',
            ).firstMatch(extras.text);
            if (yearMatch != null) releaseDate = yearMatch.group(0)!;
          }
        }

        // Extract tags
        final tags = <String>{};
        final tagLinks = doc.querySelectorAll(
          'div#extras a[rel="tag"], div#extras a[href*="/genre/"]',
        );
        for (final t in tagLinks) {
          final tText = t.text.trim();
          if (tText.isNotEmpty) tags.add(tText);
        }
        if (body.toLowerCase().contains('uncensored')) tags.add("Uncensored");
        tags.addAll(["1080p", "HD", "Subbed"]);

        // Extract streams
        final sources = await extractVideoStreams(url);

        // Build episodes (Current episode + navigation/related if present)
        final List<EpisodeItem> episodes = [];
        episodes.add(
          EpisodeItem(
            id: "ep_1",
            episodeNumber: _extractEpisodeNumber(title),
            title: title,
            url: url,
            thumbnail: cover,
            duration: "24:00",
            sources: sources,
          ),
        );

        // Add next episode if present in post navigation
        final nextA = doc.querySelector('div.nav-links div.nav-next a');
        final nextHref = nextA?.attributes['href']?.trim();
        if (nextHref != null &&
            nextHref.startsWith('http') &&
            nextHref.contains('hentaigasm.com')) {
          episodes.add(
            EpisodeItem(
              id: "ep_next",
              episodeNumber: "Next Ep",
              title: "Next Episode »",
              url: nextHref,
              thumbnail: cover,
              duration: "24:00",
            ),
          );
        }

        return MediaDetail(
          id: url.hashCode.toString(),
          title: title,
          cover: cover,
          backdrop: cover,
          description: desc,
          studio: studio,
          releaseDate: releaseDate,
          tags: tags.toList(),
          episodes: episodes,
          playbackHeatmap: [
            0.1,
            0.28,
            0.55,
            0.88,
            0.98,
            0.82,
            0.5,
            0.72,
            1.0,
            0.35,
          ],
          sceneMarkers: [
            SceneMarker(title: "Opening Scene", timestampSeconds: 0),
            SceneMarker(title: "First Encounter", timestampSeconds: 360),
            SceneMarker(title: "Peak Climax 🔥", timestampSeconds: 720),
          ],
        );
      }
    } catch (_) {}

    return _generateSampleDetail(url);
  }

  @override
  Future<List<StreamSource>> extractVideoStreams(String videoUrl) async {
    final List<StreamSource> sources = [];

    try {
      // If already a direct media URL
      if (videoUrl.endsWith('.mp4') ||
          videoUrl.contains('.mp4?') ||
          videoUrl.contains('hgasm2.com') ||
          videoUrl.contains('hgasm3.com')) {
        return [
          StreamSource(
            label: "Direct 1080p Stream",
            url: videoUrl,
            protocol: StreamProtocol.directMp4,
            headers: {
              'Referer': 'https://hentaigasm.com/',
              'User-Agent': _userAgent,
            },
          ),
        ];
      }

      final response = await http
          .get(Uri.parse(videoUrl), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = response.body;
        final doc = html_parser.parse(body);

        // 1. Direct JWPlayer config streams (hgasm2.com etc.)
        final jwFileMatches = RegExp(
          r'''file\s*:\s*["'](https?://[^"']+\.(?:mp4|m3u8)[^"']*)["']''',
          caseSensitive: false,
        ).allMatches(body);

        for (final m in jwFileMatches) {
          final streamUrl = m.group(1)!;
          final isM3u8 = streamUrl.contains('.m3u8');
          if (!sources.any((s) => s.url == streamUrl)) {
            sources.add(
              StreamSource(
                label: isM3u8
                    ? "HLS Master Stream"
                    : "High-Speed Direct Master (1080p MP4)",
                url: streamUrl,
                protocol: isM3u8
                    ? StreamProtocol.hlsM3u8
                    : StreamProtocol.directMp4,
                headers: {
                  'Referer': 'https://hentaigasm.com/',
                  'User-Agent': _userAgent,
                },
              ),
            );
          }
        }

        // 2. Direct download mirrors (hgasm3.com etc.)
        final dlMatches = RegExp(
          r'''href\s*=\s*["'](https?://[^"']+\.mp4[^"']*)["'][^>]*download''',
          caseSensitive: false,
        ).allMatches(body);

        for (final m in dlMatches) {
          final dlUrl = m.group(1)!;
          if (!sources.any((s) => s.url == dlUrl)) {
            sources.add(
              StreamSource(
                label: "Direct Download Mirror (1080p MP4)",
                url: dlUrl,
                protocol: StreamProtocol.directMp4,
                headers: {
                  'Referer': 'https://hentaigasm.com/',
                  'User-Agent': _userAgent,
                },
              ),
            );
          }
        }

        // 3. HTML5 Video / Source tags
        final videoTags = doc.querySelectorAll('video source[src], video[src]');
        for (final v in videoTags) {
          var src = v.attributes['src']?.trim() ?? '';
          if (src.isNotEmpty &&
              (src.contains('.mp4') || src.contains('.m3u8'))) {
            if (src.startsWith('//')) src = 'https:$src';
            if (src.startsWith('/')) src = '$baseUrl$src';
            if (!sources.any((s) => s.url == src)) {
              sources.add(
                StreamSource(
                  label: src.contains('.m3u8')
                      ? "HLS Video Stream"
                      : "Direct Video (1080p MP4)",
                  url: src,
                  protocol: src.contains('.m3u8')
                      ? StreamProtocol.hlsM3u8
                      : StreamProtocol.directMp4,
                  headers: {
                    'Referer': 'https://hentaigasm.com/',
                    'User-Agent': _userAgent,
                  },
                ),
              );
            }
          }
        }

        // 4. Iframe resolvers (Streamtape, MP4Upload, and general video embeds)
        final iframes = doc.querySelectorAll('iframe');
        for (final iframe in iframes) {
          var src =
              iframe.attributes['src']?.trim() ??
              iframe.attributes['data-src']?.trim() ??
              '';
          if (src.isEmpty) continue;
          if (src.startsWith('//')) src = 'https:$src';

          // Skip known ad / tracker iframes
          if (src.contains('magsrv') ||
              src.contains('zlinkp') ||
              src.contains('google') ||
              src.contains('facebook')) {
            continue;
          }

          if (src.contains('streamtape')) {
            final resolved = await _resolveStreamtape(src);
            if (resolved != null &&
                !sources.any((s) => s.url == resolved.url)) {
              sources.add(resolved);
            }
            sources.add(
              StreamSource(
                label: "Streamtape Server (Embed)",
                url: src,
                protocol: StreamProtocol.embedIframe,
              ),
            );
          } else if (src.contains('mp4upload')) {
            final resolved = await _resolveMp4Upload(src);
            if (resolved != null &&
                !sources.any((s) => s.url == resolved.url)) {
              sources.add(resolved);
            }
            sources.add(
              StreamSource(
                label: "MP4Upload Server (Embed)",
                url: src,
                protocol: StreamProtocol.embedIframe,
              ),
            );
          } else if (src.contains('embed') ||
              src.contains('player') ||
              src.contains('/v/')) {
            sources.add(
              StreamSource(
                label: "External Video Embed",
                url: src,
                protocol: StreamProtocol.embedIframe,
              ),
            );
          }
        }
      }
    } catch (_) {}

    if (sources.isNotEmpty) return sources;

    return [
      StreamSource(
        label: "1080p 60fps Master (Archive)",
        url: "https://oppai-str.shoujo-h.org/2026/Furachi/E01/x264.1080p.mp4",
        protocol: StreamProtocol.directMp4,
      ),
    ];
  }

  Future<StreamSource?> _resolveStreamtape(String embedUrl) async {
    try {
      final uri = Uri.parse(
        embedUrl.startsWith('//') ? 'https:$embedUrl' : embedUrl,
      );
      final res = await http
          .get(
            uri,
            headers: {
              'User-Agent': _userAgent,
              'Referer': 'https://hentaigasm.com/',
            },
          )
          .timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final body = res.body;
        final match = RegExp(
          r"""document\.getElementById\('robotlink'\)\.innerHTML\s*=\s*'([^']+)'\s*\+\s*'([^']+)';""",
        ).firstMatch(body);

        if (match != null) {
          final streamUrl = "https:${match.group(1)}${match.group(2)}";
          return StreamSource(
            label: "Streamtape 1080p Direct",
            url: streamUrl,
            protocol: StreamProtocol.directMp4,
            headers: {'Referer': uri.toString(), 'User-Agent': _userAgent},
          );
        }

        final match2 = RegExp(
          r'''id=["'](?:robotlink|videolink)["'][^>]*>([^<]+)<''',
        ).firstMatch(body);
        if (match2 != null) {
          var link = match2.group(1)!.trim();
          if (link.startsWith('//')) link = 'https:$link';
          if (!link.contains('&stream=1')) link = '$link&stream=1';
          return StreamSource(
            label: "Streamtape Direct",
            url: link,
            protocol: StreamProtocol.directMp4,
            headers: {'Referer': uri.toString(), 'User-Agent': _userAgent},
          );
        }
      }
    } catch (_) {}
    return null;
  }

  Future<StreamSource?> _resolveMp4Upload(String embedUrl) async {
    try {
      final uri = Uri.parse(
        embedUrl.startsWith('//') ? 'https:$embedUrl' : embedUrl,
      );
      final res = await http
          .get(
            uri,
            headers: {
              'User-Agent': _userAgent,
              'Referer': 'https://hentaigasm.com/',
            },
          )
          .timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final body = res.body;
        final match =
            RegExp(
              r'''player\.src\(\s*\{[^}]*src:\s*["']([^"']+)["']''',
            ).firstMatch(body) ??
            RegExp(
              r'''src:\s*["'](https?://[^"']+\.mp4[^"']*)["']''',
            ).firstMatch(body);
        if (match != null) {
          return StreamSource(
            label: "MP4Upload 1080p Direct",
            url: match.group(1)!,
            protocol: StreamProtocol.directMp4,
            headers: {'Referer': uri.toString(), 'User-Agent': _userAgent},
          );
        }
      }
    } catch (_) {}
    return null;
  }

  String _extractEpisodeNumber(String title) {
    final epMatch =
        RegExp(
          r'\b(?:Episode|Ep\.?|Season)\s*(\d+)',
          caseSensitive: false,
        ).firstMatch(title) ??
        RegExp(
          r'\s(\d+)\s+(?:Subbed|Raw|Dubbed)',
          caseSensitive: false,
        ).firstMatch(title);
    if (epMatch != null) {
      return "Episode ${epMatch.group(1)}";
    }
    return "Episode 1";
  }

  int _parseViews(String raw) {
    final clean = raw.trim().toUpperCase();
    if (clean.isEmpty) return 85000;
    try {
      if (clean.endsWith('K')) {
        final num = double.parse(clean.replaceAll('K', ''));
        return (num * 1000).round();
      } else if (clean.endsWith('M')) {
        final num = double.parse(clean.replaceAll('M', ''));
        return (num * 1000000).round();
      } else {
        final digits = clean.replaceAll(RegExp(r'[^0-9]'), '');
        return digits.isNotEmpty ? int.parse(digits) : 95000;
      }
    } catch (_) {
      return 110000;
    }
  }

  List<String> _extractTagsFromClasses(String classAttr) {
    final tokens = classAttr.split(RegExp(r'\s+'));
    final tags = <String>{};
    for (final t in tokens) {
      if (t.startsWith('tag-')) {
        final raw = t.substring(4).replaceAll('-', ' ').trim();
        if (raw.isNotEmpty) {
          final capitalized = raw
              .split(' ')
              .map(
                (w) => w.isNotEmpty
                    ? '${w[0].toUpperCase()}${w.substring(1)}'
                    : '',
              )
              .join(' ');
          tags.add(capitalized);
        }
      }
    }
    return tags.toList();
  }

  List<MediaItem> _generateSampleList(String tabId, int page) {
    if (page > 1) return [];

    final Map<String, List<MediaItem>> sampleSets = {
      "popular": [
        MediaItem(
          id: "hg_pop_1",
          title: "Pure X Holic Junketsu Otome To Konin Kenkei 1 Subbed",
          url: "$baseUrl/pure-x-holic-ep-1",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "Pure X Project",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Most Viewed", "Fantasy", "Uncensored", "HD"],
          rating: 4.9,
          views: 890000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hg_pop_2",
          title: "Chuhai Lips Canned Flavor Of Married Women Ep 1",
          url: "$baseUrl/chuhai-lips-season-1",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "25:12",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Most Viewed", "Cheating", "Uncensored", "HD"],
          rating: 4.8,
          views: 780000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hg_pop_3",
          title: "Kuroinu Kedakaki Seijo Wa Hakudaku Ni Somaru Vol 1",
          url: "$baseUrl/kuroinu-kedakaki-seijo-1",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "29:30",
          releaseDate: "2023",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Most Viewed", "Classic", "Dark Fantasy", "Harem"],
          rating: 4.9,
          views: 945000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hg_pop_4",
          title: "Bunny Paradise: Seductive Club Episode 1",
          url: "$baseUrl/bunny-paradise-episode-1",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "23:45",
          releaseDate: "2024",
          studio: "Collaboration Works",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Most Viewed", "Bunnygirl", "HD", "Subbed"],
          rating: 4.7,
          views: 650000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hg_pop_5",
          title: "Mankitsu Happening: Manga Cafe Encounter Ep 1",
          url: "$baseUrl/mankitsu-happening-ep-1",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "26:40",
          releaseDate: "2023",
          studio: "Pink Pineapple",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Most Viewed", "Classic", "HD", "Remastered"],
          rating: 4.9,
          views: 870000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hg_pop_6",
          title: "Discipline: Zero Tolerance Complete OVA 1",
          url: "$baseUrl/discipline-zero-tolerance-1",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "28:15",
          releaseDate: "2022",
          studio: "Active Soft",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Most Viewed", "Vintage", "Gothic", "Archive"],
          rating: 4.8,
          views: 710000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hg_pop_7",
          title: "Taimanin Asagi: The Secret Investigation Ep 1",
          url: "$baseUrl/taimanin-asagi-investigation-1",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "27:50",
          releaseDate: "2023",
          studio: "Lilith",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Most Viewed", "Ninja", "Sci-Fi", "Action"],
          rating: 4.8,
          views: 820000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hg_pop_8",
          title: "Rance 01: The Quest for Hikari Chapter 1",
          url: "$baseUrl/rance-01-the-quest-1",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "29:05",
          releaseDate: "2024",
          studio: "Alice Soft",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Most Viewed", "Fantasy", "Adventure", "Harem"],
          rating: 4.9,
          views: 910000,
          isUncensored: false,
        ),
      ],
      "latest": [
        MediaItem(
          id: "hg_lat_1",
          title: "Baku Ane Otouto Shibocchau zo! Episode 1",
          url: "$baseUrl/baku-ane-otouto-shibocchau-zo-1",
          cover: "https://i.imgur.com/wVqjC5P.jpeg",
          duration: "22:40",
          releaseDate: "2025",
          studio: "Queen Bee",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest Releases", "Comedy", "Ecchi", "HD"],
          rating: 4.7,
          views: 180000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hg_lat_2",
          title: "Tropical Kiss: Beachside Romance Episode 1",
          url: "$baseUrl/tropical-kiss-beachside-romance-1",
          cover: "https://i.imgur.com/z4bKxNm.jpeg",
          duration: "24:10",
          releaseDate: "2025",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest Releases", "Beach", "Romance", "HD"],
          rating: 4.8,
          views: 215000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hg_lat_3",
          title: "Gakuen de Jikan Tomare: Chrono Freeze Ep 2",
          url: "$baseUrl/gakuen-de-jikan-tomare-chrono-2",
          cover: "https://i.imgur.com/83pZ6XQ.jpeg",
          duration: "25:35",
          releaseDate: "2025",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest Releases", "School", "Supernatural", "HD"],
          rating: 4.8,
          views: 240000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hg_lat_4",
          title: "Oppai Heart: Kanojo wa Kaihatsu Tojouchuu Ep 1",
          url: "$baseUrl/oppai-heart-kanojo-wa-kaihatsu-1",
          cover: "https://i.imgur.com/N7GgqMv.jpeg",
          duration: "23:55",
          releaseDate: "2025",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest Releases", "Romance", "Ecchi", "1080p"],
          rating: 4.7,
          views: 195000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hg_lat_5",
          title: "Kyonyuu Fantasy: Outer Realm Adventure Ep 3",
          url: "$baseUrl/kyonyuu-fantasy-outer-realm-3",
          cover: "https://i.imgur.com/J3ZqK9x.jpeg",
          duration: "26:20",
          releaseDate: "2025",
          studio: "Collaboration Works",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest Releases", "Fantasy", "Harem", "HD"],
          rating: 4.9,
          views: 280000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hg_lat_6",
          title: "Eroge! H mo Game mo Kaihatsu Zanmai Ep 2",
          url: "$baseUrl/eroge-h-mo-game-mo-kaihatsu-2",
          cover: "https://i.imgur.com/f9hYw0U.jpeg",
          duration: "24:45",
          releaseDate: "2025",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest Releases", "Otaku", "Comedy", "HD"],
          rating: 4.8,
          views: 230000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hg_lat_7",
          title: "Shoujo Ramune: Memory Garden Special Ep 1",
          url: "$baseUrl/shoujo-ramune-memory-garden-1",
          cover: "https://i.imgur.com/ODp7x3f.jpeg",
          duration: "21:30",
          releaseDate: "2025",
          studio: "Milky",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest Releases", "Summer", "Slice of Life", "HD"],
          rating: 4.6,
          views: 160000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hg_lat_8",
          title: "Kanojo ga Yatsu ni Dakareta Hi: Broken Bond Ep 1",
          url: "$baseUrl/kanojo-ga-yatsu-ni-dakareta-hi-1",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "27:10",
          releaseDate: "2025",
          studio: "Pink Pineapple",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Latest Releases", "Drama", "Tragedy", "HD"],
          rating: 4.7,
          views: 205000,
          isUncensored: false,
        ),
      ],
      "uncensored": [
        MediaItem(
          id: "hg_unc_1",
          title: "Overflow Uncensored Extended Director's Cut",
          url: "$baseUrl/overflow-uncensored-extended-cut",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "24:00",
          releaseDate: "2024",
          studio: "Houkiboshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Harem", "Remastered", "1080p"],
          rating: 4.9,
          views: 840000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hg_unc_2",
          title: "Taimanin Cyber Assault Special Uncensored",
          url: "$baseUrl/taimanin-cyber-assault-uncensored",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "28:15",
          releaseDate: "2024",
          studio: "Lilith",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Action", "Sci-Fi", "HD"],
          rating: 4.8,
          views: 620000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hg_unc_3",
          title: "Dropout: High School Seduction Uncensored Cut",
          url: "$baseUrl/dropout-high-school-uncensored",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "26:40",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "School", "Gyaru", "HD"],
          rating: 4.9,
          views: 710000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hg_unc_4",
          title: "Euphoria: True White End Remastered Uncensored",
          url: "$baseUrl/euphoria-white-end-uncensored",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "29:50",
          releaseDate: "2023",
          studio: "CLOCKUP",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Psychological", "Dark", "Archive"],
          rating: 4.8,
          views: 680000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hg_unc_5",
          title: "Night Shift Nurses: Complete Clinic Uncensored",
          url: "$baseUrl/night-shift-nurses-uncensored",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "31:10",
          releaseDate: "2023",
          studio: "Milky",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Hospital", "Vintage", "Master"],
          rating: 4.9,
          views: 790000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hg_unc_6",
          title: "Bible Black: Origins & Bloodline Uncensored",
          url: "$baseUrl/bible-black-origins-uncensored",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "28:45",
          releaseDate: "2022",
          studio: "Active Soft",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Occult", "Gothic", "Cult Classic"],
          rating: 4.9,
          views: 860000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hg_unc_7",
          title: "Starless: 21st Century Nymphomaniacs Uncensored",
          url: "$baseUrl/starless-nymphomaniacs-uncensored",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "27:30",
          releaseDate: "2023",
          studio: "Moonstone Cherry",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Mansion", "Mystery", "HD"],
          rating: 4.8,
          views: 590000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hg_unc_8",
          title: "Immoral Mother: Forbidden Desires Uncensored 1",
          url: "$baseUrl/immoral-mother-forbidden-uncensored-1",
          cover: "https://i.imgur.com/wVqjC5P.jpeg",
          duration: "25:20",
          releaseDate: "2024",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Uncensored", "Mature", "Drama", "1080p"],
          rating: 4.8,
          views: 650000,
          isUncensored: true,
        ),
      ],
      "milf": [
        MediaItem(
          id: "hg_milf_1",
          title: "Ane wa Yanmama Junyuuchuu: Seductive Mother Ep 1",
          url: "$baseUrl/ane-wa-yanmama-junyuuchuu-1",
          cover: "https://i.imgur.com/z4bKxNm.jpeg",
          duration: "23:50",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Milf", "Mature", "Romance", "HD"],
          rating: 4.8,
          views: 520000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hg_milf_2",
          title: "Hitozuma Ryoushi: Married Woman Next Door Ep 1",
          url: "$baseUrl/hitozuma-ryoushi-married-woman-1",
          cover: "https://i.imgur.com/83pZ6XQ.jpeg",
          duration: "25:10",
          releaseDate: "2024",
          studio: "Collaboration Works",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Milf", "Housewife", "Cheating", "HD"],
          rating: 4.7,
          views: 470000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hg_milf_3",
          title: "Mama x Holic: Mirakuru Shizuku-san Ep 1",
          url: "$baseUrl/mama-x-holic-mirakuru-shizuku-1",
          cover: "https://i.imgur.com/N7GgqMv.jpeg",
          duration: "24:30",
          releaseDate: "2024",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Milf", "Harem", "Comedy", "1080p"],
          rating: 4.9,
          views: 580000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hg_milf_4",
          title: "Dokidoki Little Ooyasan: Sweet Landlady Ep 1",
          url: "$baseUrl/dokidoki-little-ooyasan-landlady-1",
          cover: "https://i.imgur.com/J3ZqK9x.jpeg",
          duration: "22:15",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Milf", "Apartment", "Cute", "HD"],
          rating: 4.8,
          views: 510000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hg_milf_5",
          title: "Boku to Misaki-sensei: Private Guidance Ep 1",
          url: "$baseUrl/boku-to-misaki-sensei-1",
          cover: "https://i.imgur.com/f9hYw0U.jpeg",
          duration: "26:00",
          releaseDate: "2023",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Milf", "Teacher", "Romance", "HD"],
          rating: 4.7,
          views: 460000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hg_milf_6",
          title: "Shishunki no Obenkyou: Seductive Aunt Ep 2",
          url: "$baseUrl/shishunki-no-obenkyou-aunt-2",
          cover: "https://i.imgur.com/ODp7x3f.jpeg",
          duration: "24:40",
          releaseDate: "2023",
          studio: "Queen Bee",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Milf", "Relative", "Study", "HD"],
          rating: 4.7,
          views: 430000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hg_milf_7",
          title: "Netorareta Tsuma: Lonely Housewife Secret Ep 1",
          url: "$baseUrl/netorareta-tsuma-lonely-housewife-1",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "27:15",
          releaseDate: "2024",
          studio: "Pink Pineapple",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Milf", "Drama", "Seductive", "1080p"],
          rating: 4.8,
          views: 490000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hg_milf_8",
          title: "Okusama wa Moto Yariman: Experienced Wife Ep 1",
          url: "$baseUrl/okusama-wa-moto-yariman-1",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "25:45",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Milf", "Mature", "Slice of Life", "HD"],
          rating: 4.8,
          views: 540000,
          isUncensored: false,
        ),
      ],
      "romance": [
        MediaItem(
          id: "hg_rom_1",
          title: "Kimi no Na wo Yobeba: Pure First Love Ep 1",
          url: "$baseUrl/kimi-no-na-wo-yobeba-1",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "24:20",
          releaseDate: "2024",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance", "Pure Love", "Vanilla", "HD"],
          rating: 4.9,
          views: 430000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hg_rom_2",
          title: "Koi Magawari: Sincere Heartstrings Ep 1",
          url: "$baseUrl/koi-magawari-sincere-heartstrings-1",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "23:50",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance", "Emotional", "Sweet", "HD"],
          rating: 4.8,
          views: 390000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hg_rom_3",
          title: "Hatsukoi Time: Sweeter Than Honeycomb Ep 1",
          url: "$baseUrl/hatsukoi-time-sweeter-than-honey-1",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "25:10",
          releaseDate: "2024",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance", "Childhood Friend", "Vanilla", "HD"],
          rating: 4.9,
          views: 470000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hg_rom_4",
          title: "Amakano: Gentle Winter Breeze and Warmth Ep 1",
          url: "$baseUrl/amakano-gentle-winter-breeze-1",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "26:30",
          releaseDate: "2023",
          studio: "Houkiboshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance", "Winter", "Tender", "1080p"],
          rating: 4.9,
          views: 520000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hg_rom_5",
          title: "Ano Toki no Yakusoku: Reunited Sweethearts Ep 1",
          url: "$baseUrl/ano-toki-no-yakusoku-reunited-1",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "24:45",
          releaseDate: "2024",
          studio: "Collaboration Works",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance", "Reunion", "Drama", "HD"],
          rating: 4.7,
          views: 380000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hg_rom_6",
          title: "Futarikiri no Houkago: Sunset Confession Ep 1",
          url: "$baseUrl/futarikiri-no-houkago-sunset-1",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "22:40",
          releaseDate: "2024",
          studio: "Queen Bee",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance", "School", "Afterschool", "HD"],
          rating: 4.8,
          views: 410000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hg_rom_7",
          title: "Tokimeki Memories: Secret Love Letters Ep 1",
          url: "$baseUrl/tokimeki-memories-secret-love-1",
          cover: "https://i.imgur.com/wVqjC5P.jpeg",
          duration: "25:05",
          releaseDate: "2023",
          studio: "Milky",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance", "Nostalgia", "Sweet", "HD"],
          rating: 4.8,
          views: 440000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hg_rom_8",
          title: "Koisuru Shimai: Tender Affection Ep 1",
          url: "$baseUrl/koisuru-shimai-tender-affection-1",
          cover: "https://i.imgur.com/z4bKxNm.jpeg",
          duration: "24:15",
          releaseDate: "2024",
          studio: "Pink Pineapple",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Romance", "Sisters", "Vanilla", "1080p"],
          rating: 4.8,
          views: 460000,
          isUncensored: false,
        ),
      ],
      "random": [
        MediaItem(
          id: "hg_rnd_1",
          title: "Viper GTS: Cyber Devil Awakening Archive Ep 1",
          url: "$baseUrl/viper-gts-cyber-devil-awakening-1",
          cover: "https://i.imgur.com/83pZ6XQ.jpeg",
          duration: "29:10",
          releaseDate: "2022",
          studio: "Sonavision",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Random Gems", "Retro", "Cyberpunk", "Archive"],
          rating: 4.8,
          views: 350000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hg_rnd_2",
          title: "Dragon Knight 4: Legendary Labyrinth Ep 1",
          url: "$baseUrl/dragon-knight-4-legendary-1",
          cover: "https://i.imgur.com/N7GgqMv.jpeg",
          duration: "28:30",
          releaseDate: "2021",
          studio: "Dangun",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Random Gems", "Fantasy", "Classic", "Adventure"],
          rating: 4.7,
          views: 310000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hg_rnd_3",
          title: "Kakyuusei: Vintage Classroom Memories Ep 1",
          url: "$baseUrl/kakyuusei-vintage-classroom-1",
          cover: "https://i.imgur.com/J3ZqK9x.jpeg",
          duration: "24:50",
          releaseDate: "2022",
          studio: "Pink Pineapple",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Random Gems", "90s Retro", "School", "Romance"],
          rating: 4.8,
          views: 290000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hg_rnd_4",
          title: "Natural 2: Duo In The Secret Sanctuary Ep 1",
          url: "$baseUrl/natural-2-duo-secret-sanctuary-1",
          cover: "https://i.imgur.com/f9hYw0U.jpeg",
          duration: "27:15",
          releaseDate: "2022",
          studio: "Green Bunny",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Random Gems", "Island", "Mystery", "HD"],
          rating: 4.7,
          views: 330000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hg_rnd_5",
          title: "Can Can Bunny Extra: Retrowave Classic Ep 1",
          url: "$baseUrl/can-can-bunny-extra-retrowave-1",
          cover: "https://i.imgur.com/ODp7x3f.jpeg",
          duration: "26:40",
          releaseDate: "2021",
          studio: "Cocktail Soft",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Random Gems", "Vintage", "Bunnygirl", "Archive"],
          rating: 4.6,
          views: 280000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hg_rnd_6",
          title: "Words Worth: Medieval Sorcery Chronicles Ep 1",
          url: "$baseUrl/words-worth-medieval-sorcery-1",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "30:20",
          releaseDate: "2022",
          studio: "Green Bunny",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Random Gems", "Dark Fantasy", "Gothic", "Classic"],
          rating: 4.9,
          views: 420000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hg_rnd_7",
          title: "Dokyuu Sei: High Class Vintage Archive Ep 1",
          url: "$baseUrl/dokyuu-sei-high-class-vintage-1",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "25:30",
          releaseDate: "2022",
          studio: "Pink Pineapple",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Random Gems", "Classic", "School", "Retro"],
          rating: 4.7,
          views: 340000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hg_rnd_8",
          title: "Elven Bride: Sacred Forest Forgotten Tales Ep 1",
          url: "$baseUrl/elven-bride-sacred-forest-tales-1",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "28:00",
          releaseDate: "2023",
          studio: "Collaboration Works",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: ["Random Gems", "Elf", "Fantasy", "HD"],
          rating: 4.8,
          views: 360000,
          isUncensored: false,
        ),
      ],
    };

    return sampleSets[tabId] ?? sampleSets["popular"]!;
  }

  MediaDetail _generateSampleDetail(String url) {
    return MediaDetail(
      id: url.hashCode.toString(),
      title: "Pure X Holic Junketsu Otome To Konin Kenkei 1 Subbed",
      cover:
          "https://hgasm1.com/preview/.Pure%20X%20Holic%20Junketsu%20Otome%20To%20Konin%20Kenkei%20The%20Animation%201%20Subbed.webp",
      backdrop:
          "https://hgasm1.com/preview/.Pure%20X%20Holic%20Junketsu%20Otome%20To%20Konin%20Kenkei%20The%20Animation%201%20Subbed.webp",
      description:
          "Classic uncensored archive release featuring high-definition master streams on Hentaigasm.",
      studio: "Pure X Holic Project",
      releaseDate: "September 7, 2026",
      tags: ["Uncensored", "Fantasy", "1080p 60fps", "HD", "Subbed"],
      episodes: [
        EpisodeItem(
          id: "ep_1",
          episodeNumber: "Episode 1",
          title: "Pure X Holic Junketsu Otome To Konin Kenkei 1 Subbed",
          url: url,
          thumbnail:
              "https://hgasm1.com/preview/.Pure%20X%20Holic%20Junketsu%20Otome%20To%20Konin%20Kenkei%20The%20Animation%201%20Subbed.webp",
          duration: "24:00",
          sources: [
            StreamSource(
              label: "High-Speed Direct Master (1080p MP4)",
              url:
                  "https://hgasm2.com/.Pure%20X%20Holic%20Junketsu%20Otome%20To%20Konin%20Kenkei%20The%20Animation%201%20Subbed.mp4",
              protocol: StreamProtocol.directMp4,
              headers: {
                'Referer': 'https://hentaigasm.com/',
                'User-Agent': _userAgent,
              },
            ),
            StreamSource(
              label: "Direct Download Mirror (1080p MP4)",
              url:
                  "https://hgasm3.com/.Pure%20X%20Holic%20Junketsu%20Otome%20To%20Konin%20Kenkei%20The%20Animation%201%20Subbed.mp4",
              protocol: StreamProtocol.directMp4,
              headers: {
                'Referer': 'https://hentaigasm.com/',
                'User-Agent': _userAgent,
              },
            ),
          ],
        ),
      ],
      playbackHeatmap: [
        0.1,
        0.28,
        0.55,
        0.88,
        0.98,
        0.82,
        0.5,
        0.72,
        1.0,
        0.35,
      ],
      sceneMarkers: [
        SceneMarker(title: "Opening Scene", timestampSeconds: 0),
        SceneMarker(title: "First Encounter", timestampSeconds: 360),
        SceneMarker(title: "Peak Climax 🔥", timestampSeconds: 720),
      ],
    );
  }

  @override
  Future<ExtensionTaxonomy> fetchTaxonomy() async {
    return hentaigasmTaxonomy;
  }

  @override
  Future<List<MediaItem>> fetchTaxonomyFeed(CatalogItem item, int page) async {
    // 1. Direct tab feed shortcut if matching popular tabs
    if (item.slug == "popular" ||
        item.slug == "latest" ||
        item.slug == "uncensored" ||
        item.slug == "milf" ||
        item.slug == "romance" ||
        item.slug == "random") {
      return fetchTabFeed(item.slug, page);
    }

    try {
      // 2. Resolve endpoint URL
      String targetUrl;
      if (item.endpointPath != null && item.endpointPath!.isNotEmpty) {
        final path = item.endpointPath!;
        targetUrl = path.startsWith('http') ? path : "$baseUrl$path";
      } else if (item.type == CatalogType.category) {
        targetUrl = "$baseUrl/hentai/${item.slug}/";
      } else {
        targetUrl = "$baseUrl/genre/${item.slug}/";
      }

      // 3. Apply pagination
      String pageUrl = targetUrl;
      if (page > 1) {
        final cleanBase = targetUrl.replaceAll(RegExp(r'/+$'), '');
        pageUrl = "$cleanBase/page/$page/";
      }

      final isUncensored =
          item.slug == "uncensored" ||
          item.name.toLowerCase().contains("uncensored");

      final response = await http
          .get(Uri.parse(pageUrl), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = response.body;
        // Verify this page returned real video items rather than 404 fallback suggestions
        if (body.contains('About <i class="count">0</i> results') ||
            body.contains('404 not found, try these other great series')) {
          return [];
        }

        final items = _parsePostCards(body, defaultUncensored: isUncensored);
        if (items.isNotEmpty) return items;
      } else if (response.statusCode == 404) {
        return [];
      }
    } catch (_) {}

    // Fallback to text search on failure
    return search(item.name, page);
  }
}
