import sys
import json
from scrapling.fetchers import Fetcher

domains = [
    "https://hentaiworld.tv",
    "https://hentaiworld.me",
    "https://hentaiworld.net",
    "https://hentaiworld.co",
]

headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.5",
}

fetcher = Fetcher()

print("Probing domains...")
for domain in domains:
    try:
        print(f"Trying {domain}...")
        resp = fetcher.get(domain, headers=headers, timeout=10)
        print(f"[{resp.status}] {domain}")
        if resp.status == 200:
            print(f"Success! Body length: {len(resp.text)}")
            print(f"Page title: {resp.css('title::text').get()}")
    except Exception as e:
        print(f"Error {domain}: {e}")
