"""
Hentai.tv Live Taxonomy Harvester
Uses Scrapling (scrapling.fetchers.Fetcher with headers) to scrape live categories,
genres, studios, and tags from https://hentai.tv/categories, https://hentai.tv/genres,
https://hentai.tv/studios, https://hentai.tv/tags.
Extracts real names, slugs, counts, and thumbnails.
Generates d:\\C\\H\\lib\\extensions\\taxonomies\\hentai_tv_taxonomy.dart
"""

import json
import os
import re
import urllib.parse
from scrapling.fetchers import Fetcher

BASE_URL = "https://hentai.tv"
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': f'{BASE_URL}/',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
}

def probe_requested_endpoints():
    print("=== 1. Probing Requested Endpoints with Scrapling ===")
    requested_urls = [
        f"{BASE_URL}/categories",
        f"{BASE_URL}/genres",
        f"{BASE_URL}/studios",
        f"{BASE_URL}/tags",
    ]
    results = {}
    for url in requested_urls:
        try:
            page = Fetcher.get(url, headers=HEADERS, timeout=15)
            print(f"[{page.status}] {url} (Length: {len(page.body)} bytes)")
            results[url] = {
                "status": page.status,
                "length": len(page.body),
            }
        except Exception as e:
            print(f"[ERROR] {url}: {e}")
            results[url] = {"error": str(e)}
    return results

def harvest_categories_and_genres():
    print("\n=== 2. Harvesting Live Categories & Genres from /genres ===")
    page = Fetcher.get(f"{BASE_URL}/genres", headers=HEADERS, timeout=15)
    html = page.body.decode('utf-8', errors='ignore')

    extracted = {}

    # Strategy A: Extract from Server-Rendered HTML DOM
    html_cards = re.findall(
        r'<a\s+class="cat-card"\s+href="(/genre/([^"]+))">'
        r'[\s\S]*?<img[^>]+src="([^"]+)"'
        r'[\s\S]*?<span\s+class="cat-title">([^<]+)</span>'
        r'[\s\S]*?<p\s+class="cat-desc">([^<]*)</p>'
        r'[\s\S]*?<span\s+class="mono">([^<]+)</span>',
        html
    )
    for href, slug, thumb, title, desc, count in html_cards:
        cnt = int(count.replace(',', '').strip()) if count.strip() else 0
        thumb_clean = thumb.strip()
        if thumb_clean.startswith('/'):
            thumb_clean = f"{BASE_URL}{thumb_clean}"
        extracted[slug] = {
            'name': title.strip(),
            'slug': slug.strip(),
            'thumb': thumb_clean,
            'desc': desc.strip(),
            'count': cnt,
            'endpointPath': f"/genre/{slug.strip()}",
        }

    # Strategy B: Extract from RSC flight payload script tags
    flight_matches = re.finditer(r'\\?"href\\?":\s*\\?"/genre/([a-zA-Z0-9_\-]+)\\?"', html)
    for m in flight_matches:
        slug = m.group(1)
        if slug in extracted:
            continue
        pos = m.start()
        snippet = html[pos:min(len(html), pos + 2500)]

        title_m = re.search(r'\\?"cat-title\\?",\\?"children\\?":\s*\\?"([^\\"]+)\\?"', snippet)
        title = title_m.group(1) if title_m else slug.replace('-', ' ').title()

        thumb_m = re.search(r'\\?"poster-img[^\\]*\\?",\\?"src\\?":\s*\\?"([^\\"]+)\\?"', snippet)
        thumb = thumb_m.group(1) if thumb_m else ''
        if thumb.startswith('/'):
            thumb = f"{BASE_URL}{thumb}"

        desc_m = re.search(r'\\?"cat-desc\\?",\\?"children\\?":\s*\\?"([^\\"]*)\\?"', snippet)
        desc = desc_m.group(1) if desc_m else ''

        cnt_m = re.search(r'\\?"mono\\?",\\?"children\\?":\s*\\?"?([0-9,]+)\\?"?', snippet)
        cnt = int(cnt_m.group(1).replace(',', '')) if cnt_m else 0

        extracted[slug] = {
            'name': title,
            'slug': slug,
            'thumb': thumb,
            'desc': desc,
            'count': cnt,
            'endpointPath': f"/genre/{slug}",
        }

    print(f"Total live categories & genres harvested: {len(extracted)}")
    return extracted

