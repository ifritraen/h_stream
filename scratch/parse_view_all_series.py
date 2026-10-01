from scrapling.fetchers import Fetcher
import json
import re

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaifreak.org/',
}

fetcher = Fetcher()
page = fetcher.get('https://hentaifreak.org/view-all-series/', headers=headers, timeout=15)

entry = page.css('.entry-content')
if not entry:
    print("No .entry-content found!")
    exit(1)

entry = entry[0]

# Check the links inside .entry-content
links = entry.css('a')
print(f"Total links inside .entry-content on /view-all-series/: {len(links)}")

series_items = []
for a in links:
    href = a.attrib.get('href', '').strip()
    text = a.get_all_text().strip()
    parent = a.parent
    parent_text = parent.get_all_text().strip() if parent else ""
    series_items.append({
        'text': text,
        'href': href,
        'parent_text': parent_text,
    })

print(f"Total series links: {len(series_items)}")
print("\nFirst 20 series items:")
for it in series_items[:20]:
    print(it)

print("\nLast 20 series items:")
for it in series_items[-20:]:
    print(it)
