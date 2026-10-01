import html
import json
import re
from scrapling.fetchers import Fetcher
from bs4 import BeautifulSoup

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://www.onlyhentaistuff.com/',
}

print("=== Task 1: Scraping live taxonomy data from OnlyHentaiStuff ===")

# 1. Probe the target endpoints requested in the prompt
probe_targets = [
    'https://www.onlyhentaistuff.com/categories/',
    'https://www.onlyhentaistuff.com/tags/',
    'https://www.onlyhentaistuff.com/genres/',
]

for target in probe_targets:
    try:
        res = Fetcher.get(target, headers=headers)
        print(f"Target: {target} -> Final: {res.url} (Status: {res.status}, Len: {len(res.body)})")
    except Exception as e:
        print(f"Target: {target} -> Error: {e}")

# 2. Scrape Categories
print("\n--- Harvesting Live Categories ---")
res_cat = Fetcher.get('https://www.onlyhentaistuff.com/categories/', headers=headers)
soup_cat = BeautifulSoup(res_cat.body, 'html.parser')

categories = []
category_covers = {}

def clean_text(s):
    if not s:
        return ""
    s = html.unescape(s).strip()
    s = s.replace('\ufffd', "'").replace('–', '-').replace('—', '-')
    s = s.replace('"', "'").replace('$', r'\$')
    return s

def get_category_icon_and_group(slug, name):
    low = (slug + ' ' + name).lower()
    if 'censor' in low:
        return 'Icons.lock_open_rounded', 'Censorship'
    if any(k in low for k in ['tit', 'boob', 'oppai', 'bust']):
        return 'Icons.bubble_chart_rounded', 'Body'
    if any(k in low for k in ['blowjob', 'oral', 'licking', 'fellatio']):
        return 'Icons.sentiment_satisfied_rounded', 'Act / Fetish'
    if any(k in low for k in ['anal', 'ass']):
        return 'Icons.accessibility_new_rounded', 'Act / Fetish'
    if any(k in low for k in ['masturbat', 'hand']):
        return 'Icons.front_hand_rounded', 'Act / Fetish'
    if any(k in low for k in ['group', 'orgy', 'threesome']):
        return 'Icons.groups_rounded', 'Act / Fetish'
    if any(k in low for k in ['rape']):
        return 'Icons.lock_rounded', 'Fetish'
    if any(k in low for k in ['bdsm', 'bondage']):
        return 'Icons.link_rounded', 'Fetish'
    if any(k in low for k in ['tentacle']):
        return 'Icons.hub_rounded', 'Fetish'
    if any(k in low for k in ['stuff', 'toy', 'fetish']):
        return 'Icons.toys_rounded', 'Fetish'
    if any(k in low for k in ['animal', 'neko', 'cat']):
        return 'Icons.pets_rounded', 'Character'
    if any(k in low for k in ['futanari', 'futa']):
        return 'Icons.transgender_rounded', 'Character'
    if any(k in low for k in ['maid']):
        return 'Icons.cleaning_services_rounded', 'Character'
    if any(k in low for k in ['nurse']):
        return 'Icons.medical_services_rounded', 'Character'
    if any(k in low for k in ['student', 'school']):
        return 'Icons.school_rounded', 'Character' if 'student' in low else 'Setting'
    if any(k in low for k in ['shota', 'loli', 'twin']):
        return 'Icons.child_care_rounded', 'Character'
    if any(k in low for k in ['swimsuit', 'kimono']):
        return 'Icons.checkroom_rounded', 'Attire'
    if any(k in low for k in ['public', 'outdoor']):
        return 'Icons.park_rounded', 'Setting'
    if any(k in low for k in ['fantasy', 'magic']):
        return 'Icons.auto_awesome_rounded', 'Theme'
    if any(k in low for k in ['sci-fi']):
        return 'Icons.rocket_launch_rounded', 'Theme'
    if any(k in low for k in ['incest']):
        return 'Icons.family_restroom_rounded', 'Theme'
    if any(k in low for k in ['yuri']):
        return 'Icons.diversity_1_rounded', 'Theme'
    if any(k in low for k in ['yaoi', 'shounen-ai']):
        return 'Icons.diversity_3_rounded', 'Theme'
    if any(k in low for k in ['virgin', 'romance', 'erotic', 'hardcore', 'classic']):
        return 'Icons.favorite_rounded', 'Theme'
    return 'Icons.category_rounded', 'Category'

