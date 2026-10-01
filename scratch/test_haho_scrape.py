import json
from scrapling.fetchers import Fetcher

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://haho.moe/',
    'Cookie': 'loop-view=thumb;',
}

fetcher = Fetcher()

for path in ['/genre', '/genres', '/playlist', '/playlists', '/anime', '/categories']:
    url = f"https://haho.moe{path}"
    try:
        page = fetcher.get(url, headers=headers, timeout=15)
        print(f"{path}: status {page.status}")
        title = page.css('title::text').get() or ''
        print(f"  Title: {title.strip()}")
    except Exception as e:
        print(f"{path}: error {e}")
