from scrapling.fetchers import Fetcher
from bs4 import BeautifulSoup

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaiera.com/',
}

for test_url in ['https://hentaiera.com/tag/big-breasts/', 'https://hentaiera.com/category/manga/']:
    res = Fetcher.get(test_url, headers=headers)
    soup = BeautifulSoup(res.body, 'html.parser')
    elements = soup.select('div.thumb, .inner_thumb, article, .item')
    print(f"URL: {test_url} -> Elements found: {len(elements)}")
    
    items = []
    seen = set()
    for el in elements:
        a = el.find('a')
        if not a: continue
        href = a.get('href', '')
        if not href or href in seen: continue
        img = el.find('img')
        cover = img.get('data-src') or img.get('src') if img else ''
        title = a.get('title') or (el.select_one('.gallery_title, h2, .title').get_text(strip=True) if el.select_one('.gallery_title, h2, .title') else '')
        if href and cover and title:
            seen.add(href)
            items.append((title[:30], href, cover))
    
    print(f"Parsed {len(items)} valid items. First 2:")
    for it in items[:2]:
        print(" ", it)
