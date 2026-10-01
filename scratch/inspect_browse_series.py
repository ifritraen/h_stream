from scrapling.fetchers import Fetcher
import re
import json

BASE_URL = "https://hentai.tv"
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': f'{BASE_URL}/',
}

# 1. Check /series page
page_series = Fetcher.get(f"{BASE_URL}/series", headers=HEADERS, timeout=15)
html_series = page_series.body.decode('utf-8', errors='ignore')
series_links = set(re.findall(r'href="(/series/[^"]+)"', html_series))
print(f"/series has {len(series_links)} series links. Samples:", list(series_links)[:10])

# 2. Check /browse page
page_browse = Fetcher.get(f"{BASE_URL}/browse", headers=HEADERS, timeout=15)
html_browse = page_browse.body.decode('utf-8', errors='ignore')
print("Browse HTML length:", len(html_browse))

# Search for studio / brand in browse or genres or series
for name, html in [('browse', html_browse), ('series', html_series)]:
    studios = re.findall(r'\"brand\"|\"studio\"|\"maker\"', html)
    print(f"{name} brand/studio mentions:", len(studios))

# Check for dropdowns or filters in /browse
filters = re.findall(r'<select[^>]*>([\s\S]*?)</select>', html_browse)
print("Select filters in browse:", len(filters))
for f in filters:
    print(f[:300])

# Check for studio or brand links in /browse
studio_links = re.findall(r'href="([^"]*(?:studio|brand)[^"]*)"', html_browse)
print("Studio/brand links in browse:", studio_links)

# Let's inspect flight data in /browse
scripts = re.findall(r'<script[^>]*>([\s\S]*?)</script>', html_browse)
for s in scripts:
    if 'brand' in s.lower() or 'studio' in s.lower():
        print("Found script with brand/studio:", s[:300])
