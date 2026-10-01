from scrapling.fetchers import Fetcher
import re
import json

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentai.sh/',
}

resp_b = Fetcher.get('https://hentai.sh/browse', headers=headers)
html_b = resp_b.body.decode('utf-8', errors='ignore')

# Search for allTags in html_b
for m in re.finditer(r'allTags', html_b):
    start = max(0, m.start() - 100)
    end = min(len(html_b), m.end() + 2000)
    print("=== Found allTags in HTML ===")
    print(html_b[start:end][:500])
    print("...\n")

# Search for allBrands in html_b
for m in re.finditer(r'allBrands', html_b):
    start = max(0, m.start() - 100)
    end = min(len(html_b), m.end() + 2000)
    print("=== Found allBrands in HTML ===")
    print(html_b[start:end][:500])
    print("...\n")
