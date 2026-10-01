import json
from scrapling.fetchers import Fetcher

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaifreak.org/',
}

fetcher = Fetcher()

urls = [
    'https://hentaifreak.org/',
    'https://hentaifreak.org/genres/',
    'https://hentaifreak.org/genre/',
    'https://hentaifreak.org/tags/',
    'https://hentaifreak.org/tag/',
    'https://hentaifreak.org/categories/',
    'https://hentaifreak.org/category/',
]

for url in urls:
    try:
        page = fetcher.get(url, headers=headers, timeout=15)
        print(f"URL: {url} -> Status: {page.status}")
        if page.status == 200:
            # Let's inspect title and nav links
            title = page.css('title')
            print(f"  Title: {title[0].get_all_text().strip() if title else 'No title'}")
    except Exception as e:
        print(f"URL: {url} -> Error: {e}")
