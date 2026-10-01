from scrapling.fetchers import Fetcher
import re

BASE_URL = "https://hentai.tv"
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': f'{BASE_URL}/',
}

p = Fetcher.get(f"{BASE_URL}/genres", headers=HEADERS, timeout=15)
html = p.body.decode('utf-8', errors='ignore')

# Search for all "href":"/genre/... in the entire page
all_hrefs = re.findall(r'href[\\"]*:[\\"]*(/genre/([a-zA-Z0-9_\-]+))', html)
slugs = set(s[1] for s in all_hrefs)
print(f"Total unique genre slugs in entire page: {len(slugs)}")
print("Sample slugs:", sorted(list(slugs))[:20])
