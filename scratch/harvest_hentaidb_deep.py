from scrapling.fetchers import Fetcher
import json
import re
import urllib.parse
import sys

sys.stdout.reconfigure(encoding='utf-8')
fetcher = Fetcher()

print("=== 1. Probing HentaiDB Pagination & Endpoints ===")
for p in [1, 2, 3]:
    url = f"https://hentaidb.xyz/?page={p}"
    r = fetcher.get(url)
    print(f"Page {p} status: {r.status}")
    series = r.css('a[href^="/s/"]')
    print(f"  Found {len(series)} series links")

# Let's inspect series card DOM structure on page 1
r1 = fetcher.get("https://hentaidb.xyz/")
# Find all series containers
cards = r1.css('div.group, div.relative, a[href^="/s/"]')
print(f"Found {len(cards)} candidate card elements")

# Extract unique series
seen_series = set()
series_list = []
for a in r1.css('a[href^="/s/"]'):
    href = a.attrib.get('href', '')
    m = re.search(r'/s/([^/?#]+)', href)
    if not m:
        continue
    slug = m.group(1)
    if slug in seen_series:
        continue
    seen_series.add(slug)
    
    # Try finding title, image, and episodes
    title = a.css('h2::text, h3::text, span::text').first or a.attrib.get('title', '')
    if not title:
        # Check parent or text
        title = a.text.strip() if a.text else slug.replace('-', ' ').title()
    
    img = a.css('img::attr(src), img::attr(data-src)').first or ""
    series_list.append({
        'slug': slug,
        'name': title.strip(),
        'cover': img,
        'endpointPath': f"/s/{slug}"
    })

print(f"Harvested {len(series_list)} unique series on homepage:")
for s in series_list[:10]:
    print(f"  {s['name']} ({s['slug']}): {s['cover'][:60]}...")

# 2. Inspect a series page detail and episode player
sample_slug = series_list[0]['slug'] if series_list else 'saimin-seishidou'
s_url = f"https://hentaidb.xyz/s/{sample_slug}"
rs = fetcher.get(s_url)
print(f"\nSeries {s_url} status: {rs.status}")
tags = rs.css('a[href*="tag="]::text').getall()
eps = rs.css('a[href*="/watch/"]::attr(href)').getall()
desc = rs.css('p::text, meta[name="description"]::attr(content)').getall()
print(f"Tags found: {tags[:15]}")
print(f"Episodes found: {eps[:5]}")

# 3. Check an episode watch page
if eps:
    w_url = f"https://hentaidb.xyz{eps[0]}" if eps[0].startswith('/') else eps[0]
    rw = fetcher.get(w_url)
    print(f"\nWatch page {w_url} status: {rw.status}")
    video_src = rw.css('video::attr(src), source::attr(src), iframe::attr(src)').getall()
    print(f"Video/Embed sources: {video_src}")
    scripts = rw.css('script::text').getall()
    m3u8 = [s for s in scripts if 'm3u8' in s or 'mp4' in s]
    print(f"Scripts with m3u8/mp4: {len(m3u8)}")
    if m3u8:
        print(f"Sample script snippet: {m3u8[0][:200]}...")
