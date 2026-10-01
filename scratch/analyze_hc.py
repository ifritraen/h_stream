import re
from scrapling.fetchers import Fetcher

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://www.hentaicity.com/',
}

fetcher = Fetcher()
res = fetcher.get('https://www.hentaicity.com/categories/', headers=headers)
html = res.body.decode('utf-8', errors='ignore')

# Extract category blocks
cat_blocks = res.css('.item.video-category')
print(f"Video categories (.item.video-category): {len(cat_blocks)}")

categories = []
seen_cats = set()
for b in cat_blocks:
    a = b.css('a')
    img = b.css('img')
    text = b.get_all_text().strip()
    href = a[0].attrib.get('href', '') if a else ''
    src = img[0].attrib.get('src', '') if img else ''
    alt = img[0].attrib.get('alt', '') if img else ''
    
    # Text usually looks like "3D 883" or "Anal 393"
    # Let's extract name and count
    match = re.search(r'^(.*?)\s+(\d+)$', text)
    if match:
        name = match.group(1).strip()
        count = int(match.group(2))
    else:
        name = alt or text
        count = 0
    
    # Slug from href: e.g. https://www.hentaicity.com/videos/straight/3d-popular.html -> 3d
    # or /videos/straight/3d-popular.html -> 3d
    slug_match = re.search(r'/([^/]+)-popular\.html', href)
    slug = slug_match.group(1) if slug_match else name.lower().replace(' ', '-')
    
    if slug not in seen_cats:
        seen_cats.add(slug)
        categories.append({
            'name': name,
            'slug': slug,
            'count': count,
            'thumbnail': src,
            'url': href,
        })

print(f"Extracted {len(categories)} unique categories:")
for c in categories[:10]:
    print(" ", c)

# Extract tag links from .category-item or anywhere
cat_items = res.css('.category-item a')
print(f"\nCategory-item links: {len(cat_items)}")

tags = []
seen_tags = set()
for a in cat_items:
    href = a.attrib.get('href', '')
    name = a.get_all_text().strip()
    if not href or not name:
        continue
    
    # Href might be /tags/video/3d+anal or /videos/straight/...
    # If it's a tag link /tags/video/<slug>
    if '/tags/' in href:
        slug = href.split('/tags/video/')[-1].split('?')[0].strip('/')
        tag_type = 'tag'
    else:
        slug = href.split('/')[-1].replace('.html', '').replace('-popular', '')
        tag_type = 'category_link'
        
    if slug not in seen_tags:
        seen_tags.add(slug)
        tags.append({
            'name': name,
            'slug': slug,
            'href': href,
            'type': tag_type,
        })

print(f"Extracted {len(tags)} unique tags from .category-item:")
for t in tags[:10]:
    print(" ", t)

# Also check how tag pages work, e.g. /tags/video/3d+anal
test_tag_url = "https://www.hentaicity.com/tags/video/3d+anal"
tag_res = fetcher.get(test_tag_url, headers=headers)
print(f"\nTest tag fetch {test_tag_url} status: {tag_res.status}, body length: {len(tag_res.body)}")
tag_items = tag_res.css('div.outer-item, div.item')
print(f"Items found on tag page: {len(tag_items)}")
