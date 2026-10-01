from scrapling.fetchers import Fetcher
import json

fetcher = Fetcher()
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaiocean.com/',
}

res = fetcher.get('https://hentaiocean.com/api?action=recent', headers=headers)
data = json.loads(res.body.decode('utf-8', errors='ignore'))
series_items = {}
for item in data:
    s = item.get('series')
    if s:
        series_items.setdefault(s, []).append(item)

print(f'Distinct series found in recent: {len(series_items)}')
for s, items in list(series_items.items())[:20]:
    name = items[0].get('videoname')
    print(f'{s}: {len(items)} episodes, e.g. {name}')
