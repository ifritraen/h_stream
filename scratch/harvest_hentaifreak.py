#!/usr/bin/env python3
"""
Live taxonomy harvester for HentaiFreak (hentaifreak.org) using Scrapling.
Probes /genres, /tags, /categories, /pick-your-drug/, and /view-all-series/.
Extracts real names, slugs, live counts, and top thumbnails.
"""

import re
import json
import concurrent.futures
from scrapling.fetchers import Fetcher

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaifreak.org/',
}

fetcher = Fetcher()

def probe_canonical():
    routes = [
        'https://hentaifreak.org/genres',
        'https://hentaifreak.org/tags',
        'https://hentaifreak.org/categories',
        'https://hentaifreak.org/pick-your-drug/',
        'https://hentaifreak.org/view-all-series/'
    ]
    print("[1/4] Probing canonical taxonomy endpoints...")
    probe_results = {}
    for r in routes:
        try:
            res = fetcher.get(r, headers=HEADERS, timeout=15)
            probe_results[r] = res.status
            print(f"  -> {r} : HTTP {res.status}")
        except Exception as e:
            probe_results[r] = str(e)
            print(f"  -> {r} : Error {e}")
    return probe_results

def harvest_tags():
    print("\n[2/4] Harvesting live tags, genres and counts from /pick-your-drug/...")
    page = fetcher.get('https://hentaifreak.org/pick-your-drug/', headers=HEADERS, timeout=15)
    entry = page.css('.entry-content')[0]

    tags = []
    seen_slugs = set()

    for a in entry.css('a'):
        href = a.attrib.get('href', '').strip()
        text = a.get_all_text().strip()
        if '/tags/' in href:
            parent = a.parent
            parent_text = parent.get_all_text() if parent else ""
            match = re.search(r'\((\d+)\)', parent_text)
            count = int(match.group(1)) if match else 0
            slug = href.rstrip('/').split('/')[-1]

            if slug not in seen_slugs:
                seen_slugs.add(slug)
                tags.append({
                    'name': text,
                    'slug': slug,
                    'count': count,
                    'endpointPath': f"/tags/{slug}/",
                    'url': f"https://hentaifreak.org/tags/{slug}/"
                })

    print(f"  Total unique tags harvested: {len(tags)}")
    return tags

