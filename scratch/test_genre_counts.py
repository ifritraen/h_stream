from scrapling.fetchers import Fetcher
from bs4 import BeautifulSoup
import re
import json
import time

with open('scratch/genres.html', 'r', encoding='utf-8', errors='ignore') as f:
    soup = BeautifulSoup(f.read(), 'html.parser')

# Every a tag with href containing /archive?genre=
genre_cards = soup.find_all('a', href=re.compile(r'/archive\?genre='))
print(f"Total genre links: {len(genre_cards)}")

genres = []
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
    
    genres.append({
        'slug': slug,
        'name': name,
        'description': desc,
        'endpointPath': f'/archive?genre={slug}',
    })

print(f"Extracted {len(genres)} unique genres.")

# Sample 5 genres to see how fast we can get count from pagination
f = Fetcher()
for g in genres[:5]:
    url = f"https://www.hentaiworld.me/archive?genre={g['slug']}"
    r = f.get(url)
    s = BeautifulSoup(r.body, 'html.parser')
    arts = s.find_all('article')
    # Check max page
    pages = [1]
    for pa in s.find_all('a', href=re.compile(r'page=(\d+)')):
        pm = re.search(r'page=(\d+)', pa.get('href', ''))
        if pm:
            pages.append(int(pm.group(1)))
    max_page = max(pages)
    approx_count = (max_page - 1) * 20 + len(arts) if max_page > 1 else len(arts)
    g['count'] = approx_count
    print(f"[{g['slug']}] Name: {g['name']}, Max Page: {max_page}, Count: ~{approx_count}")

