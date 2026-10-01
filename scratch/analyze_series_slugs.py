from scrapling.fetchers import Fetcher
import re

fetcher = Fetcher()
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaiocean.com/',
}

res = fetcher.get('https://hentaiocean.com/sitemap.xml', headers=headers)
urls = re.findall(r'<loc>https://hentaiocean\.com/watch/(.*?)</loc>', res.body.decode('utf-8', errors='ignore'))
print(f'Total watch slugs: {len(urls)}')

# Group slugs by series prefix (e.g., strip trailing episode numbers like -1, -2, -3, etc.)
series_map = {}
for slug in urls:
    match = re.match(r'^(.*?)-(\d+)$', slug)
    if match:
        base = match.group(1)
        ep = int(match.group(2))
    else:
        base = slug
        ep = 1
    series_map.setdefault(base, []).append((ep, slug))

print(f'Total identified series/franchises: {len(series_map)}')
multi_ep = {k: v for k, v in series_map.items() if len(v) > 1}
print(f'Multi-episode series: {len(multi_ep)}')
for k, v in sorted(multi_ep.items(), key=lambda x: len(x[1]), reverse=True)[:20]:
    print(f'{k:40} : {len(v)} episodes (eps: {[x[0] for x in sorted(v)]})')
