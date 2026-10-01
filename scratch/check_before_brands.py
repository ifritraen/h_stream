from scrapling.fetchers import Fetcher
import re
import json

BASE_URL = "https://hentai.tv"
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': f'{BASE_URL}/',
}

p = Fetcher.get(f"{BASE_URL}/browse", headers=HEADERS, timeout=10)
html = p.body.decode('utf-8', errors='ignore')

idx = html.find(r'{\"name\":\"Pink Pineapple\",\"count\":569}')
if idx != -1:
    start = html.rfind('[', 0, idx)
    print("Before brands array:")
    print(html[max(0, start-600):start])
