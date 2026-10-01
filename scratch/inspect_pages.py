import re
import json
from scrapling.fetchers import Fetcher

BASE_URL = "https://hentai.tv"
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': f'{BASE_URL}/',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
}

page_genres = Fetcher.get(f"{BASE_URL}/genres", headers=HEADERS, timeout=15)
html_genres = page_genres.body.decode('utf-8', errors='ignore')

print("=== /genres page analysis ===")
print("Title:", re.search(r'<title>(.*?)</title>', html_genres))

# Find links in /genres
links = set(re.findall(r'href="([^"]+)"', html_genres))
genre_links = [l for l in links if '/genre/' in l or '/genres/' in l or '/tag/' in l or '/tags/' in l or '/studio/' in l or '/studios/' in l or '/brand/' in l or '/category/' in l or '/categories/' in l]
print("Matching links in /genres:", len(genre_links), genre_links[:30])

# Check for Next.js flight data or script tags
scripts = re.findall(r'<script[^>]*>([\s\S]*?)</script>', html_genres)
print("Total scripts:", len(scripts))
for i, s in enumerate(scripts):
    if 'genre' in s.lower() or 'category' in s.lower() or 'studio' in s.lower():
        print(f"Script {i} matches: {s[:200]}...")

# Also let's check home page
page_home = Fetcher.get(f"{BASE_URL}/", headers=HEADERS, timeout=15)
html_home = page_home.body.decode('utf-8', errors='ignore')
home_links = set(re.findall(r'href="([^"]+)"', html_home))
tax_links = [l for l in home_links if any(k in l for k in ['genre', 'tag', 'studio', 'brand', 'category', 'series', 'channel', 'browse'])]
print("Matching links in /:", len(tax_links), tax_links[:30])
