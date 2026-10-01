from scrapling.fetchers import Fetcher
import re
import json

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaverse.com/',
}

fetcher = Fetcher()
page = fetcher.get('https://hentaverse.com/categories/', headers=headers, timeout=15)
html = page.html if hasattr(page, 'html') else page.body.decode('utf-8', errors='ignore')

# Save full HTML to file so we can analyze it
with open('scratch/categories_page.html', 'w', encoding='utf-8') as f:
    f.write(html)

print("Saved scratch/categories_page.html! Length:", len(html))

# Let's find occurrences of /categories/
for m in re.finditer(r'/categories/[a-zA-Z0-9_\-]+', html):
    start = max(0, m.start() - 100)
    end = min(len(html), m.end() + 200)
    print("MATCH CONTEXT:")
    print(html[start:end])
    print("-" * 50)
    break
