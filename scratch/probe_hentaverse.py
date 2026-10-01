import json
from scrapling.fetchers import Fetcher

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaverse.com/',
}

fetcher = Fetcher()

urls = [
    'https://hentaverse.com/',
    'https://hentaverse.com/categories/',
    'https://hentaverse.com/category/',
    'https://hentaverse.com/tags/',
    'https://hentaverse.com/tag/',
    'https://hentaverse.com/genres/',
    'https://hentaverse.com/genre/',
]

for url in urls:
    try:
        page = fetcher.get(url, headers=headers, timeout=15)
        print(f"URL: {url} -> Status: {page.status if hasattr(page, 'status') else 'OK'}, Length: {len(page.html) if hasattr(page, 'html') else len(page.body)}")
    except Exception as e:
        print(f"URL: {url} -> Error: {e}")
