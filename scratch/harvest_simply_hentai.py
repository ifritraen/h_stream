import json
import re
from scrapling.fetchers import Fetcher

fetcher = Fetcher()

# 1. Fetch top franchise series
print("Fetching series from Simply Hentai v3 API...")
series_url = "https://api.simply-hentai.com/v3/series?sort=largest"
r_series = fetcher.get(series_url)
series_data = json.loads(r_series.body.decode('utf-8')).get('data', [])
print(f"Total series fetched: {len(series_data)}")

# 2. Fetch top tags
print("Fetching tags from Simply Hentai v3 API...")
tags_url = "https://api.simply-hentai.com/v3/tags"
r_tags = fetcher.get(tags_url)
tags_data = json.loads(r_tags.body.decode('utf-8')).get('data', [])
print(f"Total tags fetched: {len(tags_data)}")

# 3. Fetch second page of series if available
try:
    r_series_p2 = fetcher.get("https://api.simply-hentai.com/v3/series?sort=largest&page=2")
    series_p2 = json.loads(r_series_p2.body.decode('utf-8')).get('data', [])
    series_data.extend(series_p2)
    print(f"Total series after page 2: {len(series_data)}")
except Exception as e:
    print("Page 2 series err:", e)

# 4. Fetch second page of tags
try:
    r_tags_p2 = fetcher.get("https://api.simply-hentai.com/v3/tags?page=2")
    tags_p2 = json.loads(r_tags_p2.body.decode('utf-8')).get('data', [])
    tags_data.extend(tags_p2)
    print(f"Total tags after page 2: {len(tags_data)}")
except Exception as e:
    print("Page 2 tags err:", e)

# Clean up series
clean_series = []
seen_series = set()
series_covers = {}

for s in series_data:
    slug = s.get('slug', '').strip()
    title = s.get('title', '').strip()
    count = s.get('album_count', 0)
    preview = s.get('preview', {})
    cover_url = ""
    if isinstance(preview, dict):
        cover_url = preview.get('sizes', {}).get('medium') or preview.get('sizes', {}).get('thumb') or preview.get('url') or ""
    
    if slug and slug not in seen_series and title:
        seen_series.add(slug)
        clean_series.append({
            'name': title,
            'slug': slug,
            'count': count,
            'cover': cover_url,
            'endpointPath': f"/series/{slug}"
        })
        if cover_url:
            series_covers[slug] = cover_url

# Clean up tags
clean_tags = []
seen_tags = set()
for t in tags_data:
    slug = t.get('slug', '').strip()
    title = t.get('title', '').strip()
    count = t.get('object_count', 0)
    if slug and slug not in seen_tags and title:
        seen_tags.add(slug)
        clean_tags.append({
            'name': title,
            'slug': slug,
            'count': count,
            'endpointPath': f"/tags/{slug}"
        })

print(f"Clean series: {len(clean_series)}, Clean tags: {len(clean_tags)}, Covers: {len(series_covers)}")

# Generate Dart taxonomy
dart = []
dart.append("// Simply Hentai Dynamic Taxonomy")
dart.append("// Auto-generated from official Simply Hentai API live discovery.")
dart.append("import 'package:flutter/material.dart';")
dart.append("import '../../models/catalog_model.dart';")
dart.append("")

# Cover map
dart.append("/// Series cover thumbnail artwork map")
dart.append("const Map<String, String> simplyHentaiSeriesCovers = {")
for slug, cov in series_covers.items():
    dart.append(f'  "{slug}": "{cov}",')
dart.append("};")
dart.append("")

# Series list
dart.append("/// Simply Hentai franchise series catalog")
dart.append("final List<CatalogItem> simplyHentaiSeries = [")
for s in clean_series:
    name_escaped = s['name'].replace('"', '\\"')
    slug = s['slug']
    count = s['count']
    ep = s['endpointPath']
    dart.append(f'  CatalogItem(')
    dart.append(f'    name: "{name_escaped}",')
    dart.append(f'    slug: "{slug}",')
    dart.append(f'    type: CatalogType.category,')
    dart.append(f'    categoryGroup: "Anime Franchises",')
    dart.append(f'    icon: Icons.auto_stories_rounded,')
    dart.append(f'    count: {count},')
    dart.append(f'    endpointPath: "{ep}",')
    dart.append(f'  ),')
dart.append("];")
dart.append("")

# Tags list
dart.append("/// Simply Hentai genres and tropes")
dart.append("final List<CatalogItem> simplyHentaiTags = [")
for t in clean_tags:
    name_escaped = t['name'].replace('"', '\\"')
    slug = t['slug']
    count = t['count']
    ep = t['endpointPath']
    dart.append(f'  CatalogItem(')
    dart.append(f'    name: "{name_escaped}",')
    dart.append(f'    slug: "{slug}",')
    dart.append(f'    type: CatalogType.tag,')
    dart.append(f'    icon: Icons.tag_rounded,')
    dart.append(f'    count: {count},')
    dart.append(f'    endpointPath: "{ep}",')
    dart.append(f'  ),')
dart.append("];")
dart.append("")

# ExtensionTaxonomy definition
dart.append("/// Dynamic ExtensionTaxonomy for Simply Hentai")
dart.append("final ExtensionTaxonomy simplyHentaiTaxonomy = ExtensionTaxonomy(")
dart.append("  sections: [")
dart.append("    TaxonomySection(")
dart.append('      id: "series",')
dart.append('      title: "Anime Franchises & Series",')
dart.append("      displayType: TaxonomyDisplayType.grid,")
dart.append("      items: simplyHentaiSeries,")
dart.append("    ),")
dart.append("    TaxonomySection(")
dart.append('      id: "tags",')
dart.append('      title: "Genres & Tropes",')
dart.append("      displayType: TaxonomyDisplayType.tags,")
dart.append("      items: simplyHentaiTags,")
dart.append("    ),")
dart.append("  ],")
dart.append(");")

with open('lib/extensions/taxonomies/simply_hentai_taxonomy.dart', 'w', encoding='utf-8') as f:
    f.write("\n".join(dart) + "\n")

print("Generated lib/extensions/taxonomies/simply_hentai_taxonomy.dart successfully!")
