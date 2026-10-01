from scrapling.fetchers import Fetcher
import json
import re
import urllib.parse
import sys

sys.stdout.reconfigure(encoding='utf-8')
fetcher = Fetcher()

print("=== 1. Probing HentaiDB ===")
r = fetcher.get("https://hentaidb.xyz/")
print(f"HentaiDB Homepage status: {r.status}")

# Let's inspect raw HTML of first series link
series_links = r.css('a[href^="/s/"]')
print(f"Found {len(series_links)} series links")
if series_links:
    first_a = series_links[0]
    print(f"First link HTML: {str(first_a)[:300]}")

seen_series = set()
series_list = []
for a in series_links:
    href = a.attrib.get('href', '')
    m = re.search(r'/s/([^/?#]+)', href)
    if not m:
        continue
    slug = m.group(1)
    if slug in seen_series:
        continue
    seen_series.add(slug)
    
    # Title extraction
    title = ""
    title_el = a.css('h2, h3, span, div.title, p')
    if title_el:
        for t in title_el:
            txt = t.text.strip() if hasattr(t, 'text') and t.text else ""
            if txt and len(txt) > len(title):
                title = txt
    if not title:
        title = a.attrib.get('title', '')
    if not title:
        raw_text = a.text.strip() if hasattr(a, 'text') and a.text else ""
        title = raw_text if raw_text else slug.replace('-', ' ').title()
    
    # Image
    img_el = a.css('img')
    img = ""
    if img_el:
        img = img_el[0].attrib.get('src') or img_el[0].attrib.get('data-src') or ""
    
    series_list.append({
        'slug': slug,
        'name': title,
        'cover': img,
        'endpointPath': f"/s/{slug}"
    })

print(f"Harvested {len(series_list)} unique series on homepage:")
for s in series_list[:5]:
    print(f"  {s['name']} ({s['slug']}) -> Cover: {s['cover']}")

# Now let's inspect series page details
sample_slug = series_list[0]['slug'] if series_list else 'saimin-seishidou'
s_url = f"https://hentaidb.xyz/s/{sample_slug}"
rs = fetcher.get(s_url)
print(f"\nSeries detail {s_url} status: {rs.status}")
print("Detail page snippet:")
print(rs.text[:500])

# Find tags
tag_links = rs.css('a[href*="tag="]')
tags = []
for tl in tag_links:
    tag_name = tl.text.strip() if tl.text else ""
    if tag_name:
        tags.append(tag_name)
print(f"Tags found ({len(tags)}): {tags[:20]}")

# Find episode watch links
watch_links = rs.css('a[href*="/watch/"]')
print(f"Watch links found ({len(watch_links)}):")
for w in watch_links[:5]:
    print(f"  href: {w.attrib.get('href')} | text: {w.text.strip() if w.text else ''}")

# Probing watch page
if watch_links:
    w_href = watch_links[0].attrib.get('href', '')
    w_url = f"https://hentaidb.xyz{w_href}" if w_href.startswith('/') else w_href
    rw = fetcher.get(w_url)
    print(f"\nWatch page {w_url} status: {rw.status}")
    video_sources = rw.css('video source::attr(src), video::attr(src), iframe::attr(src)')
    print(f"Direct video/iframe tags: {[v.attrib.get('src') if hasattr(v, 'attrib') else str(v) for v in video_sources]}")
    # Inspect scripts
    scripts = rw.css('script')
    for sc in scripts:
        sc_text = sc.text or ""
        if any(k in sc_text for k in ['m3u8', 'mp4', 'player', 'source', 'video', 'hls']):
            print(f"Script containing video keyword (first 200 chars): {sc_text[:200]}")
