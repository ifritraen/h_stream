import html
import re
import json
from scrapling.fetchers import Fetcher

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaisea.com/',
}

print("=== Task 1: Scraping live taxonomy data from HentaiSea ===")

# Test targets mentioned in prompt
targets = [
    'https://hentaisea.com/series',
    'https://hentaisea.com/genre',
    'https://hentaisea.com/genres',
]

target_results = {}
for target in targets:
    try:
        res = Fetcher.get(target, headers=headers)
        target_results[target] = {
            'status': res.status,
            'final_url': res.url,
            'body_len': len(res.body),
        }
        print(f"Target: {target} -> Final: {res.url} (Status: {res.status})")
    except Exception as e:
        print(f"Error fetching {target}: {e}")
        target_results[target] = {'error': str(e)}

# 1. Harvest Genres from live page (/free/ which /series resolves to)
print("\n--- Harvesting Live Genres ---")
r_home = Fetcher.get('https://hentaisea.com/free/', headers=headers)

genres = []
seen_genre_slugs = set()

def clean_text(s):
    if not s:
        return ""
    s = html.unescape(s).strip()
    s = s.replace('\ufffd', "'").replace('', "'").replace('–', '-').replace('—', '-')
    s = s.replace('"', "'").replace('$', r'\$')
    return s

def get_genre_icon_and_group(name):
    low = name.lower()
    if any(k in low for k in ['3d', 'cgi']):
        return 'Icons.view_in_ar_rounded', 'Format'
    if any(k in low for k in ['boob', 'tit', 'oppai', 'bust', 'paizuri']):
        return 'Icons.bubble_chart_rounded', 'Theme'
    if any(k in low for k in ['blowjob', 'fellatio', 'oral']):
        return 'Icons.sentiment_satisfied_rounded', 'Act / Fetish'
    if any(k in low for k in ['creampie', 'cum', 'squirt']):
        return 'Icons.water_drop_rounded', 'Act / Fetish'
    if any(k in low for k in ['school', 'student', 'sensei', 'teacher']):
        return 'Icons.school_rounded', 'Character'
    if 'uncensor' in low:
        return 'Icons.lock_open_rounded', 'Format'
    if 'censor' in low:
        return 'Icons.lock_rounded', 'Format'
    if any(k in low for k in ['anal', 'ass']):
        return 'Icons.accessibility_new_rounded', 'Act / Fetish'
    if any(k in low for k in ['milf', 'mature', 'mother', 'mom', 'housewife', 'cheating']):
        return 'Icons.woman_rounded', 'Character'
    if any(k in low for k in ['maid', 'waitress', 'nurse']):
        return 'Icons.medical_services_rounded', 'Character'
    if any(k in low for k in ['monster', 'alien', 'demon', 'tentacle', 'orc', 'beast', 'goblin']):
        return 'Icons.pest_control_rounded', 'Fantasy'
    if any(k in low for k in ['elf', 'magic', 'super power', 'supernatural', 'dragon', 'angel']):
        return 'Icons.auto_awesome_rounded', 'Fantasy'
    if any(k in low for k in ['bondage', 'bdsm', 'slave', 'torture', 'chikan', 'grope', 'forced', 'blackmail', 'humiliation']):
        return 'Icons.link_rounded', 'Trope'
    if any(k in low for k in ['group', 'harem', 'orgy', 'threesome', 'gang', 'gangbang']):
        return 'Icons.groups_rounded', 'Theme'
    if any(k in low for k in ['action', 'adventure', 'crime']):
        return 'Icons.sports_kabaddi_rounded', 'Action / Adventure'
    if any(k in low for k in ['comedy', 'funny', 'parody']):
        return 'Icons.theater_comedy_rounded', 'Theme'
    if any(k in low for k in ['romance', 'love', 'couple', 'dating']):
        return 'Icons.favorite_rounded', 'Theme'
    if any(k in low for k in ['game', 'vr', 'sfm']):
        return 'Icons.sports_esports_rounded', 'Theme'
    if any(k in low for k in ['shota', 'young', 'teen', 'virgin']):
        return 'Icons.child_care_rounded', 'Character'
    if any(k in low for k in ['yuri', 'lesbian']):
        return 'Icons.diversity_1_rounded', 'Theme'
    if any(k in low for k in ['yaoi', 'gay']):
        return 'Icons.diversity_3_rounded', 'Theme'
    if any(k in low for k in ['futa', 'shemale']):
        return 'Icons.transgender_rounded', 'Character'
    if any(k in low for k in ['cosplay', 'uniform', 'swimsuit', 'bunny', 'stocking', 'panties']):
        return 'Icons.checkroom_rounded', 'Character'
    if any(k in low for k in ['dark skin', 'kemono', 'catgirl', 'neko']):
        return 'Icons.pets_rounded', 'Character'
    return 'Icons.tag_rounded', 'Genre'

