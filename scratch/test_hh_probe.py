import json
from scrapling.fetchers import Fetcher

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaihaven.red/',
}

fetcher = Fetcher()

urls = [
    "https://hentaihaven.red/genres/",
    "https://hentaihaven.red/categories/",
    "https://hentaihaven.red/studios/",
    "https://hentaihaven.red/series/",
    "https://hentaihaven.red/genre/",
    "https://hentaihaven.red/category/",
    "https://hentaihaven.red/studio/",
    "https://hentaihaven.red/",
]

for url in urls:
    try:
        page = fetcher.get(url, headers=headers, timeout=15)
        print(f"URL: {url} -> Status: {page.status}")
        print(f"Title: {page.css('title::text').first if page.css('title::text') else 'No title'}")
        print(f"Content length: {len(page.text)}")
    except Exception as e:
        print(f"URL: {url} -> Error: {e}")
