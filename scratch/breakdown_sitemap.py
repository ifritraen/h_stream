import re
from scrapling.fetchers import Fetcher
from collections import Counter

headers = {'User-Agent': 'Mozilla/5.0'}
res = Fetcher.get('https://hentaipro.net/sitemap.xml', headers=headers)
content = res.body if isinstance(res.body, str) else res.body.decode('utf-8', errors='ignore')
urls = re.findall(r'<loc>(.*?)</loc>', content)

non_html = [u for u in urls if not u.endswith('.html')]

prefixes = Counter()
for u in non_html:
    path = u.replace('https://sexhentai.net', '').replace('https://hentaipro.net', '')
    parts = [p for p in path.split('/') if p]
    if not parts:
        prefixes['root'] += 1
    elif len(parts) == 1:
        prefixes['single_slug'] += 1
    else:
        prefixes[parts[0]] += 1

print("Prefix counts in sitemap non-HTML:")
for p, c in prefixes.most_common():
    print(f"  {p}: {c}")

# Let's inspect all 'single_slug' items (e.g. /big-boobs/, /vanilla/, etc.)
single_slugs = []
for u in non_html:
    path = u.replace('https://sexhentai.net', '').replace('https://hentaipro.net', '')
    parts = [p for p in path.split('/') if p]
    if len(parts) == 1 and parts[0] not in ['series', 'year', 'tag', 'studio']:
        single_slugs.append(parts[0])

print(f"\nAll single slugs ({len(single_slugs)}):")
for s in sorted(single_slugs):
    print(" ", s)
