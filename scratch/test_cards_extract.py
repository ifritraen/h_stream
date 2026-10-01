from scrapling.fetchers import Fetcher
import re

BASE_URL = "https://hentai.tv"
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': f'{BASE_URL}/',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
}

p = Fetcher.get(f"{BASE_URL}/genres", headers=HEADERS, timeout=15)
html = p.body.decode('utf-8', errors='ignore')

# Regex to extract cat-card from HTML
# <a class="cat-card" href="/genre/vanilla">...<img class="poster-img is-loaded" src="/uploads/media/..." ...><span class="cat-title">Vanilla</span>...<p class="cat-desc">...</p>...<span class="mono">421</span>
cards = re.findall(
    r'<a\s+class="cat-card"\s+href="(/genre/([^"]+))">'
    r'[\s\S]*?<img[^>]+src="([^"]+)"'
    r'[\s\S]*?<span\s+class="cat-title">([^<]+)</span>'
    r'[\s\S]*?<p\s+class="cat-desc">([^<]*)</p>'
    r'[\s\S]*?<span\s+class="mono">([^<]+)</span>',
    html
)

print(f"Extracted {len(cards)} cards from HTML regex!")
if len(cards) < 50:
    # Try more lenient regex or parse via HTML parser
    from html.parser import HTMLParser
    print("Trying alternative parsing...")

for c in cards[:10]:
    href, slug, thumb, title, desc, count = c
    print(f"Slug: {slug}, Title: {title}, Count: {count}, Thumb: {thumb}")
