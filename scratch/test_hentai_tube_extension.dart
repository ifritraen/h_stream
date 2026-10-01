import 'package:flutter/widgets.dart';
import 'package:hstream/extensions/sources/hentai_tube_extension.dart';
import 'package:hstream/extensions/taxonomies/hentai_tube_taxonomy.dart';
import 'package:hstream/models/catalog_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final ext = HentaiTubeExtension();
  print("Extension ID: ${ext.id}, Name: ${ext.name}");

  final taxonomy = await ext.fetchTaxonomy();
  print("Taxonomy sections: ${taxonomy.sections.length}");
  for (final s in taxonomy.sections) {
    print("  Section: ${s.title} (${s.displayType}) - ${s.items.length} items");
  }

  // Test fetching taxonomy feed for a couple items
  print("\nTesting fetchTaxonomyFeed for 'action':");
  final actionItem = hentaiTubeCategories.firstWhere((c) => c.slug == 'action');
  final actionFeed = await ext.fetchTaxonomyFeed(actionItem, 1);
  print("Action feed page 1: ${actionFeed.length} videos");
  if (actionFeed.isNotEmpty) {
    print("  First video: ${actionFeed[0].title} (${actionFeed[0].url})");
    print("  Cover: ${actionFeed[0].cover}");
  }

  print("\nTesting fetchTaxonomyFeed for 'uncensored':");
  final uncItem = hentaiTubeCategories.firstWhere((c) => c.slug == 'uncensored');
  final uncFeed = await ext.fetchTaxonomyFeed(uncItem, 1);
  print("Uncensored feed page 1: ${uncFeed.length} videos");
  if (uncFeed.isNotEmpty) {
    print("  First video: ${uncFeed[0].title} (${uncFeed[0].url})");
  }
}
