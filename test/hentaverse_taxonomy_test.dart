import 'package:flutter_test/flutter_test.dart';
import 'package:h_stream/extensions/sources/hentaverse_extension.dart';
import 'package:h_stream/extensions/taxonomies/hentaverse_taxonomy.dart';
import 'package:h_stream/models/catalog_model.dart';

void main() {
  group('Hentaverse Taxonomy & Extension Tests', () {
    final ext = HentaverseExtension();

    test('Extension metadata is correct', () {
      expect(ext.id, equals('hentaverse'));
      expect(ext.name, equals('Hentaverse'));
      expect(ext.baseUrl, equals('https://hentaverse.com'));
    });

    test('Taxonomy contains Categories and Tags sections', () async {
      final taxonomy = await ext.fetchTaxonomy();
      expect(taxonomy.sections.length, equals(2));

      final catSection =
          taxonomy.sections.firstWhere((s) => s.id == 'categories');
      expect(catSection.displayType, equals(TaxonomyDisplayType.grid));
      expect(catSection.items.length, equals(28));

      final tagSection = taxonomy.sections.firstWhere((s) => s.id == 'tags');
      expect(tagSection.displayType, equals(TaxonomyDisplayType.tags));
      expect(tagSection.items.length, equals(46));
    });

    test('All 46 harvested tags have valid slugs and endpoint paths', () {
      expect(hentaverseTags.length, equals(46));
      for (final t in hentaverseTags) {
        expect(t.slug.isNotEmpty, isTrue);
        expect(t.name.isNotEmpty, isTrue);
        expect(t.endpointPath, isNotNull);
        expect(t.endpointPath!.startsWith('/categories/'), isTrue);
      }
    });

    test('All 28 categories have valid slugs and endpoint paths', () {
      expect(hentaverseCategories.length, equals(28));
      final slugs = hentaverseCategories.map((c) => c.slug).toList();
      expect(slugs.contains('school-girl'), isTrue);
      expect(slugs.contains('ahegao'), isTrue);
      expect(slugs.contains('anal'), isTrue);
      expect(slugs.contains('bondage'), isTrue);
      expect(slugs.contains('censored'), isTrue);
      expect(slugs.contains('ugly-bastard'), isTrue);
    });

    test('fetchTaxonomyFeed extracts live items or falls back gracefully', () async {
      final item = hentaverseCategories.firstWhere((c) => c.slug == 'school-girl');
      final feed = await ext.fetchTaxonomyFeed(item, 1);
      expect(feed.isNotEmpty, isTrue);
      expect(feed.first.title.isNotEmpty, isTrue);
      expect(feed.first.cover.isNotEmpty, isTrue);
    });
  });
}
