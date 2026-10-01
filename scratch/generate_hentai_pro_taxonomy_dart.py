import json

with open('scratch/hentai_pro_harvest.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

categories = data['categories']
tags = data['tags']

# Sort categories by count descending so most popular are first
categories.sort(key=lambda c: c['count'], reverse=True)

out = []
out.append("// GENERATED LIVE TAXONOMY FOR HENTAIPRO")
out.append(f"// Scraped live via Scrapling from https://hentaipro.net/categories/, https://hentaipro.net/tags/, https://hentaipro.net/genres/")
out.append(f"// Total Categories: {len(categories)}")
out.append(f"// Total Tags & Studios: {len(tags)}")
out.append("import 'package:flutter/material.dart';")
out.append("import '../../models/catalog_model.dart';")
out.append("")
out.append("/// Authentic category cover posters scraped live from HentaiPro")
out.append("final Map<String, String> hentaiProCategoryCovers = const {")
for c in categories:
    if c['cover']:
        out.append(f'  "{c["slug"]}": "{c["cover"]}",')
for t in tags:
    if t.get('cover'):
        out.append(f'  "{t["slug"]}": "{t["cover"]}",')
out.append("};")
out.append("")
out.append("/// Authentic HentaiPro Categories scraped live")
out.append("final List<CatalogItem> hentaiProCategories = const [")

for c in categories:
    slug = c['slug']
    name = c['name']
    cat_group = c.get('categoryGroup', 'Category')
    icon = c.get('icon', 'Icons.category_rounded')
    count = c.get('count', 0)
    desc = c.get('description', '').replace('"', '\\"')
    endpoint = c.get('endpointPath', f'/{slug}/')
    
    out.append("  CatalogItem(")
    out.append(f'    name: "{name}",')
    out.append(f'    slug: "{slug}",')
    out.append(f"    type: CatalogType.category,")
    out.append(f'    categoryGroup: "{cat_group}",')
    out.append(f"    icon: {icon},")
    out.append(f"    count: {count},")
    out.append(f'    description: "{desc}",')
    out.append(f'    endpointPath: "{endpoint}",')
    out.append("  ),")

out.append("];")
out.append("")
out.append("/// Authentic HentaiPro Tags, Genres & Studios scraped live")
out.append("final List<CatalogItem> hentaiProTags = const [")

for t in tags:
    slug = t['slug']
    name = t['name']
    cat_group = t.get('categoryGroup', 'Tag')
    icon = t.get('icon', 'Icons.tag_rounded')
    count = t.get('count', 0)
    desc = t.get('description', '').replace('"', '\\"')
    endpoint = t.get('endpointPath', f'/{slug}/')
    t_type = "CatalogType.tag"
    if cat_group == 'Studio':
        t_type = "CatalogType.artist"
    elif cat_group in ['Genre', 'Quality']:
        t_type = "CatalogType.genre"
        
    out.append("  CatalogItem(")
    out.append(f'    name: "{name}",')
    out.append(f'    slug: "{slug}",')
    out.append(f"    type: {t_type},")
    out.append(f'    categoryGroup: "{cat_group}",')
    out.append(f"    icon: {icon},")
    out.append(f"    count: {count},")
    out.append(f'    description: "{desc}",')
    out.append(f'    endpointPath: "{endpoint}",')
    out.append("  ),")

out.append("];")
out.append("")
out.append("/// HentaiPro dynamic Explore Taxonomy with dynamic Grid Categories and Tags")
out.append("final ExtensionTaxonomy hentaiProTaxonomy = ExtensionTaxonomy(")
out.append("  sections: [")
out.append("    TaxonomySection(")
out.append('      id: "categories",')
out.append('      title: "Categories",')
out.append("      displayType: TaxonomyDisplayType.grid,")
out.append("      items: hentaiProCategories,")
out.append("      icon: Icons.category_rounded,")
out.append("    ),")
out.append("    TaxonomySection(")
out.append('      id: "tags",')
out.append('      title: "Tags & Studios",')
out.append("      displayType: TaxonomyDisplayType.tags,")
out.append("      items: hentaiProTags,")
out.append("      icon: Icons.tag_rounded,")
out.append("    ),")
out.append("  ],")
out.append("  categories: hentaiProCategories,")
out.append("  tagsAndGenres: hentaiProTags,")
out.append("  artists: const [],")
out.append(");")
out.append("")

dart_content = "\n".join(out)

target_file = r'd:\C\H\lib\extensions\taxonomies\hentai_pro_taxonomy.dart'
with open(target_file, 'w', encoding='utf-8') as f:
    f.write(dart_content)

print(f"Generated {target_file} successfully! Total lines: {len(out)}")
