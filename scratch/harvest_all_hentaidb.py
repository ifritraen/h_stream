from scrapling.fetchers import Fetcher
import json
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')
fetcher = Fetcher()

print("Harvesting HentaiDB catalog & tags...")
all_tags = set()
all_series = []
seen_series_slugs = set()

# Probe pages 1, 2, 3
for page in [1, 2, 3]:
    url = f"https://hentaidb.xyz/?page={page}"
    r = fetcher.get(url)
    print(f"Page {page} fetched (status: {r.status})")
    cards = r.css('a[href^="/s/"]')
    for a in cards:
        href = a.attrib.get('href', '')
        m = re.search(r'/s/([^/?#]+)', href)
        if not m:
            continue
        slug = m.group(1)
        if slug in seen_series_slugs:
            continue
        seen_series_slugs.add(slug)
        title = a.attrib.get('title', '')
        if not title:
            # check inner text
            raw = a.text.strip() if a.text else ''
            title = raw if raw else slug.replace('-', ' ').title()
        
        img_el = a.css('img')
        img = ""
        if img_el:
            img = img_el[0].attrib.get('src') or img_el[0].attrib.get('data-src') or ""
            if img.startswith('/'):
                img = f"https://hentaidb.xyz{img}"
        
        all_series.append({
            'name': title,
            'slug': slug,
            'cover': img,
            'endpointPath': f"/s/{slug}"
        })

print(f"Harvested {len(all_series)} series. Now sampling 20 series to harvest comprehensive tags...")
for s in all_series[:25]:
    s_url = f"https://hentaidb.xyz/s/{s['slug']}"
    rs = fetcher.get(s_url)
    tag_links = rs.css('a[href*="tag="]')
    for tl in tag_links:
        t_name = tl.text.strip() if tl.text else ""
        if t_name:
            all_tags.add(t_name)

tag_list = sorted(list(all_tags))
print(f"Harvested {len(tag_list)} distinct tags: {tag_list[:30]}")

output_data = {
    'series': all_series[:80],
    'tags': tag_list
}

with open("scratch/hentaidb_harvest.json", "w", encoding="utf-8") as f:
    json.dump(output_data, f, indent=2, ensure_ascii=False)

print(f"Saved {len(all_series[:80])} series and {len(tag_list)} tags to scratch/hentaidb_harvest.json")
