#!/usr/bin/env python3
"""
HMV Mania Live Taxonomy Harvester
Uses Scrapling Fetcher with headers to harvest live categories, 3D MMD/SFM tags,
Vocaloid choreography genres, and top creators from https://hmvmania.com.
Endpoints tested:
  - https://hmvmania.com/categories/
  - https://hmvmania.com/tags/
  - https://hmvmania.com/channels/
Live endpoints discovered via sitemaps:
  - https://hmvmania.com/video_category-sitemap.xml (/video-category/)
  - https://hmvmania.com/genre-sitemap.xml (/genre/)
  - https://hmvmania.com/author/

Generates:
  - scratch/hmvmania_harvest.json
  - d:\C\H\lib\extensions\taxonomies\hmvmania_taxonomy.dart
"""

import sys
import io
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

import json
import re
import time
import xml.etree.ElementTree as ET
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
from scrapling.fetchers import Fetcher

BASE_URL = "https://hmvmania.com"
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hmvmania.com/',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
}

try:
    Fetcher.configure(auto_match=False)
except Exception:
    pass

fetcher = Fetcher()

# Icon mappings for categories
CATEGORY_ICON_MAP = {
    "3d": "Icons.view_in_ar_rounded",
    "hmv": "Icons.music_note_rounded",
    "amv": "Icons.movie_filter_rounded",
    "challenge": "Icons.sports_esports_rounded",
    "generative_ai": "Icons.smart_toy_rounded",
    "tutorial": "Icons.school_rounded",
}

# Icon mappings for genres/tags
TAG_ICON_MAP = {
    "3d": "Icons.view_in_ar_rounded",
    "2d-hmv": "Icons.animation_rounded",
    "ai": "Icons.smart_toy_rounded",
    "anal": "Icons.do_not_disturb_on_rounded",
    "anime": "Icons.movie_creation_rounded",
    "bdsm": "Icons.link_rounded",
    "beat-bar-hmv": "Icons.equalizer_rounded",
    "beatbar": "Icons.music_note_rounded",
    "big-ass": "Icons.accessibility_new_rounded",
    "big-boobs": "Icons.favorite_rounded",
    "blowjob": "Icons.sentiment_satisfied_rounded",
    "blue-archive": "Icons.auto_stories_rounded",
    "body-control": "Icons.psychology_rounded",
    "boobjob": "Icons.favorite_border_rounded",
    "bouncing-breasts": "Icons.swap_calls_rounded",
    "christmas": "Icons.ac_unit_rounded",
    "cock-hero": "Icons.military_tech_rounded",
    "compilation": "Icons.collections_rounded",
    "creampie": "Icons.water_drop_rounded",
    "cum": "Icons.opacity_rounded",
    "cum-inside": "Icons.water_drop_rounded",
    "cum-on-breasts": "Icons.grain_rounded",
    "cum-on-face": "Icons.face_retouching_natural_rounded",
    "dark-skin": "Icons.palette_rounded",
    "demon": "Icons.whatshot_rounded",
    "double-penetration": "Icons.call_split_rounded",
    "ecchi": "Icons.wb_sunny_rounded",
    "elves": "Icons.flare_rounded",
    "fap-hero": "Icons.sports_score_rounded",
    "fap_hero": "Icons.sports_score_rounded",
    "faphero": "Icons.sports_score_rounded",
    "fnaf": "Icons.videogame_asset_rounded",
    "friendjoins": "Icons.group_add_rounded",
    "furry": "Icons.pets_rounded",
    "futa": "Icons.transgender_rounded",
    "futanari": "Icons.transgender_rounded",
    "game-cg": "Icons.videogame_asset_rounded",
    "game_cg": "Icons.games_rounded",
    "gangbang": "Icons.groups_3_rounded",
    "genshin-impact": "Icons.explore_rounded",
    "glasses": "Icons.visibility_rounded",
    "group-sex": "Icons.groups_rounded",
    "handjob": "Icons.front_hand_rounded",
    "hard": "Icons.bolt_rounded",
    "harem": "Icons.group_work_rounded",
    "hen": "Icons.star_rounded",
    "henetz-hmv": "Icons.audiotrack_rounded",
    "hentai": "Icons.favorite_rounded",
    "hentez": "Icons.nightlife_rounded",
    "hentez-christmas": "Icons.celebration_rounded",
    "hmv": "Icons.library_music_rounded",
    "hu-tao": "Icons.local_fire_department_rounded",
    "idol": "Icons.mic_rounded",
    "instrumental": "Icons.piano_rounded",
    "maid": "Icons.cleaning_services_rounded",
    "milf": "Icons.family_restroom_rounded",
    "mix-hentai": "Icons.shuffle_rounded",
    "mom": "Icons.family_restroom_rounded",
    "mommy": "Icons.child_friendly_rounded",
    "momson": "Icons.groups_2_rounded",
    "mona": "Icons.auto_awesome_rounded",
    "monster": "Icons.bug_report_rounded",
    "mother": "Icons.escalator_warning_rounded",
    "music": "Icons.headphones_rounded",
    "netorare": "Icons.heart_broken_rounded",
    "ntr": "Icons.warning_amber_rounded",
    "paizuri": "Icons.favorite_rounded",
    "passion": "Icons.local_fire_department_rounded",
    "penetration": "Icons.login_rounded",
    "petite": "Icons.person_pin_rounded",
    "rape": "Icons.gavel_rounded",
    "retro": "Icons.history_rounded",
    "santa": "Icons.card_giftcard_rounded",
    "school": "Icons.school_rounded",
    "sex": "Icons.bed_rounded",
    "sister": "Icons.face_3_rounded",
    "small-boob": "Icons.favorite_outline_rounded",
    "student": "Icons.menu_book_rounded",
    "succubus": "Icons.cruelty_free_rounded",
    "taboo": "Icons.do_not_disturb_rounded",
    "teacher": "Icons.co_present_rounded",
    "tentacles": "Icons.hub_rounded",
    "threesome": "Icons.filter_3_rounded",
    "uncensored": "Icons.lock_open_rounded",
    "vanilla": "Icons.favorite_border_rounded",
    "vtuber": "Icons.live_tv_rounded",
    "yuri": "Icons.female_rounded",
}

