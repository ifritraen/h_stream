import 'package:flutter_test/flutter_test.dart';
import 'package:h_stream/extensions/sources/hmvmania_extension.dart';
import 'package:h_stream/extensions/taxonomies/hmvmania_taxonomy.dart';
import 'package:h_stream/models/catalog_model.dart';

void main() {
  group('HMV Mania Taxonomy & Extension Tests', () {
    final ext = HmvManiaExtension();

    test('Extension metadata is correct', () {
      expect(ext.id, equals('hmv_mania'));
      expect(ext.name, equals('HMV Mania'));
      expect(ext.baseUrl, equals('https://hmvmania.com'));
    });

    test('Taxonomy contains Categories and Tags sections', () async {
      final taxonomy = await ext.fetchTaxonomy();
      expect(taxonomy.sections.length, equals(2));

      final catSection =
          taxonomy.sections.firstWhere((s) => s.id == 'categories');
      expect(catSection.displayType, equals(TaxonomyDisplayType.grid));
      expect(catSection.items.length, equals(6));

      final tagSection = taxonomy.sections.firstWhere((s) => s.id == 'tags');
      expect(tagSection.displayType, equals(TaxonomyDisplayType.tags));
      expect(tagSection.items.length, equals(88));
    });

    test('All 88 harvested tags have valid slugs and endpoint paths', () {
      expect(hmvManiaTags.length, equals(88));
      for (final t in hmvManiaTags) {
        expect(t.slug.isNotEmpty, isTrue);
        expect(t.name.isNotEmpty, isTrue);
        expect(t.endpointPath, isNotNull);
        expect(t.endpointPath!.startsWith('/genre/'), isTrue);
      }
    });

    test('All 6 categories have valid slugs and endpoint paths', () {
      expect(hmvManiaCategories.length, equals(6));
      final slugs = hmvManiaCategories.map((c) => c.slug).toList();
      expect(slugs.contains('3d'), isTrue);
      expect(slugs.contains('hmv'), isTrue);
      expect(slugs.contains('amv'), isTrue);
      expect(slugs.contains('challenge'), isTrue);
      expect(slugs.contains('generative_ai'), isTrue);
      expect(slugs.contains('tutorial'), isTrue);
    });

    test('fetchTaxonomyFeed gracefully falls back or extracts items', () async {
      final item = hmvManiaCategories.firstWhere((c) => c.slug == '3d');
      final feed = await ext.fetchTaxonomyFeed(item, 1);
      expect(feed.isNotEmpty, isTrue);
      expect(feed.first.title.isNotEmpty, isTrue);
      expect(feed.first.cover.isNotEmpty, isTrue);
    });
  });
}
