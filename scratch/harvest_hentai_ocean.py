import json
import re
import time
import concurrent.futures
from scrapling.fetchers import Fetcher

BASE_URL = 'https://hentaiocean.com'
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaiocean.com/',
}

fetcher = Fetcher()

print('[1/4] Probing canonical endpoints: /genre, /playlists, /series...')
probe_results = {}
for path in ['/genre', '/playlists', '/series']:
    url = f'{BASE_URL}{path}'
    res = fetcher.get(url, headers=HEADERS, timeout=12)
    probe_results[path] = {
        'status': res.status,
        'final_url': res.url,
        'bytes': len(res.body),
    }
    print(f'  {url} -> Status: {res.status}, Final: {res.url}')

print('[2/4] Harvesting live genres from /genre...')
genre_page = fetcher.get(f'{BASE_URL}/genre', headers=HEADERS, timeout=15)
genre_links = genre_page.css('a[href*=\"/genre/\"]')

raw_genres = {}
for g in genre_links:
    href = g.attrib.get('href') or ''
    name = g.get_all_text().strip()
    slug = href.split('/genre/')[-1].strip()
    clean_name = re.sub(r'\s+Hentai$', '', name).strip()
    clean_slug = re.sub(r'%20', ' ', slug).strip()
    if clean_name not in raw_genres:
        raw_genres[clean_name] = clean_slug

print(f'  Found {len(raw_genres)} unique genre entries. Harvesting video counts & thumbnails...')

def probe_single_genre(item):
    name, slug = item
    url = f'{BASE_URL}/genre/{slug}'
    try:
        res = fetcher.get(url, headers=HEADERS, timeout=15)
        cards = res.css('a.cell.card, a.card, .grid a[href*=\"/watch/\"]')
        count = len(cards)
        cover = ''
        if cards:
            cover = cards[0].css('img::attr(src)').get() or ''
        return {
            'name': name,
            'slug': slug,
            'count': count,
            'thumbnail': cover,
            'endpointPath': f'/genre/{slug}',
        }
    except Exception as e:
        return {
            'name': name,
            'slug': slug,
            'count': 0,
            'thumbnail': '',
            'endpointPath': f'/genre/{slug}',
        }

harvested_genres = []
with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
    results = list(executor.map(probe_single_genre, raw_genres.items()))
    harvested_genres.extend(results)

harvested_genres.sort(key=lambda x: (-x['count'], x['name'].lower()))
print(f'  Successfully harvested {len(harvested_genres)} genres!')

print('[3/4] Harvesting Playlists & Serialized Series from sitemap & recent API...')
sitemap_res = fetcher.get(f'{BASE_URL}/sitemap.xml', headers=HEADERS, timeout=15)
watch_slugs = re.findall(r'<loc>https://hentaiocean\.com/watch/(.*?)</loc>', sitemap_res.body.decode('utf-8', errors='ignore'))

api_res = fetcher.get(f'{BASE_URL}/api?action=recent', headers=HEADERS, timeout=15)
api_data = json.loads(api_res.body.decode('utf-8', errors='ignore'))
api_map = {item['urlname']: item for item in api_data if 'urlname' in item}

series_groups = {}
for s in watch_slugs:
    m = re.match(r'^(.*?)-(\d+)$', s)
    if m:
        base = m.group(1)
        ep = int(m.group(2))
    else:
        base = s
        ep = 1
    series_groups.setdefault(base, []).append((ep, s))

print(f'  Found {len(series_groups)} franchises.')

harvested_playlists = []
for base_slug, eps in series_groups.items():
    eps.sort(key=lambda x: x[0])
    ep_count = len(eps)
    first_ep_slug = eps[0][1]
    last_ep_slug = eps[-1][1]
    
    meta = api_map.get(first_ep_slug) or api_map.get(last_ep_slug) or {}
    videoname = meta.get('videoname', '')
    if videoname:
        clean_title = re.sub(r'\s+\d+$', '', videoname).strip()
    else:
        clean_title = ' '.join(w.capitalize() for w in base_slug.split('-'))

    coverimg = meta.get('coverimg', '')
    if coverimg:
        thumbnail = f'{BASE_URL}/assets/cover/{coverimg}'
    else:
        thumbnail = f'{BASE_URL}/thumbnail/{first_ep_slug}.webp'

    harvested_playlists.append({
        'name': clean_title,
        'slug': base_slug,
        'episodes': ep_count,
        'first_episode_slug': first_ep_slug,
        'thumbnail': thumbnail,
        'endpointPath': f'/watch/{first_ep_slug}',
        'description': f'Complete serialized collection • {ep_count} episodes' if ep_count > 1 else 'Feature standalone release • 1 episode',
    })

harvested_playlists.sort(key=lambda x: (-x['episodes'], x['name'].lower()))
print(f'  Harvested {len(harvested_playlists)} series & playlist entries!')

output = {
    'probes': probe_results,
    'genres': harvested_genres,
    'playlists': harvested_playlists,
    'summary': {
        'total_genres': len(harvested_genres),
        'total_playlists': len(harvested_playlists),
    }
}

with open('d:/C/H/scratch/hentai_ocean_harvested.json', 'w', encoding='utf-8') as f:
    json.dump(output, f, indent=2, ensure_ascii=False)

print('Done! Harvest saved to d:/C/H/scratch/hentai_ocean_harvested.json')
