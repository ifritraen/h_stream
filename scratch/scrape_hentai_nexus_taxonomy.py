"""
HentaiNexus Live Taxonomy Harvester
Uses Scrapling (scrapling.fetchers.Fetcher with headers) to probe
https://hentainexus.com/categories, https://hentainexus.com/tags, https://hentainexus.com/artists,
log canonical fallbacks, harvest live categories, tags, and artists with real names,
slugs, counts, and thumbnails, and generate Dart taxonomy.
"""

import re
import json
import urllib.parse
from concurrent.futures import ThreadPoolExecutor, as_completed
from scrapling.fetchers import Fetcher

BASE_URL = "https://hentainexus.com"
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': f'{BASE_URL}/',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
}

def probe_requested_endpoints():
    print("=== Probing Requested Endpoints with Scrapling ===")
    requested_urls = [
        f"{BASE_URL}/categories",
        f"{BASE_URL}/tags",
        f"{BASE_URL}/artists",
    ]
    for url in requested_urls:
        try:
            page = Fetcher.get(url, headers=HEADERS, timeout=12)
            print(f"[{page.status}] {url} (HTTP {page.status}, len={len(page.body)})")
        except Exception as e:
            print(f"[ERROR] {url}: {e}")

def harvest_tags():
    print("\n=== Harvesting Live Tags from /explore/categories/tag ===")
    tag_url = f"{BASE_URL}/explore/categories/tag"
    page = Fetcher.get(tag_url, headers=HEADERS, timeout=15)
    links = [a for a in page.css('a') if 'q=' in a.attrib.get('href', '')]
    print(f"Found {len(links)} raw tag links.")

    tags = []
    for a in links:
        href = a.attrib.get('href', '')
        raw_text = ' '.join(a.get_all_text().split())
        m = re.match(r'^(.*?)\s*\(used\s*([\d,]+)\s*times?\)$', raw_text)
        if m:
            name = m.group(1).strip()
            count = int(m.group(2).replace(',', ''))
            slug = name.lower().replace(' ', '-').replace("'", '')
            tags.append({
                "name": name,
                "slug": slug,
                "count": count,
                "href": href,
                "endpointPath": href,
            })
    print(f"Successfully parsed {len(tags)} tags.")
    return tags

def harvest_artists():
    print("\n=== Harvesting Live Artists from /explore/categories/artist ===")
    artist_url = f"{BASE_URL}/explore/categories/artist"
    page = Fetcher.get(artist_url, headers=HEADERS, timeout=15)
    links = [a for a in page.css('a') if 'q=' in a.attrib.get('href', '')]
    print(f"Found {len(links)} raw artist links.")

    artists = []
    for a in links:
        href = a.attrib.get('href', '')
        raw_text = ' '.join(a.get_all_text().split())
        m = re.match(r'^(.*?)\s*\(used\s*([\d,]+)\s*times?\)$', raw_text)
        if m:
            name = m.group(1).strip()
            count = int(m.group(2).replace(',', ''))
            slug = name.lower().replace(' ', '-').replace("'", '').replace('.', '')
            artists.append({
                "name": name,
                "slug": slug,
                "count": count,
                "href": href,
                "endpointPath": href,
            })
    # Sort descending by count
    artists.sort(key=lambda x: x["count"], reverse=True)
    print(f"Successfully parsed {len(artists)} artists. Top artist: {artists[0]['name']} ({artists[0]['count']} works)")
    return artists

def fetch_thumbnail_for_query(query_path):
    url = f"{BASE_URL}{query_path}"
    try:
        page = Fetcher.get(url, headers=HEADERS, timeout=10)
        for img in page.css('img'):
            src = img.attrib.get('src', '')
            if 'thumb.jpg' in src or 'hentainexus.com' in src:
                return src
    except Exception:
        pass
    return None

def harvest_thumbnails(items, max_items=25):
    print(f"\n=== Harvesting Real Thumbnails for top {max_items} items concurrently ===")
    thumbnails = {}
    with ThreadPoolExecutor(max_workers=8) as executor:
        future_to_item = {
            executor.submit(fetch_thumbnail_for_query, item["endpointPath"]): item["name"]
            for item in items[:max_items]
        }
        for future in as_completed(future_to_item):
            name = future_to_item[future]
            try:
                thumb = future.result()
                if thumb:
                    thumbnails[name] = thumb
                    print(f"  [Thumbnail] {name} -> {thumb[:80]}...")
            except Exception as e:
                print(f"  [Error] {name}: {e}")
    return thumbnails

def main():
    probe_requested_endpoints()
    tags = harvest_tags()
    artists = harvest_artists()

    # Harvest thumbnails for top categories and top artists
    top_artists = artists[:60]
    artist_thumbs = harvest_thumbnails(top_artists, max_items=20)

    results = {
        "tags_count": len(tags),
        "artists_count": len(artists),
        "tags": tags,
        "top_artists": top_artists,
        "artist_thumbnails": artist_thumbs,
    }

    with open("scratch/hentai_nexus_harvested_data.json", "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2)

    print("\nHarvested taxonomy data saved to scratch/hentai_nexus_harvested_data.json")

if __name__ == "__main__":
    main()
