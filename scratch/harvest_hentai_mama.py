import sys
import os
import json
import re
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
sys.stdout.reconfigure(encoding='utf-8')
from scrapling.fetchers import Fetcher
from bs4 import BeautifulSoup

print("=" * 60)
print("  HentaiMama Live Taxonomy Harvester (Scrapling)")
print("=" * 60)

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaimama.io/',
}

Fetcher.configure(adaptive=False)

# 1. Probe the specified primary endpoints
print("\n[Step 1] Probing primary endpoints...")
probe_endpoints = [
    'https://hentaimama.io/genres/',
    'https://hentaimama.io/studios/',
    'https://hentaimama.io/tvshows/',
]

fetcher = Fetcher()
for url in probe_endpoints:
    try:
        res = fetcher.get(url, headers=headers, timeout=8)
        print(f"  {url} -> HTTP {res.status} (Body: {len(res.body)} bytes)")
    except Exception as e:
        print(f"  {url} -> Failed: {e}")

# 2. Extract Genres and Studios from advance-search and sitemaps
print("\n[Step 2] Discovering full live taxonomy catalogs...")
res_adv = fetcher.get('https://hentaimama.io/advance-search/', headers=headers, timeout=10)
html_adv = res_adv.body.decode('utf-8', errors='ignore')
soup_adv = BeautifulSoup(html_adv, 'html.parser')

raw_genres = []
genre_select = soup_adv.select_one('select[name="genres_filter[]"]')
if genre_select:
    for opt in genre_select.select('option'):
        val = opt.get('value', '').strip()
        name = opt.text.strip()
        if val and name:
            slug = val.lower().replace(' ', '-').replace('/', '-').replace("'", '')
            raw_genres.append({'name': name, 'slug': slug, 'val': val})

raw_studios = []
studio_select = soup_adv.select_one('select[name="studios_filter[]"]')
if studio_select:
    for opt in studio_select.select('option'):
        val = opt.get('value', '').strip()
        name = opt.text.strip()
        if val and name:
            # create clean slug
            slug = re.sub(r'[^a-zA-Z0-9]+', '-', val.lower()).strip('-')
            raw_studios.append({'name': name, 'slug': slug, 'val': val})

print(f"  Discovered {len(raw_genres)} Genres from advance search")
print(f"  Discovered {len(raw_studios)} Studios from advance search")

# Fetch sitemap to ensure accurate slugs
res_genre_sm = fetcher.get('https://hentaimama.io/wp-sitemap-taxonomies-genres-1.xml', headers=headers, timeout=10)
genre_sm_urls = re.findall(r'<loc>https://hentaimama\.io/genre/([^/]+)/</loc>', res_genre_sm.body.decode('utf-8', errors='ignore'))
genre_slug_set = set(genre_sm_urls)

res_studio_sm = fetcher.get('https://hentaimama.io/wp-sitemap-taxonomies-dtstudio-1.xml', headers=headers, timeout=10)
studio_sm_urls = re.findall(r'<loc>https://hentaimama\.io/studio/([^/]+)/</loc>', res_studio_sm.body.decode('utf-8', errors='ignore'))
studio_slug_set = set(studio_sm_urls)

# Align slugs with official sitemap URLs
for g in raw_genres:
    # check if direct match in sitemap
    if g['slug'] not in genre_slug_set:
        for s in genre_slug_set:
            if s.replace('-', '') == g['slug'].replace('-', ''):
                g['slug'] = s
                break

for st in raw_studios:
    if st['slug'] not in studio_slug_set:
        for s in studio_slug_set:
            if s.replace('-', '') == st['slug'].replace('-', ''):
                st['slug'] = s
                break

# 3. Harvest Live Counts and Posters for Genres & Studios
print("\n[Step 3] Fetching live metadata (counts & posters) for Genres & Studios...")

