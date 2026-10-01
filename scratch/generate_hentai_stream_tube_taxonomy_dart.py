import json
import sys
sys.stdout.reconfigure(encoding='utf-8')

with open('d:/C/H/scratch/hentaistream_harvest.json', encoding='utf-8') as f:
    data = json.load(f)

genres = data['genres']
tags = data['tags']

print(f"Total genres: {len(genres)}")
print(f"Total tags: {len(tags)}")

# Map icon and category group based on slug/name
def get_icon_and_group(slug, name):
    s = slug.lower()
    if any(k in s for k in ['3d', 'sfm', 'mmd', 'cgi', 'animation']):
        return ('Icons.view_in_ar_rounded', 'Format')
    elif any(k in s for k in ['hd', '1080p', '4k', '60fps']):
        return ('Icons.hd_rounded', 'Format')
    elif any(k in s for k in ['ahegao', 'facial', 'expression']):
        return ('Icons.sentiment_satisfied_alt_rounded', 'Trope')
    elif any(k in s for k in ['anal']):
        return ('Icons.trip_origin_rounded', 'Trope')
    elif any(k in s for k in ['bdsm', 'bondage', 'rope', 'restraint']):
        return ('Icons.link_rounded', 'Trope')
    elif any(k in s for k in ['big-boobs', 'boob', 'tits', 'oppai', 'breast', 'cleavage']):
        return ('Icons.circle_outlined', 'Character')
    elif any(k in s for k in ['blow-job', 'oral', 'throat', 'deepthroat']):
        return ('Icons.sentiment_satisfied_rounded', 'Trope')
    elif any(k in s for k in ['censored']):
        return ('Icons.lock_outline_rounded', 'Trope')
    elif any(k in s for k in ['uncensored', 'decensored']):
        return ('Icons.lock_open_rounded', 'Trope')
    elif any(k in s for k in ['comedy', 'humor', 'funny']):
        return ('Icons.mood_rounded', 'Genre')
    elif any(k in s for k in ['cosplay', 'costume']):
        return ('Icons.theater_comedy_rounded', 'Trope')
    elif any(k in s for k in ['creampie', 'cum', 'ejaculation']):
        return ('Icons.water_drop_rounded', 'Trope')
    elif any(k in s for k in ['dark-skin', 'tan', 'gyaru']):
        return ('Icons.wb_sunny_rounded', 'Character')
    elif any(k in s for k in ['demon', 'monster', 'succubus', 'creature']):
        return ('Icons.pest_control_rounded', 'Fantasy')
    elif any(k in s for k in ['drama', 'romance', 'love', 'date']):
        return ('Icons.favorite_rounded', 'Genre')
    elif any(k in s for k in ['elf', 'fantasy', 'magic', 'isekai']):
        return ('Icons.forest_rounded', 'Fantasy')
    elif any(k in s for k in ['femdom', 'dominant']):
        return ('Icons.gavel_rounded', 'Trope')
    elif any(k in s for k in ['fingering', 'masturbation', 'hand-job']):
        return ('Icons.pan_tool_rounded', 'Trope')
    elif any(k in s for k in ['footjob', 'feet', 'foot']):
        return ('Icons.do_not_step_rounded', 'Trope')
    elif any(k in s for k in ['futanari', 'dickgirl']):
        return ('Icons.transgender_rounded', 'Trope')
    elif any(k in s for k in ['gangbang', 'orgy', 'group', 'threesome']):
        return ('Icons.groups_rounded', 'Trope')
    elif any(k in s for k in ['glasses', 'megane']):
        return ('Icons.visibility_outlined', 'Character')
    elif any(k in s for k in ['harem']):
        return ('Icons.diversity_1_rounded', 'Genre')
    elif any(k in s for k in ['horror', 'thriller', 'mind']):
        return ('Icons.psychology_rounded', 'Genre')
    elif any(k in s for k in ['incest', 'sister', 'mother', 'family', 'brother', 'stepmother']):
        return ('Icons.family_restroom_rounded', 'Trope')
    elif any(k in s for k in ['lactation', 'milky']):
        return ('Icons.opacity_rounded', 'Trope')
    elif any(k in s for k in ['loli', 'shota']):
        return ('Icons.child_care_rounded', 'Character')
    elif any(k in s for k in ['maid']):
        return ('Icons.cleaning_services_rounded', 'Character')
    elif any(k in s for k in ['milf', 'mature']):
        return ('Icons.woman_rounded', 'Character')
    elif any(k in s for k in ['mind-break', 'mind-control']):
        return ('Icons.cyclone_rounded', 'Trope')
    elif any(k in s for k in ['netorare', 'ntr', 'cheating', 'affair']):
        return ('Icons.broken_image_rounded', 'Trope')
    elif any(k in s for k in ['nurse', 'doctor', 'medical']):
        return ('Icons.medical_services_rounded', 'Character')
    elif any(k in s for k in ['paizuri', 'titfuck']):
        return ('Icons.favorite_rounded', 'Trope')
    elif any(k in s for k in ['panties', 'stockings', 'socks', 'lingerie', 'swimsuit']):
        return ('Icons.checkroom_rounded', 'Trope')
    elif any(k in s for k in ['pov']):
        return ('Icons.videocam_rounded', 'Format')
    elif any(k in s for k in ['public', 'outdoor']):
        return ('Icons.park_rounded', 'Trope')
    elif any(k in s for k in ['school', 'student', 'teacher', 'classroom']):
        return ('Icons.school_rounded', 'Character')
    elif any(k in s for k in ['squirt', 'squirting']):
        return ('Icons.waves_rounded', 'Trope')
    elif any(k in s for k in ['tentacle', 'tentacles']):
        return ('Icons.hub_rounded', 'Fantasy')
    elif any(k in s for k in ['time-stop']):
        return ('Icons.timer_off_rounded', 'Trope')
    elif any(k in s for k in ['toys', 'dildo']):
        return ('Icons.toys_rounded', 'Trope')
    elif any(k in s for k in ['tsundere']):
        return ('Icons.sentiment_very_dissatisfied_rounded', 'Character')
    elif any(k in s for k in ['vanilla', 'pure', 'wholesome']):
        return ('Icons.sentiment_very_satisfied_rounded', 'Genre')
    elif any(k in s for k in ['virgin', 'first']):
        return ('Icons.flare_rounded', 'Trope')
    elif any(k in s for k in ['x-ray']):
        return ('Icons.camera_rounded', 'Trope')
    elif any(k in s for k in ['yuri', 'lesbian']):
        return ('Icons.favorite_border_rounded', 'Trope')
    elif any(k in s for k in ['yaoi', 'gay']):
        return ('Icons.male_rounded', 'Trope')
    elif any(k in s for k in ['inflation']):
        return ('Icons.blur_circular_rounded', 'Trope')
    else:
        return ('Icons.tag_rounded', 'Genre')

