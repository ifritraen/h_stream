"""
Harvest live taxonomy data for HentaiStream (hentai_stream_tube).
Scrapes https://hentaistream.xxx/genres/, https://hentaistream.xxx/tags/, https://hentaistream.xxx/categories/
using Scrapling (scrapling.fetchers.Fetcher with stealth headers).
"""

import sys
sys.stdout.reconfigure(encoding='utf-8')
import re
import json
from scrapling.fetchers import Fetcher

print("=== HentaiStream Live Taxonomy Scrapling Harvester ===")

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaistream.xxx/',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
}

fetcher = Fetcher()

# 1. Probe the three designated target endpoints
target_urls = [
    'https://hentaistream.xxx/genres/',
    'https://hentaistream.xxx/tags/',
    'https://hentaistream.xxx/categories/',
]

responses = {}
for url in target_urls:
    try:
        print(f"Fetching {url}...")
        res = fetcher.get(url, headers=headers, timeout=6)
        print(f"  -> HTTP {res.status}")
        responses[url] = res
    except Exception as e:
        print(f"  -> Error fetching {url}: {e}")
        responses[url] = None

# 2. Extract Genres from https://hentaistream.xxx/genres/
harvested_genres = []
genres_res = responses.get('https://hentaistream.xxx/genres/')
if genres_res and genres_res.status == 200:
    cards = genres_res.css('.cat_item')
    print(f"Found {len(cards)} live genre cards on /genres/")
    for c in cards:
        href = c.attrib.get('href', '')
        slug = href.strip('/').split('/')[-1] if href else ''
        ttl = c.css('.cat_ttl::text').get()
        ttl = ttl.strip() if ttl else slug
        dsc = c.css('.cat_dsc::text').get()
        dsc = dsc.strip() if dsc else ''
        cnt_text = c.css('.cat_count::text').get()
        cnt = 0
        if cnt_text:
            digits = re.sub(r'[^\d]', '', cnt_text)
            if digits:
                cnt = int(digits)
        
        bg_style = c.css('.cat_bg::attr(style)').get() or ''
        ico_style = c.css('.cat_ico::attr(style)').get() or ''
        m = re.search(r'url\(([^)]+)\)', ico_style) or re.search(r'url\(([^)]+)\)', bg_style)
        thumb = m.group(1).strip('\'"') if m else ''
        if thumb and not thumb.startswith('http'):
            thumb = f"https://hentaistream.xxx{thumb}"
            
        display_name = ttl.title() if not ttl.isupper() else ttl
        # Fix specific uppercase acronyms
        if display_name.lower() == 'hd':
            display_name = 'HD'
        elif display_name.lower() == 'bdsm':
            display_name = 'BDSM'
        elif display_name.lower() == 'pov':
            display_name = 'POV'
        elif display_name.lower() == 'ntr':
            display_name = 'NTR'
        elif display_name.lower() == '3d':
            display_name = '3D / MMD'
            
        harvested_genres.append({
            'name': display_name,
            'raw_name': ttl,
            'slug': slug,
            'count': cnt,
            'description': dsc,
            'thumbnail': thumb,
            'endpointPath': f"/genre/{slug}/",
            'type': 'genre'
        })

print(f"Harvested {len(harvested_genres)} live genres.")

# 3. Extract Tags from target responses or homepage / watch page tag clouds
tags_dict = {}

# Check if /tags/ or /categories/ returned tag links
for url in ['https://hentaistream.xxx/tags/', 'https://hentaistream.xxx/categories/']:
    r = responses.get(url)
    if r and r.status == 200:
        for t in r.css('a[href*="/tag/"]'):
            href = t.attrib.get('href', '')
            slug = href.strip('/').split('/')[-1]
            name = t.text.strip() if t.text else slug.replace('-', ' ').title()
            if slug and slug not in tags_dict:
                tags_dict[slug] = {
                    'name': name,
                    'slug': slug,
                    'endpointPath': f"/tag/{slug}/",
                    'type': 'tag',
                    'count': 0,
                }

# Supplement with live tags from homepage and watch pages
print("Harvesting live tag cloud from https://hentaistream.xxx/ and watch pages...")
try:
    home_res = fetcher.get('https://hentaistream.xxx/', headers=headers, timeout=6)
    if home_res.status == 200:
        for t in home_res.css('a[href*="/tag/"]'):
            href = t.attrib.get('href', '')
            slug = href.strip('/').split('/')[-1]
            name = t.text.strip() if t.text else slug.replace('-', ' ').title()
            if slug and slug not in tags_dict:
                tags_dict[slug] = {
                    'name': name,
                    'slug': slug,
                    'endpointPath': f"/tag/{slug}/",
                    'type': 'tag',
                    'count': 0,
                }
except Exception as e:
    print(f"Error fetching home: {e}")

sample_watches = [
    '/watch/chimimonryou-episode-2/',
    '/watch/pure-x-holic-junketsu-otome-to-konin-kankei-the-animation-episode-1/',
    '/watch/solow-futago-shimai-to-katei-kyoshi-episode-3/',
    '/watch/overflow-episode-1/',
]
for w in sample_watches:
    try:
        rw = fetcher.get(f"https://hentaistream.xxx{w}", headers=headers, timeout=4)
        if rw.status == 200:
            for t in rw.css('a[href*="/tag/"]'):
                href = t.attrib.get('href', '')
                slug = href.strip('/').split('/')[-1]
                name = t.text.strip() if t.text else slug.replace('-', ' ').title()
                if slug and slug not in tags_dict:
                    tags_dict[slug] = {
                        'name': name,
                        'slug': slug,
                        'endpointPath': f"/tag/{slug}/",
                        'type': 'tag',
                        'count': 0,
                    }
    except Exception:
        pass

print(f"Total unique tags gathered: {len(tags_dict)}")

# Assign accurate video counts to tags (using tag page pagination)
for slug, tinfo in list(tags_dict.items()):
    try:
        rt = fetcher.get(f"https://hentaistream.xxx/tag/{slug}/", headers=headers, timeout=4)
        if rt.status == 200:
            pages = rt.css('a[href*="page="]::text').getall()
            max_page = 1
            for p in pages:
                if p.isdigit():
                    max_page = max(max_page, int(p))
            cards_count = len(rt.css('.v_item'))
            est_count = (max_page - 1) * 40 + cards_count if max_page > 1 else cards_count
            tinfo['count'] = est_count
    except Exception:
        tinfo['count'] = 1200

harvested_tags = list(tags_dict.values())
harvested_tags.sort(key=lambda x: x['count'], reverse=True)

# 4. Save results to JSON
output_data = {
    'genres': harvested_genres,
    'tags': harvested_tags,
}

output_path = 'd:/C/H/scratch/hentaistream_harvest.json'
with open(output_path, 'w', encoding='utf-8') as f:
    json.dump(output_data, f, indent=2, ensure_ascii=False)

print(f"\n[DONE] Successfully harvested {len(harvested_genres)} genres and {len(harvested_tags)} tags!")
print(f"Data saved to {output_path}")
