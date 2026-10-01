from scrapling.fetchers import Fetcher
import re

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaitube.online/',
}

fetcher = Fetcher()

test_genres = ["uncensored", "3d", "action", "anal", "comedy", "romance", "vanilla", "yuri", "tentacles"]

for g in test_genres:
    url = f"https://www.hentaitube.online/genre/{g}/"
    page = fetcher.get(url, headers=HEADERS, timeout=10)
    items = page.css('.item')
    thumb = ""
    if items:
        img = items[0].css('img')
        if img:
            thumb = img[0].attrib.get('src') or ''
            
    # Check paginacao
    pages = []
    for a in page.css('.paginacao a'):
        txt = a.text.strip() if a.text else ''
        if txt.isdigit():
            pages.append(int(txt))
            
    max_page = max(pages) if pages else 1
    total_est = (max_page - 1) * 35 + len(items) if max_page > 1 else len(items)
    
    print(f"Genre: {g:<15} | Items on p1: {len(items):<2} | Max page: {max_page:<2} | Est count: {total_est:<4} | Thumb: {thumb}")
