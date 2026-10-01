from scrapling.fetchers import Fetcher
import re

urls = [
    'https://hentaihaven.red/hentai/tag/3d/',
    'https://hentaihaven.red/brand/oz/',
    'https://hentaihaven.red/serie/15-bishoujo-hyouryuuki/',
    'https://hentaihaven.red/',
]

for u in urls:
    p = Fetcher.get(u)
    print(f"\nTesting URL: {u} (Status: {p.status})")
    
    seen = set()
    items = []
    
    # query selector matching our proposed selector
    anchors = p.css('a[href*="/watch/"], a[href*="/serie/"], a[href*="/hentai/"]')
    for a in anchors:
        href = a.attrib.get('href', '').strip()
        if not href or href in seen or href.endswith('/watch/') or href.endswith('/series/') or '/hentai/tag/' in href or href.endswith('/hentai/'):
            continue
            
        imgs = a.css('img')
        h2 = a.css('h2, h3, .post-title')
        
        cover = ''
        if imgs:
            cover = imgs.first.attrib.get('data-src', '') or imgs.first.attrib.get('src', '')
            
        title = ''
        if h2:
            title = h2.first.get_all_text().strip()
        elif imgs:
            title = imgs.first.attrib.get('alt', '').strip()
            
        if title and cover:
            seen.add(href)
            items.append((title, href, cover))
            
    print(f"Parsed {len(items)} items:")
    for t, h, c in items[:3]:
        print(f"  Title: {t}\n    URL: {h}\n    Cover: {c}")
