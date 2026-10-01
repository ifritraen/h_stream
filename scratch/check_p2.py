from scrapling.fetchers import Fetcher
import json
import re

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaverse.com/',
}

fetcher = Fetcher()

for url in ['https://hentaverse.com/categories?page=2', 'https://hentaverse.com/categories/2']:
    res = fetcher.get(url, headers=headers, timeout=10)
    text = res.text
    print(f"URL: {url} -> len: {len(text)}")
    slugs = set(re.findall(r'\"slug\":\"([a-zA-Z0-9_\-]+)\"', text))
    print(f"  slugs: {len(slugs)} -> {sorted(list(slugs))[:10]}")
    # Also check if pagination info is in RSC
    pages = re.findall(r'\"(?:totalPages|page|currentPage|total)\":\s*\d+', text)
    print("  pagination info:", set(pages))
