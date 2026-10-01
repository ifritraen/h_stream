import json
import re

def get_icon_and_group(name: str, slug: str):
    s = slug.lower()
    n = name.lower()

    # Game Parody & Characters
    if any(k in s for k in ['ada wong', 'bayonetta', 'overwatch', 'dva', 'tifa', 'nier', '2b', 'genshin', 'resident evil', 'femshep', 'ashley', 'seraphine', 'batman', 'avengers', 'chun li', 'zelda', 'lara croft']):
        icon = "Icons.sports_esports_rounded"
        group = "Game Parody"
        desc = f"Parody encounters and animated tributes featuring {name}"
        return icon, group, desc

    # Anime Parody & Characters
    if any(k in s for k in ['naruto', 'tsunade', 'hinata', 'dragon ball', 'one piece', 'bleach', 'bleach', 'pokemon', 'sailor moon', 'bible black', 'futaba', 'hanako', 'arwen']):
        icon = "Icons.movie_filter_rounded"
        group = "Anime Parody"
        desc = f"Iconic anime character parodies and encounters with {name}"
        return icon, group, desc

    # Characters & Archetypes
    if any(k in s for k in ['schoolgirl', 'student', 'teen', 'maid', 'nurse', 'teacher', 'sensei', 'milf', 'mom', 'sister', 'step', 'princess', 'queen', 'elf', 'goblin', 'orc', 'demon', 'succubus', 'vampire', 'alien', 'robot', 'android', 'goth', 'babe', 'blonde', 'redhead', 'brunette', 'waifu', 'slave', 'submissive', 'futanari', 'dickgirl']):
        if 'futanari' in s or 'dickgirl' in s:
            icon = "Icons.transgender_rounded"
        elif 'maid' in s:
            icon = "Icons.cleaning_services_rounded"
        elif 'school' in s or 'student' in s:
            icon = "Icons.school_rounded"
        elif 'alien' in s:
            icon = "Icons.public_rounded"
        elif 'robot' in s or 'android' in s:
            icon = "Icons.precision_manufacturing_rounded"
        elif 'princess' in s or 'queen' in s:
            icon = "Icons.auto_awesome_rounded"
        elif 'milf' in s or 'mom' in s:
            icon = "Icons.favorite_rounded"
        elif 'nurse' in s:
            icon = "Icons.medical_services_rounded"
        elif 'slave' in s or 'submissive' in s:
            icon = "Icons.lock_rounded"
        elif 'vampire' in s:
            icon = "Icons.nightlight_round"
        else:
            icon = "Icons.person_rounded"
        group = "Character"
        desc = f"Heroines, character archetypes, and character scenes featuring {name}"
        return icon, group, desc

    # Genres
    if any(k in s for k in ['3d', 'animation', 'animated', 'scifi', 'sci-fi', 'fantasy', 'romance', 'action', 'horror', 'comedy', 'classic', 'uncensored', 'hd', '60fps', 'lo-fi', 'ambient']):
        if '3d' in s or 'animation' in s:
            icon = "Icons.view_in_ar_rounded"
        elif 'scifi' in s or 'sci-fi' in s:
            icon = "Icons.rocket_launch_rounded"
        elif 'fantasy' in s:
            icon = "Icons.auto_awesome_rounded"
        elif 'romance' in s:
            icon = "Icons.favorite_border_rounded"
        elif 'horror' in s:
            icon = "Icons.warning_amber_rounded"
        elif 'uncensored' in s:
            icon = "Icons.lock_open_rounded"
        else:
            icon = "Icons.movie_creation_rounded"
        group = "Genre"
        desc = f"Atmospheric genre streams and productions in the {name} style"
        return icon, group, desc

    # Tropes, Acts, and Fetishes
    if any(k in s for k in ['anal', 'creampie', 'blowjob', 'oral', 'throat', 'deepthroat', 'bdsm', 'bondage', 'rough', 'spanking', 'creampie', 'nakadashi', 'doggy', 'missionary', 'cowgirl', 'riding', 'fingering', 'masturbation', 'facial', 'cum', 'cock', 'dick', 'ass', 'boobs', 'tits', 'breast', 'pussy', 'fetish', 'interracial', 'bbc', 'threesome', 'gangbang', 'double penetration', 'dp', 'voyeur', 'exhibitionism', 'public', 'bathroom', 'massage']):
        if 'creampie' in s or 'cum' in s:
            icon = "Icons.water_drop_rounded"
        elif 'anal' in s or 'ass' in s:
            icon = "Icons.adjust_rounded"
        elif 'oral' in s or 'blowjob' in s or 'throat' in s or 'facial' in s:
            icon = "Icons.face_retouching_natural_rounded"
        elif 'boobs' in s or 'tits' in s or 'breast' in s:
            icon = "Icons.lens_blur_rounded"
        elif 'bdsm' in s or 'bondage' in s:
            icon = "Icons.link_rounded"
        elif 'rough' in s:
            icon = "Icons.local_fire_department_rounded"
        elif 'interracial' in s or 'bbc' in s:
            icon = "Icons.people_alt_rounded"
        elif 'public' in s:
            icon = "Icons.visibility_rounded"
        elif 'gangbang' in s or 'threesome' in s or 'group' in s:
            icon = "Icons.groups_rounded"
        else:
            icon = "Icons.flash_on_rounded"
        group = "Trope"
        desc = f"Curated scenes and passionate sequences featuring {name}"
        return icon, group, desc

    # Default fallback
    return "Icons.tag_rounded", "Genre", f"HentaiVibe video streams tagged #{name}"

