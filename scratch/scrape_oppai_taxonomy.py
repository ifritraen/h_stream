"""
Oppai.stream Live Taxonomy Harvester
Uses Scrapling (scrapling.fetchers.Fetcher with headers) to:
1. Probe live endpoints:
   - https://oppai.stream/genre/
   - https://oppai.stream/categories/
   - https://oppai.stream/studios/
   - https://oppai.stream/actions/search.php
2. Scrape live categories, 4K UHD remasters, genres (with groups), and studios.
3. Extract real names, slugs, counts, and thumbnails.
4. Generate d:\\C\\H\\lib\\extensions\\taxonomies\\oppai_taxonomy.dart.
"""

import sys
import os
import json
import re
import urllib.parse
from concurrent.futures import ThreadPoolExecutor, as_completed
from scrapling.fetchers import Fetcher
from bs4 import BeautifulSoup

# Ensure utf-8 output on Windows
sys.stdout.reconfigure(encoding='utf-8')

BASE_URL = "https://oppai.stream"
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Referer': f'{BASE_URL}/search',
}

def probe_endpoints():
    print("=== TASK 1: Probing Requested Endpoints with Scrapling ===")
    endpoints = [
        f"{BASE_URL}/genre/",
        f"{BASE_URL}/categories/",
        f"{BASE_URL}/categories",
        f"{BASE_URL}/studios/",
        f"{BASE_URL}/actions/search.php?text=&order=recent&page=1&limit=35&genres=&blacklist=&studio=&ibt=0&swa=1",
    ]
    probe_results = {}
    for url in endpoints:
        try:
            r = Fetcher.get(url, headers=HEADERS, timeout=12)
            print(f"[{r.status}] {url} (Length: {len(r.body)})")
            probe_results[url] = {
                "status": r.status,
                "url": r.url,
                "length": len(r.body),
            }
        except Exception as e:
            print(f"[ERROR] {url}: {e}")
            probe_results[url] = {"error": str(e)}
    return probe_results

def harvest_category_thumbnails():
    print("\n=== Harvesting Category Thumbnails from /categories ===")
    r = Fetcher.get(f"{BASE_URL}/categories", headers=HEADERS, timeout=15)
    soup = BeautifulSoup(r.body.decode('utf-8', errors='ignore'), 'html.parser')
    thumbnails = {}
    for font in soup.find_all('font', class_='category-in'):
        text = font.get_text()
        slug = text.split(':')[0].strip().lower().replace(' ', '')
        img = font.find('img')
        if img and img.get('src'):
            src = img['src'].strip()
            thumbnails[slug] = src
    print(f"Harvested {len(thumbnails)} category thumbnails from /categories.")
    return thumbnails

def query_search_api(params):
    """Query search.php to extract total count ('amo') and first item thumbnail."""
    query_str = urllib.parse.urlencode(params)
    url = f"{BASE_URL}/actions/search.php?{query_str}"
    try:
        r = Fetcher.get(url, headers=HEADERS, timeout=12)
        soup = BeautifulSoup(r.body.decode('utf-8', errors='ignore'), 'html.parser')
        amo = soup.find(id='amount-full')
        count = int(amo['amo']) if amo and amo.get('amo') else 0
        
        thumbnail = ""
        first_item = soup.find('div', class_='in-grid')
        if first_item:
            img = first_item.find('img', class_='cover-img-in') or first_item.find('img')
            if img:
                thumbnail = img.get('original') or img.get('src') or ''
                if thumbnail.startswith('//'):
                    thumbnail = f"https:{thumbnail}"
                elif not thumbnail.startswith('http') and thumbnail:
                    thumbnail = f"{BASE_URL}{thumbnail}" if thumbnail.startswith('/') else f"{BASE_URL}/{thumbnail}"
        return count, thumbnail
    except Exception as e:
        return 0, ""