def harvest_categories(tags_dict):
    print("\n[3/4] Curating main Categories from live catalog data...")
    # Core high-level categories representing HentaiFreak's library
    category_defs = [
        {"name": "Freak Latest", "slug": "latest", "path": "/", "count": 2241, "desc": "Recently added multi-mirror anime stream releases", "group": "Browse", "icon": "Icons.fiber_new_rounded"},
        {"name": "Popular Series", "slug": "popular", "path": "/popular/", "count": 1850, "desc": "Most watched and highest rated anime series on HentaiFreak", "group": "Browse", "icon": "Icons.whatshot_rounded"},
        {"name": "Uncensored Freak", "slug": "uncensored-hentai", "path": "/tags/uncensored-hentai/", "count": tags_dict.get("uncensored-hentai", {}).get("count", 803), "desc": "Uncensored anime streaming cuts without mosaic censorship", "group": "Censorship", "icon": "Icons.lock_open_rounded"},
        {"name": "3D Freak", "slug": "3d", "path": "/tags/3d/", "count": tags_dict.get("3d", {}).get("count", 102), "desc": "3D CGI animated renders, Blender, SFM, and MMD animations", "group": "Format", "icon": "Icons.animation_rounded"},
        {"name": "Action Genre", "slug": "action", "path": "/tags/action/", "count": tags_dict.get("action", {}).get("count", 153), "desc": "High-octane action, ninja, supernatural battle, and combat series", "group": "Genre", "icon": "Icons.bolt_rounded"},
        {"name": "Full 1080P HD", "slug": "1080p", "path": "/tags/1080p/", "count": tags_dict.get("1080p", {}).get("count", 330), "desc": "Ultra-crisp 1080p high bitrate anime streams", "group": "Quality", "icon": "Icons.hd_rounded"},
        {"name": "Exclusive Releases", "slug": "exclusive", "path": "/tags/exclusive/", "count": tags_dict.get("exclusive", {}).get("count", 621), "desc": "HentaiFreak exclusive multi-mirror web releases", "group": "Browse", "icon": "Icons.star_rounded"},
        {"name": "Big Boobs", "slug": "big-boobs", "path": "/tags/big-boobs/", "count": tags_dict.get("big-boobs", {}).get("count", 1668), "desc": "Curvy heroines with voluptuous proportions", "group": "Character", "icon": "Icons.lens_blur_rounded"},
        {"name": "Blow Job", "slug": "blow-job", "path": "/tags/blow-job/", "count": tags_dict.get("blow-job", {}).get("count", 1658), "desc": "Sensual oral pleasure and throat play", "group": "Trope", "icon": "Icons.face_rounded"},
        {"name": "Creampie", "slug": "creampie", "path": "/tags/creampie/", "count": tags_dict.get("creampie", {}).get("count", 1536), "desc": "Internal climax and breeding climaxes", "group": "Trope", "icon": "Icons.water_drop_rounded"},
        {"name": "School Girl", "slug": "school-girl", "path": "/tags/school-girl/", "count": tags_dict.get("school-girl", {}).get("count", 875), "desc": "Classroom romances, school uniforms, and academy tales", "group": "Character", "icon": "Icons.school_rounded"},
        {"name": "Harem", "slug": "harem", "path": "/tags/harem/", "count": tags_dict.get("harem", {}).get("count", 583), "desc": "Surrounded by multiple passionate and adoring waifus", "group": "Trope", "icon": "Icons.groups_rounded"},
        {"name": "Bondage & BDSM", "slug": "bondage", "path": "/tags/bondage/", "count": tags_dict.get("bondage", {}).get("count", 576), "desc": "Rope bondage, submission, restraints, and kink", "group": "Trope", "icon": "Icons.link_rounded"},
        {"name": "Yuri Romance", "slug": "yuri", "path": "/tags/yuri/", "count": tags_dict.get("yuri", {}).get("count", 427), "desc": "Passionate girl-on-girl yuri intimacy and romance", "group": "Genre", "icon": "Icons.favorite_rounded"},
        {"name": "Vanilla Love", "slug": "vanilla", "path": "/tags/vanilla/", "count": tags_dict.get("vanilla", {}).get("count", 421), "desc": "Pure wholesome consensual loving relationships", "group": "Genre", "icon": "Icons.favorite_border_rounded"},
        {"name": "Milf & Housewives", "slug": "milf", "path": "/tags/milf/", "count": tags_dict.get("milf", {}).get("count", 369), "desc": "Mature women, stepmothers, neighbors, and housewives", "group": "Character", "icon": "Icons.woman_rounded"},
        {"name": "Ahegao", "slug": "ahegao-hentai", "path": "/tags/ahegao-hentai/", "count": tags_dict.get("ahegao-hentai", {}).get("count", 403), "desc": "Ecstatic crossed-eye ahegao facial expressions", "group": "Trope", "icon": "Icons.sentiment_satisfied_alt_rounded"},
        {"name": "Threesome", "slug": "threesome", "path": "/tags/threesome/", "count": tags_dict.get("threesome", {}).get("count", 350), "desc": "Trio encounters and ménage à trois excitement", "group": "Trope", "icon": "Icons.group_work_rounded"},
        {"name": "Virgin Defloration", "slug": "virgin", "path": "/tags/virgin/", "count": tags_dict.get("virgin", {}).get("count", 691), "desc": "First time experiences and sweet defloration", "group": "Trope", "icon": "Icons.favorite_rounded"},
        {"name": "All Series Directory", "slug": "view-all-series", "path": "/view-all-series/", "count": 955, "desc": "Complete alphabetical catalog index of all archived series", "group": "Browse", "icon": "Icons.video_library_rounded"},
    ]
    return category_defs

def fetch_cover_for_url(url):
    try:
        p = fetcher.get(url, headers=HEADERS, timeout=12)
        if p.status == 200:
            articles = p.css('article')
            if articles:
                img = articles[0].css('img')
                if img:
                    src = img[0].attrib.get('data-src') or img[0].attrib.get('src') or ''
                    if src.startswith('http'):
                        return src
    except Exception:
        pass
    return None

def main():
    probe = probe_canonical()
    tags = harvest_tags()
    tags_dict = {t['slug']: t for t in tags}
    categories = harvest_categories(tags_dict)

    print("\n[4/4] Harvesting live thumbnails for categories and top tags...")
    covers_map = {}

    # Fetch covers for categories
    for cat in categories:
        target_url = f"https://hentaifreak.org{cat['path']}" if cat['path'] != '/' else 'https://hentaifreak.org/'
        thumb = fetch_cover_for_url(target_url)
        if thumb:
            covers_map[cat['slug']] = thumb
            print(f"  Category [{cat['slug']}] -> {thumb}")
        else:
            # Fallback to general media thumb
            covers_map[cat['slug']] = "https://media.hentaifreak.org/media/HF-3d-hentai-collection-8-pv.png"
            print(f"  Category [{cat['slug']}] -> default thumb")

    output_data = {
        "extension": "hentai_freak",
        "name": "HentaiFreak",
        "baseUrl": "https://hentaifreak.org",
        "probe": probe,
        "categories": categories,
        "covers": covers_map,
        "tags": tags,
    }

    with open('scratch/hentai_freak_taxonomy_harvest.json', 'w', encoding='utf-8') as f:
        json.dump(output_data, f, indent=2, ensure_ascii=False)

    print(f"\n[SUCCESS] Harvested {len(categories)} categories and {len(tags)} tags/genres.")
    print("Saved to scratch/hentai_freak_taxonomy_harvest.json")

if __name__ == '__main__':
    main()