for g in genres:
    icon, grp = get_icon_and_group(g['slug'], g['name'])
    g['icon'] = icon
    g['categoryGroup'] = grp

for t in tags:
    icon, grp = get_icon_and_group(t['slug'], t['name'])
    t['icon'] = icon
    t['categoryGroup'] = grp

# Generate Dart file content
lines = []
lines.append("import 'package:flutter/material.dart';")
lines.append("import '../../models/catalog_model.dart';")
lines.append("")
lines.append("/// Authentic HentaiStream Category & Genre Cover Thumbnails harvested live from hentaistream.xxx")
lines.append("final Map<String, String> hentaiStreamCategoryCovers = const {")
for g in genres:
    if g['thumbnail']:
        lines.append(f'  "{g["slug"]}": "{g["thumbnail"]}",')
lines.append("};")
lines.append("")

# Categories for Categories [grid]
lines.append("/// Authentic HentaiStream Categories for Explore dynamic grid")
lines.append("final List<CatalogItem> hentaiStreamCategories = const [")

# Add primary navigation categories
nav_categories = [
    {
        "name": "Stream Latest",
        "slug": "latest",
        "icon": "Icons.fiber_new_rounded",
        "count": 4850,
        "description": "Latest fast buffering tube streams and fresh episodes",
        "endpointPath": "/",
        "categoryGroup": "Browse",
    },
    {
        "name": "Top Streams",
        "slug": "popular",
        "icon": "Icons.whatshot_rounded",
        "count": 4120,
        "description": "Highest rated and most watched hentai stream classics",
        "endpointPath": "/popular/",
        "categoryGroup": "Browse",
    },
    {
        "name": "Uncensored Stream",
        "slug": "uncensored",
        "icon": "Icons.lock_open_rounded",
        "count": 3120,
        "description": "Pure uncensored anime streams without mosaic pixelation",
        "endpointPath": "/genre/uncensored/",
        "categoryGroup": "Format",
    },
    {
        "name": "3D / MMD",
        "slug": "3d",
        "icon": "Icons.view_in_ar_rounded",
        "count": 61,
        "description": "Immersive 3D CGI, Blender, SFM, and MMD animations",
        "endpointPath": "/genre/3d/",
        "categoryGroup": "Format",
    },
    {
        "name": "Romance Genre",
        "slug": "romance",
        "icon": "Icons.favorite_rounded",
        "count": 890,
        "description": "Heartfelt anime romances, vanilla dates, and sweet love",
        "endpointPath": "/genre/romance/",
        "categoryGroup": "Genre",
    },
    {
        "name": "Full HD 1080p",
        "slug": "hd",
        "icon": "Icons.hd_rounded",
        "count": 1660,
        "description": "Crystal-clear HD hentai with stunning detail and fast buffer",
        "endpointPath": "/genre/hd/",
        "categoryGroup": "Quality",
    },
    {
        "name": "Big Boobs",
        "slug": "big-boobs",
        "icon": "Icons.circle_outlined",
        "count": 2215,
        "description": "Voluptuous curves and huge breasts overflowing with pleasure",
        "endpointPath": "/genre/big-boobs/",
        "categoryGroup": "Character",
    },
    {
        "name": "Blow Job",
        "slug": "blow-job",
        "icon": "Icons.sentiment_satisfied_rounded",
        "count": 2372,
        "description": "Sexy anime girls pleasing hard with mouth and tongue action",
        "endpointPath": "/genre/blow-job/",
        "categoryGroup": "Trope",
    },
    {
        "name": "Creampie",
        "slug": "creampie",
        "icon": "Icons.water_drop_rounded",
        "count": 2188,
        "description": "Hot inside releases and creamy anime climaxes",
        "endpointPath": "/genre/creampie/",
        "categoryGroup": "Trope",
    },
    {
        "name": "Milf",
        "slug": "milf",
        "icon": "Icons.woman_rounded",
        "count": 617,
        "description": "Seductive mature mothers, older women, and experienced ladies",
        "endpointPath": "/genre/milf/",
        "categoryGroup": "Character",
    },
    {
        "name": "School Girl",
        "slug": "school-girl",
        "icon": "Icons.school_rounded",
        "count": 1342,
        "description": "Cute schoolgirls in sexy uniforms and classroom affairs",
        "endpointPath": "/genre/school-girl/",
        "categoryGroup": "Character",
    },
    {
        "name": "Maid",
        "slug": "maid",
        "icon": "Icons.cleaning_services_rounded",
        "count": 312,
        "description": "Sexy anime maids serving naughty pleasures in skimpy uniforms",
        "endpointPath": "/genre/maid/",
        "categoryGroup": "Character",
    },
    {
        "name": "Harem",
        "slug": "harem",
        "icon": "Icons.groups_rounded",
        "count": 942,
        "description": "Harem hentai with one lucky hero and many sexy anime lovers",
        "endpointPath": "/genre/harem/",
        "categoryGroup": "Genre",
    },
    {
        "name": "Anal",
        "slug": "anal",
        "icon": "Icons.trip_origin_rounded",
        "count": 963,
        "description": "Tight naughty backdoor action and intense erotic scenes",
        "endpointPath": "/genre/anal/",
        "categoryGroup": "Trope",
    },
    {
        "name": "Ahegao",
        "slug": "ahegao",
        "icon": "Icons.sentiment_satisfied_alt_rounded",
        "count": 392,
        "description": "Over-the-top pleasure and wild facial expressions of ecstasy",
        "endpointPath": "/genre/ahegao/",
        "categoryGroup": "Trope",
    },
    {
        "name": "Futanari",
        "slug": "futanari",
        "icon": "Icons.transgender_rounded",
        "count": 272,
        "description": "Exotic futanari girls with wild surprise endowments",
        "endpointPath": "/genre/futanari/",
        "categoryGroup": "Trope",
    },
    {
        "name": "Cheating",
        "slug": "cheating",
        "icon": "Icons.broken_image_rounded",
        "count": 388,
        "description": "Forbidden affairs, netorare desires, and secret betrayals",
        "endpointPath": "/genre/cheating/",
        "categoryGroup": "Trope",
    },
    {
        "name": "Fantasy",
        "slug": "fantasy",
        "icon": "Icons.forest_rounded",
        "count": 583,
        "description": "Magical fantasy realms, monster girls, elves, and adventurers",
        "endpointPath": "/genre/fantasy/",
        "categoryGroup": "Fantasy",
    },
]

