import '../models/media_item.dart';
import '../models/extension_manifest.dart';
import '../models/tag_filter_state.dart';
import '../models/catalog_model.dart';

abstract class HentaiExtension {
  String get id;
  String get name;
  String get baseUrl;
  String get iconUrl;
  String get description;
  String get version => "1.0.0";
  bool get isNsfw => true;

  // Dynamic UI Capabilities (Transforms the App Shell)
  ViewLayoutType get defaultLayout => ViewLayoutType.widescreen16x9;
  List<ExtensionTab> get tabs;
  List<FilterGroup> get filters => [];
  List<NavButton> get customNavButtons => [];
  bool get supportsShorts => false;

  // Extractor & Search Endpoints
  Future<List<MediaItem>> fetchTabFeed(
    String tabId,
    int page, {
    Map<String, dynamic>? activeFilters,
    List<String>? whitelistedTags,
    List<String>? blacklistedTags,
  });

  Future<List<MediaItem>> search(
    String query,
    int page, {
    Map<String, dynamic>? activeFilters,
    List<String>? whitelistedTags,
    List<String>? blacklistedTags,
  });

  Future<MediaDetail> detail(String url);

  Future<List<StreamSource>> extractVideoStreams(String videoUrl);

  Future<List<TagModel>> fetchAvailableTags() async => [];

  /// Dynamically extracts live or verified categories and tags/genres supported by this extension.
  Future<ExtensionTaxonomy> fetchTaxonomy() async {
    return ExtensionTaxonomy.fromDefaultCatalog();
  }

  /// Fetches content items belonging to a specific category, genre, or tag.
  Future<List<MediaItem>> fetchTaxonomyFeed(CatalogItem item, int page) async {
    return search(item.name, page);
  }
}