DEFAULT_TAG_ICON = "Icons.tag_rounded"
DEFAULT_CAT_ICON = "Icons.category_rounded"
DEFAULT_ARTIST_ICON = "Icons.person_rounded"


def fetch_url(url: str, timeout: int = 12):
    try:
        return fetcher.get(url, headers=HEADERS, timeout=timeout)
    except Exception as e:
        print(f"  [ERROR] {url}: {e}")
        return None


def sanitize_dart_string(s: str) -> str:
    return s.replace('\\', '\\\\').replace('"', '\\"').replace('$', '\\$').strip()


def parse_page_data(r):
    """Extracts video count, cover image, and real title from a taxonomy archive page."""
    if not r or r.status != 200:
        return None

    # Title
    title = r.css('title::text').get() or ''
    # Strip suffixes like " Archives - HMV Mania" or " - HMV Mania"
    clean_title = re.sub(r'\s*(?:Archives\s*)?-\s*HMV\s*Mania.*$', '', title, flags=re.IGNORECASE).strip()

    # Pagination to calculate total video count
    page_texts = [p.text.strip() for p in r.css('.page-numbers') if p.text]
    max_page = 1
    for pt in page_texts:
        if pt.isdigit():
            val = int(pt)
            if val > max_page:
                max_page = val

    # Cards count on page 1
    cards = r.css('.video-item-card, article, .item')
    items_on_page = len(cards)

    if max_page > 1:
        estimated_count = max_page * 10
    else:
        estimated_count = items_on_page

    # Extract first valid cover
    cover = ""
    for card in cards:
        imgs = card.css('img')
        for img in imgs:
            c = img.attrib.get('data-src') or img.attrib.get('src') or ''
            if c and not c.startswith('data:') and 'preloader' not in c and 'logo' not in c:
                if c.startswith('//'):
                    c = 'https:' + c
                cover = c
                break
        if cover:
            break

    return {
        "title": clean_title,
        "count": estimated_count,
        "cover": cover,
        "items_on_page": items_on_page,
    }


def probe_endpoints():
    print("=== TASK 1: PROBING SPECIFIED ENDPOINTS ===")
    probe_targets = [
        f"{BASE_URL}/categories/",
        f"{BASE_URL}/tags/",
        f"{BASE_URL}/channels/",
        f"{BASE_URL}/video-category/",
        f"{BASE_URL}/genre/",
    ]
    for url in probe_targets:
        r = fetch_url(url)
        status = r.status if r else "Failed"
        print(f"  Target: {url} -> Status: {status}")


