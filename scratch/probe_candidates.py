from scrapling.fetchers import Fetcher
import sys

sys.stdout.reconfigure(encoding='utf-8')

print("=== 1. Pornhub Hentai Category ===")
try:
    p = Fetcher.get('https://www.pornhub.com/video?c=36', timeout=15)
    print("Pornhub status:", p.status)
    print("Pornhub title:", p.css('title::text').first)
    vids = p.css('.pcVideoListItem').getall()
    print("Pornhub video count:", len(vids))
except Exception as e:
    print("Pornhub error:", e)

print("\n=== 2. Simply Hentai ===")
try:
    p = Fetcher.get('https://www.simply-hentai.com/', timeout=15)
    print("Simply Hentai status:", p.status)
    print("Simply Hentai title:", p.css('title::text').first)
    cats = p.css('a[href*="/category/"]::text, a[href*="/series/"]::text, a[href*="/tag/"]::text').getall()
    print("Simply Hentai sample links:", [c.strip() for c in cats if c.strip()][:15])
except Exception as e:
    print("Simply Hentai error:", e)

print("\n=== 3. HD Hentai (hdhentai.tv) ===")
try:
    p = Fetcher.get('https://hdhentai.tv/categories/', timeout=15)
    print("HD Hentai status:", p.status)
    print("HD Hentai title:", p.css('title::text').first)
    links = p.css('a[href*="/category/"]::attr(href)').getall()
    titles = p.css('a[href*="/category/"]::text').getall()
    for l, t in list(zip(links, titles))[:15]:
        if t.strip():
            print(f"  {t.strip()}: {l}")
except Exception as e:
    print("HD Hentai error:", e)