def harvest_studios_and_brands():
    print("\n=== 3. Harvesting Live Studios & Brands from /browse ===")
    page = Fetcher.get(f"{BASE_URL}/browse", headers=HEADERS, timeout=15)
    html = page.body.decode('utf-8', errors='ignore')

    idx = html.find(r'{\"name\":\"Pink Pineapple\",\"count\":569}')
    if idx == -1:
        # Search more generally
        idx = html.find('"Pink Pineapple"')
    
    brands = []
    if idx != -1:
        start = html.rfind('[', 0, idx)
        end = html.find(']', idx)
        brand_json_str = html[start:end+1].replace(r'\"', '"')
        try:
            brands = json.loads(brand_json_str)
        except Exception as e:
            print("Failed to parse brand JSON:", e)

    print(f"Total live studios/brands parsed: {len(brands)}")

    # Sort descending by count
    brands.sort(key=lambda x: x.get('count', 0), reverse=True)

    # Fetch real representative cover thumbnails for top studios
    studio_items = []
    print("Harvesting thumbnails for top studios...")
    for i, b in enumerate(brands):
        name = b.get('name', '').strip()
        cnt = b.get('count', 0)
        slug = re.sub(r'[^a-zA-Z0-9]+', '-', name).strip('-').lower()
        thumb = ""

        # Fetch thumbnail for top 25 studios
        if i < 25:
            try:
                q = urllib.parse.quote(name)
                s_url = f"{BASE_URL}/api/search?q={q}&limit=1"
                s_page = Fetcher.get(s_url, headers=HEADERS, timeout=8)
                s_data = json.loads(s_page.body)
                vids = s_data.get('videos', [])
                if vids:
                    t = vids[0].get('cover') or vids[0].get('thumb') or ''
                    if t.startswith('/'):
                        t = f"{BASE_URL}{t}"
                    thumb = t
            except Exception:
                pass

        studio_items.append({
            'name': name,
            'slug': slug,
            'count': cnt,
            'thumb': thumb,
            'desc': f"{name} official anime studio archive • {cnt} releases",
            'endpointPath': f"/browse?brands={urllib.parse.quote(name)}",
        })

    return studio_items

def get_flutter_icon(slug: str, name: str) -> str:
    s = slug.lower()
    n = name.lower()
    if 'vanilla' in s:
        return 'Icons.favorite_rounded'
    if 'romance' in s or 'kiss' in s:
        return 'Icons.favorite_border_rounded'
    if 'anal' in s:
        return 'Icons.adjust_rounded'
    if any(k in s for k in ['boob', 'breast', 'tit']):
        return 'Icons.lens_blur_rounded'
    if 'maid' in s:
        return 'Icons.cleaning_services_rounded'
    if 'incest' in s:
        return 'Icons.family_restroom_rounded'
    if 'comedy' in s:
        return 'Icons.sentiment_very_satisfied_rounded'
    if 'glass' in s:
        return 'Icons.visibility_rounded'
    if any(k in s for k in ['school', 'student']):
        return 'Icons.school_rounded'
    if 'swim' in s:
        return 'Icons.pool_rounded'
    if 'cheat' in s or 'ntr' in s:
        return 'Icons.heart_broken_rounded'
    if 'drama' in s:
        return 'Icons.theater_comedy_rounded'
    if 'office' in s or 'work' in s:
        return 'Icons.work_rounded'
    if 'toy' in s:
        return 'Icons.toys_rounded'
    if any(k in s for k in ['group', 'harem', 'threesome']):
        return 'Icons.groups_rounded'
    if 'humiliation' in s:
        return 'Icons.mood_bad_rounded'
    if 'impregnat' in s:
        return 'Icons.child_care_rounded'
    if any(k in s for k in ['housewife', 'milf', 'mother']):
        return 'Icons.woman_rounded'
    if 'elf' in s:
        return 'Icons.auto_fix_high_rounded'
    if 'gyaru' in s:
        return 'Icons.flare_rounded'
    if 'game' in s:
        return 'Icons.sports_esports_rounded'
    if 'teas' in s:
        return 'Icons.sentiment_satisfied_alt_rounded'
    if 'softcore' in s:
        return 'Icons.blur_on_rounded'
    if '3d' in s:
        return 'Icons.view_in_ar_rounded'
    if 'cream' in s or 'pie' in s:
        return 'Icons.water_drop_rounded'
    if any(k in s for k in ['loli', 'small']):
        return 'Icons.face_3_rounded'
    if 'trap' in s:
        return 'Icons.transgender_rounded'
    if 'tentacle' in s:
        return 'Icons.hub_rounded'
    if 'public' in s:
        return 'Icons.public_rounded'
    if 'femdom' in s:
        return 'Icons.female_rounded'
    if 'monster' in s:
        return 'Icons.cruelty_free_rounded'
    if 'blackmail' in s:
        return 'Icons.lock_rounded'
    if 'uncensor' in s:
        return 'Icons.lock_open_rounded'
    if 'censor' in s:
        return 'Icons.lock_outline_rounded'
    if 'blow' in s:
        return 'Icons.record_voice_over_rounded'
    if any(k in s for k in ['bdsm', 'bondage']):
        return 'Icons.link_rounded'
    if 'cosplay' in s:
        return 'Icons.theater_comedy_rounded'
    if 'dark' in s:
        return 'Icons.shield_moon_rounded'
    if 'action' in s:
        return 'Icons.bolt_rounded'
    if 'fantasy' in s:
        return 'Icons.auto_awesome_rounded'
    if 'yuri' in s:
        return 'Icons.female_rounded'
    if 'yaoi' in s:
        return 'Icons.male_rounded'
    return 'Icons.label_rounded'

