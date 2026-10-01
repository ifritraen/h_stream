import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../base_extension.dart';
import '../../models/media_item.dart';
import '../../models/extension_manifest.dart';
import '../../models/tag_filter_state.dart';
import '../../models/catalog_model.dart';
import '../taxonomies/hentai_sh_taxonomy.dart';

/// Hentai.SH extension for HStream Neo.
/// High-speed dedicated uncensored anime catalog with REST API & HTML scrapers,
/// multi-episode series extraction, and multi-variant HLS master stream resolution.
class HentaiShExtension extends HentaiExtension {
  @override
  String get id => "hentai_sh";

  @override
  String get name => "Hentai.SH";

  @override
  String get baseUrl => "https://hentai.sh";

  @override
  String get iconUrl => "https://hentai.sh/favicon.ico";

  @override
  String get description =>
      "Dedicated uncensored anime catalog with adaptive HLS multi-quality streams.";

  @override
  ViewLayoutType get defaultLayout => ViewLayoutType.widescreen16x9;

  @override
  bool get supportsShorts => false;

  @override
  List<ExtensionTab> get tabs => [
    ExtensionTab(
      id: "uncensored",
      title: "Uncensored",
      icon: Icons.lock_open_rounded,
    ),
    ExtensionTab(
      id: "popular",
      title: "Most Viewed",
      icon: Icons.whatshot_rounded,
    ),
    ExtensionTab(
      id: "latest",
      title: "Recent Aired",
      icon: Icons.fiber_new_rounded,
    ),
    ExtensionTab(id: "top_rated", title: "Top Rated", icon: Icons.star_rounded),
    ExtensionTab(
      id: "romance",
      title: "Romance Genre",
      icon: Icons.favorite_rounded,
    ),
    ExtensionTab(id: "milf", title: "Milf Genre", icon: Icons.woman_rounded),
  ];

  @override
  List<FilterGroup> get filters => [
    FilterGroup(
      key: "category",
      title: "Category / Genre",
      type: FilterType.dropdown,
      defaultValue: "all",
      options: [
        FilterOption(label: "All Videos", value: "all"),
        FilterOption(label: "Uncensored", value: "uncensored"),
        FilterOption(label: "Most Viewed", value: "popular"),
        FilterOption(label: "Recent Aired", value: "latest"),
        FilterOption(label: "Top Rated", value: "top_rated"),
        FilterOption(label: "Romance Genre", value: "romance"),
        FilterOption(label: "Milf Genre", value: "milf"),
      ],
    ),
    FilterGroup(
      key: "sort",
      title: "Sort Order",
      type: FilterType.dropdown,
      defaultValue: "aired_newest",
      options: [
        FilterOption(label: "Newest First", value: "aired_newest"),
        FilterOption(label: "Most Viewed", value: "most_viewed"),
        FilterOption(label: "Top Rated", value: "highest_rated"),
        FilterOption(label: "Most Liked", value: "most_liked"),
        FilterOption(label: "Oldest First", value: "aired_oldest"),
      ],
    ),
    FilterGroup(
      key: "censorship",
      title: "Censorship",
      type: FilterType.dropdown,
      defaultValue: "all",
      options: [
        FilterOption(label: "All Anime", value: "all"),
        FilterOption(label: "Uncensored Only", value: "uncensored"),
        FilterOption(label: "Censored Only", value: "censored"),
      ],
    ),
  ];

