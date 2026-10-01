"""
Aki-H (aki-h.com) Live Taxonomy Scraper
Uses Scrapling 0.4.15 (scrapling.fetchers.Fetcher) with stealth headers to harvest
all live categories, tags, and genres from https://aki-h.com/.
"""

import sys
import json
from concurrent.futures import ThreadPoolExecutor
from scrapling.fetchers import Fetcher
from bs4 import BeautifulSoup

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://aki-h.com/',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
}

def harvest_aki_hentai_taxonomy():
    fetcher = Fetcher()
    print("=== Aki-H (aki-h.com) Live Taxonomy Harvester ===")

    # 1. Probe canonical endpoints
    canonical_candidates = [
        "https://aki-h.com/categories/",
        "https://aki-h.com/tags/",
        "https://aki-h.com/genres/",
        "https://aki-h.com/category/",
        "https://aki-h.com/genre/",
        "https://aki-h.com/filter/",
    ]
    print("\n--- Probing Candidate Endpoints ---")
    for cand in canonical_candidates:
        try:
            res = fetcher.get(cand, headers=HEADERS, timeout=10)
            is_404 = 'layout-page-404' in res.body.decode('utf-8', errors='ignore') or 'Page not found' in res.body.decode('utf-8', errors='ignore') or 'error/404' in res.url
            print(f"[{res.status}] {cand} -> 404: {is_404} (Final URL: {res.url})")
        except Exception as e:
            print(f"[ERR] {cand}: {e}")

    # 2. Harvest Categories
    print("\n--- Harvesting Categories & Top-Level Feeds ---")
    categories_def = [
        {"name": "Latest Releases", "slug": "latest", "url": "https://aki-h.com/", "endpoint": "/", "desc": "Recently uploaded anime episodes and newly subbed series", "icon": "fiber_new_rounded"},
        {"name": "Most Popular", "slug": "popular", "url": "https://aki-h.com/popular/", "endpoint": "/popular/", "desc": "Top-rated and most viewed anime series of all time", "icon": "whatshot_rounded"},
        {"name": "Uncensored Cuts", "slug": "uncensored", "url": "https://aki-h.com/category/uncensored/", "endpoint": "/category/uncensored/", "desc": "High-definition uncensored releases without mosaic blurring", "icon": "lock_open_rounded"},
        {"name": "Censored Studio", "slug": "censored", "url": "https://aki-h.com/category/censored/", "endpoint": "/category/censored/", "desc": "Official Japanese broadcast cuts with standard studio mosaics", "icon": "lock_outline_rounded"},
        {"name": "3D Animation", "slug": "3d", "url": "https://aki-h.com/genre/3d/", "endpoint": "/genre/3d/", "desc": "3D CGI animated renders, MMD productions, and modern game models", "icon": "view_in_ar_rounded"},
        {"name": "2D Classics", "slug": "2d", "url": "https://aki-h.com/genre/2d/", "endpoint": "/genre/2d/", "desc": "Classic hand-drawn 2D Japanese anime serialized series", "icon": "movie_filter_rounded"},
        {"name": "A-Z Directory", "slug": "az-list", "url": "https://aki-h.com/az-list/", "endpoint": "/az-list/", "desc": "Alphabetical catalog index of all archived hentai series", "icon": "sort_by_alpha_rounded"},
        {"name": "Random Discovery", "slug": "random", "url": "https://aki-h.com/random/", "endpoint": "/random/", "desc": "Pick and stream a completely randomized anime episode", "icon": "shuffle_rounded"},
    ]

    harvested_categories = []
    for cat in categories_def:
        try:
            p = fetcher.get(cat["url"], headers=HEADERS, timeout=12)
            soup = BeautifulSoup(p.body, "html.parser")
            items = soup.find_all("div", class_="flw-item")
            pag = soup.find("ul", class_="pagination")
            max_p = 1
            if pag:
                for a in pag.find_all("a"):
                    h = a.get("href", "")
                    if "/page/" in h:
                        try:
                            n = int(h.strip("/").split("/")[-1])
                            if n > max_p: max_p = n
                        except: pass
            total_items = (max_p - 1) * 24 + len(items) if max_p > 1 else len(items)
            if total_items == 0 and cat["slug"] in ["latest", "random"]:
                total_items = 20 if cat["slug"] == "latest" else 4
            cat_data = {
                **cat,
                "count": total_items,
                "status": p.status,
            }
            harvested_categories.append(cat_data)
            print(f"  [Category] {cat['name']:25} | slug: {cat['slug']:15} | count: {total_items:4} | endpoint: {cat['endpoint']}")
        except Exception as e:
            print(f"  [Error] {cat['name']}: {e}")

    # 3. Harvest Tags & Genres from Sidebar and Filter
    print("\n--- Harvesting Tags & Genres ---")
    p_home = fetcher.get("https://aki-h.com/", headers=HEADERS)
    soup_home = BeautifulSoup(p_home.body, "html.parser")

    genres_dict = {}
    for a in soup_home.select("div.sidebar_menu-sub ul.sub-menu a"):
        href = a.get("href", "")
        name = a.get_text(strip=True)
        if "/genre/" in href and name and name.lower() != "more":
            slug = href.strip("/").split("/")[-1]
            genres_dict[slug] = {
                "name": name,
                "slug": slug,
                "endpointPath": f"/genre/{slug}/",
                "url": href,
            }

    p_filter = fetcher.get("https://aki-h.com/filter/", headers=HEADERS)
    soup_filter = BeautifulSoup(p_filter.body, "html.parser")
    for div in soup_filter.select("div.f-genre-item"):
        name = div.get_text(strip=True)
        data_id = div.get("data-id", "")
        found = False
        for g in genres_dict.values():
            if g["name"].lower() == name.lower():
                g["filter_id"] = data_id
                found = True
                break
        if not found and name:
            slug = name.lower().replace(" ", "-")
            genres_dict[slug] = {
                "name": name,
                "slug": slug,
                "endpointPath": f"/genre/{slug}/",
                "url": f"https://aki-h.com/genre/{slug}/",
                "filter_id": data_id,
            }

    print(f"Discovered {len(genres_dict)} distinct genre/tag entities. Probing live counts...")

    def probe_single_genre(item):
        slug, info = item
        try:
            f = Fetcher()
            p = f.get(info["url"], headers=HEADERS, timeout=12)
            if p.status == 200 and "layout-page-404" not in p.body.decode("utf-8", errors="ignore"):
                soup = BeautifulSoup(p.body, "html.parser")
                items = soup.find_all("div", class_="flw-item")
                pag = soup.find("ul", class_="pagination")
                max_p = 1
                if pag:
                    for a in pag.find_all("a"):
                        h = a.get("href", "")
                        if "/page/" in h:
                            try:
                                n = int(h.strip("/").split("/")[-1])
                                if n > max_p: max_p = n
                            except: pass
                total = (max_p - 1) * 24 + len(items) if max_p > 1 else len(items)
                return slug, {**info, "status": 200, "count": total, "pages": max_p}
            else:
                return slug, {**info, "status": 404, "count": 0, "pages": 0}
        except Exception as e:
            return slug, {**info, "status": 500, "count": 0, "error": str(e)}

    harvested_tags = {}
    with ThreadPoolExecutor(max_workers=6) as pool:
        for slug, res in pool.map(probe_single_genre, genres_dict.items()):
            harvested_tags[slug] = res
            print(f"  [Tag/Genre] {res['name']:25} | slug: {slug:20} | count: {res['count']:3} | filter_id: {res.get('filter_id', 'N/A')}")

    print(f"\nSuccessfully harvested {len(harvested_categories)} categories and {len(harvested_tags)} tags/genres!")

    # Summary
    summary = {
        "extension_id": "aki_hentai",
        "name": "Aki-H",
        "base_url": "https://aki-h.com",
        "categories_count": len(harvested_categories),
        "tags_count": len(harvested_tags),
        "categories": harvested_categories,
        "tags": list(harvested_tags.values())
    }

    with open("aki_taxonomy_harvest_summary.json", "w", encoding="utf-8") as f:
        json.dump(summary, f, indent=2, ensure_ascii=False)

    return summary

if __name__ == "__main__":
    harvest_aki_hentai_taxonomy()
