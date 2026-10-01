import sys
sys.stdout.reconfigure(encoding='utf-8')
from scrapling.fetchers import Fetcher

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
}

fetcher = Fetcher()
try:
    res = fetcher.get('https://www.erohentai.net/', headers=headers, timeout=10)
    print("STATUS:", res.status)
    print("TITLE:", res.css('title::text').get())
    links = res.css('a::attr(href)').getall()
    print("TOTAL LINKS:", len(links))
    for link in sorted(set(links))[:30]:
        print("LINK:", link)
except Exception as e:
    print("ERROR:", e)
