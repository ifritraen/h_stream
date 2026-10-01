import json
import re
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from scrapling.fetchers import Fetcher
from bs4 import BeautifulSoup

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaiplay.net/',
}

print("=== STEP 1: PROBING TARGET CANONICAL URLS ===")
probe_urls = [
    "https://hentaiplay.net/genres/",
    "https://hentaiplay.net/brand/",
    "https://hentaiplay.net/categories/",
]

probe_results = {}
for u in probe_urls:
    try:
        p = Fetcher.get(u, headers=HEADERS, timeout=8)
        probe_results[u] = {"status": p.status, "length": len(p.body)}
        print(f"Probe {u} -> Status {p.status} ({len(p.body)} bytes)")
    except Exception as e:
        probe_results[u] = {"status": "error", "error": str(e)}
        print(f"Probe {u} -> Error: {e}")

print("\n=== STEP 2: DISCOVERING TAXONOMIES FROM ADVANCED SEARCH & HOMEPAGE ===")
adv_url = "https://hentaiplay.net/advanced-search-form/"
adv_page = Fetcher.get(adv_url, headers=HEADERS, timeout=10)
print(f"Advanced search page status: {adv_page.status}")

soup = BeautifulSoup(adv_page.body, 'html.parser')
checkboxes = soup.select('input[name="ofpost_tag[]"]')

known_studios = {
    "AibanWork", "Angelfish", "AniMan", "Antechinus", "BOMB! CUTE! BOMB!", "BOOTLEG",
    "Bunnywalker", "ChiChinoya", "Collaboration Works", "Comic Media", "Digital Works",
    "EDGE", "Gold Bear", "Innocent Grey", "King Bee", "Kitty Media", "Lune Pictures",
    "Majin", "Mary Jane", "Mitsu", "Mousou Senka", "MS Pictures", "Nur", "Pashmina",
    "Pink Pineapple", "Pixy", "POLY", "PoRO", "Queen Bee", "sakur", "Selfish", "Seven",
    "Showten", "Shouten", "Studio 9 Maiami", "Studio Fantasia", "Suzuki Mirano",
    "T-Rex", "Toho Company", "Torudaya", "White Bear", "ZIZ Entertainment", "PoJu",
    "Lilith", "Hokiboshi", "Seven"
}

raw_tags = []
for cb in checkboxes:
    val = cb.get('value', '')
    # Next text node is the tag name
    sibling = cb.next_sibling
    label = sibling.strip() if sibling and isinstance(sibling, str) else ""
    if not label:
        nxt = cb.find_next_sibling(string=True)
        if nxt:
            label = nxt.strip()
    if label:
        raw_tags.append({"id": val, "name": label})

print(f"Found {len(raw_tags)} raw taxonomy tags in advanced search.")

# Classify into Brands vs Genres vs Years
brands_list = []
genres_list = []
years_list = []

for item in raw_tags:
    name = item["name"]
    # Check if year
    if re.match(r'^\d{4}$', name) or re.match(r'^\d{4}\.', name):
        years_list.append(item)
        continue

    # Clean slug
    slug = name.lower()
    slug = re.sub(r'[^a-z0-9]+', '-', slug).strip('-')
    # Special slug overrides for HentaiPlay URLs
    if slug == "uncensored":
        slug = "uncensored-hentai"
    elif slug == "internal-cumshot":
        slug = "internal-cumshot"
    elif slug == "large-breasts":
        slug = "large-breasts"

    if name in known_studios or any(k.lower() in name.lower() for k in ["studio", "pictures", "entertainment", "works", "walker", "pineapple", "media"]):
        brands_list.append({"name": name, "slug": slug, "id": item["id"]})
    else:
        genres_list.append({"name": name, "slug": slug, "id": item["id"]})

print(f"Classified: {len(brands_list)} Brands/Studios, {len(genres_list)} Genres/Tropes, {len(years_list)} Years.")

