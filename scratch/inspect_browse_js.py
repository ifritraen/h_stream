from scrapling.fetchers import Fetcher
import re

BASE_URL = "https://hentai.tv"
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': f'{BASE_URL}/',
}

p = Fetcher.get(f"{BASE_URL}/browse", headers=HEADERS, timeout=10)
html = p.body.decode('utf-8', errors='ignore')

# Search for JS script src files
js_files = re.findall(r'src="(/_next/static/[^"]+\.js)"', html)
print("JS files:", js_files)

# Let's inspect the main browse page JS or chunks for 'brand' or 'studio'
for js in js_files:
    if 'browse' in js or 'page' in js:
        res = Fetcher.get(f"{BASE_URL}{js}", headers=HEADERS, timeout=10)
        js_text = res.body.decode('utf-8', errors='ignore')
        matches = re.findall(r'brand|studio|genre|category', js_text, re.IGNORECASE)
        print(f"{js} matches:", len(matches))
        # Look for API endpoints in JS
        apis = re.findall(r'/api/[a-zA-Z0-9_\-/]+', js_text)
        print(f"{js} APIs:", set(apis))
