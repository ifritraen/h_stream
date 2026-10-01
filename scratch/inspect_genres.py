import sys
sys.stdout.reconfigure(encoding='utf-8')
from scrapling.fetchers import Fetcher

fetcher = Fetcher()
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaistream.xxx/',
}

# Inspect hentaistream.xxx/genres/
res1 = fetcher.get('https://hentaistream.xxx/genres/', headers=headers)
print("=== hentaistream.xxx/genres/ ===")
print("Status:", res1.status)
# Let's inspect links
links1 = res1.css('a').getall()
print(f"Total links: {len(links1)}")
genre_links_1 = res1.css('a[href*="/genre/"], a[href*="/tag/"], a[href*="/category/"]').getall()
print(f"Genre/tag/cat links: {len(genre_links_1)}")
for g in genre_links_1[:30]:
    print("  ", g)

# Inspect tube.hentaistream.com/genres
res2 = fetcher.get('https://tube.hentaistream.com/genres', headers=headers)
print("\n=== tube.hentaistream.com/genres ===")
print("Status:", res2.status)
links2 = res2.css('a').getall()
print(f"Total links: {len(links2)}")
genre_links_2 = res2.css('a[href*="/genre/"], a[href*="/genres/"], a[href*="/tag/"], a[href*="/category/"]').getall()
print(f"Genre/tag/cat links: {len(genre_links_2)}")
for g in genre_links_2[:30]:
    print("  ", g)
