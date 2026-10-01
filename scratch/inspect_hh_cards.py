import sys
import json
from scrapling.fetchers import Fetcher

sys.stdout.reconfigure(encoding='utf-8')

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaihaven.red/',
}

for endpoint in ['genres', 'categories', 'studios', 'series']:
    url = f"https://hentaihaven.red/{endpoint}/"
    p = Fetcher.get(url, headers=headers, timeout=15)
    print(f"\n=================== {url} ===================")
    print(f"Status: {p.status}, Title: {p.css('title::text').first}")
    # Let's inspect container elements
    containers = p.css('.genres, .categories, .items, .taxonomies, article, .row, .grid, .content')
    print(f"Sample containers found: {[c.attrib.get('class', '') for c in containers[:5]]}")
    
    # Let's check card or item elements
    cards = p.css('div.genres-item, div.item, div.col, li, a.tag, a[href*="/hentai/tag/"], a[href*="/genre/"], a[href*="/category/"], a[href*="/brand/"], a[href*="/series/"]')
    print(f"Total candidate card/item elements: {len(cards)}")
    
    # Let's print the outer HTML of the first 2 cards/items found
    for i, card in enumerate(cards[:2]):
        print(f"--- Item {i} outer HTML (first 300 chars) ---")
        print(card.html_content[:300] if hasattr(card, 'html_content') else str(card)[:300])
