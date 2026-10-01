from scrapling.fetchers import Fetcher
import json
import re

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaitube.online/',
}

fetcher = Fetcher()

# Fetch the 3 URLs specified in Task 1
urls = [
    "https://hentaitube.online/genre",
    "https://hentaitube.online/tags",
    "https://hentaitube.online/categories",
]

harvested_links = {}

for u in urls:
    p = fetcher.get(u, headers=HEADERS, timeout=10)
    print(f"Fetched {u} -> Status: {p.status}")
    for a in p.css('a'):
        href = a.attrib.get('href', '')
        text = a.text.strip() if a.text else ''
        if '/genre/' in href and text:
            # Clean href
            clean_href = href
            if clean_href.startswith('/'):
                clean_href = f"https://www.hentaitube.online{clean_href}"
            slug_match = re.search(r'/genre/([^/]+)/?', clean_href)
            if slug_match:
                slug = slug_match.group(1)
                if slug not in harvested_links:
                    harvested_links[slug] = {
                        'name': text,
                        'slug': slug,
                        'url': clean_href,
                        'source_page': u
                    }

print(f"\nTotal unique genres found: {len(harvested_links)}")
for slug, data in sorted(harvested_links.items()):
    print(f"  {slug:<25}: {data['name']} ({data['url']})")
