from scrapling.fetchers import Fetcher
import json
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')
fetcher = Fetcher()

print("=== Probing Hentai.ht ===")

# 1. Probing catalog
r_cat = fetcher.get("https://hentai.ht/catalog")
print(f"Catalog status: {r_cat.status}")

# Check links in catalog
links = r_cat.css('a')
title_links = [a for a in links if a.attrib.get('href', '').startswith('/title/')]
print(f"Found {len(title_links)} title links in catalog")

titles = []
seen_titles = set()
for a in title_links:
    href = a.attrib.get('href', '')
    if href in seen_titles:
        continue
    seen_titles.add(href)
    title_text = a.text.strip() if a.text else ""
    if not title_text:
        title_text = a.attrib.get('title', '')
    # Check inner img
    img_el = a.css('img')
    img = ""
    if img_el:
        img = img_el[0].attrib.get('src') or img_el[0].attrib.get('data-src') or ""
        if img.startswith('/'):
            img = f"https://hentai.ht{img}"
    
    # If title text is still empty, look inside for heading or span
    if not title_text:
        h = a.css('h2, h3, h4, span, p')
        for el in h:
            txt = el.text.strip() if el.text else ""
            if txt and len(txt) > len(title_text):
                title_text = txt
    
    titles.append({
        'url': href,
        'title': title_text,
        'cover': img
    })

print(f"Parsed {len(titles)} titles. First 5:")
for t in titles[:5]:
    print(f"  {t['title']} -> {t['url']} (Cover: {t['cover']})")

# 2. Probing collections
r_coll = fetcher.get("https://hentai.ht/collections")
print(f"\nCollections status: {r_coll.status}")
coll_links = r_coll.css('a[href^="/collections/"]')
print(f"Found {len(coll_links)} collection links:")
collections = []
seen_coll = set()
for c in coll_links:
    chref = c.attrib.get('href', '')
    if chref in seen_coll or chref == '/collections':
        continue
    seen_coll.add(chref)
    cname = c.text.strip() if c.text else ""
    if not cname:
        h = c.css('h2, h3, span')
        if h:
            cname = h[0].text.strip() if h[0].text else ""
    collections.append({
        'href': chref,
        'name': cname or chref.split('/')[-1].replace('-', ' ').title()
    })
    print(f"  Collection: {collections[-1]['name']} -> {chref}")

# 3. Probing a sample title page
if titles:
    sample_title = titles[0]
    t_url = f"https://hentai.ht{sample_title['url']}" if sample_title['url'].startswith('/') else sample_title['url']
    rt = fetcher.get(t_url)
    print(f"\nTitle page {t_url} status: {rt.status}")
    print("Title page text snippet:")
    print(rt.text[:600])
    
    # Look for tags / genres
    t_tags = [a.text.strip() for a in rt.css('a[href*="/genre/"], a[href*="/tag/"], a[href*="/catalog?"]') if a.text]
    print(f"Tags found: {t_tags}")
    
    # Look for episodes / watch links
    w_links = [a.attrib.get('href') for a in rt.css('a[href*="/watch/"]')]
    print(f"Watch links: {w_links}")
    
    if w_links:
        w_url = f"https://hentai.ht{w_links[0]}" if w_links[0].startswith('/') else w_links[0]
        rw = fetcher.get(w_url)
        print(f"\nWatch page {w_url} status: {rw.status}")
        vids = rw.css('video, source, iframe')
        print(f"Video/Embed elements: {[str(v)[:150] for v in vids]}")
        scripts = [s.text for s in rw.css('script') if s.text and any(k in s.text for k in ['m3u8', 'mp4', 'player', 'hls', 'source', 'stream'])]
        print(f"Video scripts found: {len(scripts)}")
        for s in scripts[:2]:
            print(f"  Script snippet: {s[:200]}...")
