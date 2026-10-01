from scrapling.fetchers import Fetcher
import re

BASE_URL = "https://hentai.tv"
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': f'{BASE_URL}/',
}

page_genres = Fetcher.get(f"{BASE_URL}/genres", headers=HEADERS, timeout=15)
html = page_genres.body.decode('utf-8', errors='ignore')

scripts = re.findall(r'<script[^>]*>([\s\S]*?)</script>', html)
for i, s in enumerate(scripts):
    if 'cat-card' in s and 'vanilla' in s:
        print(s[:3000])
        break
