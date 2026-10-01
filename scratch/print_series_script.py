from scrapling.fetchers import Fetcher
import re

BASE_URL = "https://hentai.tv"
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': f'{BASE_URL}/',
}

page_series = Fetcher.get(f"{BASE_URL}/series", headers=HEADERS, timeout=15)
html_series = page_series.body.decode('utf-8', errors='ignore')

scripts = re.findall(r'<script[^>]*>([\s\S]*?)</script>', html_series)
for s in scripts:
    if '/series/' in s:
        print(s[:2000])
        break
