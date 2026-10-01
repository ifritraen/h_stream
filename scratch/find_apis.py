from scrapling.fetchers import Fetcher
import re

BASE_URL = "https://hentai.tv"
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': f'{BASE_URL}/',
}

p = Fetcher.get(f"{BASE_URL}/browse", headers=HEADERS, timeout=10)
html = p.body.decode('utf-8', errors='ignore')
js_files = re.findall(r'src="(/_next/static/[^"]+\.js)"', html)

for js in js_files:
    res = Fetcher.get(f"{BASE_URL}{js}", headers=HEADERS, timeout=10)
    js_text = res.body.decode('utf-8', errors='ignore')
    apis = set(re.findall(r'/api/[a-zA-Z0-9_\-/]+', js_text))
    if apis:
        print(f"{js} APIs: {apis}")
    if 'initialVideos' in js_text or 'sort' in js_text:
        print(f"{js} has initialVideos or sort logic")