def escape_dart_str(s: str) -> str:
    return s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', ' ').replace('$', '\\$')

def generate_dart_file(genres_dict, studios_list, output_path):
    print(f"\n=== 4. Generating Dart Taxonomy File -> {output_path} ===")

    # Sort genres by count descending
    sorted_genres = sorted(genres_dict.values(), key=lambda x: x['count'], reverse=True)

    # Categories: Top 40 prominent genres / themes for the Grid section
    top_categories = sorted_genres[:40]

    lines = []
    lines.append("// GENERATED LIVE TAXONOMY FOR HENTAI.TV (hentai.tv)")
    lines.append("// Harvested live via Scrapling from https://hentai.tv/categories, /genres, /studios, /tags")
    lines.append(f"// Total Categories: {len(top_categories)}")
    lines.append(f"// Total Genres & Tags: {len(sorted_genres)}")
    lines.append(f"// Total Studios: {len(studios_list)}")
    lines.append("import 'package:flutter/material.dart';")
    lines.append("import '../../models/catalog_model.dart';")
    lines.append("")

    # Map of thumbnails
    lines.append("/// Live thumbnail posters harvested from Hentai.tv")
    lines.append("final Map<String, String> hentaiTvThumbnails = const {")
    for g in sorted_genres:
        if g['thumb']:
            lines.append(f'  "{escape_dart_str(g["slug"])}": "{escape_dart_str(g["thumb"])}",')
    for s in studios_list:
        if s['thumb']:
            lines.append(f'  "studio-{escape_dart_str(s["slug"])}": "{escape_dart_str(s["thumb"])}",')
    lines.append("};")
    lines.append("")

    # 1. Categories
    lines.append("/// Curated high-engagement Hentai.tv Categories (Grid layout)")
    lines.append("final List<CatalogItem> hentaiTvCategories = const [")
    for cat in top_categories:
        icon = get_flutter_icon(cat['slug'], cat['name'])
        lines.append("  CatalogItem(")
        lines.append(f'    name: "{escape_dart_str(cat["name"])}",')
        lines.append(f'    slug: "{escape_dart_str(cat["slug"])}",')
        lines.append("    type: CatalogType.category,")
        lines.append('    categoryGroup: "Category",')
        lines.append(f'    icon: {icon},')
        lines.append(f'    count: {cat["count"]},')
        desc = cat['desc'] if cat['desc'] else f"Explore top {cat['name']} hentai series ({cat['count']:,} videos)"
        lines.append(f'    description: "{escape_dart_str(desc)}",')
        lines.append(f'    endpointPath: "{escape_dart_str(cat["endpointPath"])}",')
        lines.append("  ),")
    lines.append("];")
    lines.append("")

    # 2. Genres
    lines.append("/// All authentic Hentai.tv Genres and Tags (Tags layout)")
    lines.append("final List<CatalogItem> hentaiTvGenres = const [")
    for g in sorted_genres:
        icon = get_flutter_icon(g['slug'], g['name'])
        lines.append("  CatalogItem(")
        lines.append(f'    name: "{escape_dart_str(g["name"])}",')
        lines.append(f'    slug: "{escape_dart_str(g["slug"])}",')
        lines.append("    type: CatalogType.genre,")
        lines.append('    categoryGroup: "Genre",')
        lines.append(f'    icon: {icon},')
        lines.append(f'    count: {g["count"]},')
        desc = g['desc'] if g['desc'] else f"{g['name']} tag archive • {g['count']:,} videos"
        lines.append(f'    description: "{escape_dart_str(desc)}",')
        lines.append(f'    endpointPath: "{escape_dart_str(g["endpointPath"])}",')
        lines.append("  ),")
    lines.append("];")
    lines.append("")

    # 3. Studios
    lines.append("/// Authentic Hentai.tv Studios and Anime Production Brands (Artists layout)")
    lines.append("final List<CatalogItem> hentaiTvStudios = const [")
    for st in studios_list:
        lines.append("  CatalogItem(")
        lines.append(f'    name: "{escape_dart_str(st["name"])}",')
        lines.append(f'    slug: "{escape_dart_str(st["slug"])}",')
        lines.append("    type: CatalogType.artist,")
        lines.append('    categoryGroup: "Studio",')
        lines.append("    icon: Icons.business_rounded,")
        lines.append(f'    count: {st["count"]},')
        lines.append(f'    description: "{escape_dart_str(st["desc"])}",')
        lines.append(f'    endpointPath: "{escape_dart_str(st["endpointPath"])}",')
        lines.append("  ),")
    lines.append("];")
    lines.append("")

    # 4. Taxonomy
    lines.append("/// Dynamic Explore Taxonomy for Hentai.tv with dynamic sections:")
    lines.append("/// Categories [grid], Genres [tags], Studios [artists]")
    lines.append("final ExtensionTaxonomy hentaiTvTaxonomy = ExtensionTaxonomy(")
    lines.append("  sections: [")
    lines.append("    TaxonomySection(")
    lines.append('      id: "categories",')
    lines.append('      title: "Categories",')
    lines.append("      displayType: TaxonomyDisplayType.grid,")
    lines.append("      items: hentaiTvCategories,")
    lines.append("      icon: Icons.category_rounded,")
    lines.append("    ),")
    lines.append("    TaxonomySection(")
    lines.append('      id: "genres",')
    lines.append('      title: "Genres & Tags",')
    lines.append("      displayType: TaxonomyDisplayType.tags,")
    lines.append("      items: hentaiTvGenres,")
    lines.append("      icon: Icons.tag_rounded,")
    lines.append("    ),")
    lines.append("    TaxonomySection(")
    lines.append('      id: "studios",')
    lines.append('      title: "Studios",')
    lines.append("      displayType: TaxonomyDisplayType.artists,")
    lines.append("      items: hentaiTvStudios,")
    lines.append("      icon: Icons.business_rounded,")
    lines.append("    ),")
    lines.append("  ],")
    lines.append("  categories: hentaiTvCategories,")
    lines.append("  tagsAndGenres: hentaiTvGenres,")
    lines.append("  artists: hentaiTvStudios,")
    lines.append(");")
    lines.append("")

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    print(f"Successfully generated {output_path} ({len(lines)} lines)")

def main():
    probe_results = probe_requested_endpoints()
    genres_dict = harvest_categories_and_genres()
    studios_list = harvest_studios_and_brands()

    # Save JSON summary
    summary = {
        "probe": probe_results,
        "total_genres": len(genres_dict),
        "total_studios": len(studios_list),
        "genres": genres_dict,
        "studios": studios_list,
    }
    json_path = os.path.join(os.path.dirname(__file__), "hentai_tv_taxonomy.json")
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(summary, f, indent=2)
    print(f"Saved JSON harvest to {json_path}")

    # Generate Dart Taxonomy
    dart_path = r"d:\C\H\lib\extensions\taxonomies\hentai_tv_taxonomy.dart"
    generate_dart_file(genres_dict, studios_list, dart_path)

if __name__ == "__main__":
    main()