for cat in nav_categories:
    desc = cat["description"].replace('"', '\\"')
    lines.append("  CatalogItem(")
    lines.append(f'    name: "{cat["name"]}",')
    lines.append(f'    slug: "{cat["slug"]}",')
    lines.append(f'    type: CatalogType.category,')
    lines.append(f'    categoryGroup: "{cat["categoryGroup"]}",')
    lines.append(f'    icon: {cat["icon"]},')
    lines.append(f'    count: {cat["count"]},')
    lines.append(f'    description: "{desc}",')
    lines.append(f'    endpointPath: "{cat["endpointPath"]}",')
    lines.append("  ),")
lines.append("];")
lines.append("")

# Genres list
lines.append("/// Authentic HentaiStream Genres harvested live from hentaistream.xxx/genres/")
lines.append("final List<CatalogItem> hentaiStreamGenres = const [")
for g in genres:
    name = g['name'].replace('"', '\\"')
    desc = g['description'].replace('"', '\\"').replace('\n', ' ')
    lines.append("  CatalogItem(")
    lines.append(f'    name: "{name}",')
    lines.append(f'    slug: "{g["slug"]}",')
    lines.append(f'    type: CatalogType.genre,')
    lines.append(f'    categoryGroup: "{g["categoryGroup"]}",')
    lines.append(f'    icon: {g["icon"]},')
    lines.append(f'    count: {g["count"]},')
    lines.append(f'    description: "{desc}",')
    lines.append(f'    endpointPath: "{g["endpointPath"]}",')
    lines.append("  ),")
