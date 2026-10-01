from scrapling.fetchers import Fetcher
import json
import re

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaverse.com/',
}

fetcher = Fetcher()

# 1. Inspect categories page
page = fetcher.get('https://hentaverse.com/categories/', headers=headers, timeout=15)

print("--- Inspecting /categories/ ---")
links = page.css('a')
cat_links = []
tag_links = []
all_links = set()

for a in links:
    href = a.attrib.get('href', '')
    text = a.get_all_text().strip()
    all_links.add((href, text))
    if '/category/' in href or '/categories/' in href:
        cat_links.append((href, text))
    if '/tag/' in href or '/tags/' in href or '/genre/' in href or '/genres/' in href:
        tag_links.append((href, text))

print(f"Total links on /categories/: {len(links)}")
print(f"Total /category/ or /categories/ links: {len(cat_links)}")
for href, text in cat_links[:20]:
    print(f"  CAT: {href} -> {text}")

print(f"Total tag/genre links on /categories/: {len(tag_links)}")
for href, text in tag_links[:20]:
    print(f"  TAG: {href} -> {text}")

# Check card selectors on /categories/
cards = page.css('.category, .item, .card, article, .col, .box, [class*="cat"], [class*="genre"]')
print(f"Cards found matching general selector: {len(cards)}")
for c in cards[:5]:
    print("CARD class:", c.attrib.get('class'))
    print("CARD text:", c.get_all_text().strip()[:100])
    img = c.css('img')
    if img:
        print("CARD img:", img[0].attrib)

# Let's inspect the menu and all distinct path prefixes on homepage
print("\n--- Inspecting Homepage Links ---")
home_page = fetcher.get('https://hentaverse.com/', headers=headers, timeout=15)
home_links = home_page.css('a')
patterns = {}
for a in home_links:
    href = a.attrib.get('href', '')
    text = a.get_all_text().strip()
    if href.startswith('https://hentaverse.com') or href.startswith('/'):
        clean = href.replace('https://hentaverse.com', '')
        parts = [p for p in clean.split('/') if p]
        if parts:
            prefix = parts[0]
            patterns[prefix] = patterns.get(prefix, 0) + 1

print("Homepage link prefixes:", patterns)