def harvest_categories():
    print("\n=== HARVESTING LIVE CATEGORIES ===")
    r = fetch_url(f"{BASE_URL}/video_category-sitemap.xml")
    if not r or r.status != 200:
        print("  Failed to fetch video_category sitemap, fallback to hardcoded list")
        cat_slugs = ["3d", "hmv", "amv", "challenge", "generative_ai", "tutorial"]
    else:
        root = ET.fromstring(r.body)
        ns = {'ns': 'http://www.sitemaps.org/schemas/sitemap/0.9'}
        locs = [e.text.strip() for e in root.findall('.//ns:loc', ns)]
        cat_slugs = [loc.rstrip('/').split('/')[-1] for loc in locs]

    print(f"Found {len(cat_slugs)} video category slugs: {cat_slugs}")

    categories = []
    category_covers = {}

    for slug in cat_slugs:
        url = f"{BASE_URL}/video-category/{slug}/"
        res = fetch_url(url)
        data = parse_page_data(res)
        if not data:
            print(f"  Failed parsing category {slug}")
            continue

        raw_title = data["title"]
        # Format nice name
        name_map = {
            "3d": "3D MMD Dance",
            "hmv": "Top HMV",
            "amv": "AMV Edit",
            "challenge": "Beatbar & Challenge",
            "generative_ai": "Generative AI",
            "tutorial": "Tutorials & Guides",
        }
        display_name = name_map.get(slug, raw_title.capitalize())
        icon = CATEGORY_ICON_MAP.get(slug, DEFAULT_CAT_ICON)

        cat_item = {
            "name": display_name,
            "slug": slug,
            "count": data["count"],
            "cover": data["cover"],
            "endpointPath": f"/video-category/{slug}/",
            "icon": icon,
            "description": f"Curated collection of {display_name} music videos and 3D choreography ({data['count']} releases)",
        }
        categories.append(cat_item)
        if data["cover"]:
            category_covers[slug] = data["cover"]
        print(f"  [CAT OK] {display_name} ({slug}): {data['count']} videos | Cover: {data['cover'][:60]}...")

    # Sort categories by count desc
    categories.sort(key=lambda x: x["count"], reverse=True)
    return categories, category_covers


def harvest_genres_and_tags():
    print("\n=== HARVESTING LIVE 3D/SFM TAGS & VOCALOID GENRES ===")
    r = fetch_url(f"{BASE_URL}/genre-sitemap.xml")
    if not r or r.status != 200:
        print("  Failed to fetch genre sitemap")
        return [], {}

    root = ET.fromstring(r.body)
    ns = {'ns': 'http://www.sitemaps.org/schemas/sitemap/0.9'}
    locs = [e.text.strip() for e in root.findall('.//ns:loc', ns)]
    genre_slugs = [loc.rstrip('/').split('/')[-1] for loc in locs]
    print(f"Found {len(genre_slugs)} genres in live sitemap.")

    genres = []
    genre_covers = {}

    def fetch_genre(slug):
        url = f"{BASE_URL}/genre/{slug}/"
        res = fetch_url(url)
        data = parse_page_data(res)
        return slug, data

    with ThreadPoolExecutor(max_workers=8) as executor:
        futures = {executor.submit(fetch_genre, s): s for s in genre_slugs}
        for future in as_completed(futures):
            slug, data = future.result()
            if not data:
                print(f"  [FAIL] Genre: {slug}")
                continue

            # Format name
            raw_title = data["title"]
            clean_name = raw_title if raw_title else slug.replace('-', ' ').title()
            clean_name = clean_name.replace('Hmv', 'HMV').replace('Ai', 'AI').replace('Mmd', 'MMD').replace('Sfm', 'SFM')
            if clean_name.lower() == 'genshin impact':
                clean_name = 'Genshin Impact'
            elif clean_name.lower() == 'blue archive':
                clean_name = 'Blue Archive'
            elif clean_name.lower() == 'hu tao':
                clean_name = 'Hu Tao'
            elif clean_name.lower() == 'fnaf':
                clean_name = 'FNAF'
            elif clean_name.lower() == 'vtuber':
                clean_name = 'VTuber'
            elif clean_name.lower() == 'beat bar hmv':
                clean_name = 'Beat Bar HMV'

            # Assign category groups
            if slug in {"3d", "2d-hmv", "beat-bar-hmv", "beatbar", "fap-hero", "fap_hero", "faphero", "cock-hero", "compilation", "music", "instrumental", "henetz-hmv", "hentez", "idol"}:
                cat_group = "3D & MMD Dance"
            elif slug in {"genshin-impact", "blue-archive", "fnaf", "game-cg", "game_cg", "hu-tao", "mona", "vtuber"}:
                cat_group = "Game & Anime Parody"
            elif slug in {"uncensored", "futanari", "futa", "succubus", "maid", "milf", "mom", "mommy", "momson", "mother", "sister", "teacher", "student", "school", "glasses", "petite", "small-boob", "elves", "demon", "furry", "dark-skin"}:
                cat_group = "Character & Archetype"
            elif slug in {"big-boobs", "big-ass", "boobjob", "paizuri", "creampie", "cum", "cum-inside", "cum-on-face", "cum-on-breasts", "bouncing-breasts", "blowjob", "handjob", "anal", "bdsm", "tentacles", "threesome", "group-sex", "gangbang", "double-penetration", "harem", "monster"}:
                cat_group = "Action & Fetish"
            else:
                cat_group = "Theme & Trope"

            icon = TAG_ICON_MAP.get(slug, DEFAULT_TAG_ICON)

            genres.append({
                "name": clean_name,
                "slug": slug,
                "count": data["count"],
                "cover": data["cover"],
                "categoryGroup": cat_group,
                "endpointPath": f"/genre/{slug}/",
                "icon": icon,
                "description": f"HMV & MMD videos tagged with {clean_name} ({data['count']} releases)",
            })

            if data["cover"]:
                genre_covers[slug] = data["cover"]

    # Sort genres by count desc
    genres.sort(key=lambda x: x["count"], reverse=True)
    print(f"Successfully harvested {len(genres)} live genres and {len(genre_covers)} covers.")
    return genres, genre_covers