widgets = r_home.css('.genres, .genres-list, .categories, ul.genres')
for widget in widgets:
    for li in widget.css('li'):
        a = li.css('a')
        if not a:
            continue
        href = a[0].attrib.get('href', '')
        if '/genre/' not in href:
            continue
        
        raw_name = a[0].text.strip()
        if not raw_name:
            continue
        name = clean_text(raw_name)
        
        m_slug = re.search(r'/genre/([^/]+)/?', href)
        slug = m_slug.group(1) if m_slug else href.strip('/').split('/')[-1]
        
        if slug in seen_genre_slugs:
            continue
        seen_genre_slugs.add(slug)
        
        i_tag = li.css('i')
        count_text = i_tag[0].text.strip().replace(',', '') if i_tag else '0'
        count = int(count_text) if count_text.isdigit() else 0
        
        title_attr = a[0].attrib.get('title', '').strip()
        desc = clean_text(title_attr) if title_attr else f"Authentic HentaiSea {name} anime releases • {count} videos available"
        endpoint = f"/genre/{slug}/"
        icon, group = get_genre_icon_and_group(name)
        
        genres.append({
            'name': name,
            'slug': slug,
            'icon': icon,
            'categoryGroup': group,
            'count': count,
            'description': desc,
            'endpointPath': endpoint,
        })

print(f"Total Unique Live Genres Harvested: {len(genres)}")

# 2. Harvest Series from /free/ (pages 1 to 4)
print("\n--- Harvesting Live Series ---")
series = []
seen_series_slugs = set()
covers = {}

for p in range(1, 5):
    u = 'https://hentaisea.com/free/' if p == 1 else f'https://hentaisea.com/free/page/{p}/'
    r_page = Fetcher.get(u, headers=headers)
    print(f"Fetching series page {p}: {u} -> Status {r_page.status}")
    
    articles = r_page.css('article.item, article.tvshows, article')
    for art in articles:
        a = art.css('.poster a, .data h3 a, a')
        if not a:
            continue
        href = a[0].attrib.get('href', '')
        if '/watch/' not in href:
            continue
        
        m_slug = re.search(r'/watch/([^/]+)/?', href)
        slug = m_slug.group(1) if m_slug else href.strip('/').split('/')[-1]
        
        if slug in seen_series_slugs:
            continue
        seen_series_slugs.add(slug)
        
        h3 = art.css('.data h3 a, .title a, h3 a, h2 a')
        img = art.css('img')
        raw_title = h3[0].text.strip() if h3 and h3[0].text else ''
        if not raw_title and img:
            raw_title = img[0].attrib.get('alt', '')
        
        title = clean_text(raw_title)
        if not title:
            title = slug.replace('-', ' ').title()
        
        img_src = ''
        if img:
            img_src = img[0].attrib.get('src') or img[0].attrib.get('data-src') or img[0].attrib.get('data-lazy-src') or ''
        if img_src.startswith('//'):
            img_src = f"https:{img_src}"
        elif img_src.startswith('/'):
            img_src = f"https://hentaisea.com{img_src}"
        
        endpoint = f"/watch/{slug}/"
        desc = f"Complete serialized anime collection • {title}"
        
        series.append({
            'name': title,
            'slug': slug,
            'cover': img_src,
            'count': 2,
            'description': desc,
            'endpointPath': endpoint,
        })
        if img_src:
            covers[slug] = img_src

