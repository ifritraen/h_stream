from scrapling.fetchers import Fetcher
import json
import re

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaverse.com/',
}

fetcher = Fetcher()

# Test page 1 and page 2 of a category feed
test_slug = 'school-girl'
for p in [1, 2]:
    for url in [
        f'https://hentaverse.com/categories/{test_slug}?page={p}',
        f'https://hentaverse.com/categories/{test_slug}/page/{p}/',
        f'https://hentaverse.com/categories/{test_slug}/{p}',
    ]:
        try:
            r = fetcher.get(url, headers=headers, timeout=10)
            html = r.body.decode('utf-8', errors='ignore')
            vids = set(re.findall(r'/video/([a-zA-Z0-9_\-]+)', html))
            print(f"URL: {url} -> status: {r.status}, html_len: {len(html)}, videos found: {len(vids)}")
            if vids:
                print(f"  sample videos: {list(vids)[:3]}")
        except Exception as e:
            print(f"Err on {url}: {e}")
