import 'package:flutter_test/flutter_test.dart';
import 'package:h_stream/extensions/sources/hentai_tube_extension.dart';
import 'package:h_stream/extensions/taxonomies/hentai_tube_taxonomy.dart';
import 'package:h_stream/models/catalog_model.dart';

void main() {
  group('HentaiTube Taxonomy & Extension Tests', () {
    final ext = HentaiTubeExtension();

    test('Extension metadata is correct', () {
      expect(ext.id, equals('hentai_tube'));
      expect(ext.name, equals('HentaiTube'));
      expect(ext.baseUrl, equals('https://hentaitube.online'));
    });

    test('Taxonomy contains Categories and Genres sections', () async {
      final taxonomy = await ext.fetchTaxonomy();
      expect(taxonomy.sections.length, equals(2));

      final catSection = taxonomy.sections.firstWhere((s) => s.id == 'categories');
      expect(catSection.displayType, equals(TaxonomyDisplayType.grid));
      expect(catSection.items.isNotEmpty, isTrue);

      final genreSection = taxonomy.sections.firstWhere((s) => s.id == 'genres');
      expect(genreSection.displayType, equals(TaxonomyDisplayType.tags));
      expect(genreSection.items.length, equals(95));
    });

    test('All 95 harvested genres have valid slugs and endpoint paths', () {
      expect(hentaiTubeGenres.length, equals(95));
      for (final g in hentaiTubeGenres) {
        expect(g.slug.isNotEmpty, isTrue);
        expect(g.name.isNotEmpty, isTrue);
        expect(g.endpointPath, isNotNull);
        expect(g.endpointPath!.startsWith('/genre/'), isTrue);
      }
    });

    test('Categories contain key primary portals and top categories', () {
      expect(hentaiTubeCategories.isNotEmpty, isTrue);
      final slugs = hentaiTubeCategories.map((c) => c.slug).toList();
      expect(slugs.contains('hentai-list'), isTrue);
      expect(slugs.contains('uncensored'), isTrue);
      expect(slugs.contains('3d'), isTrue);
      expect(slugs.contains('action'), isTrue);
      expect(slugs.contains('romance'), isTrue);
    });

    test('fetchTaxonomyFeed gracefully falls back or extracts items', () async {
      final item = hentaiTubeCategories.firstWhere((c) => c.slug == 'action');
      final feed = await ext.fetchTaxonomyFeed(item, 1);
      expect(feed.isNotEmpty, isTrue);
      expect(feed.first.title.isNotEmpty, isTrue);
      expect(feed.first.cover.isNotEmpty, isTrue);
    });
  });
}
