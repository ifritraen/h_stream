from scrapling.fetchers import Fetcher
import json
import re

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaverse.com/',
}

fetcher = Fetcher()

# 1. Check if page 2 exists for categories
for p in [2, 3]:
    for url in [f'https://hentaverse.com/categories?page={p}', f'https://hentaverse.com/categories/page/{p}/', f'https://hentaverse.com/categories/{p}']:
        try:
            res = fetcher.get(url, headers=headers, timeout=10)
            print(f"URL: {url} -> status: {res.status if hasattr(res, 'status') else 'OK'}, len: {len(res.html)}")
            # Check if there are category objects
            cats = re.findall(r'\"slug\":\"([a-zA-Z0-9_\-]+)\"', res.html)
            print(f"  slugs on {url}: {len(cats)} -> {cats[:10]}")
        except Exception as e:
            print(f"URL {url} err:", e)

# 2. Check where the 45 slugs came from in categories_page.html
with open('scratch/categories_page.html', 'r', encoding='utf-8') as f:
    html = f.read()

all_cat_slugs = set(re.findall(r'/categories/([a-zA-Z0-9_\-]+)', html))
print(f"\nAll /categories/slug in categories_page.html: {len(all_cat_slugs)}")
print(sorted(list(all_cat_slugs)))

for slug in sorted(list(all_cat_slugs)):
    pos = html.find(f'/categories/{slug}')
    print(f"Slug: {slug}, context: {repr(html[max(0, pos-40):min(len(html), pos+60)])}")
