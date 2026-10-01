import json

with open("scratch/ero_hentai_taxonomy_harvest.json", "r", encoding="utf-8") as f:
    data = json.load(f)

lines = []
lines.append("import 'package:flutter/material.dart';")
lines.append("import '../../models/catalog_model.dart';")
lines.append("")
lines.append("/// Authentic EroHentai Categories harvested from live endpoints and site routes")
lines.append("final List<CatalogItem> eroHentaiCategories = const [")

for c in data["categories"]:
    cat_type = "CatalogType.category"
    lines.append("  CatalogItem(")
    lines.append(f'    name: "{c["name"]}",')
    lines.append(f'    slug: "{c["slug"]}",')
    lines.append(f'    type: {cat_type},')
    lines.append(f'    icon: Icons.{c["icon"]},')
    lines.append(f'    count: {c.get("count", 0)},')
    lines.append(f'    description: "{c.get("description", "")}",')
    lines.append(f'    endpointPath: "{c["endpointPath"]}",')
    lines.append("  ),")

lines.append("];")
lines.append("")
lines.append("/// Authentic EroHentai Tags & Genres harvested from live endpoints and site routes")
lines.append("final List<CatalogItem> eroHentaiTags = const [")

for t in data["tags"]:
    t_type = "CatalogType.genre" if t["type"] == "genre" else "CatalogType.tag"
    lines.append("  CatalogItem(")
    lines.append(f'    name: "{t["name"]}",')
    lines.append(f'    slug: "{t["slug"]}",')
    lines.append(f'    type: {t_type},')
    lines.append(f'    categoryGroup: "{t.get("categoryGroup", "Trope")}",')
    lines.append(f'    icon: Icons.{t["icon"]},')
    lines.append(f'    count: {t.get("count", 0)},')
    lines.append(f'    description: "{t.get("description", "")}",')
    lines.append(f'    endpointPath: "{t["endpointPath"]}",')
    lines.append("  ),")

lines.append("];")
lines.append("")
lines.append("/// Dynamic Explore Taxonomy for EroHentai extension")
lines.append("final ExtensionTaxonomy eroHentaiTaxonomy = ExtensionTaxonomy(")
lines.append("  sections: [")
lines.append("    TaxonomySection(")
lines.append('      id: "categories",')
lines.append('      title: "Category",')
lines.append("      displayType: TaxonomyDisplayType.grid,")
lines.append("      items: eroHentaiCategories,")
lines.append("      icon: Icons.folder_rounded,")
lines.append("    ),")
lines.append("    TaxonomySection(")
lines.append('      id: "tags",')
lines.append('      title: "Tags / Genre",')
lines.append("      displayType: TaxonomyDisplayType.tags,")
lines.append("      items: eroHentaiTags,")
lines.append("      icon: Icons.tag_rounded,")
lines.append("    ),")
lines.append("  ],")
lines.append("  categories: eroHentaiCategories,")
lines.append("  tagsAndGenres: eroHentaiTags,")
lines.append(");")
lines.append("")

content = "\n".join(lines)
with open("lib/extensions/taxonomies/ero_hentai_taxonomy.dart", "w", encoding="utf-8") as f:
    f.write(content)

print("Generated lib/extensions/taxonomies/ero_hentai_taxonomy.dart successfully!")
