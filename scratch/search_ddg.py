import sys
sys.stdout.reconfigure(encoding='utf-8')
from scrapling.fetchers import Fetcher

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
}

fetcher = Fetcher()
# Let's search duckduckgo html
search_url = "https://html.duckduckgo.com/html/?q=erohentai.tv+mirror+or+archive+genre"
res = fetcher.get(search_url, headers=headers, timeout=10)
print("DDG Status:", res.status)
results = res.css('.result__snippet::text').getall()
titles = res.css('.result__title a::text').getall()
urls = res.css('.result__url::text').getall()
for t, u, s in zip(titles[:10], urls[:10], results[:10]):
    print(f"Title: {t.strip()}")
    print(f"URL: {u.strip()}")
    print(f"Snippet: {s.strip()}\n")