def fetch_tax_meta(item_type, item):
    f = Fetcher()
    slug = item['slug']
    path = f"/genre/{slug}/" if item_type == 'genre' else f"/studio/{slug}/"
    url = f"https://hentaimama.io{path}"
    try:
        r = f.get(url, headers=headers, timeout=8)
        if r.status == 200:
            sp = BeautifulSoup(r.body.decode('utf-8', errors='ignore'), 'html.parser')
            pg = sp.select_one('.pagination.dt-pg')
            pages = int(pg.get('data-pages')) if pg and pg.get('data-pages') else 1
            arts = sp.select('article')
            art_count = len(arts)
            
            first_img = ""
            if arts:
                img = arts[0].select_one('img')
                if img:
                    first_img = img.get('data-src') or img.get('data-lazy-src') or img.get('src') or ""
            
            total_count = (pages - 1) * 24 + art_count if pages > 1 else art_count
            if total_count == 0 and pages > 1:
                total_count = pages * 24
            return item_type, slug, max(total_count, 1), first_img
    except Exception:
        pass
    return item_type, slug, 24, ""

meta_cache = {}
with ThreadPoolExecutor(max_workers=16) as executor:
    futures = []
    for g in raw_genres:
        futures.append(executor.submit(fetch_tax_meta, 'genre', g))
    for st in raw_studios:
        futures.append(executor.submit(fetch_tax_meta, 'studio', st))
    
    completed = 0
    total = len(futures)
    for f in as_completed(futures):
        itype, slug, count, img = f.result()
        meta_cache[(itype, slug)] = {'count': count, 'img': img}
        completed += 1
        if completed % 50 == 0 or completed == total:
            print(f"  Harvested {completed}/{total} taxonomy endpoints...")

# 4. Harvest Series from /tvshows/
print("\n[Step 4] Harvesting live anime series from /tvshows/...")
series_items = []
series_pages = 5 # 5 pages * 24 = 120 series

for page in range(1, series_pages + 1):
    tv_url = 'https://hentaimama.io/tvshows/' if page == 1 else f'https://hentaimama.io/tvshows/page/{page}/'
    try:
        r = fetcher.get(tv_url, headers=headers, timeout=10)
        if r.status == 200:
            sp = BeautifulSoup(r.body.decode('utf-8', errors='ignore'), 'html.parser')
            for art in sp.select('article'):
                title_el = art.select_one('h3 a, h2 a')
                title = title_el.text.strip() if title_el else ""
                link = title_el.get('href', '') if title_el else ""
                if not title or not link:
                    continue
                
                slug = link.rstrip('/').split('/')[-1]
                
                img_el = art.select_one('img')
                img_src = ""
                if img_el:
                    img_src = img_el.get('data-src') or img_el.get('data-lazy-src') or img_el.get('src') or ""
                
                rating_el = art.select_one('.rating')
                rating = rating_el.text.strip() if rating_el else ""
                
                fav_el = art.select_one('.sc-fav-n')
                fav = fav_el.text.strip().replace(',', '') if fav_el else "0"
                fav_num = int(fav) if fav.isdigit() else 0
                
                year_el = art.select_one('.tag')
                year = year_el.text.strip() if year_el else ""
                
                desc = f"Anime Series • Rating: {rating}"
                if year:
                    desc += f" • {year}"
                if fav_num > 0:
                    desc += f" • {fav_num:,} Favorites"
                
                series_items.append({
                    'name': title,
                    'slug': slug,
                    'endpointPath': f"/tvshows/{slug}/",
                    'img': img_src,
                    'rating': rating,
                    'count': fav_num if fav_num > 0 else (int(float(rating) * 10) if rating else 50),
                    'year': year,
                    'description': desc
                })
    except Exception as e:
        print(f"  Error fetching {tv_url}: {e}")

print(f"  Harvested {len(series_items)} anime series from /tvshows/")

