from scrapling.fetchers import Fetcher
import re

BASE_URL = "https://hentai.tv"
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': f'{BASE_URL}/',
}

p = Fetcher.get(f"{BASE_URL}/browse", headers=HEADERS, timeout=10)
html = p.body.decode('utf-8', errors='ignore')

# Look for Pink Pineapple in html
idx = html.find('Pink Pineapple')
while idx != -1:
    print("Found Pink Pineapple:")
    print(html[max(0, idx-100):min(len(html), idx+300)])
    print("="*40)
    idx = html.find('Pink Pineapple', idx+1)
