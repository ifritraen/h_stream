#!/usr/bin/env python3
"""
Hentaverse Live Taxonomy Harvester
Uses Scrapling Fetcher with headers to harvest live categories and tags/genres from:
  - https://hentaverse.com/categories/
  - https://hentaverse.com/tags/
  - https://hentaverse.com/genres/
  - https://hentaverse.com/ (homepage)
  - https://hentaverse.com/trending
  - https://hentaverse.com/newest
Extracts real names, slugs, counts/badges, thumbnails, and descriptions.
Generates:
  - scratch/hentaverse_harvest.json
  - lib/extensions/taxonomies/hentaverse_taxonomy.dart
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

BASE_URL = "https://hentaverse.com"
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaverse.com/',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
}

try:
    Fetcher.configure(auto_match=False)
except Exception:
    pass

fetcher = Fetcher()

ICON_MAP = {
    "3d": "Icons.view_in_ar_rounded",
    "ahegao": "Icons.face_retouching_natural_rounded",
    "anal": "Icons.do_not_disturb_on_rounded",
    "big-boobs": "Icons.favorite_rounded",
    "blackmail": "Icons.warning_amber_rounded",
    "blow-job": "Icons.sentiment_satisfied_rounded",
    "bondage": "Icons.link_rounded",
    "boob-job": "Icons.favorite_rounded",
    "bukkake": "Icons.water_drop_rounded",
    "censored": "Icons.lock_rounded",
    "comedy": "Icons.theater_comedy_rounded",
    "creampie": "Icons.water_drop_rounded",
    "dark-skin": "Icons.wb_sunny_rounded",
    "doggy-style": "Icons.pets_rounded",
    "dominatrix": "Icons.gavel_rounded",
    "double-penetration": "Icons.repeat_rounded",
    "erotic-asphyxiation": "Icons.air_rounded",
    "facial": "Icons.face_rounded",
    "female-student": "Icons.school_rounded",
    "filmed": "Icons.videocam_rounded",
    "futanari": "Icons.transgender_rounded",
    "gangbang": "Icons.groups_rounded",
    "glasses": "Icons.visibility_rounded",
    "hand-job": "Icons.touch_app_rounded",
    "harem": "Icons.groups_rounded",
    "horror": "Icons.warning_rounded",
    "incest": "Icons.family_restroom_rounded",
    "inflation": "Icons.add_circle_outline_rounded",
    "lactation": "Icons.opacity_rounded",
    "lingerie": "Icons.checkroom_rounded",
    "loli": "Icons.child_care_rounded",
    "maid": "Icons.cleaning_services_rounded",
    "masturbation": "Icons.touch_app_rounded",
    "milf": "Icons.favorite_rounded",
    "mind-break": "Icons.psychology_rounded",
    "mind-control": "Icons.psychology_rounded",
    "monster": "Icons.pets_rounded",
    "mother-and-son": "Icons.family_restroom_rounded",
    "nekomimi": "Icons.pets_rounded",
    "ntr": "Icons.heart_broken_rounded",
    "nurse": "Icons.medical_services_rounded",
    "orgy": "Icons.diversity_1_rounded",
    "plot": "Icons.auto_stories_rounded",
    "pov": "Icons.camera_alt_rounded",
    "pregnant": "Icons.pregnant_woman_rounded",
    "public-sex": "Icons.park_rounded",
    "rape": "Icons.gavel_rounded",
    "rimjob": "Icons.circle_outlined",
    "romance": "Icons.favorite_rounded",
    "scat": "Icons.delete_outline_rounded",
    "school-girl": "Icons.school_rounded",
    "shota": "Icons.person_rounded",
    "slaves": "Icons.lock_rounded",
    "softcore": "Icons.spa_rounded",
    "submission": "Icons.pan_tool_rounded",
    "swimsuit": "Icons.pool_rounded",
    "teacher": "Icons.school_rounded",
    "tentacle": "Icons.hub_rounded",
    "threesome": "Icons.people_rounded",
    "throat-fucking": "Icons.record_voice_over_rounded",
    "toys": "Icons.toys_rounded",
    "trap": "Icons.swap_horiz_rounded",
    "tsundere": "Icons.sentiment_dissatisfied_rounded",
    "ugly-bastard": "Icons.person_off_rounded",
    "uncensored": "Icons.lock_open_rounded",
    "virgin": "Icons.flare_rounded",
    "watersports": "Icons.water_rounded",
    "x-ray": "Icons.camera_rounded",
    "yaoi": "Icons.male_rounded",
    "yuri": "Icons.female_rounded",
}

DEFAULT_CAT_ICON = "Icons.category_rounded"
DEFAULT_TAG_ICON = "Icons.tag_rounded"


def fetch_url(url: str, timeout: int = 15):
    time.sleep(0.3)
    try:
        r = fetcher.get(url, headers=HEADERS, timeout=timeout)
        return r
    except Exception as e:
        print(f"  Error fetching {url}: {e}")
        return None


def sanitize_dart(s: str) -> str:
    return s.replace('\\', '\\\\').replace('"', '\\"').replace('$', '\\$').replace('\n', ' ').strip()


def harvest():
    print("=== 1. HARVESTING LIVE TAXONOMY DATA FROM HENTAVERSE ===")
    
    target_urls = [
        f"{BASE_URL}/categories/",
        f"{BASE_URL}/tags/",
        f"{BASE_URL}/genres/",
        f"{BASE_URL}/",
        f"{BASE_URL}/trending",
        f"{BASE_URL}/newest",
        f"{BASE_URL}/video/binetsu-hime-episode-1",
    ]
    
    all_taxonomy = {}
    primary_category_slugs = set()
    
    for url in target_urls:
        print(f"Fetching: {url}")
        res = fetch_url(url)
        if not res or not hasattr(res, 'body'):
            continue
        html = res.body.decode('utf-8', errors='ignore')
        print(f"  Received: {len(html)} bytes, Status: {res.status}")
        
        # If /categories/, record primary category slugs directly from the page
        if '/categories/' in url:
            found_slugs = set(re.findall(r'/categories/([a-zA-Z0-9_\-]+)', html))
            primary_category_slugs.update(found_slugs)
            print(f"  Discovered {len(found_slugs)} category slugs from /categories/ HTML")
        
        # Extract Next.js RSC chunks
        chunks = re.findall(r'self\.__next_f\.push\(\[(\d+),"(.*?)"\]\)', html, re.DOTALL)
        all_unescaped = []
        for c_num, c_str in chunks:
            try:
                all_unescaped.append(json.loads(f'"{c_str}"'))
            except Exception:
                all_unescaped.append(c_str.replace('\\"', '"').replace('\\\\', '\\'))
        full_rsc = "\n".join(all_unescaped)
        
        # Match all taxonomy items
        matches = re.finditer(r'\{[^{}]*?"id":"(cmbkj[a-zA-Z0-9]+)"[^{}]*?\}', full_rsc)
        item_count = 0
        for m in matches:
            try:
                data = json.loads(m.group(0))
                slug = data.get('slug')
                if slug and 'name' in data:
                    item_count += 1
                    if slug not in all_taxonomy:
                        all_taxonomy[slug] = data
                    else:
                        if data.get('videosCount', 0) > all_taxonomy[slug].get('videosCount', 0):
                            all_taxonomy[slug]['videosCount'] = data['videosCount']
                        if not all_taxonomy[slug].get('image') and data.get('image'):
                            all_taxonomy[slug]['image'] = data['image']
                        if not all_taxonomy[slug].get('description') and data.get('description'):
                            all_taxonomy[slug]['description'] = data['description']
            except Exception:
                pass
        print(f"  Parsed {item_count} taxonomy objects from RSC stream")

    # Load 28 curated categories if previously saved
    p28_path = Path("scratch/all_hentaverse_categories.json")
    if p28_path.exists():
        with open(p28_path, 'r', encoding='utf-8') as f:
            for c in json.load(f):
                s = c.get('slug')
                if s:
                    primary_category_slugs.add(s)
                    if s not in all_taxonomy or c.get('videosCount', 0) > all_taxonomy[s].get('videosCount', 0):
                        all_taxonomy[s] = c

    print(f"\nTotal unique taxonomy items harvested: {len(all_taxonomy)}")
    
    # Division: 28 Curated Categories, remaining as Tags & Genres
    # (The 28 categories shown in the /categories/ sliders)
    categories = []
    tags = []
    
    # Define canonical 28 categories featured on /categories/
    featured_28 = {
        "shota", "ugly-bastard", "masturbation", "ahegao", "mind-break", "comedy",
        "censored", "loli", "glasses", "bukkake", "submission", "orgy", "inflation",
        "mother-and-son", "rimjob", "nekomimi", "school-girl", "scat", "hand-job",
        "x-ray", "ntr", "incest", "threesome", "boob-job", "bondage", "anal",
        "softcore", "throat-fucking"
    }

    for slug, raw in sorted(all_taxonomy.items()):
        name = raw.get('name', slug.replace('-', ' ').title()).strip()
        count = int(raw.get('videosCount', 0))
        img = raw.get('image', f"uploads/categories/{slug}.webp")
        if img and not img.startswith('http'):
            img = f"{BASE_URL}/{img.lstrip('/')}"
        desc = raw.get('description', f"High-definition anime releases featuring {name} on Hentaverse.").strip()
        
        item_dict = {
            "name": name,
            "slug": slug,
            "count": count,
            "image": img,
            "description": desc,
            "endpointPath": f"/categories/{slug}",
        }
        
        if slug in featured_28:
            categories.append(item_dict)
        else:
            tags.append(item_dict)

    print(f"Categories count: {len(categories)}")
    print(f"Tags & Genres count: {len(tags)}")

    # Save to JSON
    harvest_data = {
        "extensionId": "hentaverse",
        "extensionName": "Hentaverse",
        "baseUrl": BASE_URL,
        "harvestTimestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
        "totalCategories": len(categories),
        "totalTags": len(tags),
        "totalTaxonomy": len(categories) + len(tags),
        "categories": categories,
        "tags": tags,
    }

    out_json = Path("scratch/hentaverse_harvest.json")
    with open(out_json, 'w', encoding='utf-8') as f:
        json.dump(harvest_data, f, indent=2, ensure_ascii=False)
    print(f"Saved harvest JSON to {out_json}")

    # Generate Dart taxonomy file
    generate_dart_taxonomy(categories, tags)


def generate_dart_taxonomy(categories, tags):
    print("=== 2. GENERATING DART TAXONOMY FILE ===")
    dart_path = Path("lib/extensions/taxonomies/hentaverse_taxonomy.dart")
    dart_path.parent.mkdir(parents=True, exist_ok=True)

    lines = []
    lines.append("// GENERATED LIVE TAXONOMY FOR HENTAVERSE (hentaverse.com)")
    lines.append(f"// Harvested live via Scrapling from {BASE_URL}/categories/, /tags/, /genres/")
    lines.append(f"// Total Categories: {len(categories)}")
    lines.append(f"// Total Tags & Tropes: {len(tags)}")
    lines.append("// Total Harvested Taxonomy: " + str(len(categories) + len(tags)))
    lines.append("import 'package:flutter/material.dart';")
    lines.append("import '../../models/catalog_model.dart';")
    lines.append("")

    # 1. Category Covers Map
    lines.append("/// Authentic category cover posters scraped live from Hentaverse")
    lines.append("final Map<String, String> hentaverseCategoryCovers = const {")
    for c in categories:
        lines.append(f'  "{c["slug"]}": "{c["image"]}",')
    lines.append("};")
    lines.append("")

    # 2. Tag Covers Map
    lines.append("/// Authentic tag and genre cover posters scraped live from Hentaverse")
    lines.append("final Map<String, String> hentaverseTagCovers = const {")
    for t in tags:
        lines.append(f'  "{t["slug"]}": "{t["image"]}",')
    lines.append("};")
    lines.append("")

    # 3. hentaverseCategories
    lines.append("/// Authentic Hentaverse categories harvested live via Scrapling")
    lines.append("final List<CatalogItem> hentaverseCategories = const [")
    for c in categories:
        slug = c["slug"]
        icon = ICON_MAP.get(slug, DEFAULT_CAT_ICON)
        name_esc = sanitize_dart(c["name"])
        desc_esc = sanitize_dart(c["description"])
        lines.append("  CatalogItem(")
        lines.append(f'    name: "{name_esc}",')
        lines.append(f'    slug: "{slug}",')
        lines.append("    type: CatalogType.category,")
        lines.append('    categoryGroup: "Category",')
        lines.append(f'    icon: {icon},')
        lines.append(f'    count: {c["count"]},')
        lines.append(f'    description: "{desc_esc}",')
        lines.append(f'    endpointPath: "{c["endpointPath"]}",')
        lines.append("  ),")
    lines.append("];")
    lines.append("")

    # 4. hentaverseTags
    lines.append("/// Authentic Hentaverse tags, genres, and themes harvested live via Scrapling")
    lines.append("final List<CatalogItem> hentaverseTags = const [")
    for t in tags:
        slug = t["slug"]
        icon = ICON_MAP.get(slug, DEFAULT_TAG_ICON)
        name_esc = sanitize_dart(t["name"])
        desc_esc = sanitize_dart(t["description"])
        lines.append("  CatalogItem(")
        lines.append(f'    name: "{name_esc}",')
        lines.append(f'    slug: "{slug}",')
        lines.append("    type: CatalogType.genre,")
        lines.append('    categoryGroup: "Genre",')
        lines.append(f'    icon: {icon},')
        lines.append(f'    count: {t["count"]},')
        lines.append(f'    description: "{desc_esc}",')
        lines.append(f'    endpointPath: "{t["endpointPath"]}",')
        lines.append("  ),")
    lines.append("];")
    lines.append("")

    # 5. hentaverseTaxonomy
    lines.append("/// Dynamic Explore Taxonomy for Hentaverse with Categories (grid) and Tags (tags)")
    lines.append("final ExtensionTaxonomy hentaverseTaxonomy = ExtensionTaxonomy(")
    lines.append("  sections: [")
    lines.append("    TaxonomySection(")
    lines.append('      id: "categories",')
    lines.append('      title: "Categories",')
    lines.append("      displayType: TaxonomyDisplayType.grid,")
    lines.append("      items: hentaverseCategories,")
    lines.append("      icon: Icons.category_rounded,")
    lines.append("    ),")
    lines.append("    TaxonomySection(")
    lines.append('      id: "tags",')
    lines.append('      title: "Tags & Tropes",')
    lines.append("      displayType: TaxonomyDisplayType.tags,")
    lines.append("      items: hentaverseTags,")
    lines.append("      icon: Icons.tag_rounded,")
    lines.append("    ),")
    lines.append("  ],")
    lines.append("  categories: hentaverseCategories,")
    lines.append("  tagsAndGenres: hentaverseTags,")
    lines.append(");")
    lines.append("")

    with open(dart_path, 'w', encoding='utf-8') as f:
        f.write("\n".join(lines))

    print(f"Generated Dart taxonomy at: {dart_path}")


if __name__ == "__main__":
    harvest()
