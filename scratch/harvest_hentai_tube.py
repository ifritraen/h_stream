import json
import re
from scrapling.fetchers import Fetcher

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaitube.online/',
}

fetcher = Fetcher()

urls = [
    "https://hentaitube.online/",
    "https://hentaitube.online/genre/",
    "https://hentaitube.online/genres/",
    "https://hentaitube.online/tags/",
    "https://hentaitube.online/tag/",
    "https://hentaitube.online/categories/",
    "https://hentaitube.online/category/",
]

for url in urls:
    try:
        page = fetcher.get(url, headers=HEADERS, timeout=10)
        print(f"URL: {url} -> Status: {page.status}")
        # Print a sample of links or titles
        links = page.css('a')
        print(f"  Total links: {len(links)}")
        # Check title
        title_el = page.css('title')
        print(f"  Title: {title_el[0].text if title_el else 'None'}")
    except Exception as e:
        print(f"URL: {url} -> Error: {e}")
