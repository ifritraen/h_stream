import 'package:flutter/material.dart';
import '../extensions/base_extension.dart';
import '../extensions/sources/hanime_extension.dart';
import '../extensions/sources/rule34_extension.dart';
import '../extensions/sources/hstream_extension.dart';
import '../extensions/sources/hmvmania_extension.dart';
import '../extensions/sources/oppai_extension.dart';
import '../models/media_item.dart';

class BentoRowConfig {
  final String id;
  final String title;
  final String extensionId;
  final String tabId;
  final String subtitle;
  final bool isHorizontalCarousel;

  BentoRowConfig({
    required this.id,
    required this.title,
    required this.extensionId,
    required this.tabId,
    required this.subtitle,
    this.isHorizontalCarousel = true,
  });
}

class FeedBoardProvider extends ChangeNotifier {
  final List<BentoRowConfig> _rows = [
    BentoRowConfig(
      id: "row_trending_anime",
      title: "🔥 Trending Masterpieces",
      extensionId: "hanime_tv",
      tabId: "trending",
      subtitle: "Highest-rated 1080p uncensored series",
      isHorizontalCarousel: true,
    ),
    BentoRowConfig(
      id: "row_3d_clips",
      title: "✨ 3D & MMD Highlights",
      extensionId: "rule34_video",
      tabId: "top_rated",
      subtitle: "60FPS Raytraced animations & renders",
      isHorizontalCarousel: true,
    ),
    BentoRowConfig(
      id: "row_4k_remastered",
      title: "👑 4K Ultra-HD Remasters",
      extensionId: "oppai_stream",
      tabId: "4k_recent",
      subtitle: "Lossless bitrate 2160p releases",
      isHorizontalCarousel: true,
    ),
    BentoRowConfig(
      id: "row_dubbed_series",
      title: "🎙️ English Dubbed Epic",
      extensionId: "hstream_moe",
      tabId: "dubbed",
      subtitle: "Full voice acted dark fantasy sagas",
      isHorizontalCarousel: true,
    ),
    BentoRowConfig(
      id: "row_hmv_dance",
      title: "🎵 Trending HMV Dance",
      extensionId: "hmv_mania",
      tabId: "popular_hmv",
      subtitle: "R-18 Vocaloid & Game choreography",
      isHorizontalCarousel: true,
    ),
  ];

  final Map<String, List<MediaItem>> _rowItems = {};
  bool _isLoading = false;

  List<BentoRowConfig> get rows => _rows;
  Map<String, List<MediaItem>> get rowItems => _rowItems;
  bool get isLoading => _isLoading;

  final Map<String, HentaiExtension> _extensionRegistry = {
    "hanime_tv": HanimeExtension(),
    "rule34_video": Rule34Extension(),
    "hstream_moe": HStreamExtension(),
    "hmv_mania": HmvManiaExtension(),
    "oppai_stream": OppaiExtension(),
  };

  FeedBoardProvider() {
    loadAllBoardRows();
  }

  Future<void> loadAllBoardRows() async {
    _isLoading = true;
    notifyListeners();

    for (final row in _rows) {
      final ext = _extensionRegistry[row.extensionId];
      if (ext != null) {
        try {
          final items = await ext.fetchTabFeed(row.tabId, 1);
          _rowItems[row.id] = items;
        } catch (_) {
          _rowItems[row.id] = [];
        }
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  void reorderRows(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final item = _rows.removeAt(oldIndex);
    _rows.insert(newIndex, item);
    notifyListeners();
  }
}