def harvest_all_taxonomy():
    probe_results = probe_endpoints()
    cat_thumbs = harvest_category_thumbnails()

    print("\n=== Harvesting Genres & Studios from /search ===")
    r_search = Fetcher.get(f"{BASE_URL}/search", headers=HEADERS, timeout=15)
    soup_search = BeautifulSoup(r_search.body.decode('utf-8', errors='ignore'), 'html.parser')

    # 1. Genres with groups
    genres_box = soup_search.find('div', class_='genres-box')
    raw_genres = []
    current_group = "Regular"

    for el in genres_box.find_all(['h3', 'h5']):
        if el.name == 'h3' and 'white' in el.get('class', []):
            current_group = el.get_text(strip=True)
        elif el.name == 'h5' and el.get('genre'):
            slug = el['genre'].strip()
            name = el.get_text(strip=True)
            raw_genres.append({
                'name': name,
                'slug': slug,
                'group': current_group,
            })

    # Deduplicate genres by slug
    seen_genres = set()
    genres_list = []
    for g in raw_genres:
        if g['slug'] not in seen_genres:
            seen_genres.add(g['slug'])
            genres_list.append(g)

    print(f"Extracted {len(genres_list)} unique genres.")

    # 2. Studios
    studios_box = soup_search.find('div', class_='studios-box')
    studio_names = []
    for el in studios_box.find_all(attrs={'studio': True}):
        s_name = el['studio'].strip()
        if s_name and s_name not in studio_names:
            studio_names.append(s_name)

    print(f"Extracted {len(studio_names)} unique studios.")

    # 3. Live counts & thumbnails for genres
    print(f"\nFetching live counts & thumbnails for {len(genres_list)} genres concurrently...")
    
    def fetch_genre_data(g):
        slug = g['slug']
        norm_slug = slug.lower().replace(' ', '').replace('-', '')
        thumb = cat_thumbs.get(norm_slug, '')
        
        # Query search.php for live count and thumbnail if missing
        params = {
            'text': '',
            'order': 'recent',
            'page': 1,
            'limit': 1,
            'genres': slug,
            'blacklist': '',
            'studio': '',
            'ibt': 0,
            'swa': 1
        }
        count, live_thumb = query_search_api(params)
        final_thumb = thumb if thumb else live_thumb
        return {
            'name': g['name'],
            'slug': g['slug'],
            'group': g['group'],
            'count': count,
            'thumbnail': final_thumb,
        }

    harvested_genres = []
    with ThreadPoolExecutor(max_workers=10) as executor:
        futures = {executor.submit(fetch_genre_data, g): g for g in genres_list}
        for future in as_completed(futures):
            res = future.result()
            harvested_genres.append(res)

    # Sort genres by count descending
    harvested_genres.sort(key=lambda x: x['count'], reverse=True)
    print(f"Successfully harvested {len(harvested_genres)} genres.")
    for g in harvested_genres[:5]:
        print(f"  {g['name']} ({g['slug']}): {g['count']} items | {g['thumbnail']}")

    # 4. Live counts & thumbnails for studios
    print(f"\nFetching live counts & thumbnails for {len(studio_names)} studios concurrently...")
    
    def fetch_studio_data(name):
        params = {
            'text': '',
            'order': 'recent',
            'page': 1,
            'limit': 1,
            'genres': '',
            'blacklist': '',
            'studio': name,
            'ibt': 0,
            'swa': 1
        }
        count, thumb = query_search_api(params)
        slug = re.sub(r'[^a-zA-Z0-9]+', '-', name).strip('-').lower()
        return {
            'name': name,
            'slug': slug,
            'count': count,
            'thumbnail': thumb,
        }

    harvested_studios = []
    with ThreadPoolExecutor(max_workers=10) as executor:
        futures = {executor.submit(fetch_studio_data, s): s for s in studio_names}
        for future in as_completed(futures):
            res = future.result()
            harvested_studios.append(res)

    # Sort studios by count descending
    harvested_studios.sort(key=lambda x: x['count'], reverse=True)
    print(f"Successfully harvested {len(harvested_studios)} studios.")
    for s in harvested_studios[:5]:
        print(f"  {s['name']}: {s['count']} releases | {s['thumbnail']}")

    # 5. Core categories
    print("\nHarvesting live counts & thumbnails for Categories...")
    category_defs = [
        {
            "name": "4K UHD Remasters",
            "slug": "uhd",
            "search_genres": "4k",
            "search_order": "recent",
            "icon": "Icons.four_k_rounded",
            "desc": "Lossless AI-upscaled 4K 60FPS high-bitrate master releases",
            "endpoint": "/search?a=recent&g=4k",
        },
        {
            "name": "Latest Releases",
            "slug": "recent",
            "search_genres": "",
            "search_order": "recent",
            "icon": "Icons.fiber_new_rounded",
            "desc": "Newly aired and recently remastered anime episodes",
            "endpoint": "/search?a=recent",
        },
        {
            "name": "Most Viewed",
            "slug": "popular",
            "search_genres": "",
            "search_order": "views",
            "icon": "Icons.whatshot_rounded",
            "desc": "All-time most watched and trending anime series",
            "endpoint": "/search?a=views",
        },
        {
            "name": "Highest Rated",
            "slug": "rating",
            "search_genres": "",
            "search_order": "rating",
            "icon": "Icons.star_rounded",
            "desc": "Community top-rated masterpiece hentai series",
            "endpoint": "/search?a=rating",
        },
        {
            "name": "Recently Uploaded",
            "slug": "uploaded",
            "search_genres": "",
            "search_order": "uploaded",
            "icon": "Icons.history_rounded",
            "desc": "Fresh additions to the Oppai.stream archival library",
            "endpoint": "/search?a=uploaded",
        },
        {
            "name": "Uncensored Archive",
            "slug": "uncensored",
            "search_genres": "uncensored",
            "search_order": "recent",
            "icon": "Icons.lock_open_rounded",
            "desc": "Decensored and explicit uncensored uncut editions",
            "endpoint": "/search?a=recent&g=uncensored",
        },
        {
            "name": "Vanilla & Romance",
            "slug": "vanilla",
            "search_genres": "vanilla",
            "search_order": "recent",
            "icon": "Icons.favorite_rounded",
            "desc": "Wholesome romance, sweet lovers, and intimate storytelling",
            "endpoint": "/search?a=recent&g=vanilla",
        },
        {
            "name": "3D CGI Animation",
            "slug": "3d",
            "search_genres": "3d",
            "search_order": "recent",
            "icon": "Icons.view_in_ar_rounded",
            "desc": "3D rendered animation, CGI productions, and MMD masters",
            "endpoint": "/search?a=recent&g=3d",
        },
        {
            "name": "Harem Collections",
            "slug": "harem",
            "search_genres": "harem",
            "search_order": "recent",
            "icon": "Icons.groups_3_rounded",
            "desc": "Multi-heroine school, fantasy, and domestic harem series",
            "endpoint": "/search?a=recent&g=harem",
        },
        {
            "name": "Fantasy & Isekai",
            "slug": "fantasy",
            "search_genres": "fantasy",
            "search_order": "recent",
            "icon": "Icons.auto_awesome_rounded",
            "desc": "Sword, sorcery, magical guilds, and otherworld adventures",
            "endpoint": "/search?a=recent&g=fantasy",
        },
        {
            "name": "MILF & Mature",
            "slug": "milf",
            "search_genres": "milf",
            "search_order": "recent",
            "icon": "Icons.woman_rounded",
            "desc": "Mature housewives, voluptuous mothers, and older waifus",
            "endpoint": "/search?a=recent&g=milf",
        },
        {
            "name": "School Girls",
            "slug": "schoolgirl",
            "search_genres": "schoolgirl",
            "search_order": "recent",
            "icon": "Icons.school_rounded",
            "desc": "Academy uniforms, campus romance, and after-school secrets",
            "endpoint": "/search?a=recent&g=schoolgirl",
        },
        {
            "name": "Maid & Service",
            "slug": "maid",
            "search_genres": "maid",
            "search_order": "recent",
            "icon": "Icons.cleaning_services_rounded",
            "desc": "Dedicated mansion maids, café staff, and obedient service",
            "endpoint": "/search?a=recent&g=maid",
        },
        {
            "name": "Cosplay & Gal",
            "slug": "cosplay",
            "search_genres": "cosplay",
            "search_order": "recent",
            "icon": "Icons.theater_comedy_rounded",
            "desc": "Costume dress-up, convention roleplay, and flashy gyaru",
            "endpoint": "/search?a=recent&g=cosplay",
        },
        {
            "name": "Dark Skin Waifus",
            "slug": "darkskin",
            "search_genres": "darkskin",
            "search_order": "recent",
            "icon": "Icons.wb_sunny_rounded",
            "desc": "Tanned beauties, gyaru, and sun-kissed heroines",
            "endpoint": "/search?a=recent&g=darkskin",
        },
        {
            "name": "Random Discovery",
            "slug": "random",
            "search_genres": "",
            "search_order": "random",
            "icon": "Icons.shuffle_rounded",
            "desc": "Shuffle and discover unexpected hidden anime gems",
            "endpoint": "/search?a=random",
        },
    ]

    harvested_categories = []
    for c in category_defs:
        params = {
            'text': '',
            'order': c['search_order'],
            'page': 1,
            'limit': 1,
            'genres': c['search_genres'],
            'blacklist': '',
            'studio': '',
            'ibt': 0,
            'swa': 1
        }
        count, thumb = query_search_api(params)
        if not thumb and c['slug'] in cat_thumbs:
            thumb = cat_thumbs[c['slug']]
        harvested_categories.append({
            'name': c['name'],
            'slug': c['slug'],
            'count': count,
            'thumbnail': thumb,
            'icon': c['icon'],
            'desc': c['desc'],
            'endpoint': c['endpoint'],
        })
        print(f"  Category: {c['name']} -> Count: {count} | {thumb}")

    # Save to JSON
    all_data = {
        'probe_results': probe_results,
        'categories': harvested_categories,
        'genres': harvested_genres,
        'studios': harvested_studios,
    }
    json_path = os.path.join(os.path.dirname(__file__), 'oppai_harvested.json')
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(all_data, f, indent=2, ensure_ascii=False)
    print(f"\nSaved raw harvested taxonomy to {json_path}")

    # Generate Dart taxonomy
    generate_dart_file(harvested_categories, harvested_genres, harvested_studios)

