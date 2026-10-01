#!/usr/bin/env python3
"""
Hentaigasm Live Taxonomy Harvester
Uses Scrapling Fetcher with headers to harvest live genres, franchises/series, and tags.
Endpoints tested:
  - https://hentaigasm.com/genres
  - https://hentaigasm.com/hentai/
  - https://hentaigasm.com/tag/
Extracts real names, slugs, counts, and thumbnails from live pages.
Generates:
  - scratch/hentaigasm_harvest.json
  - lib/extensions/taxonomies/hentaigasm_taxonomy.dart
"""

import sys
import io
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

import json
import re
import time
from pathlib import Path
from scrapling.fetchers import Fetcher

BASE_URL = "https://hentaigasm.com"
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaigasm.com/',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
}

try:
    Fetcher.configure(auto_match=False)
except Exception:
    pass

fetcher = Fetcher()

GENRE_ICON_MAP = {
    "3d": "Icons.view_in_ar_rounded",
    "anal": "Icons.do_not_disturb_on_rounded",
    "blowjob": "Icons.sentiment_satisfied_rounded",
    "bondage": "Icons.link_rounded",
    "boobjob": "Icons.favorite_rounded",
    "cheating": "Icons.warning_amber_rounded",
    "creampie": "Icons.water_drop_rounded",
    "demon": "Icons.whatshot_rounded",
    "exclusive": "Icons.stars_rounded",
    "exhibition": "Icons.park_rounded",
    "fantasy": "Icons.auto_awesome_rounded",
    "footjob": "Icons.do_not_step_rounded",
    "futanari": "Icons.transgender_rounded",
    "gangbang": "Icons.groups_3_rounded",
    "harem": "Icons.groups_rounded",
    "incest": "Icons.family_restroom_rounded",
    "maid": "Icons.cleaning_services_rounded",
    "masturbation": "Icons.touch_app_rounded",
    "monster": "Icons.pets_rounded",
    "motion-anime": "Icons.auto_stories_rounded",
    "nurse": "Icons.medical_services_rounded",
    "preview": "Icons.visibility_rounded",
    "rape": "Icons.gavel_rounded",
    "school": "Icons.school_rounded",
    "season": "Icons.calendar_month_rounded",
    "series": "Icons.video_collection_rounded",
    "sex-toy": "Icons.toys_rounded",
    "swimsuit": "Icons.pool_rounded",
    "tentacle": "Icons.hub_rounded",
    "uncensored": "Icons.lock_open_rounded",
    "vanilla": "Icons.favorite_border_rounded",
    "virgin": "Icons.flare_rounded",
    "x-ray": "Icons.camera_rounded",
    "yuri": "Icons.female_rounded",
}

DEFAULT_GENRE_ICON = "Icons.tag_rounded"
DEFAULT_FRANCHISE_ICON = "Icons.movie_filter_rounded"


def fetch_url(url: str, timeout: int = 15):
    time.sleep(0.3)
    try:
        return fetcher.get(url, headers=HEADERS, timeout=timeout, retries=1)
    except Exception as e:
        print(f"  Error fetching {url}: {e}")
        return None


def sanitize_dart_string(s: str) -> str:
    return s.replace('\\', '\\\\').replace('"', '\\"').replace('$', '\\$').strip()


def probe_endpoints():
    print("=== PROBING TARGET ENDPOINTS ===")
    targets = [
        f"{BASE_URL}/genres",
        f"{BASE_URL}/hentai/",
        f"{BASE_URL}/tag/",
    ]
    for url in targets:
        r = fetch_url(url)
        if r:
            print(f"  GET {url} -> Status: {r.status} (Final URL: {r.url})")
        else:
            print(f"  GET {url} -> Request failed")


def harvest_tags_and_genres():
    print("\n=== HARVESTING LIVE GENRES & TAGS ===")
    url = f"{BASE_URL}/wp-json/wp/v2/tags?per_page=100"
    r = fetch_url(url)
    if not r or r.status != 200:
        print(f"  Failed to fetch tags: {r.status if r else 'No response'}")
        return []

    data = json.loads(r.body)
    print(f"  Successfully fetched {len(data)} live tags/genres from WordPress REST API.")

    genres = []
    for item in data:
        name = item.get("name", "").strip()
        slug = item.get("slug", "").strip()
        count = item.get("count", 0)
        link = item.get("link", f"{BASE_URL}/genre/{slug}/")
        endpoint_path = f"/genre/{slug}/"
        icon = GENRE_ICON_MAP.get(slug, DEFAULT_GENRE_ICON)

        genres.append({
            "name": name,
            "slug": slug,
            "count": count,
            "link": link,
            "endpointPath": endpoint_path,
            "icon": icon,
            "description": f"Explore {count} {name} anime titles and classic releases on Hentaigasm.",
        })

    genres.sort(key=lambda x: x["count"], reverse=True)
    return genres


