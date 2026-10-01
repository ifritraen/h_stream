import sys
import io
import re
from scrapling.fetchers import Fetcher
from bs4 import BeautifulSoup

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
    'Referer': 'https://hentaipro.net/',
}
test_slugs = ['vanilla', 'milf', '3d', 'anal', 'big-boobs', 'khong-che', 'maid', 'futanari', 'elf']

for s in test_slugs:
    url = f'https://hentaipro.net/{s}/'
    res = Fetcher.get(url, headers=headers)
    soup = BeautifulSoup(res.body, 'html.parser')
    h1 = soup.select_one('h1.h2-section__title, h1')
    name = h1.get_text(strip=True) if h1 and h1.get_text(strip=True) else s.capitalize()
    
    # Thumb
    first_card = soup.select_one('article.h2-card, article, .video-card')
    thumb = ''
    if first_card:
        img = first_card.select_one('img')
        if img:
            thumb = img.get('data-src') or img.get('src') or ''
    
    # Count from pagination
    pages = []
    for a in soup.find_all('a'):
        href = a.get('href', '')
        if '/page/' in href:
            m = re.search(r'/page/(\d+)/', href)
            if m:
                pages.append(int(m.group(1)))
    
    max_page = max(pages) if pages else 1
    cards_on_page = len(soup.select('article.h2-card, article, .video-card'))
    total_count = max_page * 30 if max_page > 1 else cards_on_page
    
    print(f"Slug: {s:12} | Name: {name:15} | Count: ~{total_count:4} (pages: {max_page}) | Thumb: {thumb}")