for item in soup_cat.select('a.item'):
    href = item.get('href', '')
    m = re.search(r'/categories/([^/]+)/?', href)
    if not m:
        continue
    slug = m.group(1)
    title_el = item.select_one('.title')
    title = clean_text(title_el.get_text(strip=True) if title_el else item.get('title', slug))
    
    img = item.select_one('img')
    img_url = img.get('src') or img.get('data-original') or img.get('data-src') if img else ''
    if img_url.startswith('//'):
        img_url = 'https:' + img_url
    elif img_url.startswith('/'):
        img_url = 'https://www.onlyhentaistuff.com' + img_url

    count_el = item.select_one('.videos')
    count = 0
    if count_el:
        cm = re.search(r'([\d,]+)', count_el.get_text())
        if cm:
            count = int(cm.group(1).replace(',', ''))

    icon, group = get_category_icon_and_group(slug, title)

    categories.append({
        'name': title,
        'slug': slug,
        'count': count,
        'cover': img_url,
        'icon': icon,
        'group': group,
        'description': f"Stream {count:,} {title} hentai releases on OnlyHentaiStuff",
        'endpointPath': f'/categories/{slug}/',
    })
    if img_url:
        category_covers[slug] = img_url

print(f"Total Categories Harvested: {len(categories)}")

# 3. Scrape Tags
print("\n--- Harvesting Live Tags ---")
res_tags = Fetcher.get('https://www.onlyhentaistuff.com/tags/', headers=headers)
soup_tags = BeautifulSoup(res_tags.body, 'html.parser')

tags = []
seen_tags = set()

def get_tag_icon_and_group(name, slug):
    slug_low = slug.lower()
    low = name.lower()

    if re.match(r'^\d{4}$', name):
        return 'Icons.calendar_today_rounded', 'Year / Release'
    if any(k in slug_low for k in ['sub', 'dub', 'rus', 'eng']):
        return 'Icons.translate_rounded', 'Audio / Subtitle'
    if any(k in slug_low for k in ['3d', 'sfm', 'cgi', 'blender']):
        return 'Icons.view_in_ar_rounded', 'Format'
    if 'uncensor' in slug_low:
        return 'Icons.lock_open_rounded', 'Censorship'
    if any(k in slug_low for k in ['studio', 'production', 'animation', 'film', 'media', 'soft', 'pictures', 'anime']):
        return 'Icons.business_rounded', 'Studio / Brand'
    if any(k in slug_low for k in ['boob', 'tit', 'oppai', 'bust', 'paizuri']):
        return 'Icons.bubble_chart_rounded', 'Body'
    if any(k in slug_low for k in ['creampie', 'cum', 'squirt']):
        return 'Icons.water_drop_rounded', 'Act / Fetish'
    if any(k in slug_low for k in ['blowjob', 'oral', 'fellatio', 'deepthroat']):
        return 'Icons.sentiment_satisfied_rounded', 'Act / Fetish'
    if any(k in slug_low for k in ['anal', 'ass']):
        return 'Icons.accessibility_new_rounded', 'Act / Fetish'
    if any(k in slug_low for k in ['school', 'student', 'teacher', 'sensei']):
        return 'Icons.school_rounded', 'Character'
    if any(k in slug_low for k in ['milf', 'mature', 'mother', 'mom', 'housewife']):
        return 'Icons.woman_rounded', 'Character'
    if any(k in slug_low for k in ['maid', 'nurse']):
        return 'Icons.medical_services_rounded', 'Character'
    if any(k in slug_low for k in ['monster', 'tentacle', 'demon', 'alien', 'orc', 'beast', 'goblin']):
        return 'Icons.pest_control_rounded', 'Fantasy'
    if any(k in slug_low for k in ['magic', 'supernatural', 'elf', 'dragon', 'angel']):
        return 'Icons.auto_awesome_rounded', 'Fantasy'
    if any(k in slug_low for k in ['bondage', 'bdsm', 'slave', 'forced', 'rape', 'chikan']):
        return 'Icons.link_rounded', 'Fetish'
    if any(k in slug_low for k in ['harem', 'group', 'orgy', 'threesome', 'gangbang']):
        return 'Icons.groups_rounded', 'Theme'
    if any(k in slug_low for k in ['action', 'adventure']):
        return 'Icons.sports_kabaddi_rounded', 'Theme'
    if any(k in slug_low for k in ['comedy', 'parody']):
        return 'Icons.theater_comedy_rounded', 'Theme'
    if any(k in slug_low for k in ['romance', 'love', 'vanilla']):
        return 'Icons.favorite_rounded', 'Theme'
    if any(k in slug_low for k in ['game', 'vr']):
        return 'Icons.sports_esports_rounded', 'Theme'
    if any(k in slug_low for k in ['yuri', 'lesbian']):
        return 'Icons.diversity_1_rounded', 'Theme'
    if any(k in slug_low for k in ['yaoi', 'gay']):
        return 'Icons.diversity_3_rounded', 'Theme'
    if any(k in slug_low for k in ['futa', 'shemale']):
        return 'Icons.transgender_rounded', 'Character'
    if any(k in slug_low for k in ['catgirl', 'neko', 'animal']):
        return 'Icons.pets_rounded', 'Character'
    if len(name.split()) == 2 and not any(char.isdigit() for char in name):
        return 'Icons.person_rounded', 'Artist / Director'
    return 'Icons.tag_rounded', 'Tag'

