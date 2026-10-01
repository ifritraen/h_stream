import 'package:flutter_test/flutter_test.dart';
import 'package:h_stream/extensions/sources/hentai_stream_tube_extension.dart';
import 'package:h_stream/extensions/taxonomies/hentai_stream_tube_taxonomy.dart';
import 'package:h_stream/models/catalog_model.dart';

void main() {
  group('HentaiStreamTube Taxonomy & Extension Tests', () {
    final ext = HentaiStreamTubeExtension();

    test('Extension metadata is correct', () {
      expect(ext.id, equals('hentai_stream_tube'));
      expect(ext.name, equals('HentaiStream'));
      expect(ext.baseUrl, equals('https://hentaistream.xxx'));
    });

    test('Taxonomy contains dynamic Genres and Categories sections', () async {
      final taxonomy = await ext.fetchTaxonomy();
      expect(taxonomy.sections.length, equals(2));

      final genreSection = taxonomy.sections.firstWhere((s) => s.id == 'genres');
      expect(genreSection.displayType, equals(TaxonomyDisplayType.tags));
      expect(genreSection.items.length, equals(66));

      final catSection = taxonomy.sections.firstWhere((s) => s.id == 'categories');
      expect(catSection.displayType, equals(TaxonomyDisplayType.grid));
      expect(catSection.items.isNotEmpty, isTrue);
    });

    test('All 66 harvested genres have valid slugs, names, and endpoint paths', () {
      expect(hentaiStreamGenres.length, equals(66));
      for (final g in hentaiStreamGenres) {
        expect(g.slug.isNotEmpty, isTrue);
        expect(g.name.isNotEmpty, isTrue);
        expect(g.endpointPath, isNotNull);
        expect(g.endpointPath!.startsWith('/genre/'), isTrue);
      }
    });

    test('All 44 harvested tags have valid slugs, names, and endpoint paths', () {
      expect(hentaiStreamTags.length, equals(44));
      for (final t in hentaiStreamTags) {
        expect(t.slug.isNotEmpty, isTrue);
        expect(t.name.isNotEmpty, isTrue);
        expect(t.endpointPath, isNotNull);
        expect(t.endpointPath!.startsWith('/tag/'), isTrue);
      }
    });

    test('Cover thumbnails map is populated with authentic image URLs', () {
      expect(hentaiStreamCategoryCovers.isNotEmpty, isTrue);
      expect(hentaiStreamCategoryCovers.containsKey('3d'), isTrue);
      expect(hentaiStreamCategoryCovers.containsKey('big-boobs'), isTrue);
      expect(hentaiStreamCategoryCovers['3d']!.startsWith('https://hentaistream.xxx/'), isTrue);
    });

    test('fetchTaxonomyFeed gracefully extracts or falls back to valid MediaItems', () async {
      final item = hentaiStreamCategories.firstWhere((c) => c.slug == 'romance');
      final feed = await ext.fetchTaxonomyFeed(item, 1);
      expect(feed.isNotEmpty, isTrue);
      expect(feed.first.title.isNotEmpty, isTrue);
      expect(feed.first.cover.isNotEmpty, isTrue);
    });
  });
}