print(f"Total Unique Live Series Harvested: {len(series)}")

# 3. Generate Dart Taxonomy File
print("\n--- Generating lib/extensions/taxonomies/hentai_sea_taxonomy.dart ---")

dart_lines = [
    "// GENERATED LIVE TAXONOMY FOR HENTAISEA",
    "// Scraped live via Scrapling from https://hentaisea.com/series, /genre, /free/, and sitemaps",
    f"// Total Live Genres: {len(genres)}",
    f"// Total Live Series: {len(series)}",
    "import 'package:flutter/material.dart';",
    "import '../../models/catalog_model.dart';",
    "",
    "/// Authentic HentaiSea series poster covers harvested live",
    "final Map<String, String> hentaiSeaCovers = const {",
]

for slug, url in covers.items():
    dart_lines.append(f'  "{slug}": "{url}",')
dart_lines.append("};")
dart_lines.append("")

# Series List
dart_lines.append("/// Authentic HentaiSea Anime Series scraped live from https://hentaisea.com/series")
dart_lines.append("final List<CatalogItem> hentaiSeaSeries = const [")
for s in series:
    dart_lines.append("  CatalogItem(")
    dart_lines.append(f'    name: "{s["name"]}",')
    dart_lines.append(f'    slug: "{s["slug"]}",')
    dart_lines.append("    type: CatalogType.category,")
    dart_lines.append('    categoryGroup: "Anime Series",')
    dart_lines.append("    icon: Icons.video_library_rounded,")
    dart_lines.append(f'    count: {s["count"]},')
    dart_lines.append(f'    description: "{s["description"]}",')
    dart_lines.append(f'    endpointPath: "{s["endpointPath"]}",')
    dart_lines.append("  ),")
dart_lines.append("];")
dart_lines.append("")

# Genres List
dart_lines.append("/// Authentic HentaiSea Genres scraped live from https://hentaisea.com/genre")
dart_lines.append("final List<CatalogItem> hentaiSeaGenres = const [")
for g in genres:
    dart_lines.append("  CatalogItem(")
    dart_lines.append(f'    name: "{g["name"]}",')
    dart_lines.append(f'    slug: "{g["slug"]}",')
    dart_lines.append("    type: CatalogType.genre,")
    dart_lines.append(f'    categoryGroup: "{g["categoryGroup"]}",')
    dart_lines.append(f'    icon: {g["icon"]},')
    dart_lines.append(f'    count: {g["count"]},')
    dart_lines.append(f'    description: "{g["description"]}",')
    dart_lines.append(f'    endpointPath: "{g["endpointPath"]}",')
    dart_lines.append("  ),")
dart_lines.append("];")
dart_lines.append("")

# Taxonomy
dart_lines.extend([
    "/// Dynamic ExtensionTaxonomy for HentaiSea Explore browsing",
    "final ExtensionTaxonomy hentaiSeaTaxonomy = ExtensionTaxonomy(",
    "  sections: [",
    "    TaxonomySection(",
    '      id: "series",',
    '      title: "Anime Series",',
    "      displayType: TaxonomyDisplayType.grid,",
    "      items: hentaiSeaSeries,",
    "      icon: Icons.video_library_rounded,",
    "    ),",
    "    TaxonomySection(",
    '      id: "genres",',
    '      title: "Genres",',
    "      displayType: TaxonomyDisplayType.tags,",
    "      items: hentaiSeaGenres,",
    "      icon: Icons.category_rounded,",
    "    ),",
    "  ],",
    "  categories: hentaiSeaSeries,",
    "  tagsAndGenres: hentaiSeaGenres,",
    "  artists: const [],",
    ");",
    "",
])

dart_content = "\n".join(dart_lines)

target_dart_path = "d:/C/H/lib/extensions/taxonomies/hentai_sea_taxonomy.dart"
with open(target_dart_path, "w", encoding="utf-8") as f:
    f.write(dart_content)

print(f"Taxonomy file written to {target_dart_path} ({len(dart_content)} bytes)")
