import json
import re

with open("scratch/iwara_harvest_results.json", "r", encoding="utf-8") as f:
    data = json.load(f)

categories = data["categories"]
tags = data["tags"]
creators = data["creators"]

def escape_dart_str(s):
    if not s:
        return ""
    return s.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$')

lines = []
lines.append("import 'package:flutter/material.dart';")
lines.append("import '../../models/catalog_model.dart';")
lines.append("")
lines.append("/// Authentic Iwara.net 3D/MMD Categories harvested live from api.iwara.tv & iwara.tv")
lines.append("final List<CatalogItem> iwaraNetCategories = const [")

for c in categories:
    name = escape_dart_str(c["name"])
    slug = escape_dart_str(c["slug"])
    group = escape_dart_str(c["group"])
    icon = c["icon"]
    count = c["count"]
    desc = escape_dart_str(f"3D MMD animations & CGI clips under {c['name']}")
    endpoint = escape_dart_str(f"/videos?tags={c['slug']}")

    lines.append("  CatalogItem(")
    lines.append(f"    name: '{name}',")
    lines.append(f"    slug: '{slug}',")
    lines.append("    type: CatalogType.category,")
    lines.append(f"    categoryGroup: '{group}',")
    lines.append(f"    icon: {icon},")
    lines.append(f"    count: {count},")
    lines.append(f"    description: '{desc}',")
    lines.append(f"    endpointPath: '{endpoint}',")
    lines.append("  ),")

lines.append("];")
lines.append("")
lines.append("/// Authentic Iwara.net Live Tags harvested from api.iwara.tv/tags & trending feeds")
lines.append("final List<CatalogItem> iwaraNetTags = const [")

for t in tags:
    name = escape_dart_str(t["name"])
    slug = escape_dart_str(t["slug"])
    group = escape_dart_str(t["group"])
    icon = t["icon"]
    count = t["count"]
    desc = escape_dart_str(f"Iwara clips & dance choreography tagged #{t['name']}")
    endpoint = escape_dart_str(f"/videos?tags={t['slug']}")

    lines.append("  CatalogItem(")
    lines.append(f"    name: '{name}',")
    lines.append(f"    slug: '{slug}',")
    lines.append("    type: CatalogType.tag,")
    lines.append(f"    categoryGroup: '{group}',")
    lines.append(f"    icon: {icon},")
    lines.append(f"    count: {count},")
    lines.append(f"    description: '{desc}',")
    lines.append(f"    endpointPath: '{endpoint}',")
    lines.append("  ),")

lines.append("];")
lines.append("")
lines.append("/// Top 3D MMD Creators & Animators harvested live from Iwara API video discovery")
lines.append("final List<CatalogItem> iwaraNetCreators = const [")

for cr in creators:
    name = escape_dart_str(cr["name"])
    username = escape_dart_str(cr["username"])
    uid = escape_dart_str(cr["id"])
    views = cr["sample_views"]
    likes = cr["sample_likes"]
    vcount = cr["sample_videos"]
    
    # Formatted view string for desc
    if views >= 1000000:
        view_str = f"{views / 1000000:.1f}M views"
    elif views >= 1000:
        view_str = f"{views / 1000:.1f}K views"
    else:
        view_str = f"{views} views"
        
    desc = escape_dart_str(f"Top 3D MMD animator @{cr['username']} • {view_str} • {likes:,} likes")
    endpoint = escape_dart_str(f"/profile/{cr['username']}?user={cr['id']}")

    lines.append("  CatalogItem(")
    lines.append(f"    name: '{name}',")
    lines.append(f"    slug: '{username}',")
    lines.append("    type: CatalogType.artist,")
    lines.append("    categoryGroup: 'Creator',")
    lines.append("    icon: Icons.palette_rounded,")
    lines.append(f"    count: {views},")
    lines.append(f"    description: '{desc}',")
    lines.append(f"    endpointPath: '{endpoint}',")
    lines.append("  ),")

lines.append("];")
lines.append("")
lines.append("/// Dynamic Explore Taxonomy configuration for Iwara.net")
lines.append("final ExtensionTaxonomy iwaraNetTaxonomy = ExtensionTaxonomy(")
lines.append("  sections: [")
lines.append("    TaxonomySection(")
lines.append("      id: 'categories',")
lines.append("      title: 'Categories',")
lines.append("      displayType: TaxonomyDisplayType.grid,")
lines.append("      items: iwaraNetCategories,")
lines.append("      icon: Icons.category_rounded,")
lines.append("    ),")
lines.append("    TaxonomySection(")
lines.append("      id: 'tags',")
lines.append("      title: 'Tags',")
lines.append("      displayType: TaxonomyDisplayType.tags,")
lines.append("      items: iwaraNetTags,")
lines.append("      icon: Icons.tag_rounded,")
lines.append("    ),")
lines.append("    TaxonomySection(")
lines.append("      id: 'creators',")
lines.append("      title: 'Creators',")
lines.append("      displayType: TaxonomyDisplayType.artists,")
lines.append("      items: iwaraNetCreators,")
lines.append("      icon: Icons.palette_rounded,")
lines.append("    ),")
lines.append("  ],")
lines.append("  categories: iwaraNetCategories,")
lines.append("  tagsAndGenres: iwaraNetTags,")
lines.append("  artists: iwaraNetCreators,")
lines.append(");")
lines.append("")

output_code = "\n".join(lines)
with open("lib/extensions/taxonomies/iwara_net_taxonomy.dart", "w", encoding="utf-8") as f:
    f.write(output_code)

print("Generated lib/extensions/taxonomies/iwara_net_taxonomy.dart successfully!")
