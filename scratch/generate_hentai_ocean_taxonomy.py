import json
import re

with open('d:/C/H/scratch/hentai_ocean_harvested.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

genres = data['genres']
playlists = data['playlists']

def get_genre_icon(slug, name):
    s = slug.lower()
    if '3d' in s: return 'Icons.view_in_ar_rounded'
    if 'uncensor' in s: return 'Icons.lock_open_rounded'
    if 'milf' in s: return 'Icons.woman_rounded'
    if 'creampie' in s: return 'Icons.water_drop_rounded'
    if 'boob' in s: return 'Icons.bubble_chart_rounded'
    if 'school' in s: return 'Icons.school_rounded'
    if 'maid' in s: return 'Icons.cleaning_services_rounded'
    if 'nurse' in s: return 'Icons.local_hospital_rounded'
    if 'teacher' in s: return 'Icons.menu_book_rounded'
    if 'anal' in s: return 'Icons.adjust_rounded'
    if 'blowjob' in s: return 'Icons.sentiment_satisfied_rounded'
    if 'comedy' in s: return 'Icons.mood_rounded'
    if 'cosplay' in s: return 'Icons.theater_comedy_rounded'
    if 'dark' in s: return 'Icons.wb_sunny_outlined'
    if 'facial' in s: return 'Icons.face_retouching_natural_rounded'
    if 'fantasy' in s: return 'Icons.auto_awesome_rounded'
    if 'futanari' in s: return 'Icons.transgender_rounded'
    if 'gangbang' in s or 'orgy' in s: return 'Icons.groups_rounded'
    if 'gyaru' in s: return 'Icons.flare_rounded'
    if 'harem' in s: return 'Icons.diversity_1_rounded'
    if 'incest' in s: return 'Icons.family_restroom_rounded'
    if 'masturbation' in s: return 'Icons.touch_app_rounded'
    if 'mind' in s: return 'Icons.cyclone_rounded'
    if 'ntr' in s: return 'Icons.broken_image_rounded'
    if 'pov' in s: return 'Icons.videocam_rounded'
    if 'pregnant' in s: return 'Icons.pregnant_woman_rounded'
    if 'public' in s: return 'Icons.location_city_rounded'
    if 'rape' in s: return 'Icons.gavel_rounded'
    if 'swimsuit' in s: return 'Icons.pool_rounded'
    if 'tentacle' in s: return 'Icons.hub_rounded'
    if 'toy' in s: return 'Icons.toys_rounded'
    if 'vanilla' in s: return 'Icons.favorite_rounded'
    if 'virgin' in s: return 'Icons.star_outline_rounded'
    if 'x-ray' in s: return 'Icons.camera_rounded'
    if 'yaoi' in s: return 'Icons.male_rounded'
    if 'yuri' in s: return 'Icons.female_rounded'
    return 'Icons.tag_rounded'

def get_genre_group(slug):
    s = slug.lower()
    if any(k in s for k in ['milf', 'maid', 'nurse', 'teacher', 'school', 'gyaru', 'shouta']):
        return 'Character'
    if any(k in s for k in ['anal', 'blowjob', 'boobjob', 'creampie', 'facial', 'footjob', 'handjob', 'masturbation', 'toys', 'rimjob']):
        return 'Act / Fetish'
    if any(k in s for k in ['harem', 'incest', 'mind', 'ntr', 'rape', 'tentacle', 'x-ray', 'ahegao', 'tsundere']):
        return 'Trope'
    if any(k in s for k in ['fantasy', 'comedy', 'cosplay', 'vanilla', 'yaoi', 'yuri']):
        return 'Genre'
    if any(k in s for k in ['uncensor', 'softcore', '3d']):
        return 'Format'
    return 'Theme'

def get_genre_desc(name, count):
    return f"Authentic Hentai Ocean {name} anime releases • {count} videos available"

filtered_playlists = [p for p in playlists if p['episodes'] >= 2]
selected_playlists = filtered_playlists[:85]

lines = []
lines.append("// GENERATED LIVE TAXONOMY FOR HENTAI OCEAN")
lines.append("// Scraped live via Scrapling from https://hentaiocean.com/genre, /playlists, /series, /sitemap.xml")
lines.append(f"// Total Live Genres: {len(genres)}")
lines.append(f"// Total Playlists & Series: {len(selected_playlists)}")
lines.append("import 'package:flutter/material.dart';")
lines.append("import '../../models/catalog_model.dart';")
lines.append("")
lines.append("/// Authentic Hentai Ocean Genres scraped live via Scrapling")
lines.append("final List<CatalogItem> hentaiOceanGenres = const [")

for g in genres:
    name = g['name']
    slug = g['slug']
    count = g['count']
    icon = get_genre_icon(slug, name)
    group = get_genre_group(slug)
    desc = get_genre_desc(name, count)
    ep = g['endpointPath']
    lines.append("  CatalogItem(")
    lines.append(f"    name: {json.dumps(name)},")
    lines.append(f"    slug: {json.dumps(slug)},")
    lines.append("    type: CatalogType.genre,")
    lines.append(f"    categoryGroup: {json.dumps(group)},")
    lines.append(f"    icon: {icon},")
    lines.append(f"    count: {count},")
    lines.append(f"    description: {json.dumps(desc)},")
    lines.append(f"    endpointPath: {json.dumps(ep)},")
    lines.append("  ),")

lines.append("];")
lines.append("")
lines.append("/// Authentic Hentai Ocean Serialized Series & Playlists scraped live via Scrapling")
lines.append("final List<CatalogItem> hentaiOceanPlaylists = const [")

for p in selected_playlists:
    name = p['name']
    slug = p['slug']
    count = p['episodes']
    desc = p['description']
    ep = p['endpointPath']
    lines.append("  CatalogItem(")
    lines.append(f"    name: {json.dumps(name)},")
    lines.append(f"    slug: {json.dumps(slug)},")
    lines.append("    type: CatalogType.category,")
    lines.append("    categoryGroup: \"Hentai Series\",")
    lines.append("    icon: Icons.playlist_play_rounded,")
    lines.append(f"    count: {count},")
    lines.append(f"    description: {json.dumps(desc)},")
    lines.append(f"    endpointPath: {json.dumps(ep)},")
    lines.append("  ),")

lines.append("];")
lines.append("")
lines.append("/// Dynamic ExtensionTaxonomy for Hentai Ocean Explore browsing")
lines.append("final ExtensionTaxonomy hentaiOceanTaxonomy = ExtensionTaxonomy(")
lines.append("  sections: [")
lines.append("    TaxonomySection(")
lines.append("      id: \"genres\",")
lines.append("      title: \"Genres\",")
lines.append("      displayType: TaxonomyDisplayType.tags,")
lines.append("      items: hentaiOceanGenres,")
lines.append("      icon: Icons.tag_rounded,")
lines.append("    ),")
lines.append("    TaxonomySection(")
lines.append("      id: \"playlists\",")
lines.append("      title: \"Playlists & Series\",")
lines.append("      displayType: TaxonomyDisplayType.grid,")
lines.append("      items: hentaiOceanPlaylists,")
lines.append("      icon: Icons.playlist_play_rounded,")
lines.append("    ),")
lines.append("  ],")
lines.append("  categories: hentaiOceanPlaylists,")
lines.append("  tagsAndGenres: hentaiOceanGenres,")
lines.append("  artists: const [],")
lines.append(");")
lines.append("")

dart_content = "\n".join(lines)
with open('d:/C/H/lib/extensions/taxonomies/hentai_ocean_taxonomy.dart', 'w', encoding='utf-8') as f:
    f.write(dart_content)

print(f"Successfully wrote d:/C/H/lib/extensions/taxonomies/hentai_ocean_taxonomy.dart ({len(lines)} lines)!")