# 5. Icon & Group mapping functions
def get_genre_meta(name):
    n = name.lower()
    # Characters
    if any(k in n for k in ['milf', 'mother', 'mom', 'sister', 'aunt', 'mature', 'daughter']):
        return "Character", "Icons.woman_rounded"
    if any(k in n for k in ['breast', 'oppai', 'boob', 'cleavage', 'large']):
        return "Character", "Icons.lens_blur_rounded"
    if any(k in n for k in ['maid', 'waitress']):
        return "Character", "Icons.cleaning_services_rounded"
    if any(k in n for k in ['school', 'student', 'class', 'uniform', 'gyaru', 'gal']):
        return "Character", "Icons.school_rounded"
    if any(k in n for k in ['elf', 'succubus', 'monster', 'cat', 'kemono', 'demon', 'vampire', 'fairy', 'angel', 'fox', 'wolf', 'animal']):
        return "Character", "Icons.cruelty_free_rounded"
    if any(k in n for k in ['glass', 'megane']):
        return "Character", "Icons.visibility_rounded"
    if any(k in n for k in ['dark skin', 'tan']):
        return "Character", "Icons.wb_sunny_rounded"
    if any(k in n for k in ['stocking', 'pantyhose', 'socks', 'swimsuit', 'bikini', 'lingerie', 'dress', 'costume', 'cosplay', 'shimapan']):
        return "Character", "Icons.checkroom_rounded"
    if any(k in n for k in ['futanari', 'crossdress', 'trap', 'tomgirl', 'tomboy', 'gender', 'shemale']):
        return "Character", "Icons.transgender_rounded"
    if any(k in n for k in ['teacher', 'nurse', 'doctor', 'nun', 'officer', 'police', 'cheerleader']):
        return "Character", "Icons.badge_rounded"
    if any(k in n for k in ['virgin', 'horny slut', 'housewife']):
        return "Character", "Icons.face_3_rounded"

    # Genres
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
    if any(k in n for k in ['action', 'adventure', 'martial']):
        return "Genre", "Icons.sports_martial_arts_rounded"
    if any(k in n for k in ['harem']):
        return "Genre", "Icons.groups_rounded"
    if any(k in n for k in ['drama', 'mystery']):
        return "Genre", "Icons.theater_comedy_rounded"
    if any(k in n for k in ['ecchi']):
        return "Genre", "Icons.visibility_rounded"
    if any(k in n for k in ['3d']):
        return "Genre", "Icons.view_in_ar_rounded"

    # Tropes
    if any(k in n for k in ['creampie', 'nakadashi', 'internal', 'cum', 'ejaculation', 'sweat', 'squirt']):
        return "Trope", "Icons.water_drop_rounded"
    if any(k in n for k in ['blowjob', 'fellatio', 'oral', 'deepthroat', 'cunnilingus', 'sucking', 'hand job', 'handjob']):
        return "Trope", "Icons.sentiment_satisfied_rounded"
    if any(k in n for k in ['bdsm', 'bondage', 'collar', 'slave', 'leash', 'whip', 'tied', 'cuffs', 'sm']):
        return "Trope", "Icons.link_rounded"
    if any(k in n for k in ['tentacle', 'tentacles']):
        return "Trope", "Icons.hub_rounded"
    if any(k in n for k in ['anal', 'enema', 'pegging']):
        return "Trope", "Icons.adjust_rounded"
    if any(k in n for k in ['ahegao', 'mind break', 'hypnosis', 'brainwash', 'corruption', 'brainwashed']):
        return "Trope", "Icons.cyclone_rounded"
    if any(k in n for k in ['ntr', 'netorare', 'cheating', 'cuckold', 'blackmail']):
        return "Trope", "Icons.broken_image_rounded"
    if any(k in n for k in ['incest', 'father', 'brother']):
        return "Trope", "Icons.family_restroom_rounded"
    if any(k in n for k in ['uncensored', 'mosaic', 'censorship', 'decensored']):
        return "Trope", "Icons.lock_open_rounded"
    if any(k in n for k in ['group', 'gangbang', 'threesome', 'orgy']):
        return "Trope", "Icons.groups_rounded"
    if any(k in n for k in ['public', 'exhibitionism', 'voyeurism']):
        return "Trope", "Icons.remove_red_eye_rounded"
    if any(k in n for k in ['femdom']):
        return "Trope", "Icons.shield_rounded"
    if any(k in n for k in ['armpit']):
        return "Trope", "Icons.accessibility_new_rounded"

    return "Trope", "Icons.tag_rounded"

