import sys
import json
from scrapling.fetchers import Fetcher

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.5',
}

fetcher = Fetcher()

domains = [
    'https://erohentai.tv',
    'https://erohentai.me',
    'https://erohentai.tube',
    'https://ero-hentai.tv',
    'https://ero-hentai.com',
]

print("--- Testing Domains ---")
active_domain = None
for domain in domains:
    try:
        page = fetcher.get(domain, headers=headers, timeout=8)
        title = page.css('title::text').get() or ''
        print(f"{domain}: status={page.status}, title={title.strip()}")
        if page.status == 200 and not active_domain:
            active_domain = domain
    except Exception as e:
        print(f"{domain}: error={e}")

print(f"\nActive Domain: {active_domain}")