def choose_genre_icon(slug, name, group):
    s = slug.lower()
    if s in ['4k', 'uhd', 'hd']:
        return "Icons.high_quality_rounded"
    if s in ['uncensored', 'censored']:
        return "Icons.lock_open_rounded" if s == 'uncensored' else "Icons.lock_rounded"
    if s in ['vanilla', 'romance']:
        return "Icons.favorite_rounded"
    if s in ['3d']:
        return "Icons.view_in_ar_rounded"
    if s in ['harem']:
        return "Icons.groups_3_rounded"
    if s in ['fantasy', 'magic', 'monster']:
        return "Icons.auto_awesome_rounded"
    if s in ['maid']:
        return "Icons.cleaning_services_rounded"
    if s in ['schoolgirl']:
        return "Icons.school_rounded"
    if s in ['milf', 'dominantgirl', 'female']:
        return "Icons.woman_rounded"
    if s in ['shota', 'old', 'uglybastard', 'trap']:
        return "Icons.man_rounded"
    if s in ['cosplay']:
        return "Icons.theater_comedy_rounded"
    if s in ['darkskin']:
        return "Icons.wb_sunny_rounded"
    if s in ['beach', 'swimsuit']:
        return "Icons.beach_access_rounded"
    if s in ['comedy']:
        return "Icons.sentiment_very_satisfied_rounded"
    if s in ['horror', 'gore', 'blood']:
        return "Icons.warning_amber_rounded"
    if s in ['mindbreak', 'mindcontrol']:
        return "Icons.psychology_rounded"
    if s in ['tentacle']:
        return "Icons.hub_rounded"
    if s in ['yuri']:
        return "Icons.female_rounded"
    if s in ['yaoi']:
        return "Icons.male_rounded"
    if s in ['creampie', 'lactation', 'watersports']:
        return "Icons.water_drop_rounded"
    if s in ['ahegao']:
        return "Icons.face_retouching_natural_rounded"
    if s in ['teacher']:
        return "Icons.menu_book_rounded"
    if s in ['glasses']:
        return "Icons.visibility_rounded"
    if s in ['succubus', 'demon', 'vampire']:
        return "Icons.nightlight_round"
    if s in ['elf']:
        return "Icons.park_rounded"
    if s in ['nurse']:
        return "Icons.local_hospital_rounded"
    if s in ['bigboobs', 'smallboobs', 'boobjob']:
        return "Icons.favorite_border_rounded"
    if group == "Sexual Actions":
        return "Icons.flash_on_rounded"
    if group == "Female Options":
        return "Icons.person_rounded"
    if group == "Male Options":
        return "Icons.boy_rounded"
    return "Icons.tag_rounded"