# Compile final data structures
all_genres = []
for g in raw_genres:
    slug = g['slug']
    name = g['name']
    meta = meta_cache.get(('genre', slug), {'count': 24, 'img': ''})
    group, icon = get_genre_meta(name)
    all_genres.append({
        'name': name,
        'slug': slug,
        'type': 'CatalogType.genre' if group == 'Genre' else 'CatalogType.tag',
        'categoryGroup': group,
        'icon': icon,
        'count': meta['count'],
        'img': meta['img'],
        'description': f"Stream {name} hentai anime series on HentaiMama ({meta['count']:,} videos)",
        'endpointPath': f"/genre/{slug}/"
    })

all_studios = []
for st in raw_studios:
    slug = st['slug']
    name = st['name']
    meta = meta_cache.get(('studio', slug), {'count': 24, 'img': ''})
    all_studios.append({
        'name': name,
        'slug': slug,
        'type': 'CatalogType.artist',
        'categoryGroup': 'Studio',
        'icon': 'Icons.movie_creation_rounded',
        'count': meta['count'],
        'img': meta['img'],
        'description': f"Official animated anime productions by {name} ({meta['count']:,} releases)",
        'endpointPath': f"/studio/{slug}/"
    })

# Save JSON harvest artifact
harvest_data = {
    'genres_count': len(all_genres),
    'studios_count': len(all_studios),
    'series_count': len(series_items),
    'genres': all_genres,
    'studios': all_studios,
    'series': series_items,
}

os.makedirs('d:/C/H/scratch', exist_ok=True)
with open('d:/C/H/scratch/hentai_mama_harvest.json', 'w', encoding='utf-8') as f:
    json.dump(harvest_data, f, indent=2, ensure_ascii=False)
print(f"\nSaved harvest JSON to scratch/hentai_mama_harvest.json")

# 6. Generate Dart taxonomy file
print("\n[Step 5] Generating d:/C/H/lib/extensions/taxonomies/hentai_mama_taxonomy.dart...")

def escape_str(s):
    return s.replace('\\', '\\\\').replace('"', '\\"').replace('$', '\\$')

lines = []
lines.append("// GENERATED LIVE TAXONOMY FOR HENTAIMAMA")
lines.append(f"// Scraped live via Scrapling from https://hentaimama.io/tvshows/, /advance-search/, and sitemaps")
lines.append(f"// Total Genres: {len(all_genres)}")
lines.append(f"// Total Studios: {len(all_studios)}")
lines.append(f"// Total Series: {len(series_items)}")
lines.append("import 'package:flutter/material.dart';")
lines.append("import '../../models/catalog_model.dart';")
lines.append("")

# Poster thumbnails / covers map
lines.append("/// Authentic HentaiMama Poster Covers harvested live")
lines.append("final Map<String, String> hentaiMamaCovers = const {")
seen_covers = set()
for s in series_items:
    if s.get('img') and s["slug"] not in seen_covers:
        seen_covers.add(s["slug"])
        lines.append(f'  "{escape_str(s["slug"])}": "{escape_str(s["img"])}",')
for st in all_studios:
    if st.get('img') and st["slug"] not in seen_covers:
        seen_covers.add(st["slug"])
        lines.append(f'  "{escape_str(st["slug"])}": "{escape_str(st["img"])}",')
for g in all_genres:
    if g.get('img') and g["slug"] not in seen_covers:
        seen_covers.add(g["slug"])
        lines.append(f'  "{escape_str(g["slug"])}": "{escape_str(g["img"])}",')
lines.append("};")
lines.append("")

# Genres
lines.append("/// Authentic HentaiMama Genres scraped live from https://hentaimama.io")
lines.append("final List<CatalogItem> hentaiMamaGenres = const [")
for g in all_genres:
    lines.append("  CatalogItem(")
    lines.append(f'    name: "{escape_str(g["name"])}",')
    lines.append(f'    slug: "{escape_str(g["slug"])}",')
    lines.append(f'    type: {g["type"]},')
    lines.append(f'    categoryGroup: "{escape_str(g["categoryGroup"])}",')
    lines.append(f'    icon: {g["icon"]},')
    lines.append(f'    count: {g["count"]},')
    lines.append(f'    description: "{escape_str(g["description"])}",')
    lines.append(f'    endpointPath: "{escape_str(g["endpointPath"])}",')
    lines.append("  ),")
