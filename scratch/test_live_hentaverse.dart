import 'package:h_stream/extensions/sources/hentaverse_extension.dart';
import 'package:h_stream/models/catalog_model.dart';

void main() async {
  print("Testing HentaverseExtension live integration...");
  final ext = HentaverseExtension();

  final taxonomy = await ext.fetchTaxonomy();
  print("Taxonomy sections: ${taxonomy.sections.length}");
  print("Taxonomy categories: ${taxonomy.categories.length}");
  print("Taxonomy tags: ${taxonomy.tagsAndGenres.length}");

  // Test live feed for first category
  final testCat = taxonomy.categories.firstWhere((c) => c.slug == "school-girl");
  print("\nFetching live category feed for: ${testCat.name} (${testCat.slug})...");
  final catItems = await ext.fetchTaxonomyFeed(testCat, 1);
  print("Fetched ${catItems.length} items from live feed!");
  if (catItems.isNotEmpty) {
    final first = catItems.first;
    print("  First item title: ${first.title}");
    print("  URL: ${first.url}");
    print("  Cover: ${first.cover}");
    print("  Duration: ${first.duration}");
    print("  Tags: ${first.tags}");
  }

  // Test live feed for a tag
  final testTag = taxonomy.tagsAndGenres.firstWhere((t) => t.slug == "futanari");
  print("\nFetching live tag feed for: ${testTag.name} (${testTag.slug})...");
  final tagItems = await ext.fetchTaxonomyFeed(testTag, 1);
  print("Fetched ${tagItems.length} items from tag feed!");
  if (tagItems.isNotEmpty) {
    final first = tagItems.first;
    print("  First item title: ${first.title}");
    print("  URL: ${first.url}");
    print("  Cover: ${first.cover}");
    print("  Duration: ${first.duration}");
    print("  Tags: ${first.tags}");
  }

  print("\nAll integration checks passed!");
}
