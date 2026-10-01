from scrapling.fetchers import Fetcher
import json
import re

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaverse.com/',
}

fetcher = Fetcher()

# Check a few more video pages to see if any new slugs appear
res = fetcher.get('https://hentaverse.com/trending', headers=headers, timeout=10)
vids = set(re.findall(r'/video/([a-zA-Z0-9_\-]+)', res.body.decode('utf-8', errors='ignore')))
print(f"Trending videos: {len(vids)}")

all_slugs = set()
with open('scratch/all_hentaverse_categories.json', 'r', encoding='utf-8') as f:
    cats28 = json.load(f)
    for c in cats28:
        all_slugs.add(c['slug'])

print(f"Base 28 categories: {len(all_slugs)}")

# Sample 5 different videos from trending
for v in list(vids)[:8]:
    try:
        vr = fetcher.get(f'https://hentaverse.com/video/{v}', headers=headers, timeout=10)
        html = vr.body.decode('utf-8', errors='ignore')
        matches = re.findall(r'"slug":"([a-zA-Z0-9_\-]+)"', html)
        for s in matches:
            all_slugs.add(s)
    except Exception as e:
        print(f"Err on {v}: {e}")

print(f"Total slugs after checking 8 videos: {len(all_slugs)}")
print(sorted(list(all_slugs)))
