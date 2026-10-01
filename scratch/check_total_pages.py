import sys
sys.stdout.reconfigure(encoding='utf-8')

from scrapling.fetchers import Fetcher
from bs4 import BeautifulSoup

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentai.sh/',
}

page = 3
while True:
    url = f'https://hentai.sh/community?page={page}'
    resp = Fetcher.get(url, headers=headers)
    soup = BeautifulSoup(resp.body.decode('utf-8', errors='ignore'), 'html.parser')
    cards = soup.find_all('a', href=lambda h: h and '/playlist/' in h)
    print(f"Page {page}: {len(cards)} playlists")
    if not cards:
        break
    pager = soup.find('nav', class_='pagination')
    next_btn = pager.find('a', rel='next') if pager else None
    if not next_btn:
        print(f"No next button on page {page}. Last page reached!")
        break
    page += 1