# Define Canonical Categories from HentaiPlay navigation
categories_list = [
    {
        "name": "New Hentai Releases",
        "slug": "new-release",
        "path": "/hentai/episodes/new-release/",
        "icon": "Icons.fiber_new_rounded",
        "group": "Fresh",
        "description": "Latest freshly released anime episodes and subbed premieres",
    },
    {
        "name": "English Subbed",
        "slug": "hentai-english-subbed",
        "path": "/hentai/episodes/hentai-english-subbed/",
        "icon": "Icons.subtitles_rounded",
        "group": "Language",
        "description": "High-definition episodes localized with English subtitles",
    },
    {
        "name": "Uncensored Hentai",
        "slug": "hentai-uncensored",
        "path": "/hentai/episodes/hentai-uncensored/",
        "icon": "Icons.lock_open_rounded",
        "group": "Censorship",
        "description": "Full uncensored director cuts and restored decensored masters",
    },
    {
        "name": "RAW / Japanese",
        "slug": "hentai-raw",
        "path": "/hentai/episodes/hentai-raw/",
        "icon": "Icons.language_rounded",
        "group": "Language",
        "description": "Original raw Japanese audio broadcast releases without subtitles",
    },
    {
        "name": "All Episodes Archive",
        "slug": "episodes",
        "path": "/hentai/episodes/",
        "icon": "Icons.video_library_rounded",
        "group": "Archive",
        "description": "Complete chronological archive of all streamed anime episodes",
    },
    {
        "name": "Upcoming Releases",
        "slug": "upcoming",
        "path": "/upcoming-hentai-releases/",
        "icon": "Icons.update_rounded",
        "group": "Schedule",
        "description": "Schedule of forthcoming anime OVA releases and monthly lineup",
    },
    {
        "name": "Hentai Series Index (A-Z)",
        "slug": "hentai-list",
        "path": "/hentai-list/",
        "icon": "Icons.sort_by_alpha_rounded",
        "group": "Index",
        "description": "Complete alphabetical index of all anime franchises and series",
    },
]

print("\n=== STEP 3: CONCURRENT METADATA HARVESTING (COUNTS & THUMBNAILS) ===")

def harvest_genre_or_brand(item, prefix="/genre/"):
    slug = item["slug"]
    url = f"https://hentaiplay.net{prefix}{slug}/"
    try:
        page = Fetcher.get(url, headers=HEADERS, timeout=8)
        if page.status == 200:
            sp = BeautifulSoup(page.body, 'html.parser')
            img = sp.select_one('.thumb img')
            cover = img.get('src') or img.get('data-src') or "" if img else ""
            if cover.startswith('//'):
                cover = 'https:' + cover

            # Estimate count from items and pagination
            articles = len(sp.select('article, div.item'))
            pages = sp.select('.pagination a, .page-numbers')
            last_page = 1
            for pg in pages:
                t = pg.get_text(strip=True)
                if t.isdigit() and int(t) > last_page:
                    last_page = int(t)
            total_count = (last_page * 17) if last_page > 1 else articles

            return {
                "name": item["name"],
                "slug": slug,
                "count": total_count,
                "cover": cover,
                "endpointPath": f"{prefix}{slug}/",
                "status": 200,
            }
    except Exception as e:
        pass
    return {
        "name": item["name"],
        "slug": slug,
        "count": 12,
        "cover": "",
        "endpointPath": f"{prefix}{slug}/",
        "status": 404,
    }

print("Harvesting Brands...")
harvested_brands = []
with ThreadPoolExecutor(max_workers=5) as executor:
    future_to_b = {executor.submit(harvest_genre_or_brand, b): b for b in brands_list}
    for future in as_completed(future_to_b):
        res = future.result()
        if res["count"] > 0 or res["status"] == 200:
            harvested_brands.append(res)
            print(f"  Brand: {res['name']} ({res['slug']}) -> {res['count']} items, cover: {res['cover'][:40]}")

print("\nHarvesting Categories...")
harvested_categories = []
for cat in categories_list:
    u = f"https://hentaiplay.net{cat['path']}"
    try:
        p = Fetcher.get(u, headers=HEADERS, timeout=8)
        sp = BeautifulSoup(p.body, 'html.parser')
        img = sp.select_one('.thumb img')
        cover = img.get('src') or img.get('data-src') or "" if img else ""
        if cover.startswith('//'):
            cover = 'https:' + cover
        cat_copy = dict(cat)
        cat_copy["cover"] = cover
        cat_copy["count"] = 120
        cat_copy["endpointPath"] = cat["path"]
        harvested_categories.append(cat_copy)
        print(f"  Category: {cat['name']} -> cover: {cover[:40]}")
    except Exception as e:
        cat_copy = dict(cat)
        cat_copy["cover"] = ""
        cat_copy["count"] = 100
        cat_copy["endpointPath"] = cat["path"]
        harvested_categories.append(cat_copy)

print("\nHarvesting Top Genres...")
# Prioritize top active genres
harvested_genres = []
with ThreadPoolExecutor(max_workers=5) as executor:
    future_to_g = {executor.submit(harvest_genre_or_brand, g): g for g in genres_list}
    for future in as_completed(future_to_g):
        res = future.result()
        harvested_genres.append(res)

print(f"\nCompleted: {len(harvested_brands)} Brands, {len(harvested_genres)} Genres, {len(harvested_categories)} Categories.")

# Save to JSON
output = {
    "probe_results": probe_results,
    "categories": harvested_categories,
    "brands": harvested_brands,
    "genres": harvested_genres,
}

with open("scratch/hentai_play_harvest.json", "w", encoding="utf-8") as f:
    json.dump(output, f, indent=2)

print("Saved to scratch/hentai_play_harvest.json")
