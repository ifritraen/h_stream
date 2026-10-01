import json
import re
import time
import concurrent.futures
from scrapling.fetchers import Fetcher

BASE_URL = "https://haho.moe"
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://haho.moe/',
    'Cookie': 'loop-view=thumb;',
}

fetcher = Fetcher()

def harvest_formats():
    print("[1/3] Harvesting Formats from https://haho.moe/type & /anime...")
    # Fetch /type
    page = fetcher.get(f"{BASE_URL}/type", headers=HEADERS, timeout=15)
    cards = page.css('ul.loop > li')
    formats = []
    for c in cards:
        href = c.css('a::attr(href)').get() or ''
        title = "".join(c.css('.label ::text, .title ::text, a ::text').getall()).strip()
        slug = href.split('/type/')[-1].split('/')[0].strip()
        if not slug or slug == "unknown":
            continue
        
        # Determine appropriate icon name and description
        desc_map = {
            'tv-series': 'Serialized multi-episode anime television broadcasts',
            'ova': 'Original Video Animations - direct-to-video master releases',
            'movie': 'Theatrical hentai feature films and cinematic presentations',
            'web': 'Original Net Animations and web stream productions',
            'music-video': 'Animated music videos, opening sequences, and character songs',
            'tv-special': 'Television specials, bonus side-stories, and extra releases',
            'other': 'Miscellaneous compilations, promotional clips, and omake',
        }
        
        formats.append({
            'name': title,
            'slug': slug,
            'description': desc_map.get(slug, f"{title} format releases on Haho.moe"),
            'endpoint': f"/type/{slug}",
        })
    print(f"  Harvested {len(formats)} formats.")
    return formats

def harvest_playlists():
    print("[2/3] Harvesting Playlists from https://haho.moe/playlist...")
    playlists = []
    
    def fetch_page(page_num):
        url = f"{BASE_URL}/playlist?page={page_num}" if page_num > 1 else f"{BASE_URL}/playlist"
        page = fetcher.get(url, headers=HEADERS, timeout=15)
        cards = page.css('ul.loop > li')
        results = []
        for c in cards:
            title = c.css('.playlist-title::text').get()
            if not title:
                continue
            title = title.strip()
            href = c.css('.playlist-title::attr(href)').get() or ''
            slug = href.split('/playlist/')[-1].split('/')[0].strip()
            
            img = c.css('img.playlist-cover-image::attr(src)').get() or ''
            if img and not img.startswith('http'):
                img = f"{BASE_URL}{img}"
                
            user = c.css('.playlist-user a::text').get() or ''
            user = user.strip()
            
            count_text = c.css('.playlist-video-count::text').get() or ''
            count = 0
            if count_text:
                digits = "".join(filter(str.isdigit, count_text))
                if digits:
                    count = int(digits)
                    
            results.append({
                'name': title,
                'slug': slug,
                'user': user,
                'count': count,
                'image': img,
                'description': f"Curated by {user} • {count} videos" if user else f"{count} videos",
                'endpoint': f"/playlist/{slug}",
            })
        return results

    with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
        futures = {executor.submit(fetch_page, p): p for p in range(1, 6)}
        for f in concurrent.futures.as_completed(futures):
            playlists.extend(f.result())

    # Sort playlists by video count descending
    playlists.sort(key=lambda x: x['count'], reverse=True)
    print(f"  Harvested {len(playlists)} playlists.")
    return playlists

def harvest_genres():
    print("[3/3] Harvesting Genres from https://haho.moe/genre...")
    genres = []
    
    def fetch_page(page_num):
        url = f"{BASE_URL}/genre?page={page_num}" if page_num > 1 else f"{BASE_URL}/genre"
        page = fetcher.get(url, headers=HEADERS, timeout=15)
        cards = page.css('ul.loop > li')
        results = []
        for c in cards:
            a = c.css('a')
            if not a:
                continue
            href = a.css('::attr(href)').get() or ''
            title = a.css('::attr(title)').get() or c.css('.thumb-title::text').get() or ''
            title = title.strip()
            desc = a.css('::attr(data-content)').get() or ''
            desc = desc.strip()
            if desc == "No description.":
                desc = ""
            img = c.css('img::attr(src)').get() or ''
            if img and not img.startswith('http'):
                img = f"{BASE_URL}{img}"
            slug = href.split('/genre/')[-1].split('/')[0].strip()
            
            results.append({
                'name': title,
                'slug': slug,
                'description': desc if desc else f"Haho.moe {title} anime category",
                'image': img,
                'has_real_image': not ('placeholder' in img or not img),
                'endpoint': f"/genre/{slug}",
            })
        return results

    with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
        futures = {executor.submit(fetch_page, p): p for p in range(1, 30)}
        for f in concurrent.futures.as_completed(futures):
            genres.extend(f.result())

    # Deduplicate by slug
    seen = set()
    unique_genres = []
    for g in genres:
        if g['slug'] and g['slug'] not in seen:
            seen.add(g['slug'])
            unique_genres.append(g)

    # Sort alphabetically by name
    unique_genres.sort(key=lambda x: x['name'].lower())
    print(f"  Harvested {len(unique_genres)} unique genres.")
    return unique_genres

if __name__ == "__main__":
    t0 = time.time()
    formats = harvest_formats()
    playlists = harvest_playlists()
    genres = harvest_genres()
    
    output = {
        'formats': formats,
        'playlists': playlists,
        'genres': genres,
        'counts': {
            'formats': len(formats),
            'playlists': len(playlists),
            'genres': len(genres),
        }
    }
    
    with open("d:/C/H/scratch/haho_moe_harvested.json", "w", encoding="utf-8") as f:
        json.dump(output, f, indent=2, ensure_ascii=False)
        
    print(f"Harvest complete in {time.time() - t0:.2f}s!")
    print(f"Summary: Formats={len(formats)}, Playlists={len(playlists)}, Genres={len(genres)}")