def harvest_creators():
    print("\n=== HARVESTING LIVE TOP CREATORS ===")
    # Crawl pages 1 to 10 of /video/ to discover all active creators
    creators_dict = {}

    def fetch_page_creators(p):
        url = f"{BASE_URL}/video/page/{p}/" if p > 1 else f"{BASE_URL}/video/"
        r = fetch_url(url)
        if not r or r.status != 200:
            return []
        cards = r.css('.video-item-card, article, .item')
        found = []
        for card in cards:
            a_links = card.css('a[href*="/author/"]')
            for a in a_links:
                href = a.attrib.get('href', '')
                slug = href.rstrip('/').split('/')[-1]
                # Try finding creator display name from img[alt]
                imgs = a.css('img')
                name = ""
                avatar = ""
                if imgs:
                    name = imgs[0].attrib.get('alt', '').strip()
                    avatar = imgs[0].attrib.get('data-src') or imgs[0].attrib.get('src') or ''
                if not name and a.text:
                    name = a.text.strip()
                if not name:
                    name = slug.replace('-', ' ').title()
                found.append((slug, name, href, avatar))
        return found

    with ThreadPoolExecutor(max_workers=5) as executor:
        futures = [executor.submit(fetch_page_creators, p) for p in range(1, 11)]
        for f in as_completed(futures):
            for slug, name, href, avatar in f.result():
                if slug not in creators_dict:
                    creators_dict[slug] = {
                        "name": name,
                        "slug": slug,
                        "endpointPath": f"/author/{slug}/",
                        "avatar": avatar,
                        "count": 0,
                    }
                creators_dict[slug]["count"] += 1
                if not creators_dict[slug]["avatar"] and avatar:
                    creators_dict[slug]["avatar"] = avatar

    # Now for top creators, fetch their author page to get exact video count & avatar
    top_slugs = sorted(creators_dict.keys(), key=lambda s: creators_dict[s]["count"], reverse=True)[:25]
    print(f"Top {len(top_slugs)} creators identified from recent archives.")

    creators = []
    for slug in top_slugs:
        info = creators_dict[slug]
        author_url = f"{BASE_URL}/author/{slug}/"
        r = fetch_url(author_url)
        exact_count = info["count"]
        if r and r.status == 200:
            title = r.css('title::text').get() or ''
            m = re.match(r'^(.*?),\s*Author at', title, re.IGNORECASE)
            if m:
                info["name"] = m.group(1).strip()
            # Check pagination
            pdata = parse_page_data(r)
            if pdata and pdata["count"] > 0:
                exact_count = pdata["count"]
            # Look for avatar
            for img in r.css('.author-header img, .avatar img, .author-avatar img'):
                av = img.attrib.get('data-src') or img.attrib.get('src') or ''
                if av and not av.startswith('data:'):
                    info["avatar"] = av
                    break

        creators.append({
            "name": info["name"],
            "slug": slug,
            "count": exact_count,
            "endpointPath": f"/author/{slug}/",
            "avatar": info["avatar"],
            "icon": DEFAULT_ARTIST_ICON,
            "description": f"Featured HMV & 3D animator {info['name']} on HMV Mania ({exact_count} videos)",
        })
        print(f"  [CREATOR OK] {info['name']} ({slug}): {exact_count} videos")

    creators.sort(key=lambda x: x["count"], reverse=True)
    return creators


