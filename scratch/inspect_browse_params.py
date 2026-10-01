from scrapling.fetchers import Fetcher
import re

BASE_URL = "https://hentai.tv"
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': f'{BASE_URL}/',
}

res = Fetcher.get(f"{BASE_URL}/_next/static/chunks/1fw2f65e47y25.js", headers=HEADERS, timeout=10)
text = res.body.decode('utf-8', errors='ignore')

idx = text.find('/api/browse')
if idx != -1:
    print(text[max(0, idx-600):min(len(text), idx+100)])
