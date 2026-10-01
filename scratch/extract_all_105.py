from scrapling.fetchers import Fetcher
import re
import json

BASE_URL = "https://hentai.tv"
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': f'{BASE_URL}/',
}

p = Fetcher.get(f"{BASE_URL}/genres", headers=HEADERS, timeout=15)
html = p.body.decode('utf-8', errors='ignore')

# 1. First extract from HTML
html_cards = re.findall(
    r'<a\s+class="cat-card"\s+href="(/genre/([^"]+))">'
    r'[\s\S]*?<img[^>]+src="([^"]+)"'
    r'[\s\S]*?<span\s+class="cat-title">([^<]+)</span>'
    r'[\s\S]*?<p\s+class="cat-desc">([^<]*)</p>'
    r'[\s\S]*?<span\s+class="mono">([^<]+)</span>',
    html
)

extracted = {}
for href, slug, thumb, title, desc, count in html_cards:
    cnt = int(count.replace(',', '').strip()) if count.strip() else 0
    extracted[slug] = {
        'name': title.strip(),
        'slug': slug.strip(),
        'thumb': thumb.strip(),
        'desc': desc.strip(),
        'count': cnt,
    }

print(f"Extracted {len(extracted)} from HTML")

# 2. Extract remaining from RSC flight data
# Look for pattern:
# "href":"/genre/<slug>"...
flight_matches = re.finditer(r'\\?"href\\?":\s*\\?"/genre/([a-zA-Z0-9_\-]+)\\?"', html)
for m in flight_matches:
    slug = m.group(1)
    if slug in extracted:
        continue
    # Extract snippet around this match
    pos = m.start()
    snippet = html[pos:min(len(html), pos+2000)]
    
    # Title
    title_m = re.search(r'\\?"cat-title\\?",\\?"children\\?":\s*\\?"([^\\"]+)\\?"', snippet)
    title = title_m.group(1) if title_m else slug.replace('-', ' ').title()
    
    # Thumb
    thumb_m = re.search(r'\\?"poster-img[^\\]*\\?",\\?"src\\?":\s*\\?"([^\\"]+)\\?"', snippet)
    thumb = thumb_m.group(1) if thumb_m else ''
    
    # Desc
    desc_m = re.search(r'\\?"cat-desc\\?",\\?"children\\?":\s*\\?"([^\\"]*)\\?"', snippet)
    desc = desc_m.group(1) if desc_m else ''
    
    # Count
    cnt_m = re.search(r'\\?"mono\\?",\\?"children\\?":\s*\\?"?([0-9,]+)\\?"?', snippet)
    cnt = int(cnt_m.group(1).replace(',', '')) if cnt_m else 0
    
    extracted[slug] = {
        'name': title,
        'slug': slug,
        'thumb': thumb,
        'desc': desc,
        'count': cnt,
    }

print(f"Total extracted after RSC flight parse: {len(extracted)} of 105")
for slug, data in list(extracted.items())[:10]:
    print(f"  {slug}: {data['name']} (cnt={data['count']}, thumb={data['thumb']})")

missing = [s for s in re.findall(r'href[\\"]*:[\\"]*/genre/([a-zA-Z0-9_\-]+)', html) if s not in extracted]
print("Missing:", set(missing))
