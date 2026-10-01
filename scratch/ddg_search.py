from scrapling.fetchers import Fetcher
import sys
import re

sys.stdout.reconfigure(encoding='utf-8')

for query in ['xxxhdhentai', 'simply hentai']:
    print(f"=== Searching: {query} ===")
    try:
        url = f"https://html.duckduckgo.com/html/?q={query}"
        page = Fetcher.get(url, timeout=15)
        print("Status:", page.status)
        results = page.css('.result__url::text, .result__snippet::text, .result__title a::attr(href)').getall()
        for r in results[:15]:
            print(" ", r.strip())
    except Exception as e:
        print("Error:", e)
