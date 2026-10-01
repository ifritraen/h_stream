import re
import json
import time
from bs4 import BeautifulSoup
from concurrent.futures import ThreadPoolExecutor, as_completed
from scrapling.fetchers import Fetcher

with open('scratch/genres.html', 'r', encoding='utf-8', errors='ignore') as f:
    soup = BeautifulSoup(f.read(), 'html.parser')

genre_cards = soup.find_all('a', href=re.compile(r'/archive\?genre='))
raw_genres = []
seen = set()

for a in genre_cards:
    href = a.get('href', '')
    m = re.search(r'genre=([a-zA-Z0-9_\-]+)', href)
    if not m:
        continue
    slug = m.group(1)
    if slug in seen:
        continue
    seen.add(slug)
    
    h3 = a.find('h3')
    name = h3.get_text().strip() if h3 else slug.replace('-', ' ').title()
    p = a.find('p')
    desc = p.get_text().strip() if p else f"{name} anime series and episodes"
    
    raw_genres.append({
        'slug': slug,
        'name': name,
        'description': desc,
        'endpointPath': f'/archive?genre={slug}',
    })

print(f"Total genres to harvest: {len(raw_genres)}")

def fetch_genre_details(g):
    slug = g['slug']
    url = f"https://www.hentaiworld.me/archive?genre={slug}"
    fetcher = Fetcher()
    try:
        r = fetcher.get(url, timeout=10)
        if r.status != 200:
            return g | {'count': 50, 'sample_titles': []}
        s = BeautifulSoup(r.body, 'html.parser')
        arts = s.find_all('article')
        pages = [1]
        for pa in s.find_all('a', href=re.compile(r'page=(\d+)')):
            pm = re.search(r'page=(\d+)', pa.get('href', ''))
            if pm:
                pages.append(int(pm.group(1)))
        max_page = max(pages)
        approx_count = (max_page - 1) * 20 + len(arts) if max_page > 1 else len(arts)
        
        sample_titles = []
        for art in arts[:3]:
            h3 = art.find('h3')
            if h3:
                sample_titles.append(h3.get_text().strip())
                
        return g | {
            'count': approx_count,
            'max_page': max_page,
            'sample_titles': sample_titles,
        }
    except Exception as e:
        print(f"Error fetching {slug}: {e}")
        return g | {'count': 40, 'sample_titles': []}

results = []
with ThreadPoolExecutor(max_workers=5) as executor:
    future_to_genre = {executor.submit(fetch_genre_details, g): g for g in raw_genres}
    for future in as_completed(future_to_genre):
        data = future.result()
        results.append(data)
        print(f"Harvested [{data['slug']}]: {data['name']} (Count: ~{data['count']})")

results.sort(key=lambda x: x['name'].lower())

with open('scratch/harvested_genres.json', 'w', encoding='utf-8') as f:
    json.dump(results, f, indent=2, ensure_ascii=False)

print(f"Saved {len(results)} genres to scratch/harvested_genres.json")
