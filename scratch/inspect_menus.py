import json
import re
from scrapling.fetchers import Fetcher

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaitube.online/',
}

fetcher = Fetcher()

# Let's inspect https://hentaitube.online/ and https://hentaitube.online/genre/
for target in ["https://hentaitube.online/", "https://hentaitube.online/genre/"]:
    page = fetcher.get(target, headers=HEADERS, timeout=10)
    print(f"\n=== INSPECTING {target} ===")
    
    # Find all <a> tags with href containing genre, category, or tag
    links = page.css('a')
    taxonomy_links = []
    all_hrefs = set()
    
    for a in links:
        href = a.attrib.get('href', '')
        text = a.text.strip() if a.text else ''
        if not href or href in all_hrefs:
            continue
        all_hrefs.add(href)
        
        if any(term in href for term in ['/genre/', '/category/', '/tag/', '/genres/', '/categories/', '/tags/', '/channels/', '/models/']):
            taxonomy_links.append((href, text))
            
    print(f"Found {len(taxonomy_links)} taxonomy links:")
    for href, text in taxonomy_links[:50]:
        print(f"  {text} -> {href}")
        
    # Check if there are menus, sidebars, or dropdowns
    nav_items = page.css('nav, .menu, .navbar, .genres, .categories, .tags, ul.sub-menu')
    print(f"Found {len(nav_items)} nav containers")
    for nav in nav_items:
        cls = nav.attrib.get('class', '')
        print(f"  Container class: {cls}")
