import sys
sys.stdout.reconfigure(encoding='utf-8')
from scrapling.fetchers import Fetcher

fetcher = Fetcher()
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaistream.xxx/',
}

# 1. Fetch a real watch page
watch_url = 'https://hentaistream.xxx/watch/chimimonryou-episode-2/'
res = fetcher.get(watch_url, headers=headers)
print(f"Watch page: {res.status}")
print("Title:", res.css('title::text').get())
tag_links = res.css('a[href*="/tag/"], a[href*="/genre/"]').getall()
print(f"Watch page tag/genre links ({len(tag_links)}):")
for t in tag_links:
    print("  ", t)

# 2. Check sitemaps
for sm in ['https://hentaistream.xxx/sitemap.xml', 'https://hentaistream.xxx/robots.txt', 'https://tube.hentaistream.com/sitemap.xml', 'https://tube.hentaistream.com/robots.txt']:
    r = fetcher.get(sm, headers=headers)
    print(f"\n{sm}: {r.status}")
    if r.status == 200:
        lines = r.text.splitlines()[:15]
        for l in lines:
            print("  ", l)
