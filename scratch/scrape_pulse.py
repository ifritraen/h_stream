from scrapling.fetchers import Fetcher
import json
import re

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaipulse.com/',
}

print("Fetching homepage...")
home = Fetcher.get('https://hentaipulse.com/', headers=headers, timeout=15)
print(f"Homepage status: {home.status}")

# Find all links in navbar / menu / header / footer
menu_links = home.css('header a, nav a, .menu a, .navbar a, footer a')
print(f"Found {len(menu_links)} navigation links:")
for a in menu_links:
    href = a.attrib.get('href', '')
    text = a.text.strip() if a.text else ''
    if any(k in href for k in ['tag', 'category', 'genre', 'channel', 'series', 'browse', 'list', 'models']):
        print(f"  {text} -> {href}")

# Also look at all links on homepage
all_links = home.css('a')
links_by_type = {}
for a in all_links:
    href = a.attrib.get('href', '')
    text = a.text.strip() if a.text else ''
    if '/tag/' in href:
        links_by_type.setdefault('tag', []).append((text, href))
    elif '/category/' in href:
        links_by_type.setdefault('category', []).append((text, href))
    elif '/genre/' in href:
        links_by_type.setdefault('genre', []).append((text, href))
    elif '/channels/' in href or '/channel/' in href:
        links_by_type.setdefault('channel', []).append((text, href))

for k, v in links_by_type.items():
    print(f"Type '{k}': {len(v)} occurrences. Sample: {v[:5]}")

print("\nFetching /tags/...")
tags_page = Fetcher.get('https://hentaipulse.com/tags/', headers=headers, timeout=15)
print(f"Tags page status: {tags_page.status}")
print(f"Tags page URL: {tags_page.url}")

# Let's inspect elements on tags page
tag_cards = tags_page.css('.tag-item, .item, .tag, a[href*="/tag/"], .card')
print(f"Found {len(tag_cards)} tag-like elements on /tags/")

# Let's see some samples
tag_links = tags_page.css('a[href*="/tag/"]')
print(f"Found {len(tag_links)} a[href*='/tag/'] links:")
sample_tags = []
for a in tag_links[:20]:
    sample_tags.append((a.text.strip() if a.text else '', a.attrib.get('href', '')))
print(sample_tags)

# Check pagination on /tags/
pagination = tags_page.css('.pagination, .pager, .nav-links, a[href*="page"]')
print(f"Pagination elements on /tags/: {len(pagination)}")
for p in pagination:
    print(f"  Pagination html snippet: {p.attrib} {p.text}")