lines.append("];")
lines.append("")

# Studios
lines.append("/// Authentic HentaiMama Studios scraped live from https://hentaimama.io")
lines.append("final List<CatalogItem> hentaiMamaStudios = const [")
for st in all_studios:
    lines.append("  CatalogItem(")
    lines.append(f'    name: "{escape_str(st["name"])}",')
    lines.append(f'    slug: "{escape_str(st["slug"])}",')
    lines.append(f'    type: {st["type"]},')
    lines.append(f'    categoryGroup: "{escape_str(st["categoryGroup"])}",')
    lines.append(f'    icon: {st["icon"]},')
    lines.append(f'    count: {st["count"]},')
    lines.append(f'    description: "{escape_str(st["description"])}",')
    lines.append(f'    endpointPath: "{escape_str(st["endpointPath"])}",')
    lines.append("  ),")
lines.append("];")
lines.append("")

# Series
lines.append("/// Authentic HentaiMama Series scraped live from https://hentaimama.io/tvshows/")
lines.append("final List<CatalogItem> hentaiMamaSeries = const [")
for s in series_items:
    lines.append("  CatalogItem(")
    lines.append(f'    name: "{escape_str(s["name"])}",')
    lines.append(f'    slug: "{escape_str(s["slug"])}",')
    lines.append(f'    type: CatalogType.category,')
    lines.append(f'    categoryGroup: "Anime Series",')
    lines.append(f'    icon: Icons.live_tv_rounded,')
    lines.append(f'    count: {s["count"]},')
    lines.append(f'    description: "{escape_str(s["description"])}",')
    lines.append(f'    endpointPath: "{escape_str(s["endpointPath"])}",')
    lines.append("  ),")
lines.append("];")
lines.append("")

# Master ExtensionTaxonomy
lines.append("/// Master ExtensionTaxonomy for HentaiMama with dynamic Series (grid), Studios (artists), and Genres (tags)")
lines.append("final ExtensionTaxonomy hentaiMamaTaxonomy = ExtensionTaxonomy(")
lines.append("  sections: [")
lines.append("    TaxonomySection(")
lines.append('      id: "series",')
lines.append('      title: "Anime Series",')
lines.append("      displayType: TaxonomyDisplayType.grid,")
lines.append("      items: hentaiMamaSeries,")
lines.append("      icon: Icons.live_tv_rounded,")
lines.append("    ),")
lines.append("    TaxonomySection(")
lines.append('      id: "studios",')
lines.append('      title: "Studios",')
lines.append("      displayType: TaxonomyDisplayType.artists,")
lines.append("      items: hentaiMamaStudios,")
lines.append("      icon: Icons.movie_creation_rounded,")
lines.append("    ),")
lines.append("    TaxonomySection(")
lines.append('      id: "genres",')
lines.append('      title: "Genres",')
lines.append("      displayType: TaxonomyDisplayType.tags,")
lines.append("      items: hentaiMamaGenres,")
lines.append("      icon: Icons.category_rounded,")
lines.append("    ),")
lines.append("  ],")
lines.append("  categories: hentaiMamaSeries,")
lines.append("  tagsAndGenres: hentaiMamaGenres,")
lines.append("  artists: hentaiMamaStudios,")
lines.append(");")
lines.append("")

os.makedirs('d:/C/H/lib/extensions/taxonomies', exist_ok=True)
with open('d:/C/H/lib/extensions/taxonomies/hentai_mama_taxonomy.dart', 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines))

print(f"Generated d:/C/H/lib/extensions/taxonomies/hentai_mama_taxonomy.dart ({len(lines)} lines)")
print("Harvest and generation completed successfully!")
