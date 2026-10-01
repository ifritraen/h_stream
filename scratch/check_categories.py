from scrapling.fetchers import Fetcher
from bs4 import BeautifulSoup
import re

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaiera.com/',
}

# Check categories list
cats = [
    ('Doujinshi', '/category/doujinshi/'),
    ('Manga', '/category/manga/'),
    ('Western', '/category/western/'),
    ('Image Set', '/category/image-set/'),
]

for name, path in cats:
    url = f'https://hentaiera.com{path}'
    res = Fetcher.get(url, headers=headers)
    soup = BeautifulSoup(res.body, 'html.parser')
    
    # Check title, total count, pagination
    h1 = soup.find('h1')
    pagination = soup.find('ul', class_='pagination')
    max_page = 1
    if pagination:
        pages = [int(a.get_text(strip=True)) for a in pagination.find_all('a') if a.get_text(strip=True).isdigit()]
        if pages:
            max_page = max(pages)
    
    # First item cover
    first_thumb = soup.select_one('.thumb img')
    cover = first_thumb.get('data-src') if first_thumb else ''
    
    print(f"Category: {name} | Path: {path} | H1: {h1.get_text(strip=True) if h1 else 'None'} | Max Pages: {max_page} | First Cover: {cover}")

