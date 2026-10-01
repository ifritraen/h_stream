import sys
sys.stdout.reconfigure(encoding='utf-8')
from scrapling.fetchers import Fetcher
import re

fetcher = Fetcher()
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaistream.xxx/',
}

# 1. Scrape all genres from hentaistream.xxx/genres/
res = fetcher.get('https://hentaistream.xxx/genres/', headers=headers)
print("Genres status:", res.status)

cat_items = res.css('.cat_item')
print(f"Total .cat_item on /genres/: {len(cat_items)}")

genres = []
for c in cat_items:
    href = c.attrib.get('href', '')
    slug = href.strip('/').split('/')[-1] if href else ''
    
    # Title
    ttl = c.css('.cat_ttl::text').get()
    if ttl:
        ttl = ttl.strip()
    
    # Desc
    dsc = c.css('.cat_dsc::text').get()
    dsc = dsc.strip() if dsc else ''
    
    # Count
    cnt_text = c.css('.cat_count::text').get()
    cnt = 0
    if cnt_text:
        cnt_clean = re.sub(r'[^\d]', '', cnt_text)
        if cnt_clean.isdigit():
            cnt = int(cnt_clean)
            
    # Thumbnail / Image
    # check style of .cat_ico or .cat_bg
    bg_style = c.css('.cat_bg::attr(style)').get() or ''
    ico_style = c.css('.cat_ico::attr(style)').get() or ''
    
    # extract url(...)
    m = re.search(r'url\(([^)]+)\)', ico_style) or re.search(r'url\(([^)]+)\)', bg_style)
    thumb = m.group(1).strip('\'"') if m else ''
    if thumb and not thumb.startswith('http'):
        thumb = f"https://hentaistream.xxx{thumb}"
        
    genres.append({
        'name': ttl,
        'slug': slug,
        'description': dsc,
        'count': cnt,
        'thumbnail': thumb,
        'href': href,
    })

print(f"Parsed {len(genres)} genres:")
for g in genres[:10]:
    print(" ", g)

# Also check tube.hentaistream.com/sitemap.xml
sm_res = fetcher.get('https://tube.hentaistream.com/sitemap.xml', headers=headers)
print(f"\nSitemap len: {len(sm_res.text)}")
sitemap_links = re.findall(r'<loc>(https://[^<]+)</loc>', sm_res.text)
print(f"Total locs in sitemap: {len(sitemap_links)}")
for l in sitemap_links[:20]:
    print(" ", l)
