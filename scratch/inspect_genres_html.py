from scrapling.fetchers import Fetcher
import re

BASE_URL = "https://hentai.tv"
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': f'{BASE_URL}/',
}

page_genres = Fetcher.get(f"{BASE_URL}/genres", headers=HEADERS, timeout=15)
html_genres = page_genres.body.decode('utf-8', errors='ignore')

idx = html_genres.find('class="cat-card"')
if idx != -1:
    print("Found cat-card in HTML:")
    print(html_genres[idx:idx+1200])
else:
    print("Not found as HTML tag, might be in flight data or dynamic")