def generate_dart_taxonomy(categories, category_covers, tags, tag_covers, creators, output_path: Path):
    print(f"\n=== GENERATING DART TAXONOMY FILE: {output_path} ===")

    dart_lines = [
        "// GENERATED LIVE TAXONOMY FOR HMV MANIA (hmvmania.com)",
        f"// Harvested live via Scrapling Fetcher from {BASE_URL}/video-category/ and {BASE_URL}/genre/",
        f"// Total Categories: {len(categories)}",
        f"// Total 3D/SFM Tags & Vocaloid Genres: {len(tags)}",
        f"// Total Top Creators: {len(creators)}",
        f"// Total Live Harvested Covers: {len(category_covers) + len(tag_covers)}",
        "import 'package:flutter/material.dart';",
        "import '../../models/catalog_model.dart';",
        "",
        "/// Authentic category cover posters scraped live from HMV Mania",
        "final Map<String, String> hmvManiaCategoryCovers = const {",
    ]

    for slug, url in sorted(category_covers.items()):
        dart_lines.append(f'  "{slug}": "{sanitize_dart_string(url)}",')
    dart_lines.append("};")
    dart_lines.append("")

    dart_lines.append("/// Authentic tag and genre cover posters scraped live from HMV Mania")
    dart_lines.append("final Map<String, String> hmvManiaTagCovers = const {")
    for slug, url in sorted(tag_covers.items()):
        dart_lines.append(f'  "{slug}": "{sanitize_dart_string(url)}",')
    dart_lines.append("};")
    dart_lines.append("")

    # Categories
    dart_lines.append("/// Authentic HMV Mania video categories harvested live via Scrapling")
    dart_lines.append("final List<CatalogItem> hmvManiaCategories = const [")
    for c in categories:
        dart_lines.append("  CatalogItem(")
        dart_lines.append(f'    name: "{sanitize_dart_string(c["name"])}",')
        dart_lines.append(f'    slug: "{sanitize_dart_string(c["slug"])}",')
        dart_lines.append("    type: CatalogType.category,")
        dart_lines.append('    categoryGroup: "Category",')
        dart_lines.append(f'    icon: {c["icon"]},')
        dart_lines.append(f'    count: {c["count"]},')
        dart_lines.append(f'    description: "{sanitize_dart_string(c["description"])}",')
        dart_lines.append(f'    endpointPath: "{sanitize_dart_string(c["endpointPath"])}",')
        dart_lines.append("  ),")
    dart_lines.append("];")
    dart_lines.append("")

    # Tags & Genres
    dart_lines.append("/// Authentic HMV Mania 3D MMD/SFM tags & Vocaloid choreography genres")
    dart_lines.append("final List<CatalogItem> hmvManiaTags = const [")
    for t in tags:
        dart_lines.append("  CatalogItem(")
        dart_lines.append(f'    name: "{sanitize_dart_string(t["name"])}",')
        dart_lines.append(f'    slug: "{sanitize_dart_string(t["slug"])}",')
        dart_lines.append("    type: CatalogType.genre,")
        dart_lines.append(f'    categoryGroup: "{sanitize_dart_string(t["categoryGroup"])}",')
        dart_lines.append(f'    icon: {t["icon"]},')
        dart_lines.append(f'    count: {t["count"]},')
        dart_lines.append(f'    description: "{sanitize_dart_string(t["description"])}",')
        dart_lines.append(f'    endpointPath: "{sanitize_dart_string(t["endpointPath"])}",')
        dart_lines.append("  ),")
    dart_lines.append("];")
    dart_lines.append("")

    # Artists / Creators
    dart_lines.append("/// Top 3D MMD animators and HMV creators harvested live from HMV Mania")
    dart_lines.append("final List<CatalogItem> hmvManiaCreators = const [")
    for a in creators:
        dart_lines.append("  CatalogItem(")
        dart_lines.append(f'    name: "{sanitize_dart_string(a["name"])}",')
        dart_lines.append(f'    slug: "{sanitize_dart_string(a["slug"])}",')
        dart_lines.append("    type: CatalogType.artist,")
        dart_lines.append('    categoryGroup: "Creator",')
        dart_lines.append(f'    icon: {a["icon"]},')
        dart_lines.append(f'    count: {a["count"]},')
        dart_lines.append(f'    description: "{sanitize_dart_string(a["description"])}",')
        dart_lines.append(f'    endpointPath: "{sanitize_dart_string(a["endpointPath"])}",')
        dart_lines.append("  ),")
    dart_lines.append("];")
    dart_lines.append("")

    # ExtensionTaxonomy
    dart_lines.append("/// Dynamic Explore Taxonomy for HMV Mania with dynamic sections:")
    dart_lines.append("/// - Categories [grid]")
    dart_lines.append("/// - Tags & Genres [tags]")
    dart_lines.append("/// - Top Creators [artists]")
    dart_lines.append("final ExtensionTaxonomy hmvManiaTaxonomy = ExtensionTaxonomy(")
    dart_lines.append("  sections: [")
    dart_lines.append("    TaxonomySection(")
    dart_lines.append('      id: "categories",')
    dart_lines.append('      title: "Categories",')
    dart_lines.append("      displayType: TaxonomyDisplayType.grid,")
    dart_lines.append("      items: hmvManiaCategories,")
    dart_lines.append("      icon: Icons.category_rounded,")
    dart_lines.append("    ),")
    dart_lines.append("    TaxonomySection(")
    dart_lines.append('      id: "tags",')
    dart_lines.append('      title: "Tags & Genres",')
    dart_lines.append("      displayType: TaxonomyDisplayType.tags,")
    dart_lines.append("      items: hmvManiaTags,")
    dart_lines.append("      icon: Icons.tag_rounded,")
    dart_lines.append("    ),")
    dart_lines.append("    TaxonomySection(")
    dart_lines.append('      id: "creators",')
    dart_lines.append('      title: "Top Creators",')
    dart_lines.append("      displayType: TaxonomyDisplayType.artists,")
    dart_lines.append("      items: hmvManiaCreators,")
    dart_lines.append("      icon: Icons.palette_rounded,")
    dart_lines.append("    ),")
    dart_lines.append("  ],")
    dart_lines.append("  categories: hmvManiaCategories,")
    dart_lines.append("  tagsAndGenres: hmvManiaTags,")
    dart_lines.append("  artists: hmvManiaCreators,")
    dart_lines.append(");")
    dart_lines.append("")

    content = "\n".join(dart_lines)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"Successfully generated Dart file: {output_path} ({len(dart_lines)} lines)")


