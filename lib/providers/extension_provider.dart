import 'package:flutter/material.dart';
import '../extensions/base_extension.dart';
import '../extensions/extensions_registry.dart';
import '../models/media_item.dart';
import '../models/catalog_model.dart';

class ExtensionProvider extends ChangeNotifier {
  final List<HentaiExtension> _extensions = ExtensionRegistry.getAllExtensions();

  late HentaiExtension _activeExtension;
  late String _activeTabId;
  final Map<String, dynamic> _activeFilters = {};

  final List<MediaItem> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String _currentSearchQuery = "";
  String? _errorMessage;

  final Map<String, ExtensionTaxonomy> _taxonomyCache = {};
  bool _isTaxonomyLoading = false;

  List<HentaiExtension> get extensions => _extensions;
  HentaiExtension get activeExtension => _activeExtension;
  String get activeTabId => _activeTabId;
  Map<String, dynamic> get activeFilters => _activeFilters;
  List<MediaItem> get items => _items;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  int get currentPage => _currentPage;
  String get currentSearchQuery => _currentSearchQuery;
  String? get errorMessage => _errorMessage;

  ExtensionTaxonomy? get currentTaxonomy => _taxonomyCache[_activeExtension.id];
  bool get isTaxonomyLoading => _isTaxonomyLoading;

  ExtensionProvider() {
    _activeExtension = _extensions.first;
    _activeTabId = _activeExtension.tabs.first.id;
    loadTaxonomyForActiveExtension();
  }

  void setActiveExtension(HentaiExtension extension) {
    if (_activeExtension.id == extension.id) return;
    _activeExtension = extension;
    _activeTabId = extension.tabs.first.id;
    _activeFilters.clear();
    _currentSearchQuery = "";
    notifyListeners();
    fetchFeed(refresh: true);
    loadTaxonomyForActiveExtension();
  }

  Future<void> loadTaxonomyForActiveExtension({bool forceRefresh = false}) async {
    if (!forceRefresh && _taxonomyCache.containsKey(_activeExtension.id)) {
      return;
    }

    _isTaxonomyLoading = true;
    notifyListeners();

    try {
      final taxonomy = await _activeExtension.fetchTaxonomy();
      _taxonomyCache[_activeExtension.id] = taxonomy;
    } catch (_) {
      _taxonomyCache[_activeExtension.id] = ExtensionTaxonomy.fromDefaultCatalog();
    } finally {
      _isTaxonomyLoading = false;
      notifyListeners();
    }
  }

  void setActiveTab(String tabId) {
    if (_activeTabId == tabId) return;
    _activeTabId = tabId;
    _currentSearchQuery = "";
    notifyListeners();
    fetchFeed(refresh: true);
  }

  void updateFilter(String key, dynamic value) {
    _activeFilters[key] = value;
    notifyListeners();
    fetchFeed(refresh: true);
  }

  Future<void> fetchFeed({
    bool refresh = false,
    List<String>? whitelistedTags,
    List<String>? blacklistedTags,
  }) async {
    if (_isLoading) return;

    if (refresh) {
      _currentPage = 1;
      _items.clear();
      _hasMore = true;
      _errorMessage = null;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final newItems = _currentSearchQuery.isEmpty
          ? await _activeExtension.fetchTabFeed(
              _activeTabId,
              _currentPage,
              activeFilters: _activeFilters,
              whitelistedTags: whitelistedTags,
              blacklistedTags: blacklistedTags,
            )
          : await _activeExtension.search(
              _currentSearchQuery,
              _currentPage,
              activeFilters: _activeFilters,
              whitelistedTags: whitelistedTags,
              blacklistedTags: blacklistedTags,
            );

      if (newItems.isEmpty) {
        _hasMore = false;
      } else {
        _items.addAll(newItems);
        _currentPage++;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void search(String query) {
    _currentSearchQuery = query.trim();
    fetchFeed(refresh: true);
  }

  Future<MediaDetail> getDetail(String url) async {
    return await _activeExtension.detail(url);
  }

  Future<List<StreamSource>> getStreams(String videoUrl) async {
    return await _activeExtension.extractVideoStreams(videoUrl);
  }
}
