import 'package:flutter_test/flutter_test.dart';
import 'package:h_stream/extensions/sources/xanimeporn_extension.dart';
import 'package:h_stream/extensions/taxonomies/xanimeporn_taxonomy.dart';
import 'package:h_stream/models/catalog_model.dart';

void main() {
  group('Xanimeporn Taxonomy & Extension Tests', () {
    final ext = XanimepornExtension();

    test('Extension metadata is correct', () {
      expect(ext.id, equals('xanimeporn'));
      expect(ext.name, equals('Xanimeporn'));
      expect(ext.baseUrl, equals('https://xanimeporn.com'));
    });

    test('Taxonomy contains Categories (grid) and Tags (tags) sections', () async {
      final taxonomy = await ext.fetchTaxonomy();
      expect(taxonomy.sections.length, equals(2));

      final catSection = taxonomy.sections.firstWhere((s) => s.id == 'categories');
      expect(catSection.displayType, equals(TaxonomyDisplayType.grid));
      expect(catSection.items.length, equals(20));

      final tagSection = taxonomy.sections.firstWhere((s) => s.id == 'tags');
      expect(tagSection.displayType, equals(TaxonomyDisplayType.tags));
      expect(tagSection.items.isNotEmpty, isTrue);
    });

    test('All 20 harvested categories have authentic data, counts, and covers', () {
      expect(xanimepornCategories.length, equals(20));
      for (final cat in xanimepornCategories) {
        expect(cat.name.isNotEmpty, isTrue);
        expect(cat.slug.isNotEmpty, isTrue);
        expect(cat.type, equals(CatalogType.category));
        expect(cat.count, greaterThan(0));
        expect(cat.endpointPath, startsWith('/'));
        expect(xanimepornCategoryCovers[cat.slug], isNotNull);
        expect(
          xanimepornCategoryCovers[cat.slug]!,
          startsWith('https://xanimeporn.com/wp-content/uploads/'),
        );
      }
    });

    test('All harvested tags have valid slugs and endpoint paths', () {
      expect(xanimepornTags.isNotEmpty, isTrue);
      for (final tag in xanimepornTags) {
        expect(tag.name.isNotEmpty, isTrue);
        expect(tag.slug.isNotEmpty, isTrue);
        expect(tag.type, equals(CatalogType.tag));
        expect(tag.endpointPath, startsWith('/'));
      }
    });

    test('fetchTaxonomyFeed extracts live video items from category', () async {
      final item = xanimepornCategories.firstWhere((c) => c.slug == 'big-tits');
      final feed = await ext.fetchTaxonomyFeed(item, 1);
      expect(feed.isNotEmpty, isTrue);
      expect(feed.first.title.isNotEmpty, isTrue);
      expect(feed.first.url, startsWith('https://xanimeporn.com/'));
      expect(feed.first.cover, startsWith('http'));
    });
  });
}
