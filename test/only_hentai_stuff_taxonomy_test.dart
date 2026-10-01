import 'package:flutter_test/flutter_test.dart';
import 'package:h_stream/extensions/sources/only_hentai_stuff_extension.dart';
import 'package:h_stream/extensions/taxonomies/only_hentai_stuff_taxonomy.dart';
import 'package:h_stream/models/catalog_model.dart';

void main() {
  group('OnlyHentaiStuff Taxonomy & Extension Tests', () {
    final ext = OnlyHentaiStuffExtension();

    test('Extension metadata is correct', () {
      expect(ext.id, equals('only_hentai_stuff'));
      expect(ext.name, equals('OnlyHentaiStuff'));
      expect(ext.baseUrl, equals('https://www.onlyhentaistuff.com'));
    });

    test('Taxonomy contains Categories (grid) and Tags (tags) sections', () async {
      final taxonomy = await ext.fetchTaxonomy();
      expect(taxonomy.sections.length, equals(2));

      final catSection = taxonomy.sections.firstWhere((s) => s.id == 'categories');
      expect(catSection.displayType, equals(TaxonomyDisplayType.grid));
      expect(catSection.items.length, equals(36));

      final tagSection = taxonomy.sections.firstWhere((s) => s.id == 'tags');
      expect(tagSection.displayType, equals(TaxonomyDisplayType.tags));
      expect(tagSection.items.length, equals(715));
    });

    test('All 36 harvested categories have authentic data, covers, and endpoints', () {
      expect(onlyHentaiStuffCategories.length, equals(36));
      for (final cat in onlyHentaiStuffCategories) {
        expect(cat.name.isNotEmpty, isTrue);
        expect(cat.slug.isNotEmpty, isTrue);
        expect(cat.type, equals(CatalogType.category));
        expect(cat.count, greaterThan(0));
        expect(cat.endpointPath, startsWith('/categories/'));
        expect(onlyHentaiStuffCategoryCovers[cat.slug], isNotNull);
        expect(
          onlyHentaiStuffCategoryCovers[cat.slug]!,
          startsWith('https://www.onlyhentaistuff.com/contents/categories/'),
        );
      }
    });

    test('All 715 harvested tags have valid slugs and endpoint paths', () {
      expect(onlyHentaiStuffTags.length, equals(715));
      for (final tag in onlyHentaiStuffTags) {
        expect(tag.name.isNotEmpty, isTrue);
        expect(tag.slug.isNotEmpty, isTrue);
        expect(tag.type, equals(CatalogType.tag));
        expect(tag.endpointPath, startsWith('/tags/'));
      }
    });

    test('fetchTaxonomyFeed extracts live video items from category', () async {
      final item = onlyHentaiStuffCategories.firstWhere((c) => c.slug == 'animal-girls');
      final feed = await ext.fetchTaxonomyFeed(item, 1);
      expect(feed.isNotEmpty, isTrue);
      expect(feed.first.title.isNotEmpty, isTrue);
      expect(feed.first.url, contains('/videos/'));
      expect(feed.first.cover, startsWith('http'));
    });
  });
}
