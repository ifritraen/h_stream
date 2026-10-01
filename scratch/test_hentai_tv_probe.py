import json
from scrapling.fetchers import Fetcher

BASE_URL = "https://hentai.tv"
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': f'{BASE_URL}/',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
}

urls = [
    f"{BASE_URL}/categories",
    f"{BASE_URL}/genres",
    f"{BASE_URL}/studios",
    f"{BASE_URL}/tags",
]

for url in urls:
    try:
        page = Fetcher.get(url, headers=HEADERS, timeout=15)
        print(f"URL: {url} -> Status: {page.status}, Length: {len(page.body)}")
        # Check title or first 500 chars of body
        print(f"Snippet: {page.body[:300].decode('utf-8', errors='ignore')}\n")
    except Exception as e:
        print(f"URL: {url} -> Exception: {e}\n")
