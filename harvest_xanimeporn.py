import html
import json
import re
from scrapling.fetchers import Fetcher
from bs4 import BeautifulSoup

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://xanimeporn.com/',
}

print("=== Task 1: Scraping live taxonomy data from Xanimeporn ===")

# 1. Probe canonical endpoints requested
probe_targets = [
    'https://xanimeporn.com/categories/',
    'https://xanimeporn.com/tags/',
    'https://xanimeporn.com/hentai-series/',
    'https://xanimeporn.com/hentai-list/',
    'https://xanimeporn.com/channels/',
    'https://xanimeporn.com/top-10/',
    'https://xanimeporn.com/uncensored/',
    'https://xanimeporn.com/category-sitemap.xml',
    'https://xanimeporn.com/sitemap_index.xml',
]

for target in probe_targets:
    try:
        res = Fetcher.get(target, headers=headers)
        print(f"Target: {target} -> Final: {res.url} (Status: {res.status}, Len: {len(res.body)})")
    except Exception as e:
        print(f"Target: {target} -> Error: {e}")

# 2. Extract Category URLs from category-sitemap.xml
print("\n--- Probing category-sitemap.xml ---")
cat_sitemap = Fetcher.get('https://xanimeporn.com/category-sitemap.xml', headers=headers)
import xml.etree.ElementTree as ET
root = ET.fromstring(cat_sitemap.body)
category_urls = [loc.text for elem in root for loc in elem.findall('{http://www.sitemaps.org/schemas/sitemap/0.9}loc')]
print(f"Found {len(category_urls)} categories in category-sitemap.xml")

# 3. For each category, scrape name, slug, authentic video count, and thumbnail
categories_data = []
category_covers = {}

for u in category_urls:
    slug = u.rstrip('/').split('/')[-1]
    res = Fetcher.get(u, headers=headers)
    soup = BeautifulSoup(res.body, 'html.parser')
    
    # H1 format: "All videos in category Action (98 videos)"
    h1 = soup.find('h1')
    h1_text = h1.text.strip() if h1 else ""
    
    # Extract name and count
    m = re.search(r'category\s+([^(]+?)\s*\(([0-9,]+)\s*videos?\)', h1_text, re.I)
    if m:
        name = m.group(1).strip()
        count = int(m.group(2).replace(',', ''))
    else:
        name = slug.replace('-', ' ').title()
        count = 0
        
    # Extract first video thumbnail as representative cover
    cover = ""
    for it in soup.select('ul.listing-tube > li, li.box-shadow, article, .post, .item'):
        img = it.find('img')
        if img:
            src = img.get('data-lazy-src') or img.get('data-src') or img.get('src') or ''
            if src.startswith('http') and not src.endswith('.svg') and 'wp-content/uploads' in src:
                cover = src
                break
                
    if cover:
        category_covers[slug] = cover
        
    categories_data.append({
        'name': name,
        'slug': slug,
        'count': count,
        'cover': cover,
        'endpointPath': f'/{slug}/',
    })
    print(f"Scraped Category: {name} (/{slug}/) -> Count: {count}, Cover: {cover[:60]}...")

print(f"\nTotal category covers acquired: {len(category_covers)}/{len(categories_data)}")

# 4. Scrape Hentai Series from hentai-list
print("\n--- Harvesting Hentai Series from /hentai-list/ ---")
res_list = Fetcher.get('https://xanimeporn.com/hentai-list/', headers=headers)
soup_list = BeautifulSoup(res_list.body, 'html.parser')

known_cat_slugs = set(c['slug'] for c in categories_data) | {'hentai-list', 'hentai-series', 'top-10', 'contact-us', 'dmca', 'privacy-policy', 'terms', 'terms-and-conditions'}

series_data = []
for a in soup_list.find_all('a'):
    href = a.get('href', '')
    text = a.get_text(strip=True)
    if 'xanimeporn.com/' in href:
        m = re.match(r'https?://(?:www\.)?xanimeporn\.com/([a-zA-Z0-9_\-]+)/?$', href)
        if m:
            slug = m.group(1)
            if slug not in known_cat_slugs and text:
                clean_name = html.unescape(text).strip().replace('\ufffd', "'").replace('–', '-').replace('—', '-')
                series_data.append({
                    'name': clean_name,
                    'slug': slug,
                    'endpointPath': f'/{slug}/',
                })

print(f"Total Hentai Series scraped: {len(series_data)}")

# Save JSON results
with open('xanimeporn_harvest_raw.json', 'w', encoding='utf-8') as f:
    json.dump({
        'categories': categories_data,
        'category_covers': category_covers,
        'series_count': len(series_data),
        'series': series_data,
    }, f, indent=2, ensure_ascii=False)

print("\nHarvest finished successfully! Saved to xanimeporn_harvest_raw.json.")