def generate_dart_file(categories, genres, studios):
    target_path = r"d:\C\H\lib\extensions\taxonomies\oppai_taxonomy.dart"
    print(f"\n=== Generating {target_path} ===")

    lines = []
    lines.append("// GENERATED LIVE TAXONOMY FOR OPPAI.STREAM (oppai.stream)")
    lines.append(f"// Harvested live via Scrapling from https://oppai.stream/categories, /search, /actions/search.php")
    lines.append(f"// Total Categories: {len(categories)}")
    lines.append(f"// Total Genres: {len(genres)}")
    lines.append(f"// Total Studios: {len(studios)}")
    lines.append("import 'package:flutter/material.dart';")
    lines.append("import '../../models/catalog_model.dart';")
    lines.append("")

    # 1. Category Covers
    lines.append("/// Authentic category cover posters harvested live from Oppai.stream")
    lines.append("final Map<String, String> oppaiCategoryCovers = const {")
    for c in categories:
        if c['thumbnail']:
            lines.append(f'  "{c["slug"]}": "{c["thumbnail"]}",')
    lines.append("};")
    lines.append("")

    # 2. Genre Covers
    lines.append("/// Authentic genre and tag thumbnail covers harvested live from Oppai.stream")
    lines.append("final Map<String, String> oppaiGenreCovers = const {")
    for g in genres:
        if g['thumbnail']:
            lines.append(f'  "{g["slug"]}": "{g["thumbnail"]}",')
    lines.append("};")
    lines.append("")

    # 3. Studio Covers
    lines.append("/// Authentic studio preview covers harvested live from latest episode releases")
    lines.append("final Map<String, String> oppaiStudioCovers = const {")
    for s in studios:
        if s['thumbnail']:
            safe_name = s["name"].replace('"', '\\"')
            lines.append(f'  "{safe_name}": "{s["thumbnail"]}",')
    lines.append("};")
    lines.append("")

    # 4. oppaiCategories
    lines.append("/// Live Oppai.stream categories (featured formats, rankings, master archives)")
    lines.append("final List<CatalogItem> oppaiCategories = const [")
    for c in categories:
        safe_name = c["name"].replace('"', '\\"')
        safe_desc = c["desc"].replace('"', '\\"')
        lines.append("  CatalogItem(")
        lines.append(f'    name: "{safe_name}",')
        lines.append(f'    slug: "{c["slug"]}",')
        lines.append("    type: CatalogType.category,")
        lines.append('    categoryGroup: "Category",')
        lines.append(f'    icon: {c["icon"]},')
        lines.append(f'    count: {c["count"]},')
        lines.append(f'    description: "{safe_desc}",')
        lines.append(f'    endpointPath: "{c["endpoint"]}",')
        lines.append("  ),")
    lines.append("];")
    lines.append("")

    # 5. oppaiGenres
    lines.append("/// Live Oppai.stream genres, character archetypes, tropes, and sexual actions")
    lines.append("final List<CatalogItem> oppaiGenres = const [")
    for g in genres:
        safe_name = g["name"].replace('"', '\\"')
        icon_name = choose_genre_icon(g["slug"], g["name"], g["group"])
        safe_group = g["group"].replace('"', '\\"')
        desc = f'{safe_name} ({safe_group}) • {g["count"]} releases' if g["count"] > 0 else f'{safe_name} ({safe_group})'
        endpoint = f'/search?a=recent&g={g["slug"]}'
        lines.append("  CatalogItem(")
        lines.append(f'    name: "{safe_name}",')
        lines.append(f'    slug: "{g["slug"]}",')
        lines.append("    type: CatalogType.genre,")
        lines.append(f'    categoryGroup: "{safe_group}",')
        lines.append(f'    icon: {icon_name},')
        lines.append(f'    count: {g["count"]},')
        lines.append(f'    description: "{desc}",')
        lines.append(f'    endpointPath: "{endpoint}",')
        lines.append("  ),")
    lines.append("];")
    lines.append("")

    # 6. oppaiStudios
    lines.append("/// Live Oppai.stream anime animation studios and creator labels")
    lines.append("final List<CatalogItem> oppaiStudios = const [")
    for s in studios:
        safe_name = s["name"].replace('"', '\\"')
        safe_slug = s["slug"].replace('"', '\\"')
        desc = f'{safe_name} studio archive • {s["count"]} releases' if s["count"] > 0 else f'{safe_name} studio archive'
        enc_studio = urllib.parse.quote(s["name"])
        endpoint = f'/search?studio={enc_studio}'
        lines.append("  CatalogItem(")
        lines.append(f'    name: "{safe_name}",')
        lines.append(f'    slug: "{safe_slug}",')
        lines.append("    type: CatalogType.artist,")
        lines.append('    categoryGroup: "Studio",')
        lines.append("    icon: Icons.business_rounded,")
        lines.append(f'    count: {s["count"]},')
        lines.append(f'    description: "{desc}",')
        lines.append(f'    endpointPath: "{endpoint}",')
        lines.append("  ),")
    lines.append("];")
    lines.append("")

    # 7. oppaiTaxonomy
    lines.append("/// Dynamic Explore Taxonomy for Oppai.stream with multi-tab structure")
    lines.append("final ExtensionTaxonomy oppaiTaxonomy = ExtensionTaxonomy(")
    lines.append("  sections: [")
    lines.append("    TaxonomySection(")
    lines.append('      id: "categories",')
    lines.append('      title: "Categories",')
    lines.append("      displayType: TaxonomyDisplayType.grid,")
    lines.append("      items: oppaiCategories,")
    lines.append("      icon: Icons.category_rounded,")
    lines.append("    ),")
    lines.append("    TaxonomySection(")
    lines.append('      id: "genres",')
    lines.append('      title: "Genres & Tropes",')
    lines.append("      displayType: TaxonomyDisplayType.tags,")
    lines.append("      items: oppaiGenres,")
    lines.append("      icon: Icons.tag_rounded,")
    lines.append("    ),")
    lines.append("    TaxonomySection(")
    lines.append('      id: "studios",')
    lines.append('      title: "Studios & Creators",')
    lines.append("      displayType: TaxonomyDisplayType.artists,")
    lines.append("      items: oppaiStudios,")
    lines.append("      icon: Icons.business_rounded,")
    lines.append("    ),")
    lines.append("  ],")
    lines.append("  categories: oppaiCategories,")
    lines.append("  tagsAndGenres: oppaiGenres,")
    lines.append("  artists: oppaiStudios,")
    lines.append(");")
    lines.append("")

    content = "\n".join(lines)
    with open(target_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Generated {target_path} successfully ({len(content)} bytes).")

if __name__ == '__main__':
    harvest_all_taxonomy()
