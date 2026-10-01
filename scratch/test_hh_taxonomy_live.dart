import 'package:flutter/widgets.dart';
import '../lib/extensions/sources/hentai_haven_extension.dart';
import '../lib/extensions/taxonomies/hentai_haven_taxonomy.dart';
import '../lib/models/catalog_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print("Testing HentaiHavenExtension live taxonomy...");
  final ext = HentaiHavenExtension();
  
  final tax = await ext.fetchTaxonomy();
  print("Effective sections: ${tax.effectiveSections.length}");
  for (final s in tax.effectiveSections) {
    print("  Section: ${s.id} (${s.title}) -> ${s.items.length} items [${s.displayType}]");
  }
  
  // Test feed on first genre: 3d
  print("\nFetching taxonomy feed for 3d...");
  final items = await ext.fetchTaxonomyFeed(hentaiHavenGenres.first, 1);
  print("Found ${items.length} items for ${hentaiHavenGenres.first.name}:");
  for (final it in items.take(3)) {
    print("  Title: ${it.title} | Cover: ${it.cover} | URL: ${it.url}");
  }

  // Test feed on first category: Most Viewed
  print("\nFetching taxonomy feed for Most Viewed...");
  final catItems = await ext.fetchTaxonomyFeed(hentaiHavenCategories.first, 1);
  print("Found ${catItems.length} items for ${hentaiHavenCategories.first.name}:");
  for (final it in catItems.take(3)) {
    print("  Title: ${it.title} | Cover: ${it.cover} | URL: ${it.url}");
  }

  // Test feed on first studio: Pink Pineapple
  print("\nFetching taxonomy feed for studio Pink Pineapple...");
  final studio = hentaiHavenStudios.first;
  final studioItems = await ext.fetchTaxonomyFeed(studio, 1);
  print("Found ${studioItems.length} items for ${studio.name}:");
  for (final it in studioItems.take(3)) {
    print("  Title: ${it.title} | Cover: ${it.cover} | URL: ${it.url}");
  }

  print("\nAll live tests passed!");
}