def generate():
    with open('scratch/hentai_vibe_harvest.json', 'r', encoding='utf-8') as f:
        data = json.load(f)

    categories = data['categories']
    tags = data['tags']
    thumbnails = data.get('thumbnails', {})

    lines = []
    lines.append("// GENERATED LIVE TAXONOMY FOR HENTAIVIBE")
    lines.append("// Harvested live via Scrapling from https://hentaivibe.com & https://hentaivibe.org")
    lines.append(f"// Total Categories: {len(categories)}")
    lines.append(f"// Total Genres & Tags: {len(tags)}")
    lines.append("import 'package:flutter/material.dart';")
    lines.append("import '../../models/catalog_model.dart';")
    lines.append("")

    # Category Covers Map
    lines.append("/// Authentic category covers harvested live from HentaiVibe")
    lines.append("final Map<String, String> hentaiVibeCategoryCovers = const {")
    for cat in categories:
        slug = cat['slug']
        thumb = cat.get('thumbnail') or thumbnails.get(slug, '')
        if thumb:
            lines.append(f'  "{slug}": "{thumb}",')
    lines.append("};")
    lines.append("")

    # Categories list
    lines.append("/// Authentic HentaiVibe Categories harvested live via Scrapling")
    lines.append("final List<CatalogItem> hentaiVibeCategories = const [")
    for cat in categories:
        name = cat['name']
        slug = cat['slug']
        c_group = cat.get('categoryGroup', 'Browse')
        icon = cat.get('icon', 'Icons.category_rounded')
        count = cat.get('count', 0)
        desc = cat.get('description', '')
        ep = cat.get('endpointPath', f"/tags/{slug}/")

        lines.append("  CatalogItem(")
        lines.append(f'    name: "{name}",')
        lines.append(f'    slug: "{slug}",')
        lines.append("    type: CatalogType.category,")
        lines.append(f'    categoryGroup: "{c_group}",')
        lines.append(f'    icon: {icon},')
        lines.append(f'    count: {count},')
        lines.append(f'    description: "{desc}",')
        lines.append(f'    endpointPath: "{ep}",')
        lines.append("  ),")
    lines.append("];")
    lines.append("")

    # Genres & Tags list
    lines.append("/// Authentic HentaiVibe Genres & Tags harvested live via Scrapling")
    lines.append("final List<CatalogItem> hentaiVibeGenres = const [")
    for t in tags:
        name = t['name']
        slug = t['slug']
        raw_slug = t['raw_slug']
        count = t.get('count', 0)
        ep = t.get('endpoint', f"/tags/{raw_slug}/")

        icon, group, desc = get_icon_and_group(name, slug)

        lines.append("  CatalogItem(")
        lines.append(f'    name: "{name}",')
        lines.append(f'    slug: "{slug}",')
        lines.append("    type: CatalogType.tag,")
        lines.append(f'    categoryGroup: "{group}",')
        lines.append(f'    icon: {icon},')
        lines.append(f'    count: {count},')
        lines.append(f'    description: "{desc}",')
        lines.append(f'    endpointPath: "{ep}",')
        lines.append("  ),")
    lines.append("];")
    lines.append("")

    # ExtensionTaxonomy definition
    lines.append("/// Dynamic Explore Taxonomy for HentaiVibe extension")
    lines.append("final ExtensionTaxonomy hentaiVibeTaxonomy = ExtensionTaxonomy(")
    lines.append("  sections: [")
    lines.append("    TaxonomySection(")
    lines.append('      id: "categories",')
    lines.append('      title: "Categories",')
    lines.append("      displayType: TaxonomyDisplayType.grid,")
    lines.append("      items: hentaiVibeCategories,")
    lines.append("      icon: Icons.category_rounded,")
    lines.append("    ),")
    lines.append("    TaxonomySection(")
    lines.append('      id: "genres",')
    lines.append('      title: "Genres & Tags",')
    lines.append("      displayType: TaxonomyDisplayType.tags,")
    lines.append("      items: hentaiVibeGenres,")
    lines.append("      icon: Icons.tag_rounded,")
    lines.append("    ),")
    lines.append("  ],")
    lines.append("  categories: hentaiVibeCategories,")
    lines.append("  tagsAndGenres: hentaiVibeGenres,")
    lines.append(");")
    lines.append("")

    content = '\n'.join(lines)
    with open('d:/C/H/lib/extensions/taxonomies/hentai_vibe_taxonomy.dart', 'w', encoding='utf-8') as f:
        f.write(content)
    print("Generated d:/C/H/lib/extensions/taxonomies/hentai_vibe_taxonomy.dart successfully!")

if __name__ == '__main__':
    generate()