def harvest_franchises():
    print("\n=== HARVESTING LIVE FRANCHISES / SERIES ===")
    franchises = []
    seen_slugs = set()

    for page in range(1, 4):
        url = f"{BASE_URL}/wp-json/wp/v2/categories?per_page=50&page={page}&orderby=count&order=desc"
        r = fetch_url(url)
        if not r or r.status != 200:
            print(f"  Categories page {page} failed or ended")
            break
        data = json.loads(r.body)
        print(f"  Page {page}: fetched {len(data)} series categories.")

        for item in data:
            slug = item.get("slug", "").strip()
            name = item.get("name", "").strip()
            count = item.get("count", 0)
            if not slug or slug in seen_slugs or count < 1:
                continue

            if slug in {"uncategorized"}:
                continue

            seen_slugs.add(slug)
            endpoint_path = f"/hentai/{slug}/"
            franchises.append({
                "name": name,
                "slug": slug,
                "count": count,
                "endpointPath": endpoint_path,
                "icon": DEFAULT_FRANCHISE_ICON,
                "description": f"Complete {name} anime episodes archive with {count} releases.",
            })

    print(f"  Total franchises harvested: {len(franchises)}")
    return franchises


def harvest_covers(genres, franchises):
    print("\n=== HARVESTING LIVE THUMBNAILS ACROSS RECENT ARCHIVE PAGES ===")
    covers = {}

    for page in range(1, 6):
        url = f"{BASE_URL}/page/{page}/" if page > 1 else f"{BASE_URL}/"
        try:
            r = fetch_url(url)
            if not r or r.status != 200:
                continue
            items = r.css('div.item, article, .post')
            print(f"  Page {page} ({url}): {len(items)} items found")
            for item in items:
                cls = item.attrib.get('class', '')
                imgs = item.css('div.thumb img, img')
                if not imgs:
                    continue
                cover = imgs[0].attrib.get('data-src') or imgs[0].attrib.get('src') or ''
                if not cover or 'lip.png' in cover or 'logo.png' in cover or 'data:image' in cover:
                    continue
                if cover.startswith('//'):
                    cover = 'https:' + cover

                cat_matches = re.findall(r'\bcategory-([a-z0-9-]+)\b', cls)
                for cat in cat_matches:
                    if cat not in covers:
                        covers[cat] = cover

                tag_matches = re.findall(r'\btag-([a-z0-9-]+)\b', cls)
                for tag in tag_matches:
                    if tag not in covers:
                        covers[tag] = cover
        except Exception as e:
            print(f"  Error crawling page {page}: {e}")

    print(f"  Captured {len(covers)} unique covers from catalog scan.")

    # Missing genres
    missing_genres = [g['slug'] for g in genres if g['slug'] not in covers]
    if missing_genres:
        print(f"  Fetching missing covers for {len(missing_genres)} genres...")
        for slug in missing_genres:
            genre_url = f"{BASE_URL}/genre/{slug}/"
            r = fetch_url(genre_url)
            if r and r.status == 200:
                items = r.css('div.item, article, .post')
                if items:
                    imgs = items[0].css('div.thumb img, img')
                    if imgs:
                        c = imgs[0].attrib.get('data-src') or imgs[0].attrib.get('src') or ''
                        if c and 'lip.png' not in c and 'logo.png' not in c:
                            if c.startswith('//'):
                                c = 'https:' + c
                            covers[slug] = c
                            print(f"    [OK] Cover for genre '{slug}': {c}")

    # Top franchises missing covers (first 10)
    missing_franchises = [f['slug'] for f in franchises[:50] if f['slug'] not in covers]
    if missing_franchises:
        print(f"  Fetching covers for top franchises missing covers ({len(missing_franchises[:10])})...")
        for slug in missing_franchises[:10]:
            cat_url = f"{BASE_URL}/hentai/{slug}/"
            r = fetch_url(cat_url)
            if r and r.status == 200:
                items = r.css('div.item, article, .post')
                if items:
                    imgs = items[0].css('div.thumb img, img')
                    if imgs:
                        c = imgs[0].attrib.get('data-src') or imgs[0].attrib.get('src') or ''
                        if c and 'lip.png' not in c and 'logo.png' not in c:
                            if c.startswith('//'):
                                c = 'https:' + c
                            covers[slug] = c
                            print(f"    [OK] Cover for franchise '{slug}': {c}")

    return covers


