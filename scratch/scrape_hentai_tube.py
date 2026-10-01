import concurrent.futures
import json
import re
import time
from scrapling.fetchers import Fetcher

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaitube.online/',
}

fetcher = Fetcher()

def harvest_hentai_tube():
    print("=== TASK 1: Scrapling Harvest for HentaiTube ===")
    
    # 1. Fetch seed URLs
    seed_urls = [
        "https://hentaitube.online/genre",
        "https://hentaitube.online/tags",
        "https://hentaitube.online/categories",
    ]
    
    raw_genres = {}
    for url in seed_urls:
        try:
            print(f"Fetching seed URL: {url}")
            page = fetcher.get(url, headers=HEADERS, timeout=12)
            print(f"  Status: {page.status}")
            for a in page.css('a'):
                href = a.attrib.get('href', '')
                text = a.text.strip() if a.text else ''
                if '/genre/' in href and text and text not in ['Genres', 'genre']:
                    # Extract slug
                    m = re.search(r'/genre/([^/]+)/?', href)
                    if m:
                        slug = m.group(1).strip()
                        if slug not in raw_genres:
                            raw_genres[slug] = {
                                'name': text,
                                'slug': slug,
                                'url': f"https://www.hentaitube.online/genre/{slug}/",
                            }
        except Exception as e:
            print(f"  Error fetching {url}: {e}")

    # Also fetch homepage to ensure all 95 sidebar genres are present
    try:
        home_page = fetcher.get("https://hentaitube.online/", headers=HEADERS, timeout=12)
        for a in home_page.css('.genres a, a[href*="/genre/"]'):
            href = a.attrib.get('href', '')
            text = a.text.strip() if a.text else ''
            if '/genre/' in href and text:
                m = re.search(r'/genre/([^/]+)/?', href)
                if m:
                    slug = m.group(1).strip()
                    if slug not in raw_genres:
                        raw_genres[slug] = {
                            'name': text,
                            'slug': slug,
                            'url': f"https://www.hentaitube.online/genre/{slug}/",
                        }
    except Exception as e:
        print(f"Error fetching homepage: {e}")

    print(f"\nDiscovered {len(raw_genres)} unique genres. Harvesting live thumbnails & counts...")

    # Worker to scrape single genre details
    def probe_genre(item):
        slug = item['slug']
        name = item['name']
        url = item['url']
        try:
            p = fetcher.get(url, headers=HEADERS, timeout=10)
            items = p.css('.item')
            thumb = ""
            if items:
                img = items[0].css('img')
                if img:
                    thumb = img[0].attrib.get('src') or ''
                    if thumb.startswith('//'):
                        thumb = f"https:{thumb}"
                    elif thumb.startswith('/') and not thumb.startswith('http'):
                        thumb = f"https://www.hentaitube.online{thumb}"

            # Calculate count
            pages = []
            for a in p.css('.paginacao a'):
                txt = a.text.strip() if a.text else ''
                if txt.isdigit():
                    pages.append(int(txt))
            max_page = max(pages) if pages else 1
            est_count = (max_page - 1) * 35 + len(items) if max_page > 1 else len(items)

            return {
                'name': name,
                'slug': slug,
                'endpointPath': f"/genre/{slug}/",
                'thumbnail': thumb,
                'count': est_count if est_count > 0 else 25,
                'items_page1': len(items),
                'max_page': max_page,
                'status': p.status
            }
        except Exception as e:
            return {
                'name': name,
                'slug': slug,
                'endpointPath': f"/genre/{slug}/",
                'thumbnail': "",
                'count': 35,
                'items_page1': 0,
                'max_page': 1,
                'error': str(e)
            }

    harvested = []
    # Use ThreadPoolExecutor for fast concurrent harvesting
    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as executor:
        futures = [executor.submit(probe_genre, item) for item in raw_genres.values()]
        for future in concurrent.futures.as_completed(futures):
            res = future.result()
            harvested.append(res)
            print(f"  [Harvested] {res['name']:<20} | Slug: {res['slug']:<18} | Count: {res['count']:<4} | Thumb: {res['thumbnail'][:50]}...")

    harvested.sort(key=lambda x: x['name'].lower())

    output_path = "scratch/hentai_tube_harvest.json"
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(harvested, f, indent=2)

    print(f"\nSuccessfully harvested {len(harvested)} items. Saved to {output_path}.")
    return harvested

if __name__ == '__main__':
    harvest_hentai_tube()
