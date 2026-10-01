import json
import re
from scrapling.fetchers import Fetcher

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaitube.online/',
}

fetcher = Fetcher()

# Let's inspect /hentai-list/ and /genre/
for url in ["https://hentaitube.online/genre/", "https://hentaitube.online/hentai-list/", "https://hentaitube.online/genre/uncensored/"]:
    page = fetcher.get(url, headers=HEADERS, timeout=10)
    print(f"\n=== INSPECTING {url} (status: {page.status}) ===")
    
    # Check for cards, thumbnails, counts, etc.
    cards = page.css('article, .post, .item, .video-block, .thumb, .entry, .col, .card')
    print(f"Total card elements found: {len(cards)}")
    
    # Let's inspect the first 2 cards if found
    for idx, c in enumerate(cards[:2]):
        print(f"  Card {idx}: tag={c.attrib}")
        for img in c.css('img'):
            print(f"    img: src={img.attrib.get('src')} data-src={img.attrib.get('data-src')} alt={img.attrib.get('alt')}")
        for a in c.css('a'):
            print(f"    a: href={a.attrib.get('href')} text={a.text.strip() if a.text else ''}")

    # Check pagination elements
    pagination = page.css('.pagination, .nav-links, .pages, .page-numbers, .pager')
    print(f"Pagination elements: {len(pagination)}")
    for p in pagination:
        for a in p.css('a, span'):
            print(f"    page link: {a.text.strip() if a.text else ''} -> {a.attrib.get('href')}")
