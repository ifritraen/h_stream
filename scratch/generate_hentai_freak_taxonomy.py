import json
import re

with open('scratch/hentai_freak_taxonomy_harvest.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

categories = data['categories']
covers = data['covers']
tags = data['tags']

def get_group_and_icon(name, slug):
    slug_l = slug.lower()
    name_l = name.lower()
    
    # Format / Media / Years
    if slug_l in ['3d', '1080p', 'exclusive', 'view-all-series']:
        if '3d' in slug_l: return 'Format', 'Icons.animation_rounded'
        if '1080p' in slug_l: return 'Format', 'Icons.hd_rounded'
        return 'Format', 'Icons.movie_filter_rounded'
    if re.match(r'^\d{4}$', slug_l):
        return 'Year', 'Icons.calendar_today_rounded'

    # Studios / Circles / Authors
    if slug_l in ['aanix', 'amelialtie', 'chrs', 'cockman-pictures', 'kuro-dimension', 'queen-bee', 
                  'redmoa', 'seven', 'sfm-overlord', 'wildeer-studio', 'wutboi', 'xordel', 'zero-my-love',
                  '26regionsfm', 'hentaihaven', 'poro', 'pink-pineapple', 'bunnywalker', 'numericgazer', 'jackerman']:
        return 'Studio', 'Icons.business_rounded'

    # Characters
    if any(k in slug_l for k in ['girl', 'milf', 'maid', 'nurse', 'teacher', 'elf', 'demon', 'alien', 
                                  'sister', 'mother', 'mom', 'loli', 'shota', 'dark-skin', 'furry', 
                                  'futanari', 'monster', 'succubus', 'yandere', 'tsundere', 'gyaru', 'virgin']):
        if 'milf' in slug_l: return 'Character', 'Icons.woman_rounded'
        if 'school' in slug_l: return 'Character', 'Icons.school_rounded'
        if 'maid' in slug_l: return 'Character', 'Icons.cleaning_services_rounded'
        if 'nurse' in slug_l: return 'Character', 'Icons.medical_services_rounded'
        if 'teacher' in slug_l: return 'Character', 'Icons.cast_for_education_rounded'
        if 'dark-skin' in slug_l: return 'Character', 'Icons.brightness_low_rounded'
        if 'demon' in slug_l or 'monster' in slug_l: return 'Character', 'Icons.pest_control_rodent_rounded'
        if 'virgin' in slug_l: return 'Character', 'Icons.favorite_rounded'
        return 'Character', 'Icons.person_rounded'

    # Tropes / Acts / Anatomy
    if any(k in slug_l for k in ['anal', 'bdsm', 'bondage', 'blow-job', 'boob-job', 'hand-job', 'creampie', 
                                  'deep-throat', 'facial', 'fingering', 'gangbang', 'licking', 'masturbation', 
                                  'paizuri', 'public-sex', 'rape', 'squirt', 'threesome', 'toys', 'watersports', 
                                  'x-ray', 'ahegao', 'cheating', 'blackmail', 'bukkake', 'footjob', 'gokkun', 
                                  'lactation', 'mind-break', 'netorare', 'ntr', 'orgasm', 'pegging', 'rimjob', 
                                  'spanking', 'strip', 'tentacles', 'urine', 'voyeurism', 'big-boobs', 'big-ass', 'chubby']):
        if 'ahegao' in slug_l: return 'Trope', 'Icons.sentiment_satisfied_alt_rounded'
        if 'creampie' in slug_l: return 'Trope', 'Icons.water_drop_rounded'
        if 'big-boobs' in slug_l: return 'Trope', 'Icons.lens_blur_rounded'
        if 'blow-job' in slug_l or 'deep-throat' in slug_l: return 'Trope', 'Icons.face_rounded'
        if 'bondage' in slug_l or 'bdsm' in slug_l: return 'Trope', 'Icons.link_rounded'
        if 'threesome' in slug_l or 'gangbang' in slug_l: return 'Trope', 'Icons.group_work_rounded'
        if 'toys' in slug_l: return 'Trope', 'Icons.smart_toy_rounded'
        if 'x-ray' in slug_l: return 'Trope', 'Icons.visibility_rounded'
        if 'masturbation' in slug_l or 'fingering' in slug_l: return 'Trope', 'Icons.touch_app_rounded'
        if 'hand-job' in slug_l: return 'Trope', 'Icons.pan_tool_rounded'
        return 'Trope', 'Icons.favorite_rounded'

    # Genres
    if any(k in slug_l for k in ['comedy', 'cosplay', 'fantasy', 'harem', 'incest', 'parody', 'plot', 
                                  'romance', 'sci-fi', 'supernatural', 'vanilla', 'yaoi', 'yuri', 'action', 'horror', 'magic']):
        if 'comedy' in slug_l: return 'Genre', 'Icons.sentiment_very_satisfied_rounded'
        if 'cosplay' in slug_l: return 'Genre', 'Icons.theater_comedy_rounded'
        if 'action' in slug_l: return 'Genre', 'Icons.bolt_rounded'
        if 'yuri' in slug_l: return 'Genre', 'Icons.favorite_rounded'
        if 'harem' in slug_l: return 'Genre', 'Icons.groups_rounded'
        if 'vanilla' in slug_l: return 'Genre', 'Icons.favorite_border_rounded'
        if 'incest' in slug_l: return 'Genre', 'Icons.family_restroom_rounded'
        return 'Genre', 'Icons.category_rounded'

    return 'Trope', 'Icons.label_rounded'

lines = []
lines.append("import 'package:flutter/material.dart';")
lines.append("import '../../models/catalog_model.dart';")
lines.append("")
lines.append("/// Authentic category covers harvested live from https://hentaifreak.org")
lines.append("final Map<String, String> hentaiFreakCategoryCovers = const {")
for slug, thumb in covers.items():
    lines.append(f'  "{slug}": "{thumb}",')
lines.append("};")
lines.append("")
lines.append("/// Authentic HentaiFreak Categories harvested live via Scrapling from https://hentaifreak.org")
lines.append("final List<CatalogItem> hentaiFreakCategories = const [")

for cat in categories:
    name = cat['name']
    slug = cat['slug']
    path = cat['path']
    count = cat['count']
    desc = cat['desc']
    group = cat['group']
    icon = cat['icon']

    lines.append("  CatalogItem(")
    lines.append(f'    name: "{name}",')
    lines.append(f'    slug: "{slug}",')
    lines.append("    type: CatalogType.category,")
    lines.append(f'    categoryGroup: "{group}",')
    lines.append(f"    icon: {icon},")
    lines.append(f"    count: {count},")
    lines.append(f'    description: "{desc}",')
    lines.append(f'    endpointPath: "{path}",')
    lines.append("  ),")

lines.append("];")
lines.append("")
lines.append("/// Authentic HentaiFreak Tags and Genres harvested live via Scrapling from https://hentaifreak.org/pick-your-drug/")
lines.append("final List<CatalogItem> hentaiFreakGenres = const [")

for t in tags:
    name = t['name'].replace('"', '\\"')
    slug = t['slug']
    count = t['count']
    path = t['endpointPath']
    group, icon = get_group_and_icon(name, slug)
    desc = f"Videos tagged with #{name} ({count:,} releases)" if count > 0 else f"Videos tagged with #{name}"

    lines.append("  CatalogItem(")
    lines.append(f'    name: "{name}",')
    lines.append(f'    slug: "{slug}",')
    lines.append("    type: CatalogType.genre,")
    lines.append(f'    categoryGroup: "{group}",')
    lines.append(f"    icon: {icon},")
    lines.append(f"    count: {count},")
    lines.append(f'    description: "{desc}",')
    lines.append(f'    endpointPath: "{path}",')
    lines.append("  ),")

lines.append("];")
lines.append("")
lines.append("/// Dynamic Explore Taxonomy for HentaiFreak extension")
lines.append("final ExtensionTaxonomy hentaiFreakTaxonomy = ExtensionTaxonomy(")
lines.append("  sections: [")
lines.append("    TaxonomySection(")
lines.append('      id: "categories",')
lines.append('      title: "Categories",')
lines.append("      displayType: TaxonomyDisplayType.grid,")
lines.append("      items: hentaiFreakCategories,")
lines.append("      icon: Icons.category_rounded,")
lines.append("    ),")
lines.append("    TaxonomySection(")
lines.append('      id: "genres",')
lines.append('      title: "Genres",')
lines.append("      displayType: TaxonomyDisplayType.tags,")
lines.append("      items: hentaiFreakGenres,")
lines.append("      icon: Icons.label_rounded,")
lines.append("    ),")
lines.append("  ],")
lines.append("  categories: hentaiFreakCategories,")
lines.append("  tagsAndGenres: hentaiFreakGenres,")
lines.append(");")
lines.append("")

output_path = 'lib/extensions/taxonomies/hentai_freak_taxonomy.dart'
with open(output_path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines))

print(f"Generated {output_path} successfully ({len(categories)} categories, {len(tags)} genres).")
