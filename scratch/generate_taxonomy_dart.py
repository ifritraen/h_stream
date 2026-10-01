import json
import re

with open('scratch/hentaiera_harvest.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

categories = data['categories']
tags = data['tags']

def get_tag_meta(name):
    n = name.lower()
    # Group & Icon matching
    if any(k in n for k in ['milf', 'mother', 'mom', 'sister', 'aunt', 'mature', 'daughter']):
        return "Character", "Icons.woman_rounded"
    if any(k in n for k in ['breast', 'oppai', 'boob', 'cleavage']):
        return "Character", "Icons.lens_blur_rounded"
    if any(k in n for k in ['maid', 'waitress', 'butler']):
        return "Character", "Icons.cleaning_services_rounded"
    if any(k in n for k in ['school', 'student', 'class', 'uniform', 'gyaru', 'gal']):
        return "Character", "Icons.school_rounded"
    if any(k in n for k in ['elf', 'succubus', 'monster', 'catgirl', 'kemonomimi', 'demon', 'vampire', 'alien', 'fairy', 'angel', 'fox', 'wolf']):
        return "Character", "Icons.cruelty_free_rounded"
    if any(k in n for k in ['glass', 'megane']):
        return "Character", "Icons.visibility_rounded"
    if any(k in n for k in ['tan', 'dark skin']):
        return "Character", "Icons.wb_sunny_rounded"
    if any(k in n for k in ['stocking', 'pantyhose', 'socks', 'collar', 'swimsuit', 'bikini', 'lingerie', 'dress', 'costume', 'cosplay']):
        return "Character", "Icons.checkroom_rounded"
    if any(k in n for k in ['futanari', 'crossdress', 'trap', 'tomgirl', 'tomboy', 'gender']):
        return "Character", "Icons.transgender_rounded"
    if any(k in n for k in ['teacher', 'nurse', 'doctor', 'nun', 'officer', 'police', 'cheerleader']):
        return "Character", "Icons.badge_rounded"
    
    # Genre
    if any(k in n for k in ['romance', 'love', 'vanilla', 'pure', 'sweet']):
        return "Genre", "Icons.favorite_rounded"
    if any(k in n for k in ['comedy', 'parody', 'humor', 'funny']):
        return "Genre", "Icons.mood_rounded"
    if any(k in n for k in ['fantasy', 'magic', 'isekai']):
        return "Genre", "Icons.auto_awesome_rounded"
    if any(k in n for k in ['horror', 'zombie', 'gore', 'gothic', 'dark']):
        return "Genre", "Icons.nightlight_round"
    if any(k in n for k in ['sci-fi', 'cyber', 'robot', 'mecha', 'space']):
        return "Genre", "Icons.rocket_launch_rounded"
    if any(k in n for k in ['harem']):
        return "Genre", "Icons.groups_rounded"
    
    # Trope
    if any(k in n for k in ['group', 'gangbang', 'threesome', 'orgy', 'menage']):
        return "Trope", "Icons.groups_rounded"
    if any(k in n for k in ['creampie', 'nakadashi', 'internal', 'cum', 'ejaculation', 'sweat', 'squirt']):
        return "Trope", "Icons.water_drop_rounded"
    if any(k in n for k in ['blowjob', 'fellatio', 'oral', 'deepthroat', 'cunnilingus', 'sucking']):
        return "Trope", "Icons.sentiment_satisfied_rounded"
    if any(k in n for k in ['bdsm', 'bondage', 'collar', 'slave', 'leash', 'whip', 'tied', 'cuffs', 'sm']):
        return "Trope", "Icons.link_rounded"
    if any(k in n for k in ['tentacle']):
        return "Trope", "Icons.hub_rounded"
    if any(k in n for k in ['anal', 'enema', 'pegging']):
        return "Trope", "Icons.adjust_rounded"
    if any(k in n for k in ['ahegao', 'mind break', 'hypnosis', 'brainwash', 'corruption']):
        return "Trope", "Icons.cyclone_rounded"
    if any(k in n for k in ['ntr', 'netorare', 'cheating', 'cuckold']):
        return "Trope", "Icons.broken_image_rounded"
    if any(k in n for k in ['incest', 'father', 'brother', 'mother', 'daughter', 'sister', 'family']):
        return "Trope", "Icons.family_restroom_rounded"
    if any(k in n for k in ['uncensored', 'mosaic', 'censorship', 'decensored']):
        return "Trope", "Icons.lock_open_rounded"
    if any(k in n for k in ['sole female', 'sole male']):
        return "Trope", "Icons.person_rounded"
    if any(k in n for k in ['masturbation', 'fingering', 'handjob']):
        return "Trope", "Icons.front_hand_rounded"
    if any(k in n for k in ['exhibitionism', 'public', 'voyeurism']):
        return "Trope", "Icons.remove_red_eye_rounded"
    if any(k in n for k in ['femdom', 'female domination']):
        return "Trope", "Icons.shield_rounded"
    if any(k in n for k in ['defloration', 'first time', 'virgin']):
        return "Trope", "Icons.stars_rounded"

    return "Trope", "Icons.tag_rounded"

# Generate Dart file
lines = []
lines.append("import 'package:flutter/material.dart';")
lines.append("import '../../models/catalog_model.dart';")
lines.append("")
lines.append("/// Authentic category covers harvested live from https://hentaiera.com/categories/")
lines.append("final Map<String, String> hentaiEraCategoryCovers = const {")
for c in categories:
    lines.append(f'  "{c["slug"]}": "{c["cover"]}",')
lines.append("};")
lines.append("")
lines.append("/// Authentic HentaiEra categories harvested live via Scrapling from https://hentaiera.com/categories/")
lines.append("final List<CatalogItem> hentaiEraCategories = const [")

for c in categories:
    slug = c["slug"]
    name = c["name"]
    icon = c["icon"]
    count = c["count"]
    group = c["categoryGroup"]
    desc = c["description"]
    path = c["endpointPath"]
    lines.append("  CatalogItem(")
    lines.append(f'    name: "{name}",')
    lines.append(f'    slug: "{slug}",')
    lines.append("    type: CatalogType.category,")
    lines.append(f'    categoryGroup: "{group}",')
    lines.append(f'    icon: {icon},')
    lines.append(f'    count: {count},')
    lines.append(f'    description: "{desc}",')
    lines.append(f'    endpointPath: "{path}",')
    lines.append("  ),")

lines.append("];")
lines.append("")
lines.append("/// Authentic HentaiEra popular tags harvested live via Scrapling from https://hentaiera.com/tags/")
lines.append("final List<CatalogItem> hentaiEraTags = const [")

for t in tags:
    name = t["name"].replace('"', '\\"')
    slug = t["slug"].replace('"', '\\"')
    count = t["count"]
    path = t["endpointPath"].replace('"', '\\"')
    group, icon = get_tag_meta(t["name"])
    lines.append("  CatalogItem(")
    lines.append(f'    name: "{name}",')
    lines.append(f'    slug: "{slug}",')
    lines.append("    type: CatalogType.tag,")
    lines.append(f'    categoryGroup: "{group}",')
    lines.append(f'    icon: {icon},')
    lines.append(f'    count: {count},')
    lines.append(f'    description: "Galleries tagged with #{name}",')
    lines.append(f'    endpointPath: "{path}",')
    lines.append("  ),")

lines.append("];")
lines.append("")
lines.append("/// Dynamic Explore taxonomy for HentaiEra with Categories and Tags sections.")
lines.append("final ExtensionTaxonomy hentaiEraTaxonomy = ExtensionTaxonomy(")
lines.append("  sections: [")
lines.append("    TaxonomySection(")
lines.append('      id: "categories",')
lines.append('      title: "Categories",')
lines.append("      displayType: TaxonomyDisplayType.grid,")
lines.append("      items: hentaiEraCategories,")
lines.append("      icon: Icons.grid_view_rounded,")
lines.append("    ),")
lines.append("    TaxonomySection(")
lines.append('      id: "tags",')
lines.append('      title: "Tags & Tropes",')
lines.append("      displayType: TaxonomyDisplayType.tags,")
lines.append("      items: hentaiEraTags,")
lines.append("      icon: Icons.tag_rounded,")
lines.append("    ),")
lines.append("  ],")
lines.append("  categories: hentaiEraCategories,")
lines.append("  tagsAndGenres: hentaiEraTags,")
lines.append(");")
lines.append("")

dart_code = "\n".join(lines)

with open('lib/extensions/taxonomies/hentai_era_taxonomy.dart', 'w', encoding='utf-8') as f:
    f.write(dart_code)

print("Generated lib/extensions/taxonomies/hentai_era_taxonomy.dart successfully!")