for a in soup_tags.select('a[href*="/tags/"]'):
    href = a.get('href', '')
    m = re.search(r'/tags/([^/]+)/?', href)
    if not m:
        continue
    slug = m.group(1)
    if slug in ('tags', 'all') or slug in seen_tags:
        continue
    seen_tags.add(slug)
    name = clean_text(a.get_text(strip=True))
    if not name:
        continue

    icon, group = get_tag_icon_and_group(name, slug)
    desc = f"Collection of anime tagged with {name}"

    tags.append({
        'name': name,
        'slug': slug,
        'icon': icon,
        'group': group,
        'description': desc,
        'endpointPath': f'/tags/{slug}/',
    })

print(f"Total Tags Harvested: {len(tags)}")

# 4. Generate Dart Taxonomy File
print("\n--- Generating lib/extensions/taxonomies/only_hentai_stuff_taxonomy.dart ---")

dart_lines = [
    "// GENERATED LIVE TAXONOMY FOR ONLYHENTAISTUFF (onlyhentaistuff.com)",
    "// Scraped live via Scrapling from https://www.onlyhentaistuff.com/categories/ and https://www.onlyhentaistuff.com/tags/",
    f"// Total Live Categories Harvested: {len(categories)}",
    f"// Total Live Tags Harvested: {len(tags)}",
    "import 'package:flutter/material.dart';",
    "import '../../models/catalog_model.dart';",
    "",
    "/// Authentic category cover posters scraped live from OnlyHentaiStuff",
    "final Map<String, String> onlyHentaiStuffCategoryCovers = const {",
]

for slug, url in category_covers.items():
    dart_lines.append(f'  "{slug}": "{url}",')
dart_lines.append("};")
dart_lines.append("")

# Categories List
dart_lines.append("/// Authentic OnlyHentaiStuff Categories scraped live from https://www.onlyhentaistuff.com/categories/")
dart_lines.append("final List<CatalogItem> onlyHentaiStuffCategories = const [")
for c in categories:
    dart_lines.append("  CatalogItem(")
    dart_lines.append(f'    name: "{c["name"]}",')
    dart_lines.append(f'    slug: "{c["slug"]}",')
    dart_lines.append("    type: CatalogType.category,")
    dart_lines.append(f'    categoryGroup: "{c["group"]}",')
    dart_lines.append(f'    icon: {c["icon"]},')
    dart_lines.append(f'    count: {c["count"]},')
    dart_lines.append(f'    description: "{c["description"]}",')
    dart_lines.append(f'    endpointPath: "{c["endpointPath"]}",')
    dart_lines.append("  ),")
dart_lines.append("];")
dart_lines.append("")

# Tags List
dart_lines.append("/// Authentic OnlyHentaiStuff Tags scraped live from https://www.onlyhentaistuff.com/tags/")
dart_lines.append("final List<CatalogItem> onlyHentaiStuffTags = const [")
for t in tags:
    dart_lines.append("  CatalogItem(")
    dart_lines.append(f'    name: "{t["name"]}",')
    dart_lines.append(f'    slug: "{t["slug"]}",')
    dart_lines.append("    type: CatalogType.tag,")
    dart_lines.append(f'    categoryGroup: "{t["group"]}",')
    dart_lines.append(f'    icon: {t["icon"]},')
    dart_lines.append(f'    description: "{t["description"]}",')
    dart_lines.append(f'    endpointPath: "{t["endpointPath"]}",')
    dart_lines.append("  ),")
dart_lines.append("];")
dart_lines.append("")

# Taxonomy Definition
dart_lines.append("/// Dynamic Explore Taxonomy for OnlyHentaiStuff with Categories (grid) and Tags (tags)")
dart_lines.append("final ExtensionTaxonomy onlyHentaiStuffTaxonomy = ExtensionTaxonomy(")
dart_lines.append("  sections: [")
dart_lines.append("    TaxonomySection(")
dart_lines.append('      id: "categories",')
dart_lines.append('      title: "Categories",')
dart_lines.append("      displayType: TaxonomyDisplayType.grid,")
dart_lines.append("      items: onlyHentaiStuffCategories,")
dart_lines.append("      icon: Icons.category_rounded,")
dart_lines.append("    ),")
dart_lines.append("    TaxonomySection(")
dart_lines.append('      id: "tags",')
dart_lines.append('      title: "Tags",')
dart_lines.append("      displayType: TaxonomyDisplayType.tags,")
dart_lines.append("      items: onlyHentaiStuffTags,")
dart_lines.append("      icon: Icons.tag_rounded,")
dart_lines.append("    ),")
dart_lines.append("  ],")
dart_lines.append("  categories: onlyHentaiStuffCategories,")
dart_lines.append("  tagsAndGenres: onlyHentaiStuffTags,")
dart_lines.append(");")
dart_lines.append("")

output_path = "lib/extensions/taxonomies/only_hentai_stuff_taxonomy.dart"
with open(output_path, "w", encoding="utf-8") as f:
    f.write("\n".join(dart_lines))

print(f"Generated {output_path} successfully ({len(dart_lines)} lines).")
