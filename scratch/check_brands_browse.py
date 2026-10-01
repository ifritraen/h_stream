from scrapling.fetchers import Fetcher
import re

BASE_URL = "https://hentai.tv"
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': f'{BASE_URL}/',
}

p = Fetcher.get(f"{BASE_URL}/browse", headers=HEADERS, timeout=10)
html = p.body.decode('utf-8', errors='ignore')

# Check flight scripts in /browse for brands
brands_match = re.findall(r'\"brands\":\[([\s\S]*?)\]', html)
print("brands matches in HTML:", len(brands_match))
for b in brands_match:
    print(b[:500])
    print("="*40)