def generate_dart_code(genres, franchises, covers, output_path: Path):
    print(f"\n=== GENERATING DART TAXONOMY: {output_path} ===")

    dart_lines = [
        "// GENERATED LIVE TAXONOMY FOR HENTAIGASM (hentaigasm.com)",
        f"// Harvested live via Scrapling Fetcher from {BASE_URL}/genre/ and {BASE_URL}/hentai/",
        f"// Total Genres & Tags: {len(genres)}",
        f"// Total Franchises / Series: {len(franchises)}",
        f"// Total Harvested Covers: {len(covers)}",
        "import 'package:flutter/material.dart';",
        "import '../../models/catalog_model.dart';",
        "",
        "/// Authentic Hentaigasm poster & thumbnail covers harvested live",
        "final Map<String, String> hentaigasmCovers = const {",
    ]

    for slug, url in sorted(covers.items()):
        dart_lines.append(f'  "{slug}": "{sanitize_dart_string(url)}",')
    dart_lines.append("};")
    dart_lines.append("")

    # Genres
    dart_lines.append("/// Authentic Hentaigasm Genres & Tags scraped live from /genre/ and /tag/")
    dart_lines.append("final List<CatalogItem> hentaigasmGenres = const [")
    for g in genres:
        dart_lines.append("  CatalogItem(")
        dart_lines.append(f'    name: "{sanitize_dart_string(g["name"])}",')
        dart_lines.append(f'    slug: "{sanitize_dart_string(g["slug"])}",')
        dart_lines.append("    type: CatalogType.genre,")
        dart_lines.append('    categoryGroup: "Genre",')
        dart_lines.append(f'    icon: {g["icon"]},')
        dart_lines.append(f'    count: {g["count"]},')
        dart_lines.append(f'    description: "{sanitize_dart_string(g["description"])}",')
        dart_lines.append(f'    endpointPath: "{sanitize_dart_string(g["endpointPath"])}",')
        dart_lines.append("  ),")
    dart_lines.append("];")
    dart_lines.append("")

    # Franchises
    dart_lines.append("/// Authentic Hentaigasm Franchises & Series scraped live from /hentai/")
    dart_lines.append("final List<CatalogItem> hentaigasmFranchises = const [")
    for f in franchises:
        dart_lines.append("  CatalogItem(")
        dart_lines.append(f'    name: "{sanitize_dart_string(f["name"])}",')
        dart_lines.append(f'    slug: "{sanitize_dart_string(f["slug"])}",')
        dart_lines.append("    type: CatalogType.category,")
        dart_lines.append('    categoryGroup: "Franchise",')
        dart_lines.append(f'    icon: {f["icon"]},')
        dart_lines.append(f'    count: {f["count"]},')
        dart_lines.append(f'    description: "{sanitize_dart_string(f["description"])}",')
        dart_lines.append(f'    endpointPath: "{sanitize_dart_string(f["endpointPath"])}",')
        dart_lines.append("  ),")
    dart_lines.append("];")
    dart_lines.append("")

    # ExtensionTaxonomy
    dart_lines.append("/// Dynamic Explore Taxonomy for Hentaigasm with dynamic sections:")
    dart_lines.append("/// - Franchises / Series [grid]")
    dart_lines.append("/// - Genres & Tags [tags]")
    dart_lines.append("final ExtensionTaxonomy hentaigasmTaxonomy = ExtensionTaxonomy(")
    dart_lines.append("  sections: [")
    dart_lines.append("    TaxonomySection(")
    dart_lines.append('      id: "franchises",')
    dart_lines.append('      title: "Franchises / Series",')
    dart_lines.append("      displayType: TaxonomyDisplayType.grid,")
    dart_lines.append("      items: hentaigasmFranchises,")
    dart_lines.append("      icon: Icons.movie_filter_rounded,")
    dart_lines.append("    ),")
    dart_lines.append("    TaxonomySection(")
    dart_lines.append('      id: "genres",')
    dart_lines.append('      title: "Genres & Tags",')
    dart_lines.append("      displayType: TaxonomyDisplayType.tags,")
    dart_lines.append("      items: hentaigasmGenres,")
    dart_lines.append("      icon: Icons.tag_rounded,")
    dart_lines.append("    ),")
    dart_lines.append("  ],")
    dart_lines.append("  categories: hentaigasmFranchises,")
    dart_lines.append("  tagsAndGenres: hentaigasmGenres,")
    dart_lines.append(");")
    dart_lines.append("")

    content = "\n".join(dart_lines)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"  [OK] Written {len(dart_lines)} lines to {output_path}")


def main():
    probe_endpoints()
    genres = harvest_tags_and_genres()
    franchises = harvest_franchises()
    covers = harvest_covers(genres, franchises)

    for g in genres:
        if g['slug'] in covers:
            g['cover'] = covers[g['slug']]
    for f in franchises:
        if f['slug'] in covers:
            f['cover'] = covers[f['slug']]

    json_path = Path("scratch/hentaigasm_harvest.json")
    json_path.parent.mkdir(parents=True, exist_ok=True)
    harvest_data = {
        "metadata": {
            "source": BASE_URL,
            "harvested_at": time.strftime("%Y-%m-%d %H:%M:%S"),
            "genre_count": len(genres),
            "franchise_count": len(franchises),
            "cover_count": len(covers),
        },
        "genres": genres,
        "franchises": franchises,
        "covers": covers,
    }
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(harvest_data, f, indent=2, ensure_ascii=False)
    print(f"\n[OK] Saved harvest JSON to {json_path}")

    dart_path = Path("lib/extensions/taxonomies/hentaigasm_taxonomy.dart")
    generate_dart_code(genres, franchises, covers, dart_path)

    print("\n=== HARVEST COMPLETE SUMMARY ===")
    print(f"Genres & Tags:       {len(genres)}")
    print(f"Franchises / Series: {len(franchises)}")
    print(f"Live Covers:         {len(covers)}")


if __name__ == "__main__":
    main()
