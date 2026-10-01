from scrapling.fetchers import Fetcher
import re

BASE_URL = "https://hentai.tv"
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': f'{BASE_URL}/',
}

page_browse = Fetcher.get(f"{BASE_URL}/browse", headers=HEADERS, timeout=15)
html_browse = page_browse.body.decode('utf-8', errors='ignore')

scripts = re.findall(r'<script[^>]*>([\s\S]*?)</script>', html_browse)
for s in scripts:
    if 'initialVideos' in s:
        print(s[:1500])
        break
