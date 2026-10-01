from scrapling.fetchers import Fetcher
import sys

sys.stdout.reconfigure(encoding='utf-8')

print("=== 1. Pornhub Categories ===")
try:
    p = Fetcher.get('https://www.pornhub.com/categories', timeout=15)
    cat_links = p.css('a[href*="/video?c="]::text, a[href*="/categories/"]::text').getall()
    clean_cats = list(dict.fromkeys([c.strip() for c in cat_links if c.strip() and len(c.strip()) > 1]))
    print(f"Total categories found: {len(clean_cats)}")
    print("Sample categories:", clean_cats[:25])
except Exception as e:
    print("Pornhub err:", e)

print("\n=== 2. Simply Hentai ===")
try:
    p = Fetcher.get('https://www.simply-hentai.com/series', timeout=15)
    series = p.css('a[href*="/series/"]::text').getall()
    clean_series = list(dict.fromkeys([s.strip() for s in series if s.strip() and len(s.strip()) > 1]))
    print(f"Total series found: {len(clean_series)}")
    print("Sample series:", clean_series[:25])
except Exception as e:
    print("Simply Hentai err:", e)

print("\n=== 3. HD Hentai ===")
try:
    p = Fetcher.get('https://hdhentai.tv/categories/', timeout=15)
    cats = p.css('a[href*="/category/"]::text').getall()
    clean_h = list(dict.fromkeys([c.strip() for c in cats if c.strip() and len(c.strip()) > 1]))
    print(f"Total categories found: {len(clean_h)}")
    print("Sample categories:", clean_h[:25])
except Exception as e:
    print("HD Hentai err:", e)
