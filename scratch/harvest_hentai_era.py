import json
import re
import html
from scrapling.fetchers import Fetcher
from bs4 import BeautifulSoup

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaiera.com/',
}

print("=== 1. HARVESTING CATEGORIES ===")
# Fetch categories landing page
cat_page = Fetcher.get('https://hentaiera.com/categories/', headers=headers)
print(f"Categories landing page status: {cat_page.status}")

# Harvest canonical categories
canonical_cats = [
    {
        "name": "Doujinshi",
        "slug": "doujinshi",
        "path": "/category/doujinshi/",
        "icon": "Icons.menu_book_rounded",
        "group": "Format",
        "desc": "Fan-made and indie doujinshi manga publications and parodies",
    },
    {
        "name": "Manga",
        "slug": "manga",
        "path": "/category/manga/",
        "icon": "Icons.auto_stories_rounded",
        "group": "Format",
        "desc": "Commercial and serialized Japanese hentai tankoubon & chapters",
    },
    {
        "name": "Western",
        "slug": "western",
        "path": "/category/western/",
        "icon": "Icons.public_rounded",
        "group": "Format",
        "desc": "Western 3D CGI, comics, and full-color adult graphic novels",
    },
    {
        "name": "Image Set",
        "slug": "image-set",
        "path": "/category/image-set/",
        "icon": "Icons.photo_library_rounded",
        "group": "Format",
        "desc": "High-resolution CG illustration packs, artbooks, and pin-up sets",
    },
]

categories_data = []
for c in canonical_cats:
    url = f"https://hentaiera.com{c['path']}"
    res = Fetcher.get(url, headers=headers)
    print(f"Fetched {url} -> {res.status}")
    soup = BeautifulSoup(res.body, 'html.parser')
    
    # Extract total count from h1 (e.g. "Read all 534,370DoujinshiXXX Galleries")
    count = 0
    h1 = soup.find('h1')
    if h1:
        match = re.search(r'([\d,]+)', h1.get_text())
        if match:
            count = int(match.group(1).replace(',', ''))
    
    # Extract poster cover from first item
    first_thumb = soup.select_one('.thumb img')
    cover = ""
    if first_thumb:
        cover = first_thumb.get('data-src') or first_thumb.get('src') or ""
    
    categories_data.append({
        "name": c["name"],
        "slug": c["slug"],
        "count": count,
        "cover": cover,
        "endpointPath": c["path"],
        "icon": c["icon"],
        "categoryGroup": c["group"],
        "description": c["desc"],
    })

# Add top curated explore sections
categories_data.insert(0, {
    "name": "Latest Releases",
    "slug": "latest",
    "count": sum(c["count"] for c in categories_data),
    "cover": categories_data[0]["cover"],
    "endpointPath": "/",
    "icon": "Icons.fiber_new_rounded",
    "categoryGroup": "Browse",
    "description": "Freshest manga, doujinshi, and western comic releases",
})

print(f"Categories harvested: {len(categories_data)}")
for c in categories_data:
    print(f" - {c['name']} ({c['slug']}): count={c['count']:,}, cover={c['cover']}")

print("\n=== 2. HARVESTING TAGS ===")
tags_data = []
seen_slugs = set()

# Fetch from /tags/popular/ across multiple pages
pages_to_fetch = 8  # 8 pages * 25 = 200 top popular tags
for page_num in range(1, pages_to_fetch + 1):
    url = f"https://hentaiera.com/tags/popular/?page={page_num}" if page_num > 1 else "https://hentaiera.com/tags/popular/"
    res = Fetcher.get(url, headers=headers)
    print(f"Fetched {url} -> {res.status}")
    soup = BeautifulSoup(res.body, 'html.parser')
    thumbs = soup.select('.row.galleries .thumb')
    
    for t in thumbs:
        title_a = t.select_one('.gallery_title a')
        if not title_a: continue
        name = title_a.get_text(strip=True)
        href = title_a.get('href', '')
        # slug from /tag/<slug>/
        slug_match = re.search(r'/tag/([^/]+)/', href)
        slug = slug_match.group(1) if slug_match else name.lower().replace(' ', '-')
        
        if slug in seen_slugs:
            continue
        seen_slugs.add(slug)
        
        count_el = t.select_one('.inside_p')
        count = 0
        if count_el:
            c_text = count_el.get_text(strip=True).replace(',', '')
            if c_text.isdigit():
                count = int(c_text)
        
        img = t.select_one('img')
        cover = img.get('data-src') or img.get('src') or "" if img else ""
        
        tags_data.append({
            "name": name,
            "slug": slug,
            "count": count,
            "cover": cover,
            "endpointPath": f"/tag/{slug}/",
        })

print(f"Total tags harvested: {len(tags_data)}")

# Save scraped raw JSON
with open('scratch/hentaiera_harvest.json', 'w', encoding='utf-8') as f:
    json.dump({
        "categories": categories_data,
        "tags": tags_data,
    }, f, indent=2)

print("Saved to scratch/hentaiera_harvest.json")
