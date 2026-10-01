from scrapling.fetchers import Fetcher
from bs4 import BeautifulSoup
import re

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://www.onlyhentaistuff.com/',
}

for slug in ['3d', 'action', 'romance', 'eng-sub']:
    url = f'https://www.onlyhentaistuff.com/tags/{slug}/'
    r = Fetcher.get(url, headers=headers)
    soup = BeautifulSoup(r.body, 'html.parser')
    # Check if there is pagination or video count
    title = soup.select_one('h1, h2, .headline')
    pagination = soup.select('.pagination a, .paging a, ul.pagination li')
    pages = [p.get_text(strip=True) for p in pagination]
    videos = soup.select('.item')
    print(f'Tag {slug}: title={title.get_text(strip=True) if title else None}, videos_on_page={len(videos)}, pages={pages}')
