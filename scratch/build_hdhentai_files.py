import json
import re

with open('d:/C/H/.aaa/scratch/hdhentai_harvested.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

cats = data.get('categories', [])
tags = data.get('tags', [])

# Deduplicate categories
seen_slugs = set()
valid_cats = []
for c in cats:
    slug = c['slug'].strip()
    if slug and slug not in seen_slugs:
        seen_slugs.add(slug)
        valid_cats.append(c)

# Deduplicate tags
seen_tag_slugs = set()
valid_tags = []
for t in tags:
    slug = t['slug'].strip()
    if slug and slug not in seen_tag_slugs:
        seen_tag_slugs.add(slug)
        valid_tags.append(t)

print(f"Valid categories: {len(valid_cats)}, Valid tags: {len(valid_tags)}")

# Map semantic icons
def get_icon(name, slug):
    s = (name + " " + slug).lower()
    if '3d' in s or 'animation' in s:
        return 'Icons.view_in_ar_rounded'
    if 'uncensored' in s or 'censored' in s:
        return 'Icons.lock_open_rounded'
    if 'harem' in s or 'romance' in s or 'love' in s:
        return 'Icons.favorite_rounded'
    if 'hanime' in s or 'anime' in s:
        return 'Icons.movie_rounded'
    if 'game' in s or 'parody' in s:
        return 'Icons.sports_esports_rounded'
    if 'dark' in s or 'horror' in s or 'monster' in s:
        return 'Icons.dark_mode_rounded'
    if 'anal' in s or 'creampie' in s or 'blowjob' in s:
        return 'Icons.whatshot_rounded'
    if 'school' in s or 'maid' in s:
        return 'Icons.school_rounded'
    return 'Icons.category_rounded'

# Map categoryGroup
def get_group(name, slug):
    s = (name + " " + slug).lower()
    if any(k in s for k in ['3d', 'sfm', 'blender', 'cgi']):
        return '3D & CGI'
    if any(k in s for k in ['hanime', 'mangatoon', 'affect3d', 'bladx', 'luckycharmz', '3dxpassion', 'dreamforge', 'sherbek', 'yinrai']):
        return 'Studios & Creators'
    if any(k in s for k in ['anal', 'creampie', 'blowjob', 'boobs', 'cunnilingus', 'gangbang', 'masturbation', 'paizuri']):
        return 'Acts & Fetishes'
    if any(k in s for k in ['school', 'maid', 'milf', 'nurse', 'sister', 'teacher', 'cheerleader']):
        return 'Character Archetypes'
    return 'Genres & Themes'

# Generate Dart taxonomy
dart = []
dart.append("// HD Hentai (xxxhdhentai) Dynamic Taxonomy")
dart.append("// Auto-generated from live Scrapling discovery harvest.")
dart.append("import 'package:flutter/material.dart';")
dart.append("import '../../models/catalog_model.dart';")
dart.append("")

# Cover map
dart.append("/// Category cover thumbnail artwork map")
dart.append("const Map<String, String> hdHentaiCategoryCovers = {")
for c in valid_cats:
    if c.get('cover'):
        dart.append(f'  "{c["slug"]}": "{c["cover"]}",')
dart.append("};")
dart.append("")

# Categories list
dart.append("/// HD Hentai studio & video categories")
dart.append("final List<CatalogItem> hdHentaiCategories = [")
for c in valid_cats:
    name_escaped = c['name'].replace('"', '\\"')
    slug = c['slug']
    count = c.get('count', 0)
    icon = get_icon(c['name'], slug)
    grp = get_group(c['name'], slug)
    ep = f"/category/{slug}/"
    dart.append(f'  CatalogItem(')
    dart.append(f'    name: "{name_escaped}",')
    dart.append(f'    slug: "{slug}",')
    dart.append(f'    type: CatalogType.category,')
    dart.append(f'    categoryGroup: "{grp}",')
    dart.append(f'    icon: {icon},')
    dart.append(f'    count: {count},')
    dart.append(f'    endpointPath: "{ep}",')
    dart.append(f'  ),')
dart.append("];")
dart.append("")

# Tags list
dart.append("/// HD Hentai tags & tropes")
dart.append("final List<CatalogItem> hdHentaiTags = [")
for t in valid_tags[:200]:  # Top 200 clean tags
    name_escaped = t['name'].replace('"', '\\"')
    slug = t['slug']
    count = t.get('count', 0)
    icon = get_icon(t['name'], slug)
    ep = f"/tag/{slug}/"
    dart.append(f'  CatalogItem(')
    dart.append(f'    name: "{name_escaped}",')
    dart.append(f'    slug: "{slug}",')
    dart.append(f'    type: CatalogType.tag,')
    dart.append(f'    icon: {icon},')
    dart.append(f'    count: {count},')
    dart.append(f'    endpointPath: "{ep}",')
    dart.append(f'  ),')
dart.append("];")
dart.append("")

# ExtensionTaxonomy definition
dart.append("/// Dynamic ExtensionTaxonomy for HD Hentai")
dart.append("final ExtensionTaxonomy hdHentaiTaxonomy = ExtensionTaxonomy(")
dart.append("  sections: [")
dart.append("    TaxonomySection(")
dart.append('      id: "categories",')
dart.append('      title: "Categories & Studios",')
dart.append("      displayType: TaxonomyDisplayType.grid,")
dart.append("      items: hdHentaiCategories,")
dart.append("    ),")
dart.append("    TaxonomySection(")
dart.append('      id: "tags",')
dart.append('      title: "Tags & Tropes",')
dart.append("      displayType: TaxonomyDisplayType.tags,")
dart.append("      items: hdHentaiTags,")
dart.append("    ),")
dart.append("  ],")
dart.append(");")

with open('lib/extensions/taxonomies/xxxhdhentai_taxonomy.dart', 'w', encoding='utf-8') as f:
    f.write("\n".join(dart) + "\n")

print("Generated lib/extensions/taxonomies/xxxhdhentai_taxonomy.dart successfully!")
