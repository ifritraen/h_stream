import 'package:flutter_test/flutter_test.dart';
import 'package:h_stream/extensions/extensions_registry.dart';
import 'package:h_stream/extensions/sources/pornhub_extension.dart';
import 'package:h_stream/extensions/sources/simply_hentai_extension.dart';
import 'package:h_stream/extensions/sources/xxxhdhentai_extension.dart';
import 'package:h_stream/extensions/sources/hentaidb_extension.dart';
import 'package:h_stream/extensions/sources/hentai_ht_extension.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ExtensionRegistry contains 48 total extensions', () {
    final all = ExtensionRegistry.getAllExtensions();
    expect(all.length, 48);

    final ids = all.map((e) => e.id).toSet();
    expect(ids.contains('pornhub'), isTrue);
    expect(ids.contains('simply_hentai'), isTrue);
    expect(ids.contains('xxxhdhentai'), isTrue);
    expect(ids.contains('hentaidb'), isTrue);
    expect(ids.contains('hentai_ht'), isTrue);
  });

  test('PornhubExtension metadata and taxonomy check', () async {
    final ext = PornhubExtension();
    expect(ext.id, 'pornhub');
    expect(ext.name, 'PornHub Hentai');
    expect(ext.baseUrl, 'https://www.pornhub.com');
    expect(ext.tabs.isNotEmpty, isTrue);

    final taxonomy = await ext.fetchTaxonomy();
    expect(taxonomy.effectiveSections.isNotEmpty, isTrue);
    final catSection = taxonomy.effectiveSections.firstWhere((s) => s.id == 'categories');
    expect(catSection.items.isNotEmpty, isTrue);
  });

  test('SimplyHentaiExtension metadata and taxonomy check', () async {
    final ext = SimplyHentaiExtension();
    expect(ext.id, 'simply_hentai');
    expect(ext.name, 'Simply Hentai');
    expect(ext.baseUrl, 'https://www.simply-hentai.com');
    expect(ext.tabs.isNotEmpty, isTrue);

    final taxonomy = await ext.fetchTaxonomy();
    expect(taxonomy.effectiveSections.isNotEmpty, isTrue);
    final seriesSection = taxonomy.effectiveSections.firstWhere((s) => s.id == 'series');
    expect(seriesSection.items.isNotEmpty, isTrue);
  });

  test('XxxHdhentaiExtension metadata and taxonomy check', () async {
    final ext = XxxHdhentaiExtension();
    expect(ext.id, 'xxxhdhentai');
    expect(ext.name, 'HD Hentai');
    expect(ext.baseUrl, 'https://hdhentai.tv');
    expect(ext.tabs.isNotEmpty, isTrue);

    final taxonomy = await ext.fetchTaxonomy();
    expect(taxonomy.effectiveSections.isNotEmpty, isTrue);
    final catSection = taxonomy.effectiveSections.firstWhere((s) => s.id == 'categories');
    expect(catSection.items.isNotEmpty, isTrue);
  });

  test('HentaiDbExtension metadata and taxonomy check', () async {
    final ext = HentaiDbExtension();
    expect(ext.id, 'hentaidb');
    expect(ext.name, 'HentaiDB');
    expect(ext.baseUrl, 'https://hentaidb.xyz');
    expect(ext.tabs.isNotEmpty, isTrue);

    final taxonomy = await ext.fetchTaxonomy();
    expect(taxonomy.effectiveSections.isNotEmpty, isTrue);
    final seriesSection = taxonomy.effectiveSections.firstWhere((s) => s.id == 'series');
    expect(seriesSection.items.length, 80);
    final tagsSection = taxonomy.effectiveSections.firstWhere((s) => s.id == 'tags');
    expect(tagsSection.items.length, 203);
  });

  test('HentaiHtExtension metadata and taxonomy check', () async {
    final ext = HentaiHtExtension();
    expect(ext.id, 'hentai_ht');
    expect(ext.name, 'Hentai.ht');
    expect(ext.baseUrl, 'https://hentai.ht');
    expect(ext.tabs.isNotEmpty, isTrue);

    final taxonomy = await ext.fetchTaxonomy();
    expect(taxonomy.effectiveSections.isNotEmpty, isTrue);
    final collSection = taxonomy.effectiveSections.firstWhere((s) => s.id == 'collections');
    expect(collSection.items.isNotEmpty, isTrue);
    final studiosSection = taxonomy.effectiveSections.firstWhere((s) => s.id == 'studios');
    expect(studiosSection.items.length, 45);
    final tagsSection = taxonomy.effectiveSections.firstWhere((s) => s.id == 'tags');
    expect(tagsSection.items.length, 58);
  });
}