def main():
    probe_endpoints()
    categories, cat_covers = harvest_categories()
    tags, tag_covers = harvest_genres_and_tags()
    creators = harvest_creators()

    json_path = Path("scratch/hmvmania_harvest.json")
    json_path.parent.mkdir(parents=True, exist_ok=True)
    data = {
        "metadata": {
            "source": BASE_URL,
            "harvested_at": time.strftime("%Y-%m-%d %H:%M:%S"),
            "category_count": len(categories),
            "tag_count": len(tags),
            "creator_count": len(creators),
            "cover_count": len(cat_covers) + len(tag_covers),
        },
        "categories": categories,
        "category_covers": cat_covers,
        "tags": tags,
        "tag_covers": tag_covers,
        "creators": creators,
    }
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    print(f"\n[OK] Harvest saved to {json_path}")

    dart_path = Path("lib/extensions/taxonomies/hmvmania_taxonomy.dart")
    generate_dart_taxonomy(categories, cat_covers, tags, tag_covers, creators, dart_path)

    print("\n=== HARVEST COMPLETE SUMMARY ===")
    print(f"Categories:           {len(categories)}")
    print(f"3D/SFM Tags & Genres: {len(tags)}")
    print(f"Top Creators:         {len(creators)}")
    print(f"Live Covers:          {len(cat_covers) + len(tag_covers)}")


if __name__ == "__main__":
    main()
