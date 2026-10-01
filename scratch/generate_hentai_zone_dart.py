import json
import re

def clean_description(desc, name):
    if not desc:
        return f"Collection of {name} hentai releases and translations"
    # Remove HTML tags
    desc = re.sub(r'<[^>]+>', ' ', desc)
    # Replace non-breaking space and control chars
    desc = desc.replace('\u00a0', ' ').replace('\n', ' ').replace('\r', ' ').replace('\t', ' ')
    # Collapse multiple whitespace
    desc = ' '.join(desc.split()).strip()
    if not desc:
        return f"Collection of {name} hentai releases and translations"
    return desc

def get_cat_icon(name, slug):
    s = slug.lower()
    if 'sub-ita' in s or 'video' in s:
        return 'Icons.play_circle_filled_rounded'
    if 'manga' in s:
        return 'Icons.menu_book_rounded'
    if 'doujinshi' in s:
        return 'Icons.auto_stories_rounded'
    if 'fumetti' in s or 'immagini' in s:
        return 'Icons.photo_library_rounded'
    if '3d' in s:
        return 'Icons.view_in_ar_rounded'
    if 'milf' in s:
        return 'Icons.woman_rounded'
    if 'teen' in s:
        return 'Icons.face_rounded'
    if 'tette-grosse' in s or 'tette-piccole' in s or 'bbw' in s:
        return 'Icons.favorite_rounded'
    if 'bondage' in s:
        return 'Icons.link_rounded'
    if 'incesto' in s:
        return 'Icons.family_restroom_rounded'
    if 'femdom' in s:
        return 'Icons.gavel_rounded'
    if 'futanari' in s:
        return 'Icons.transgender_rounded'
    if 'yuri' in s:
        return 'Icons.female_rounded'
    if 'yaoi' in s:
        return 'Icons.male_rounded'
    if 'color' in s:
        return 'Icons.palette_rounded'
    if 'western' in s or 'american' in s or 'futurama' in s or 'griffin' in s:
        return 'Icons.public_rounded'
    if 'dragon-ball' in s or 'naruto' in s or 'one-piece' in s or 'my-hero' in s or 'sailor' in s or 'final-fantasy' in s:
        return 'Icons.sports_martial_arts_rounded'
    if 'simpson' in s or 'flintstones' in s:
        return 'Icons.tv_rounded'
    if 'furry' in s or 'bestiality' in s or 'monster' in s:
        return 'Icons.pets_rounded'
    if 'giochi' in s:
        return 'Icons.sports_esports_rounded'
    if 'italiano' in s:
        return 'Icons.language_rounded'
    if 'tradotti' in s:
        return 'Icons.translate_rounded'
    if 'premium' in s:
        return 'Icons.workspace_premium_rounded'
    if 'interracial' in s:
        return 'Icons.diversity_1_rounded'
    return 'Icons.category_rounded'

def get_tag_icon(name, slug):
    s = slug.lower()
    if 'creampie' in s or 'squirt' in s or 'orgasmo' in s:
        return 'Icons.water_drop_rounded'
    if 'cock' in s or 'anale' in s or 'blowjob' in s or 'ass' in s or 'spagnola' in s:
        return 'Icons.whatshot_rounded'
    if 'tette' in s:
        return 'Icons.favorite_rounded'
    if 'ahegao' in s:
        return 'Icons.mood_bad_rounded'
    if 'toys' in s:
        return 'Icons.smart_toy_rounded'
    if 'fetish' in s:
        return 'Icons.stars_rounded'
    if 'orgia' in s or 'threesome' in s or 'gang-bang' in s or 'harem' in s:
        return 'Icons.groups_3_rounded'
    if 'mind' in s:
        return 'Icons.psychology_rounded'
    if 'censure' in s or 'uncensored' in s:
        return 'Icons.lock_open_rounded'
    if 'slave' in s or 'bdsm' in s:
        return 'Icons.link_rounded'
    if 'tradimento' in s:
        return 'Icons.heart_broken_rounded'
    if 'occhiali' in s:
        return 'Icons.visibility_rounded'
    if 'student' in s or 'scuola' in s:
        return 'Icons.school_rounded'
    if 'public' in s:
        return 'Icons.park_rounded'
    if 'impregnation' in s or 'vergine' in s:
        return 'Icons.child_care_rounded'
    if 'cosplay' in s:
        return 'Icons.theater_comedy_rounded'
    if 'monster' in s or 'tentacle' in s:
        return 'Icons.hub_rounded'
    return 'Icons.tag_rounded'

def escape_dart_str(text):
    return text.replace('\\', '\\\\').replace('"', '\\"').replace('$', '\\$')

