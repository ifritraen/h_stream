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

# Extract the full brands array
idx = html.find(r'{\"name\":\"Pink Pineapple\",\"count\":569}')
if idx != -1:
    # Look backwards for '[' and forwards for ']'
    start = html.rfind('[', 0, idx)
    end = html.find(']', idx)
    brand_json_str = html[start:end+1].replace(r'\"', '"')
    try:
        brands = json.loads(brand_json_str)
        print(f"Extracted {len(brands)} live studios/brands!")
        print("Top 10 studios by count:")
        brands_sorted = sorted(brands, key=lambda x: x.get('count', 0), reverse=True)
        for b in brands_sorted[:10]:
            print(f"  {b['name']}: {b['count']} releases")
    except Exception as e:
        print("JSON parse error:", e)
        print("Raw snippet:", brand_json_str[:200])
