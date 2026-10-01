import sys
sys.stdout.reconfigure(encoding='utf-8')
from scrapling.fetchers import Fetcher
import re

fetcher = Fetcher()
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaistream.xxx/',
}

# Check tube.hentaistream.com homepage
r = fetcher.get('https://tube.hentaistream.com/', headers=headers)
print("tube.hentaistream.com status:", r.status)

# Find all links
tube_links = set()
for a in r.css('a'):
    href = a.attrib.get('href', '')
    text = a.text
    if href and any(k in href for k in ['tag', 'genre', 'cat', 'category']):
        tube_links.add((href, text.strip() if text else ""))

print(f"Total matching links on tube.hentaistream.com: {len(tube_links)}")
for h, t in sorted(tube_links)[:30]:
    print(f"  {h} -> '{t}'")
