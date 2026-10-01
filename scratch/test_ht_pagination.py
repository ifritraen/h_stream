from scrapling.fetchers import Fetcher
import re

fetcher = Fetcher()

# Test various pagination formats
for test_url in [
    "https://hentai.ht/catalog?page=2",
    "https://hentai.ht/catalog/2",
    "https://hentai.ht/catalog/page/2",
    "https://hentai.ht/catalog?p=2",
    "https://hentai.ht/catalog?offset=60",
    "https://hentai.ht/collections/recently-published",
    "https://hentai.ht/collections/uncensored-editions"
]:
    r = fetcher.get(test_url)
    body = r.body.decode('utf-8', errors='ignore')
    cards = re.findall(r'<li class="seo-card"><a href="([^"]+)">([^<]+)</a>', body)
    print(f"URL: {test_url} -> Status: {r.status} -> Found {len(cards)} cards")
    if cards:
        print(f"  First card: {cards[0][1]} ({cards[0][0]})")
