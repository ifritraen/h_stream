import sys
sys.stdout.reconfigure(encoding='utf-8')

from scrapling.fetchers import Fetcher
from bs4 import BeautifulSoup
import json
import re

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentai.sh/',
}

# 1. Harvest Genres / Tags from browse
print("Scraping tags and genres from https://hentai.sh/browse...")
resp_b = Fetcher.get('https://hentai.sh/browse', headers=headers)
html_b = resp_b.body.decode('utf-8', errors='ignore')

idx = html_b.find('allTags')
raw_tags = []
if idx != -1:
    tag_start = html_b.find('[', idx)
    depth = 0
    end = tag_start
    for i in range(tag_start, len(html_b)):
        if html_b[i] == '[':
            depth += 1
        elif html_b[i] == ']':
            depth -= 1
            if depth == 0:
                end = i + 1
                break
    raw_str = html_b[tag_start:end]
    clean_str = raw_str.replace('\\"', '"').replace('\\\\', '\\')
    raw_tags = json.loads(clean_str)

print(f"Total raw tags found: {len(raw_tags)}")

# 2. Harvest Playlists from community & playlists
print("Scraping playlists from https://hentai.sh/community & https://hentai.sh/playlists...")
raw_playlists = []
seen_slugs = set()

for page in [1, 2, 3]:
    url = f"https://hentai.sh/community?page={page}"
    try:
        resp = Fetcher.get(url, headers=headers)
        soup = BeautifulSoup(resp.body.decode('utf-8', errors='ignore'), 'html.parser')
        cards = soup.find_all('a', href=lambda h: h and '/playlist/' in h)
        for card in cards:
            href = card.get('href', '')
            slug = href.split('/playlist/')[-1].strip('/')
            if not slug or slug in seen_slugs:
                continue
            seen_slugs.add(slug)
            
            img = card.find('img')
            thumb = img.get('src', '') if img else ''
            title = card.find('h3')
            name = title.text.strip() if title else (img.get('alt', '').strip() if img else slug)
            
            duration_span = card.find('span', class_='duration')
            count = 0
            if duration_span:
                m = re.search(r'(\d+)', duration_span.text)
                if m:
                    count = int(m.group(1))
            
            # Author/curator
            meta_div = card.find('div', class_='meta')
            author = "Community"
            if meta_div:
                text_meta = meta_div.text
                if 'by' in text_meta:
                    author = text_meta.split('by')[-1].split('•')[0].split('views')[0].strip()
            
            raw_playlists.append({
                'name': name,
                'slug': slug,
                'count': count,
                'curator': author,
                'thumbnail': thumb,
                'endpointPath': f"/playlist/{slug}",
            })
    except Exception as e:
        print(f"Error on page {page}: {e}")

print(f"Total live playlists harvested: {len(raw_playlists)}")

# Save intermediate JSON
with open('scratch/harvested_data.json', 'w', encoding='utf-8') as f:
    json.dump({'tags': raw_tags, 'playlists': raw_playlists}, f, indent=2, ensure_ascii=False)

print("Saved harvested data to scratch/harvested_data.json")
