from scrapling.fetchers import Fetcher
import json
import re

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaifreak.org/',
}

fetcher = Fetcher()
page = fetcher.get('https://hentaifreak.org/pick-your-drug/', headers=headers, timeout=15)

entry = page.css('.entry-content')
if not entry:
    print("No .entry-content found!")
    exit(1)

entry = entry[0]

# Check the links inside .entry-content
links = entry.css('a')
print(f"Total links inside .entry-content on /pick-your-drug/: {len(links)}")

tag_items = []
for a in links:
    href = a.attrib.get('href', '').strip()
    text = a.get_all_text().strip()
    if '/tags/' in href or '/genre/' in href or '/category/' in href:
        # Check if parent or sibling has count
        parent = a.parent
        parent_text = parent.get_all_text().strip() if parent else ""
        tag_items.append({
            'text': text,
            'href': href,
            'parent_text': parent_text,
        })

print(f"Total tag/genre links: {len(tag_items)}")
print("\nFirst 20 items:")
for it in tag_items[:20]:
    print(it)

print("\nLast 20 items:")
for it in tag_items[-20:]:
    print(it)

# Let's see how many unique tags we have
unique_tags = {}
for it in tag_items:
    unique_tags[it['href']] = it['text']

print(f"\nUnique tags/genres: {len(unique_tags)}")
