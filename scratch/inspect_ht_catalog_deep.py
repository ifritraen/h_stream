from scrapling.fetchers import Fetcher
import json
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')
fetcher = Fetcher()

print("Fetching https://hentai.ht/ and https://hentai.ht/catalog...")
for page_url in ["https://hentai.ht/", "https://hentai.ht/catalog"]:
    r = fetcher.get(page_url)
    body = r.body.decode('utf-8', errors='ignore')
    m = re.search(r'<script type="application/ld\+json"[^>]*>(.*?)</script>', body, re.DOTALL)
    if m:
        try:
            data = json.loads(m.group(1))
            graph = data.get('@graph', [])
            print(f"\n--- URL: {page_url} ---")
            for node in graph:
                ntype = node.get('@type')
                print(f"Node Type: {ntype}")
                if ntype == 'ItemList':
                    elements = node.get('itemListElement', [])
                    print(f"ItemList elements count: {len(elements)}")
                    for el in elements[:10]:
                        item = el.get('item', {}) if isinstance(el.get('item'), dict) else el
                        print(f"  Item: {item.get('name')} | URL: {item.get('url')} | Image: {item.get('image')}")
        except Exception as e:
            print("Error parsing JSON-LD:", e)

    # Also parse SEO cards
    cards = re.findall(r'<li class="seo-card"><a href="([^"]+)">([^<]+)</a>(?:<p class="seo-muted">([^<]+)</p>)?</li>', body)
    print(f"SEO cards count on {page_url}: {len(cards)}")
    for c in cards[:5]:
        print(f"  Card: href={c[0]} | title={c[1]} | meta={c[2]}")
