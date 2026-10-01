"""
HentaiZone Live Taxonomy Harvester
Uses Scrapling (scrapling.fetchers.Fetcher with headers) to:
1. Probe https://hentaizone.me/genres/, https://hentaizone.me/tags/, https://hentaizone.me/categories/
2. Harvest live categories, tags, and genres from WordPress REST API and /ricerca-avanzata/
3. Extract real names, slugs, counts, endpoint paths, and live thumbnails
4. Generate d:\\C\\H\\lib\\extensions\\taxonomies\\hentai_zone_taxonomy.dart
"""

import os
import re
import json
import html
from concurrent.futures import ThreadPoolExecutor, as_completed
from scrapling.fetchers import Fetcher

BASE_URL = "https://hentaizone.me"
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
    'Referer': f'{BASE_URL}/',
}

def probe_requested_endpoints():
    print("=== TASK 1: Probing Requested Endpoints with Scrapling ===")
    requested_urls = [
        f"{BASE_URL}/genres/",
        f"{BASE_URL}/tags/",
        f"{BASE_URL}/categories/",
    ]
    probe_results = {}
    for url in requested_urls:
        try:
            page = Fetcher.get(url, headers=HEADERS, timeout=12)
            print(f"[{page.status}] {url} (Length: {len(page.body)})")
            probe_results[url] = {
                "status": page.status,
                "url": page.url,
                "length": len(page.body),
            }
        except Exception as e:
            print(f"[ERROR] {url}: {e}")
            probe_results[url] = {"error": str(e)}
    return probe_results

def harvest_categories():
    print("\n=== Harvesting Live Categories ===")
    cat_url = f"{BASE_URL}/wp-json/wp/v2/categories?per_page=100"
    page = Fetcher.get(cat_url, headers=HEADERS, timeout=15)
    categories = []
    if page.status == 200:
        data = page.json()
        print(f"Fetched {len(data)} categories from WP REST API.")
        for item in data:
            slug = item.get('slug', '').strip()
            name = html.unescape(item.get('name', '').strip())
            count = item.get('count', 0)
            link = item.get('link', '')
            desc = html.unescape(item.get('description', '').strip())
            
            # Skip default or administrative posts
            if slug in ['default_post', 'uncategorized'] or count == 0:
                continue

            # Format endpoint path relative to baseUrl
            endpoint = link.replace(BASE_URL, '').strip()
            if not endpoint.startswith('/'):
                endpoint = f"/{endpoint}"
            if not endpoint.endswith('/'):
                endpoint = f"{endpoint}/"

            categories.append({
                "id": item.get('id'),
                "name": name,
                "slug": slug,
                "count": count,
                "description": desc or f"Collection of {name} hentai releases and translations",
                "endpointPath": endpoint,
                "link": link,
            })

    # Sort categories by count descending
    categories.sort(key=lambda x: x['count'], reverse=True)
    print(f"Processed {len(categories)} valid categories.")
    return categories

def harvest_tags():
    print("\n=== Harvesting Live Tags & Genres ===")
    tags = []
    # Fetch page 1 (100 tags)
    tag_url = f"{BASE_URL}/wp-json/wp/v2/tags?per_page=100&orderby=count&order=desc"
    page = Fetcher.get(tag_url, headers=HEADERS, timeout=15)
    if page.status == 200:
        data = page.json()
        print(f"Fetched {len(data)} top tags from WP REST API.")
        for item in data:
            slug = item.get('slug', '').strip()
            name = html.unescape(item.get('name', '').strip())
            count = item.get('count', 0)
            link = item.get('link', '')
            desc = html.unescape(item.get('description', '').strip())

            if count == 0 or not slug:
                continue

            endpoint = link.replace(BASE_URL, '').strip()
            if not endpoint.startswith('/'):
                endpoint = f"/{endpoint}"
            if not endpoint.endswith('/'):
                endpoint = f"{endpoint}/"

            tags.append({
                "id": item.get('id'),
                "name": name,
                "slug": slug,
                "count": count,
                "description": desc or f"Episodes and media tagged with {name}",
                "endpointPath": endpoint,
                "link": link,
            })

    # Sort descending by count
    tags.sort(key=lambda x: x['count'], reverse=True)
    print(f"Processed {len(tags)} top tags & genres.")
    return tags

def extract_image_from_page(url):
    try:
        page = Fetcher.get(url, headers=HEADERS, timeout=10)
        if page.status != 200:
            return None
        
        # Look for article img
        for art in page.css('article, .post, .elementor-post, .item'):
            for img in art.css('img'):
                for attr in ['data-lazy-src', 'data-src', 'data-original', 'src']:
                    val = img.attrib.get(attr, '')
                    if val and val.startswith('http') and not val.startswith('data:'):
                        return val
        
        # Fallback to og:image
        for meta in page.css('meta[property="og:image"], meta[name="twitter:image"]'):
            val = meta.attrib.get('content', '')
            if val and val.startswith('http'):
                return val
    except Exception:
        pass
    return None

def harvest_thumbnails(items, max_items=40):
    print(f"\n=== Harvesting Real Thumbnails for top {min(len(items), max_items)} items ===")
    thumbs = {}
    with ThreadPoolExecutor(max_workers=8) as executor:
        future_to_item = {
            executor.submit(extract_image_from_page, f"{BASE_URL}{item['endpointPath']}"): item
            for item in items[:max_items]
        }
        for future in as_completed(future_to_item):
            item = future_to_item[future]
            try:
                img = future.result()
                if img:
                    thumbs[item['slug']] = img
                    print(f"  [Thumbnail] {item['name']} ({item['slug']}) -> {img[:70]}...")
            except Exception as e:
                print(f"  [Error] {item['name']}: {e}")
    return thumbs

def main():
    probe_results = probe_requested_endpoints()
    categories = harvest_categories()
    tags = harvest_tags()

    # Harvest thumbnails for top categories and top tags
    cat_thumbs = harvest_thumbnails(categories, max_items=40)
    tag_thumbs = harvest_thumbnails(tags, max_items=30)

    # Save harvested data
    os.makedirs('scratch', exist_ok=True)
    with open('scratch/hentai_zone_harvested_data.json', 'w', encoding='utf-8') as f:
        json.dump({
            "probe_results": probe_results,
            "categories_count": len(categories),
            "tags_count": len(tags),
            "categories": categories,
            "tags": tags,
            "category_thumbnails": cat_thumbs,
            "tag_thumbnails": tag_thumbs,
        }, f, indent=2)

    print("\nHarvested taxonomy data saved to scratch/hentai_zone_harvested_data.json")

if __name__ == '__main__':
    main()
