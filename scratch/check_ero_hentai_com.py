import sys
sys.stdout.reconfigure(encoding='utf-8')
from scrapling.fetchers import Fetcher

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.5',
}

fetcher = Fetcher()

res = fetcher.get('https://ero-hentai.com/', headers=headers, timeout=10)
print(f"Status: {res.status}")
print(f"Title: {res.css('title::text').get()}")
links = res.css('a::attr(href)').getall()
print(f"Total links: {len(links)}")
sample_links = [l for l in set(links) if any(x in l for x in ['category', 'genre', 'tag', 'series', 'video', 'watch', 'ero'])]
print("Sample links:", sample_links[:20])