lines.append("];")
lines.append("")

# Tags list
lines.append("/// Authentic HentaiStream Tags harvested live from hentaistream.xxx")
lines.append("final List<CatalogItem> hentaiStreamTags = const [")
for t in tags:
    name = t['name'].replace('"', '\\"')
    desc = f"Videos tagged with #{t['name']} on HentaiStream"
    lines.append("  CatalogItem(")
    lines.append(f'    name: "{name}",')
    lines.append(f'    slug: "{t["slug"]}",')
    lines.append(f'    type: CatalogType.tag,')
    lines.append(f'    categoryGroup: "{t["categoryGroup"]}",')
    lines.append(f'    icon: {t["icon"]},')
    lines.append(f'    count: {t["count"]},')
    lines.append(f'    description: "{desc}",')
    lines.append(f'    endpointPath: "{t["endpointPath"]}",')
    lines.append("  ),")
lines.append("];")
lines.append("")

# ExtensionTaxonomy
lines.append("/// Dynamic Explore Taxonomy for HentaiStream Tube extension")
lines.append("final ExtensionTaxonomy hentaiStreamTubeTaxonomy = ExtensionTaxonomy(")
lines.append("  sections: [")
lines.append("    TaxonomySection(")
lines.append('      id: "genres",')
lines.append('      title: "Genres",')
lines.append("      displayType: TaxonomyDisplayType.tags,")
lines.append("      items: hentaiStreamGenres,")
lines.append("      icon: Icons.label_rounded,")
lines.append("    ),")
lines.append("    TaxonomySection(")
lines.append('      id: "categories",')
lines.append('      title: "Categories",')
lines.append("      displayType: TaxonomyDisplayType.grid,")
lines.append("      items: hentaiStreamCategories,")
lines.append("      icon: Icons.category_rounded,")
lines.append("    ),")
lines.append("  ],")
lines.append("  categories: hentaiStreamCategories,")
lines.append("  tagsAndGenres: hentaiStreamGenres,")
lines.append(");")
lines.append("")

target_path = 'd:/C/H/lib/extensions/taxonomies/hentai_stream_tube_taxonomy.dart'
content = '\n'.join(lines)
with open(target_path, 'w', encoding='utf-8') as f:
    f.write(content)

print(f"Generated {target_path} successfully ({len(lines)} lines)!")
