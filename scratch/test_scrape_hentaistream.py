import sys
sys.stdout.reconfigure(encoding='utf-8')
from scrapling.fetchers import Fetcher

fetcher = Fetcher()
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaistream.xxx/',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
}

urls = [
    'https://hentaistream.xxx',
    'https://hentaistream.xxx/genres/',
    'https://hentaistream.xxx/tags/',
    'https://hentaistream.xxx/categories/',
    'https://tube.hentaistream.com',
    'https://tube.hentaistream.com/genres/',
    'https://tube.hentaistream.com/tags/',
    'https://tube.hentaistream.com/categories/',
]

for url in urls:
    try:
        print(f"Testing {url}...")
        res = fetcher.get(url, headers=headers, timeout=6)
        print(f"  -> Status: {res.status}, Len: {len(res.text) if hasattr(res, 'text') else len(res.body)}")
        # Check title
        title = res.css('title::text').get()
        print(f"  -> Title: {title}")
    except Exception as e:
        print(f"  -> Error: {type(e).__name__}: {e}")