def main():
    with open('scratch/hentai_zone_harvested_data.json', 'r', encoding='utf-8') as f:
        data = json.load(f)

    categories = data['categories']
    tags = data['tags']
    cat_thumbs = data['category_thumbnails']
    tag_thumbs = data['tag_thumbnails']

    lines = []
    lines.append("// GENERATED LIVE TAXONOMY FOR HENTAIZONE (hentaizone.me)")
    lines.append("// Harvested live via Scrapling from https://hentaizone.me/genres/, /tags/, /categories/")
    lines.append(f"// Total Categories: {len(categories)}")
    lines.append(f"// Total Genres & Tags: {len(tags)}")
    lines.append("import 'package:flutter/material.dart';")
    lines.append("import '../../models/catalog_model.dart';")
    lines.append("")

    # Category Covers Map
    lines.append("/// Authentic category cover posters scraped live from HentaiZone")
    lines.append("final Map<String, String> hentaiZoneCategoryCovers = const {")
    for slug, thumb in cat_thumbs.items():
        lines.append(f'  "{slug}": "{thumb}",')
    lines.append("};")
    lines.append("")

    # Tag Covers Map
    lines.append("/// Authentic tag and genre cover posters scraped live from HentaiZone")
    lines.append("final Map<String, String> hentaiZoneGenreCovers = const {")
    for slug, thumb in tag_thumbs.items():
        lines.append(f'  "{slug}": "{thumb}",')
    lines.append("};")
    lines.append("")

    # hentaiZoneCategories
    lines.append("/// Authentic HentaiZone categories harvested live via Scrapling")
    lines.append("final List<CatalogItem> hentaiZoneCategories = const [")
    for cat in categories:
        name = escape_dart_str(cat['name'])
        slug = escape_dart_str(cat['slug'])
        count = cat['count']
        desc = escape_dart_str(clean_description(cat['description'], cat['name']))
        endpoint = escape_dart_str(cat['endpointPath'])
        icon = get_cat_icon(cat['name'], cat['slug'])

        # Grouping logic
        if slug in ['hentai-sub-ita', '3d']:
            group = "Format"
        elif slug in ['hentai-manga', 'doujinshi-hentai', 'fumetti-porno', 'immagini-porno-fumetti']:
            group = "Print & Manga"
        elif slug in ['dragon-ball', 'naruto', 'one-piece', 'my-hero-academia', 'simpson-porno', 'american-dad', 'futurama', 'griffin', 'flintstones', 'final-fantasy', 'sailor-moon', 'jabcomix', 'milftoon']:
            group = "Franchise"
        elif slug in ['italiano', 'tradotti-da-noi', 'premium']:
            group = "Curation"
        else:
            group = "Category"

        lines.append("  CatalogItem(")
        lines.append(f'    name: "{name}",')
        lines.append(f'    slug: "{slug}",')
        lines.append("    type: CatalogType.category,")
        lines.append(f'    categoryGroup: "{group}",')
        lines.append(f'    icon: {icon},')
        lines.append(f'    count: {count},')
        lines.append(f'    description: "{desc}",')
        lines.append(f'    endpointPath: "{endpoint}",')
        lines.append("  ),")
    lines.append("];")
    lines.append("")

    # hentaiZoneGenres
    lines.append("/// Authentic HentaiZone genres and tags harvested live via Scrapling")
    lines.append("final List<CatalogItem> hentaiZoneGenres = const [")
    for tag in tags:
        name = escape_dart_str(tag['name'])
        slug = escape_dart_str(tag['slug'])
        count = tag['count']
        desc = escape_dart_str(clean_description(tag['description'], tag['name']))
        endpoint = escape_dart_str(tag['endpointPath'])
        icon = get_tag_icon(tag['name'], tag['slug'])

        lines.append("  CatalogItem(")
        lines.append(f'    name: "{name}",')
        lines.append(f'    slug: "{slug}",')
        lines.append("    type: CatalogType.genre,")
        lines.append('    categoryGroup: "Genre",')
        lines.append(f'    icon: {icon},')
        lines.append(f'    count: {count},')
        lines.append(f'    description: "{desc}",')
        lines.append(f'    endpointPath: "{endpoint}",')
        lines.append("  ),")
    lines.append("];")
    lines.append("")

    # hentaiZoneTaxonomy
    lines.append("/// Dynamic Explore Taxonomy for HentaiZone with Categories (grid) and Genres (tags)")
    lines.append("final ExtensionTaxonomy hentaiZoneTaxonomy = ExtensionTaxonomy(")
    lines.append("  sections: [")
    lines.append("    TaxonomySection(")
    lines.append('      id: "categories",')
    lines.append('      title: "Categories",')
    lines.append("      displayType: TaxonomyDisplayType.grid,")
    lines.append("      items: hentaiZoneCategories,")
    lines.append("      icon: Icons.category_rounded,")
    lines.append("    ),")
    lines.append("    TaxonomySection(")
    lines.append('      id: "genres",')
    lines.append('      title: "Genres & Tags",')
    lines.append("      displayType: TaxonomyDisplayType.tags,")
    lines.append("      items: hentaiZoneGenres,")
    lines.append("      icon: Icons.tag_rounded,")
    lines.append("    ),")
    lines.append("  ],")
    lines.append("  categories: hentaiZoneCategories,")
    lines.append("  tagsAndGenres: hentaiZoneGenres,")
    lines.append(");")
    lines.append("")

    out_file = "d:/C/H/lib/extensions/taxonomies/hentai_zone_taxonomy.dart"
    with open(out_file, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))
    print(f"Generated Dart taxonomy at: {out_file} with {len(lines)} lines")

if __name__ == '__main__':
    main()