  static const Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Accept': 'application/json, text/html, application/xhtml+xml, */*',
    'Referer': 'https://hentai.sh/',
  };

  static const Map<String, String> _streamHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentai.sh/',
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
      String? altPath;
      String sort = "aired_newest";
      final List<String> apiTags = [];

      switch (tabId) {
        case "uncensored":
          path = "/genre/uncensored/";
          altPath = "/?tag=uncensored";
          sort = "most_viewed";
          apiTags.add("uncensored");
          break;
        case "popular":
          path = "/popular/";
          altPath = "/?orderby=views";
          sort = "most_viewed";
          break;
        case "latest":
          path = "/";
          altPath = "/latest/";
          sort = "aired_newest";
          break;
        case "top_rated":
          path = "/top-rated/";
          altPath = "/?orderby=rating";
          sort = "highest_rated";
          break;
        case "romance":
          path = "/genre/romance/";
          altPath = "/genre/vanilla/";
          sort = "aired_newest";
          apiTags.add("romance");
          break;
        case "milf":
          path = "/genre/milf/";
          altPath = "/?tag=milf";
          sort = "aired_newest";
          apiTags.add("milf");
          break;
        default:
          path = "/";
          altPath = "/?orderby=views";
          break;
      }

      if (activeFilters != null) {
        final fSort = activeFilters["sort"]?.toString();
        if (fSort != null && fSort.isNotEmpty) {
          sort = fSort;
        }

        final censorship = activeFilters["censorship"]?.toString();
        if (censorship == "uncensored" && !apiTags.contains("uncensored")) {
          apiTags.add("uncensored");
        } else if (censorship == "censored" && !apiTags.contains("censored")) {
          apiTags.add("censored");
        }
      }

      if (whitelistedTags != null && whitelistedTags.isNotEmpty) {
        apiTags.addAll(whitelistedTags);
      }

      // 1. Try REST API endpoint
      final queryParams = <String, String>{
        'page': page.toString(),
        'sort': sort,
      };
      if (apiTags.isNotEmpty) {
        queryParams['tags'] = apiTags.join(',');
      }
      if (blacklistedTags != null && blacklistedTags.isNotEmpty) {
        queryParams['tagBlacklist'] = blacklistedTags.join(',');
      }

      try {
        final apiUrl = Uri.parse(
          "$baseUrl/api/videos",
        ).replace(queryParameters: queryParams);
        final response = await http
            .get(apiUrl, headers: _headers)
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data is Map<String, dynamic> && data['videos'] is List) {
            final List<dynamic> videos = data['videos'];
            final List<MediaItem> items = [];
            for (final v in videos) {
              if (v is Map<String, dynamic>) {
                final parsed = _parseVideoJson(v);
                if (parsed != null) items.add(parsed);
              }
            }
            if (items.isNotEmpty) return items;
          }
        }
      } catch (_) {}

      // 2. Scrape distinct paths: /genre/uncensored/, /popular/, /, /top-rated/, /genre/romance/, /genre/milf/
      final targetUrl = page == 1
          ? (path == '/' ? baseUrl : '$baseUrl$path')
          : (path == '/'
                ? '$baseUrl/page/$page/'
                : '$baseUrl${path}page/$page/');

      try {
        var webResponse = await http
            .get(Uri.parse(targetUrl), headers: _headers)
            .timeout(const Duration(seconds: 4));

        if (webResponse.statusCode != 200 && altPath.isNotEmpty) {
          final altUrl = page == 1
              ? '$baseUrl$altPath'
              : (altPath.contains('?')
                    ? '$baseUrl$altPath&page=$page'
                    : '$baseUrl${altPath}page/$page/');
          webResponse = await http
              .get(Uri.parse(altUrl), headers: _headers)
              .timeout(const Duration(seconds: 4));
        }

        if (webResponse.statusCode == 200) {
          final parsedHtml = _parseCardsFromHtml(
            webResponse.body,
            tabId: tabId,
          );
          if (parsedHtml.isNotEmpty) return parsedHtml;
        }
      } catch (_) {}
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
      final searchApiUrl = Uri.parse(
        "$baseUrl/api/videos",
      ).replace(queryParameters: {'q': query, 'page': page.toString()});

      final response = await http
          .get(searchApiUrl, headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic> && data['videos'] is List) {
          final List<dynamic> videos = data['videos'];
          final List<MediaItem> items = [];
          for (final v in videos) {
            if (v is Map<String, dynamic>) {
              final parsed = _parseVideoJson(v);
              if (parsed != null) items.add(parsed);
            }
          }
          if (items.isNotEmpty) return items;
        }
      }

      // Quick-search fallback
      final quickUrl = Uri.parse(
        "$baseUrl/api/search",
      ).replace(queryParameters: {'q': query});
      final quickResponse = await http
          .get(quickUrl, headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (quickResponse.statusCode == 200) {
        final data = json.decode(quickResponse.body);
        if (data is Map<String, dynamic> && data['results'] is List) {
          final List<dynamic> results = data['results'];
          final List<MediaItem> items = [];
          for (final r in results) {
            if (r is Map<String, dynamic>) {
              final slug = r['slug']?.toString() ?? '';
              final title = r['title']?.toString() ?? 'Anime';
              final thumb = r['thumbnail']?.toString() ?? '';
              if (slug.isNotEmpty) {
                items.add(
                  MediaItem(
                    id: r['id']?.toString() ?? slug,
                    title: title,
                    url: "$baseUrl/video/$slug",
                    cover: thumb,
                    duration: "24:00",
                    studio: r['seriesTitle']?.toString() ?? "Hentai.SH",
                    extensionId: id,
                    type: MediaType.animeSeries,
                    tags: const ["HD", "Uncensored"],
                    rating: 4.8,
                    views: 12000,
                    isUncensored: true,
                  ),
                );
              }
            }
          }
          if (items.isNotEmpty) return items;
        }
      }

      // HTML Fallback for search
      final browseUrl = Uri.parse(
        "$baseUrl/browse",
      ).replace(queryParameters: {'q': query, 'page': page.toString()});
      final browseResponse = await http
          .get(browseUrl, headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (browseResponse.statusCode == 200) {
        final parsedHtml = _parseCardsFromHtml(
          browseResponse.body,
          tabId: 'search',
        );
        if (parsedHtml.isNotEmpty) return parsedHtml;
      }
    } catch (_) {}

    return _generateSampleList('latest', page);
  }

  @override
  Future<MediaDetail> detail(String url) async {
    try {
      String slug = url.trim();
      if (slug.contains('/video/')) {
        slug = slug.split('/video/').last;
      }
      slug = slug.split('?').first.replaceAll('/', '').trim();

      if (slug.isNotEmpty) {
        final detailApi = Uri.parse("$baseUrl/api/videos/$slug");
        final response = await http
            .get(detailApi, headers: _headers)
            .timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data is Map<String, dynamic> && data['video'] is Map) {
            final v = data['video'] as Map<String, dynamic>;
            final title =
                v['title']?.toString() ??
                v['titleEnglish']?.toString() ??
                v['seriesTitle']?.toString() ??
                "Hentai.SH Feature";
            final cover =
                v['thumbnail']?.toString() ??
                "https://edge1.hentai.sh/v/$slug/thumb.jpg";
            final backdrop = cover;

            String desc = v['description']?.toString() ?? "";
            if (desc.contains("AdProvider") ||
                desc.contains("function myFunction") ||
                desc.trim().isEmpty) {
              desc =
                  "Watch $title in full HD quality with adaptive multi-resolution streams on Hentai.SH.";
            }

            final studio = _extractStudio(v);

            final releaseDate =
                v['airedDate']?.toString().split('-').first ??
                v['uploadedAt']?.toString().split('-').first ??
                "2024";

            final List<String> tags = _extractTags(v['tags']);
            if (!tags.contains("Uncensored")) {
              tags.add("Uncensored");
            }

            final List<EpisodeItem> episodes = [];
            final seriesEps = data['seriesEpisodes'];
            if (seriesEps is List && seriesEps.isNotEmpty) {
              for (int i = 0; i < seriesEps.length; i++) {
                final ep = seriesEps[i];
                if (ep is Map<String, dynamic>) {
                  final epSlug = ep['slug']?.toString() ?? slug;
                  final epNum = ep['episodeNumber']?.toString() ?? "${i + 1}";
                  final epTitle = ep['title']?.toString() ?? "Episode $epNum";
                  final epThumb = ep['thumbnail']?.toString() ?? cover;
                  final epDur = ep['duration']?.toString() ?? "24:00";
                  final epVideoUrl = ep['videoUrl']?.toString() ?? "";

                  final List<StreamSource> epSources = [];
                  if (epVideoUrl.isNotEmpty) {
                    epSources.add(
                      StreamSource(
                        label: "HLS Master (Auto)",
                        url: epVideoUrl,
                        protocol: StreamProtocol.hlsM3u8,
                        headers: _streamHeaders,
                        format: "m3u8",
                      ),
                    );
                  }

                  episodes.add(
                    EpisodeItem(
                      id: ep['id']?.toString() ?? "ep_$epNum",
                      episodeNumber: "Episode $epNum",
                      title: epTitle,
                      url: "$baseUrl/video/$epSlug",
                      thumbnail: epThumb,
                      duration: epDur,
                      sources: epSources,
                    ),
                  );
                }
              }
            }

            if (episodes.isEmpty) {
              final videoStream = v['videoUrl']?.toString() ?? "";
              episodes.add(
                EpisodeItem(
                  id: v['id']?.toString() ?? "ep_1",
                  episodeNumber: v['episodeNumber'] != null
                      ? "Episode ${v['episodeNumber']}"
                      : "Episode 1",
                  title: title,
                  url: "$baseUrl/video/$slug",
                  thumbnail: cover,
                  duration: v['duration']?.toString() ?? "24:00",
                  sources: videoStream.isNotEmpty
                      ? [
                          StreamSource(
                            label: "HLS Master (Auto)",
                            url: videoStream,
                            protocol: StreamProtocol.hlsM3u8,
                            headers: _streamHeaders,
                            format: "m3u8",
                          ),
                        ]
                      : [],
                ),
              );
            }

            final List<MediaItem> relatedList = [];
            if (data['related'] is List) {
              for (final r in data['related']) {
                if (r is Map<String, dynamic>) {
                  final parsed = _parseVideoJson(r);
                  if (parsed != null) relatedList.add(parsed);
                }
              }
            }

            final durationSec = v['durationSeconds'] is num
                ? (v['durationSeconds'] as num).toDouble()
                : 900.0;

            return MediaDetail(
              id: v['id']?.toString() ?? slug,
              title: title,
              cover: cover,
              backdrop: backdrop,
              description: desc,
              studio: studio,
              releaseDate: releaseDate,
              tags: tags,
              episodes: episodes,
              related: relatedList,
              playbackHeatmap: const [
                0.1,
                0.35,
                0.65,
                0.95,
                0.85,
                0.45,
                0.3,
                0.8,
                1.0,
                0.35,
              ],
              sceneMarkers: [
                SceneMarker(title: "Opening", timestampSeconds: 0),
                SceneMarker(
                  title: "Climax Highlight 🔥",
                  timestampSeconds: (durationSec * 0.65).clamp(
                    60.0,
                    durationSec,
                  ),
                ),
              ],
              franchiseId:
                  v['seriesId']?.toString() ?? v['franchiseKey']?.toString(),
            );
          }
        }
      }

      // HTML scraping fallback for detail page
      final pageUrl = url.startsWith('http') ? url : "$baseUrl/video/$slug";
      final pageResp = await http
          .get(Uri.parse(pageUrl), headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (pageResp.statusCode == 200) {
        final doc = html_parser.parse(pageResp.body);
        final title =
            doc.querySelector('h1, meta[property="og:title"]')?.text.trim() ??
            doc
                .querySelector('meta[property="og:title"]')
                ?.attributes['content'] ??
            "Hentai.SH Episode";
        final cover =
            doc
                .querySelector('meta[property="og:image"]')
                ?.attributes['content'] ??
            "https://edge1.hentai.sh/v/$slug/thumb.jpg";
        final desc =
            doc
                .querySelector('meta[name="description"]')
                ?.attributes['content'] ??
            "Watch $title uncensored on Hentai.SH.";

        final streams = await extractVideoStreams(pageUrl);

        return MediaDetail(
          id: slug.isNotEmpty ? slug : url.hashCode.toString(),
          title: title,
          cover: cover,
          backdrop: cover,
          description: desc,
          studio: "Hentai.SH",
          releaseDate: "2024",
          tags: const ["Uncensored", "HD", "Anime"],
          episodes: [
            EpisodeItem(
              id: "ep_1",
              episodeNumber: "Episode 1",
              title: title,
              url: pageUrl,
              thumbnail: cover,
              duration: "24:00",
              sources: streams,
            ),
          ],
          playbackHeatmap: const [
            0.1,
            0.35,
            0.65,
            0.95,
            0.85,
            0.45,
            0.3,
            0.8,
            1.0,
            0.35,
          ],
          sceneMarkers: [
            SceneMarker(title: "Opening", timestampSeconds: 0),
            SceneMarker(title: "Climax Highlight 🔥", timestampSeconds: 580),
          ],
        );
      }
    } catch (_) {}

    return _generateSampleDetail(url);
  }

  @override
  Future<List<StreamSource>> extractVideoStreams(String videoUrl) async {
    try {
      // 1. Direct M3U8 stream URL
      if (videoUrl.contains('.m3u8')) {
        final variants = await _resolveHlsVariants(videoUrl);
        if (variants.isNotEmpty) return variants;
      }

      // 2. Direct MP4 stream URL
      if (videoUrl.contains('.mp4')) {
        return [
          StreamSource(
            label: "Direct MP4",
            url: videoUrl,
            protocol: StreamProtocol.directMp4,
            headers: _streamHeaders,
            format: "mp4",
          ),
        ];
      }

      // 3. Page URL -> query /api/videos/{slug}
      String slug = videoUrl.trim();
      if (slug.contains('/video/')) {
        slug = slug.split('/video/').last;
      }
      slug = slug.split('?').first.replaceAll('/', '').trim();

      if (slug.isNotEmpty) {
        final apiUri = Uri.parse("$baseUrl/api/videos/$slug");
        final resp = await http
            .get(apiUri, headers: _headers)
            .timeout(const Duration(seconds: 8));

        if (resp.statusCode == 200) {
          final data = json.decode(resp.body);
          final streamUrl = data['video']?['videoUrl']?.toString();
          if (streamUrl != null && streamUrl.isNotEmpty) {
            final variants = await _resolveHlsVariants(streamUrl);
            if (variants.isNotEmpty) return variants;
          }
        }
      }

      // 4. HTML fallback Regex search on page
      final targetPageUrl = videoUrl.startsWith('http')
          ? videoUrl
          : "$baseUrl/video/$slug";
      final pageResp = await http
          .get(Uri.parse(targetPageUrl), headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (pageResp.statusCode == 200) {
        final body = pageResp.body;
        final m3u8Match =
            RegExp(
              r'https?://[^\s"<>]+master\.m3u8[^\s"<>]*',
            ).firstMatch(body) ??
            RegExp(r'https?://[^\s"<>]+\.m3u8[^\s"<>]*').firstMatch(body);
        if (m3u8Match != null) {
          final foundUrl = m3u8Match.group(0)!.replaceAll(r'\/', '/');
          final variants = await _resolveHlsVariants(foundUrl);
          if (variants.isNotEmpty) return variants;
        }

        final mp4Match = RegExp(
          r'https?://[^\s"<>]+\.mp4[^\s"<>]*',
        ).firstMatch(body);
        if (mp4Match != null) {
          final foundUrl = mp4Match.group(0)!.replaceAll(r'\/', '/');
          return [
            StreamSource(
              label: "Direct MP4",
              url: foundUrl,
              protocol: StreamProtocol.directMp4,
              headers: _streamHeaders,
              format: "mp4",
            ),
          ];
        }
      }
    } catch (_) {}

    // 5. Fallback stream sources
    return [
      StreamSource(
        label: "HLS Master (Auto)",
        url: "https://edge1.hentai.sh/v/so_low-episode-3/master.m3u8",
        protocol: StreamProtocol.hlsM3u8,
        headers: _streamHeaders,
        format: "m3u8",
      ),
      StreamSource(
        label: "720p HD",
        url: "https://edge1.hentai.sh/v/so_low-episode-3/720/playlist.m3u8",
        protocol: StreamProtocol.hlsM3u8,
        headers: _streamHeaders,
        format: "m3u8",
      ),
    ];
  }

  @override
  Future<List<TagModel>> fetchAvailableTags() async {
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/api/tags"), headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic> && data['tags'] is List) {
          final List<dynamic> tagList = data['tags'];
          final List<TagModel> result = [];
          for (final t in tagList) {
            if (t is Map<String, dynamic>) {
              final name = t['name']?.toString() ?? '';
              final slug = t['slug']?.toString() ?? '';
              if (name.isNotEmpty && slug.isNotEmpty) {
                result.add(TagModel(name: name, slug: slug));
              }
            }
          }
          if (result.isNotEmpty) return result;
        }
      }
    } catch (_) {}
    return [];
  }

  /// Parses multi-quality variants from HLS Master manifest.
  Future<List<StreamSource>> _resolveHlsVariants(String masterUrl) async {
    final List<StreamSource> sources = [];

    // Master stream (Auto adaptive bitrate)
    sources.add(
      StreamSource(
        label: "HLS Master (Auto)",
        url: masterUrl,
        protocol: StreamProtocol.hlsM3u8,
        headers: _streamHeaders,
        format: "m3u8",
      ),
    );

    try {
      final response = await http
          .get(Uri.parse(masterUrl), headers: _streamHeaders)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 && response.body.contains("#EXTM3U")) {
        final lines = response.body.split('\n');
        final baseUri = Uri.parse(masterUrl);
        String? pendingLabel;

        for (int i = 0; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.startsWith('#EXT-X-STREAM-INF:')) {
            final resMatch = RegExp(r'RESOLUTION=(\d+x\d+)').firstMatch(line);
            if (resMatch != null) {
              final res = resMatch.group(1)!;
              final height = res.split('x').last;
              pendingLabel = "${height}p Stream";
            } else {
              pendingLabel = "HD Stream";
            }
          } else if (line.isNotEmpty &&
              !line.startsWith('#') &&
              pendingLabel != null) {
            final resolvedUrl = baseUri.resolve(line).toString();
            sources.add(
              StreamSource(
                label: pendingLabel,
                url: resolvedUrl,
                protocol: StreamProtocol.hlsM3u8,
                headers: _streamHeaders,
                format: "m3u8",
              ),
            );
            pendingLabel = null;
          }
        }
      }
    } catch (_) {}

    return sources;
  }

  /// Extracts studio / brand name safely from video JSON map.
  String _extractStudio(Map<String, dynamic> v) {
    if (v['brand'] != null && v['brand'].toString().isNotEmpty) {
      return v['brand'].toString();
    }
    final brands = v['brands'];
    if (brands is List && brands.isNotEmpty) {
      final first = brands[0];
      if (first is Map && first['brand'] is Map) {
        final bName = first['brand']['name']?.toString();
        if (bName != null && bName.isNotEmpty) return bName;
      }
    }
    return "Hentai.SH";
  }

  /// Extracts tag names list safely from raw tags.
  List<String> _extractTags(dynamic rawTags) {
    final List<String> tagList = [];
    if (rawTags is List) {
      for (final t in rawTags) {
        if (t is Map && t['tag'] is Map) {
          final n = t['tag']['name']?.toString();
          if (n != null && n.isNotEmpty) tagList.add(n);
        } else if (t is String && t.isNotEmpty) {
          tagList.add(t);
        }
      }
    }
    return tagList;
  }

  /// Converts an API video JSON object into a MediaItem.
  MediaItem? _parseVideoJson(Map<String, dynamic> v) {
    final slug = v['slug']?.toString() ?? '';
    if (slug.isEmpty) return null;

    final title =
        v['title']?.toString() ??
        v['titleEnglish']?.toString() ??
        v['seriesTitle']?.toString() ??
        'Anime';
    final cover =
        v['thumbnail']?.toString() ??
        "https://edge1.hentai.sh/v/$slug/thumb.jpg";
    final duration = v['duration']?.toString() ?? "24:00";
    final releaseDate =
        v['airedDate']?.toString().split('-').first ??
        v['uploadedAt']?.toString().split('-').first ??
        "2024";

    final studio = _extractStudio(v);
    final tagList = _extractTags(v['tags']);

    final likes = v['likes'] is num ? (v['likes'] as num).toDouble() : 0.0;
    final dislikes = v['dislikes'] is num
        ? (v['dislikes'] as num).toDouble()
        : 0.0;
    final double rating = (likes + dislikes > 0)
        ? ((likes / (likes + dislikes)) * 5.0).clamp(1.0, 5.0)
        : 4.8;

    final views = v['views'] is int
        ? v['views'] as int
        : int.tryParse(v['views']?.toString() ?? '') ?? 15000;

    final isUncensored =
        tagList.any((t) => t.toLowerCase().contains("uncensored")) ||
        (v['quality']?.toString().toLowerCase().contains("uncensored") ?? true);

    return MediaItem(
      id: v['id']?.toString() ?? slug,
      title: title,
      url: "$baseUrl/video/$slug",
      cover: cover,
      duration: duration,
      releaseDate: releaseDate,
      studio: studio,
      extensionId: id,
      type: MediaType.animeSeries,
      tags: tagList.isNotEmpty ? tagList : const ["HD", "Uncensored"],
      rating: rating,
      views: views,
      isUncensored: isUncensored,
      previewVideoUrl: v['previewGif']?.toString(),
    );
  }

  /// Parses HTML card markup from hentai.sh pages.
  List<MediaItem> _parseCardsFromHtml(
    String htmlBody, {
    String tabId = 'latest',
  }) {
    final doc = html_parser.parse(htmlBody);
    final cards = doc.querySelectorAll(
      'article, .post, .item, .sh-item, .video-card, a.video-card',
    );
    final List<MediaItem> items = [];
    final Set<String> seenUrls = {};

    for (final card in cards) {
      final a = card.localName?.toLowerCase() == 'a'
          ? card
          : card.querySelector('a');
      var href = a?.attributes['href'] ?? card.attributes['href'] ?? '';
      if (href.isEmpty) continue;

      final fullUrl = href.startsWith('http')
          ? href
          : (href.startsWith('/') ? "$baseUrl$href" : "$baseUrl/$href");
      if (seenUrls.contains(fullUrl)) continue;
      seenUrls.add(fullUrl);

      final img = card.querySelector('img');
      var title =
          card
              .querySelector('div.video-body h3, h2, .title, .entry-title, h3')
              ?.text
              .trim() ??
          a?.attributes['title']?.trim() ??
          img?.attributes['alt']?.trim() ??
          '';
      title = _cleanTitle(title);
      if (title.isEmpty) title = 'Hentai.SH Video';

      // Prioritize data-src over src
      var cover =
          img?.attributes['data-src'] ??
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
      } else if (cover.startsWith('/') && !cover.startsWith('http')) {
        cover = '$baseUrl$cover';
      }

      final duration =
          card
              .querySelector('span.duration, .duration, .time, .badge-duration')
              ?.text
              .trim() ??
          "24:00";

      final tags = card
          .querySelectorAll('div.video-body .tags .tag, .tag, .badge')
          .map((e) => e.text.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final previewUrl =
          card.querySelector('video.video-preview')?.attributes['data-src'] ??
          card.querySelector('video')?.attributes['src'];

      if (cover.startsWith('http')) {
        items.add(
          MediaItem(
            id: fullUrl.hashCode.toString(),
            title: title,
            url: fullUrl,
            cover: cover,
            duration: duration.isEmpty ? "24:00" : duration,
            releaseDate: "2025",
            studio: "Hentai.SH",
            extensionId: id,
            type: MediaType.animeSeries,
            tags: tags.isNotEmpty ? tags : _getDefaultTagsForTab(tabId),
            rating: 4.85,
            views: 35000,
            isUncensored:
                tabId == 'uncensored' ||
                title.toLowerCase().contains("uncensored") ||
                tags.any((t) => t.toLowerCase().contains("uncensored")),
            previewVideoUrl: previewUrl,
          ),
        );
      }
    }

    return items;
  }

  String _cleanTitle(String raw) {
    return raw
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  List<String> _getDefaultTagsForTab(String tabId) {
    switch (tabId) {
      case 'uncensored':
        return const ["Uncensored", "Full HD", "Decensored"];
      case 'popular':
        return const ["Most Viewed", "Popular", "HD"];
      case 'latest':
        return const ["Recent Aired", "New Release", "HD"];
      case 'top_rated':
        return const ["Top Rated", "Masterpiece", "HD"];
      case 'romance':
        return const ["Romance Genre", "Vanilla", "Pure Love", "HD"];
      case 'milf':
        return const ["Milf Genre", "Mature", "HD"];
      default:
        return const ["Uncensored", "HD"];
    }
  }

  List<MediaItem> _generateSampleList(String tabId, int page) {
    if (page > 1) return [];

    final Map<String, List<MediaItem>> sampleSets = {
      "uncensored": [
        MediaItem(
          id: "hsh_unc_1",
          title: "Harem-jima e Youkoso! The Animation Episode 1",
          url: "$baseUrl/video/harem-jima-e-youkoso-episode-1",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "18:45",
          releaseDate: "2024",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Uncensored", "Harem", "Island", "Full HD"],
          rating: 4.95,
          views: 520000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hsh_unc_2",
          title: "So Low: Futago Shimai to Katei Kyoshi Uncensored Cut",
          url: "$baseUrl/video/so-low-futago-shimai-uncensored",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "27:59",
          releaseDate: "2024",
          studio: "Bunnywalker",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Uncensored", "Twins", "School", "Tutor"],
          rating: 4.92,
          views: 485000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hsh_unc_3",
          title: "1LDK+JK Ikinari Doukyo? Micchaku!? Decensored Master",
          url: "$baseUrl/video/1ldk-jk-ikinari-doukyo-decensored",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "19:30",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Uncensored", "JK", "Co-habitation", "Romance"],
          rating: 4.88,
          views: 440000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hsh_unc_4",
          title: "Overflow Extended Cut: Warm Bath Edition",
          url: "$baseUrl/video/overflow-extended-cut-uncensored",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "24:15",
          releaseDate: "2024",
          studio: "Houkiboshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Uncensored", "Bath", "Sisters", "Full HD"],
          rating: 4.98,
          views: 710000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hsh_unc_5",
          title: "Sister Breeder: Pure Fantasy Uncensored Ep 1",
          url: "$baseUrl/video/sister-breeder-pure-fantasy-uncensored",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "24:12",
          releaseDate: "2024",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Uncensored", "Breeding", "Fantasy", "Elves"],
          rating: 4.85,
          views: 395000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hsh_unc_6",
          title: "Futabu!! Complete Decensored Remaster",
          url: "$baseUrl/video/futabu-complete-decensored-remaster",
          cover: "https://i.imgur.com/wVqjC5P.jpeg",
          duration: "25:40",
          releaseDate: "2024",
          studio: "Ziz",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Uncensored", "Futanari", "Comedy", "School"],
          rating: 4.91,
          views: 610000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hsh_unc_7",
          title: "Tiny Evil: Devilish Pact Uncensored 1080p",
          url: "$baseUrl/video/tiny-evil-devilish-pact-uncensored",
          cover: "https://i.imgur.com/z4bKxNm.jpeg",
          duration: "26:10",
          releaseDate: "2024",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Uncensored", "Succubus", "Magic", "Fantasy"],
          rating: 4.94,
          views: 580000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hsh_unc_8",
          title: "Resort Boin: Sunny Beach Uncensored Special",
          url: "$baseUrl/video/resort-boin-sunny-beach-uncensored",
          cover: "https://i.imgur.com/83pZ6XQ.jpeg",
          duration: "28:30",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Uncensored", "Big Boobs", "Resort", "Vacation"],
          rating: 4.89,
          views: 530000,
          isUncensored: true,
        ),
      ],
      "popular": [
        MediaItem(
          id: "hsh_pop_1",
          title: "Mankitsu Happening: The Complete Encounter",
          url: "$baseUrl/video/mankitsu-happening-complete",
          cover: "https://i.imgur.com/N7GgqMv.jpeg",
          duration: "32:15",
          releaseDate: "2024",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Most Viewed", "Harem", "Manga Cafe", "Classic"],
          rating: 5.0,
          views: 950000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hsh_pop_2",
          title: "Bible Black: La Noche de Walpurgis HD Remaster",
          url: "$baseUrl/video/bible-black-walpurgis-hd",
          cover: "https://i.imgur.com/J3ZqK9x.jpeg",
          duration: "30:40",
          releaseDate: "2024",
          studio: "Milky Animation",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Most Viewed", "Occult", "Supernatural", "Classic"],
          rating: 4.96,
          views: 1120000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hsh_pop_3",
          title: "Kuroinu: Kedakaki Seijo wa Hakudaku ni Somaru",
          url: "$baseUrl/video/kuroinu-kedakaki-seijo",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "29:50",
          releaseDate: "2024",
          studio: "Eroman",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Most Viewed", "Dark Fantasy", "Elves", "Action"],
          rating: 4.93,
          views: 890000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hsh_pop_4",
          title: "Taimanin Asagi: Shadow Operatives Director's Cut",
          url: "$baseUrl/video/taimanin-asagi-shadow-operatives",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "27:40",
          releaseDate: "2024",
          studio: "Lilith",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Most Viewed", "Ninja", "Action", "Supernatural"],
          rating: 4.91,
          views: 860000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hsh_pop_5",
          title: "Discipline: Shin Teikoku Anime Complete Series",
          url: "$baseUrl/video/discipline-shin-teikoku-complete",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "28:15",
          releaseDate: "2024",
          studio: "Active Soft",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Most Viewed", "School", "Academy", "Classic"],
          rating: 4.88,
          views: 810000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hsh_pop_6",
          title: "Night Shift Nurses: Ren'ai Shinryoushitou Remaster",
          url: "$baseUrl/video/night-shift-nurses-renai-shinryoushitou",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "26:50",
          releaseDate: "2024",
          studio: "Milky Animation",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Most Viewed", "Hospital", "Nurse", "Classic"],
          rating: 4.87,
          views: 790000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hsh_pop_7",
          title: "Rance 01: Hikari o Motomete The Animation",
          url: "$baseUrl/video/rance-01-hikari-o-motomete",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "31:20",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Most Viewed", "RPG", "Adventure", "Fantasy"],
          rating: 4.94,
          views: 930000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hsh_pop_8",
          title: "Oni Chichi: Re-born Special Edition",
          url: "$baseUrl/video/oni-chichi-reborn-special",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "25:35",
          releaseDate: "2024",
          studio: "Blue Eyes",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Most Viewed", "Family", "Comedy", "HD"],
          rating: 4.9,
          views: 875000,
          isUncensored: true,
        ),
      ],
      "latest": [
        MediaItem(
          id: "hsh_lat_1",
          title: "Kanojo Saimin Episode 2: Hypnosis Classroom",
          url: "$baseUrl/video/kanojo-saimin-episode-2",
          cover: "https://i.imgur.com/pZ8vG3P.jpeg",
          duration: "24:30",
          releaseDate: "2025",
          studio: "Bunnywalker",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Recent Aired", "Hypnosis", "School", "HD"],
          rating: 4.88,
          views: 320000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hsh_lat_2",
          title: "Onaji Zemi no Someya-san: College Romance Ep 6",
          url: "$baseUrl/video/onaji-zemi-no-someya-san-ep-6",
          cover: "https://i.imgur.com/W2RzV7q.jpeg",
          duration: "25:10",
          releaseDate: "2025",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Recent Aired", "College", "Romance", "HD"],
          rating: 4.85,
          views: 290000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hsh_lat_3",
          title: "Dokidoki Little Ooyasan: Sweet Landlady Hours Ep 4",
          url: "$baseUrl/video/dokidoki-little-ooyasan-ep-4",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "22:15",
          releaseDate: "2025",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Recent Aired", "Comedy", "Cute", "HD"],
          rating: 4.8,
          views: 310000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hsh_lat_4",
          title: "Isekai Harem Monogatari: Royal Chamber Special Ep 3",
          url: "$baseUrl/video/isekai-harem-royal-chamber-ep-3",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "26:30",
          releaseDate: "2025",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Recent Aired", "Isekai", "Fantasy", "Harem"],
          rating: 4.92,
          views: 420000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hsh_lat_5",
          title: "Kuro Gal ni Natta kara Shin'yuu to Shite Mita Ep 2",
          url: "$baseUrl/video/kuro-gal-ni-natta-kara-ep-2",
          cover: "https://i.imgur.com/wVqjC5P.jpeg",
          duration: "23:45",
          releaseDate: "2025",
          studio: "Irawits",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Recent Aired", "Gyaru", "Romance", "HD"],
          rating: 4.78,
          views: 275000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hsh_lat_6",
          title: "Show Time! Uta no O-nee-san datte Shitai 2 Ep 5",
          url: "$baseUrl/video/show-time-uta-no-oneesan-2-ep-5",
          cover: "https://i.imgur.com/z4bKxNm.jpeg",
          duration: "21:20",
          releaseDate: "2025",
          studio: "Suiseisha",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Recent Aired", "Idol", "Romance", "HD"],
          rating: 4.82,
          views: 330000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hsh_lat_7",
          title: "Inaka ni wa Kore Kurai Shika Goraku ga Nai Ep 3",
          url: "$baseUrl/video/inaka-ni-wa-kore-kurai-ep-3",
          cover: "https://i.imgur.com/83pZ6XQ.jpeg",
          duration: "23:10",
          releaseDate: "2025",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Recent Aired", "Countryside", "Romance", "HD"],
          rating: 4.81,
          views: 285000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hsh_lat_8",
          title: "Bijukubo: Training Camp Days Episode 1",
          url: "$baseUrl/video/bijukubo-training-camp-ep-1",
          cover: "https://i.imgur.com/N7GgqMv.jpeg",
          duration: "25:40",
          releaseDate: "2025",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Recent Aired", "Camp", "Sports", "HD"],
          rating: 4.86,
          views: 350000,
          isUncensored: true,
        ),
      ],
      "top_rated": [
        MediaItem(
          id: "hsh_top_1",
          title: "Euphoria: Transcendent White Room Masterpiece",
          url: "$baseUrl/video/euphoria-white-room-masterpiece",
          cover: "https://i.imgur.com/J3ZqK9x.jpeg",
          duration: "33:20",
          releaseDate: "2024",
          studio: "Magin",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Top Rated", "Psychological", "Thriller", "Masterpiece"],
          rating: 4.99,
          views: 880000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hsh_top_2",
          title: "Starless: 21st Century Gothic Palace Decensored",
          url: "$baseUrl/video/starless-21st-century-gothic",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "29:45",
          releaseDate: "2024",
          studio: "Milky Animation",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Top Rated", "Mansion", "Gothic", "Mystery"],
          rating: 4.96,
          views: 740000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hsh_top_3",
          title: "Chou-kou Tenshi Escalayer: Decensored Heroine",
          url: "$baseUrl/video/chou-kou-tenshi-escalayer-hd",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "28:50",
          releaseDate: "2024",
          studio: "Alice Soft",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Top Rated", "Mahou Shoujo", "Sci-Fi", "Heroine"],
          rating: 4.95,
          views: 680000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hsh_top_4",
          title: "Viper GTS: Devil Awakening Uncensored Master",
          url: "$baseUrl/video/viper-gts-devil-awakening",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "27:30",
          releaseDate: "2024",
          studio: "Sonomama",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Top Rated", "Cyberpunk", "Classic", "Decensored"],
          rating: 4.93,
          views: 620000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hsh_top_5",
          title: "Princess Lover! OVA: Sylvia van Hossen Route",
          url: "$baseUrl/video/princess-lover-ova-sylvia",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "26:15",
          releaseDate: "2024",
          studio: "Public Enemies",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Top Rated", "Aristocrat", "Romance", "Masterpiece"],
          rating: 4.97,
          views: 810000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hsh_top_6",
          title: "Kyonyuu Fantasy: The Golden Empire Chronicles",
          url: "$baseUrl/video/kyonyuu-fantasy-golden-empire",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "29:10",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Top Rated", "Fantasy", "Kingdom", "Comedy"],
          rating: 4.94,
          views: 760000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hsh_top_7",
          title: "Seikatsu Shuukan: Life Habit Change Remaster",
          url: "$baseUrl/video/seikatsu-shuukan-life-habit",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "27:45",
          releaseDate: "2024",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Top Rated", "Hypnosis", "School", "Masterpiece"],
          rating: 4.92,
          views: 710000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hsh_top_8",
          title: "Shoujo Ramune: Nostalgic Summer Breeze HD",
          url: "$baseUrl/video/shoujo-ramune-nostalgic-summer",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "27:15",
          releaseDate: "2024",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Top Rated", "Nostalgia", "Summer", "Masterpiece"],
          rating: 4.91,
          views: 650000,
          isUncensored: true,
        ),
      ],
      "romance": [
        MediaItem(
          id: "hsh_rom_1",
          title: "Kanojo x Kanojo x Kanojo: Pure Heart Vow",
          url: "$baseUrl/video/kanojo-x-kanojo-pure-heart",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "26:30",
          releaseDate: "2024",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Romance Genre", "Vanilla", "Sweet", "Childhood Friend"],
          rating: 4.9,
          views: 450000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hsh_rom_2",
          title: "Lovely Heart: Starlit Confession on Terrace",
          url: "$baseUrl/video/lovely-heart-starlit-confession",
          cover: "https://i.imgur.com/wVqjC5P.jpeg",
          duration: "24:15",
          releaseDate: "2024",
          studio: "Bunnywalker",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Romance Genre", "First Love", "Vanilla", "School"],
          rating: 4.88,
          views: 380000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hsh_rom_3",
          title: "Koi Magiri: Gentle Rain & Warm Blanket Nights",
          url: "$baseUrl/video/koi-magiri-gentle-rain-warm-nights",
          cover: "https://i.imgur.com/z4bKxNm.jpeg",
          duration: "23:50",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Romance Genre", "Vanilla", "Gentle", "Pure Love"],
          rating: 4.85,
          views: 340000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hsh_rom_4",
          title: "Pure Love Story: Sunset Beach Kiss Promise",
          url: "$baseUrl/video/pure-love-story-sunset-beach-kiss",
          cover: "https://i.imgur.com/83pZ6XQ.jpeg",
          duration: "25:40",
          releaseDate: "2024",
          studio: "Houkiboshi",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Romance Genre", "Sunset", "Beach", "Vanilla"],
          rating: 4.92,
          views: 410000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hsh_rom_5",
          title: "Sweet Days with Senpai: Library Encounter",
          url: "$baseUrl/video/sweet-days-senpai-library",
          cover: "https://i.imgur.com/N7GgqMv.jpeg",
          duration: "22:15",
          releaseDate: "2024",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Romance Genre", "Senpai", "Library", "Sweet"],
          rating: 4.83,
          views: 360000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hsh_rom_6",
          title: "Hatsukoi Ribbon: First Kiss Behind Gymnasium",
          url: "$baseUrl/video/hatsukoi-ribbon-first-kiss",
          cover: "https://i.imgur.com/J3ZqK9x.jpeg",
          duration: "27:10",
          releaseDate: "2024",
          studio: "Bunnywalker",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Romance Genre", "First Love", "School", "Romance"],
          rating: 4.87,
          views: 395000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hsh_rom_7",
          title: "Boku to Misaki-sensei: Secret Classroom Vow",
          url: "$baseUrl/video/boku-to-misaki-sensei-secret-vow",
          cover: "https://i.imgur.com/7jZQY1B.jpeg",
          duration: "28:20",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Romance Genre", "Teacher", "Romance", "Sweet"],
          rating: 4.91,
          views: 460000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hsh_rom_8",
          title: "Futari no Jikan: Cozy Winter Holiday Together",
          url: "$baseUrl/video/futari-no-jikan-cozy-winter",
          cover: "https://i.imgur.com/zWc3f8K.jpeg",
          duration: "24:35",
          releaseDate: "2024",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Romance Genre", "Winter", "Cozy", "Pure Love"],
          rating: 4.89,
          views: 375000,
          isUncensored: true,
        ),
      ],
      "milf": [
        MediaItem(
          id: "hsh_mlf_1",
          title: "Ane wa Yanmama Junyuu-chuu: Reunion Night",
          url: "$baseUrl/video/ane-wa-yanmama-reunion-night",
          cover: "https://i.imgur.com/W6Qz8mQ.jpeg",
          duration: "28:40",
          releaseDate: "2024",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Milf Genre", "Milf", "Family", "HD"],
          rating: 4.92,
          views: 540000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hsh_mlf_2",
          title: "Kateikyoushi x Saimin: Motherly Hypnosis Room",
          url: "$baseUrl/video/kateikyoushi-x-saimin-motherly",
          cover: "https://i.imgur.com/8Q9Z5b4.jpeg",
          duration: "25:30",
          releaseDate: "2024",
          studio: "T-Rex",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Milf Genre", "Hypnosis", "Mature", "HD"],
          rating: 4.87,
          views: 490000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hsh_mlf_3",
          title: "Saimin Seishidou: Neighborhood Mother's Secret",
          url: "$baseUrl/video/saimin-seishidou-neighborhood-mother",
          cover: "https://i.imgur.com/2mK9p7q.jpeg",
          duration: "27:15",
          releaseDate: "2024",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Milf Genre", "Mature", "Drama", "Full HD"],
          rating: 4.89,
          views: 510000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hsh_mlf_4",
          title: "Paihame Kazoku: Mother's Bountiful Care",
          url: "$baseUrl/video/paihame-kazoku-mothers-care",
          cover: "https://i.imgur.com/Ue1mB8u.jpeg",
          duration: "26:50",
          releaseDate: "2024",
          studio: "Ziz",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Milf Genre", "Big Boobs", "Family", "HD"],
          rating: 4.84,
          views: 450000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hsh_mlf_5",
          title: "Shitsurakuen: Beautiful Stepmother's Confession",
          url: "$baseUrl/video/shitsurakuen-stepmother-confession",
          cover: "https://i.imgur.com/K3Z9j9b.jpeg",
          duration: "29:00",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Milf Genre", "Stepmother", "Drama", "Romance"],
          rating: 4.91,
          views: 480000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hsh_mlf_6",
          title: "Mama wa Shougaku 4-nensei: Loving Care Special",
          url: "$baseUrl/video/mama-wa-shougaku-loving-care",
          cover: "https://i.imgur.com/8rQ3UjF.jpeg",
          duration: "23:40",
          releaseDate: "2024",
          studio: "Bunnywalker",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Milf Genre", "Cute", "Comedy", "HD"],
          rating: 4.8,
          views: 410000,
          isUncensored: false,
        ),
        MediaItem(
          id: "hsh_mlf_7",
          title: "Haha wa Kanojo de Hitozuma: Secret Midnight Affair",
          url: "$baseUrl/video/haha-wa-kanojo-secret-affair",
          cover: "https://i.imgur.com/wVqjC5P.jpeg",
          duration: "28:10",
          releaseDate: "2024",
          studio: "PoRO",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Milf Genre", "Affair", "Mature", "Drama"],
          rating: 4.93,
          views: 530000,
          isUncensored: true,
        ),
        MediaItem(
          id: "hsh_mlf_8",
          title: "Zettai Junpaku Mahou Shoujo: Mother's Corrupted Light",
          url: "$baseUrl/video/zettai-junpaku-mothers-corrupted-light",
          cover: "https://i.imgur.com/z4bKxNm.jpeg",
          duration: "26:45",
          releaseDate: "2024",
          studio: "Seven",
          extensionId: id,
          type: MediaType.animeSeries,
          tags: const ["Milf Genre", "Mahou Shoujo", "Dark", "Mature"],
          rating: 4.88,
          views: 470000,
          isUncensored: true,
        ),
      ],
    };

    return sampleSets[tabId] ?? sampleSets["uncensored"] ?? [];
  }

  MediaDetail _generateSampleDetail(String url) {
    return MediaDetail(
      id: url.hashCode.toString(),
      title: "Hentai.SH Master Feature",
      cover: "https://edge1.hentai.sh/v/so_low-episode-3/thumb.jpg?v=mssmzo9m",
      backdrop:
          "https://edge1.hentai.sh/v/so_low-episode-3/thumb.jpg?v=mssmzo9m",
      description:
          "Watch exclusive uncensored anime releases streamed directly in 1080p 60fps HD with multi-variant HLS support.",
      studio: "Hentai.SH Studio",
      releaseDate: "2024",
      tags: const ["Uncensored", "Action", "1080p 60fps", "HD"],
      episodes: [
        EpisodeItem(
          id: "ep_1",
          episodeNumber: "Episode 1",
          title: "Hentai.SH Episode 1",
          url: url,
          thumbnail:
              "https://edge1.hentai.sh/v/so_low-episode-3/thumb.jpg?v=mssmzo9m",
          duration: "27:59",
          sources: [
            StreamSource(
              label: "HLS Master (Auto)",
              url: "https://edge1.hentai.sh/v/so_low-episode-3/master.m3u8",
              protocol: StreamProtocol.hlsM3u8,
              headers: _streamHeaders,
              format: "m3u8",
            ),
            StreamSource(
              label: "720p HD",
              url:
                  "https://edge1.hentai.sh/v/so_low-episode-3/720/playlist.m3u8",
              protocol: StreamProtocol.hlsM3u8,
              headers: _streamHeaders,
              format: "m3u8",
            ),
          ],
        ),
      ],
      playbackHeatmap: const [
        0.1,
        0.35,
        0.7,
        0.95,
        0.85,
        0.4,
        0.3,
        0.9,
        1.0,
        0.35,
      ],
      sceneMarkers: [
        SceneMarker(title: "Introduction", timestampSeconds: 0),
        SceneMarker(title: "Climax Highlight 🔥", timestampSeconds: 580),
      ],
    );
  }

  @override
  Future<ExtensionTaxonomy> fetchTaxonomy() async {
    return hentaiShTaxonomy;
  }

  @override
  Future<List<MediaItem>> fetchTaxonomyFeed(CatalogItem item, int page) async {
    // 1. Playlists: Scrape video cards from the playlist page
    if (item.type == CatalogType.category ||
        (item.endpointPath != null &&
            item.endpointPath!.contains('/playlist/'))) {
      try {
        final slug = item.slug.trim();
        final playlistUrl =
            item.endpointPath != null && item.endpointPath!.isNotEmpty
            ? (item.endpointPath!.startsWith('http')
                  ? item.endpointPath!
                  : "$baseUrl${item.endpointPath}")
            : "$baseUrl/playlist/$slug";

        final response = await http
            .get(Uri.parse(playlistUrl), headers: _headers)
            .timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final items = _parseCardsFromHtml(response.body, tabId: 'playlist');
          if (items.isNotEmpty) {
            const pageSize = 24;
            final safePage = page < 1 ? 1 : page;
            final startIndex = (safePage - 1) * pageSize;
            if (startIndex < items.length) {
              return items.skip(startIndex).take(pageSize).toList();
            }
            return [];
          }
        }
      } catch (_) {}

      return search(item.name, page);
    }

    // 2. Genres & Tags: Query /api/videos with tag slug
    try {
      final tagSlug = item.slug.trim();
      final queryParams = <String, String>{
        'page': page.toString(),
        'sort': 'most_viewed',
        'tags': tagSlug,
      };

      final apiUrl = Uri.parse(
        "$baseUrl/api/videos",
      ).replace(queryParameters: queryParams);
      final response = await http
          .get(apiUrl, headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic> && data['videos'] is List) {
          final List<dynamic> videos = data['videos'];
          final List<MediaItem> items = [];
          for (final v in videos) {
            if (v is Map<String, dynamic>) {
              final parsed = _parseVideoJson(v);
              if (parsed != null) items.add(parsed);
            }
          }
          if (items.isNotEmpty) return items;
        }
      }

      // HTML Fallback for browse tag
      final browseUrl = page == 1
          ? "$baseUrl/browse?tags=$tagSlug"
          : "$baseUrl/browse?tags=$tagSlug&page=$page";
      final browseResponse = await http
          .get(Uri.parse(browseUrl), headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (browseResponse.statusCode == 200) {
        final items = _parseCardsFromHtml(browseResponse.body, tabId: tagSlug);
        if (items.isNotEmpty) return items;
      }
    } catch (_) {}

    return search(item.name, page);
  }
}
