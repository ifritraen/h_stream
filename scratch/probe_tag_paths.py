import sys
sys.stdout.reconfigure(encoding='utf-8')
from scrapling.fetchers import Fetcher
import re

fetcher = Fetcher()
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaistream.xxx/',
}

candidate_tag_paths = [
    '/tags/',
    '/tags',
    '/tag/',
    '/all-tags/',
    '/tag-cloud/',
    '/tag-list/',
    '/keywords/',
    '/cloud/',
    '/labels/',
    '/browse/tags/',
    '/browse/genres/',
    '/browse/categories/',
    '/categories/',
    '/category/',
    '/channels/',
]

for p in candidate_tag_paths:
    url = f"https://hentaistream.xxx{p}"
    r = fetcher.get(url, headers=headers)
    print(f"{url} -> {r.status}")
    if r.status == 200:
        print("  Found 200! Title:", r.css('title::text').get())
        tags = r.css('a[href*="/tag/"]').getall()
        print(f"  Tag links count: {len(tags)}")
