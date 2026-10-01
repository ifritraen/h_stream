from scrapling.fetchers import Fetcher
import re
import json

BASE_URL = "https://hentai.tv"
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': f'{BASE_URL}/',
}

page_browse = Fetcher.get(f"{BASE_URL}/browse", headers=HEADERS, timeout=15)
html_browse = page_browse.body.decode('utf-8', errors='ignore')

# Extract initialVideos
match = re.search(r'\"initialVideos\":(\[[\s\S]*?\])\s*,\s*\"', html_browse)
if match:
    # Need to clean escaped quotes
    raw = match.group(1).replace(r'\"', '"')
    try:
        videos = json.loads(raw)
        print(f"Parsed {len(videos)} videos from initialVideos")
        print("Sample video keys:", list(videos[0].keys()))
        print("Sample video:", json.dumps(videos[0], indent=2))
        brands = set(v.get('brand') for v in videos if v.get('brand'))
        print("Brands in browse:", brands)
    except Exception as e:
        print("JSON parse error:", e)
        print("Raw start:", raw[:500])
else:
    print("No initialVideos match")
