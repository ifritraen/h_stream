from scrapling.fetchers import Fetcher

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaifreak.org/',
}

fetcher = Fetcher()

# 1. Fetch categories from /pick-your-drug/
print("=== Fetching /pick-your-drug/ ===")
page = fetcher.get('https://hentaifreak.org/pick-your-drug/', headers=headers, timeout=15)
print(f"Status: {page.status}")

# Check content
links = page.css('a')
print(f"Total links on /pick-your-drug/: {len(links)}")

categories = []
for a in links:
    href = a.attrib.get('href', '')
    text = a.get_all_text().strip()
    img = a.css('img')
    img_src = img[0].attrib.get('src') or img[0].attrib.get('data-src') if img else None
    if '/genre/' in href or '/category/' in href or '/tags/' in href or 'hentaifreak.org' in href:
        categories.append({
            'href': href,
            'text': text,
            'img': img_src,
            'parent_class': a.parent.attrib.get('class') if hasattr(a, 'parent') and a.parent else ''
        })

print(f"Matching category links count: {len(categories)}")
for c in categories[:30]:
    print(c)

# 2. Check sidebar tags in home or any page
print("\n=== Checking all tags in sidebar on homepage ===")
home = fetcher.get('https://hentaifreak.org/', headers=headers, timeout=15)
tag_links = home.css('.widget-area a[href*="/tags/"], a[href*="/tags/"]')
print(f"Total /tags/ links on homepage: {len(tag_links)}")
for a in tag_links[:30]:
    print(f"Tag: href={a.attrib.get('href')} text='{a.get_all_text().strip()}'")

# Check if there is tag cloud or count in class
for a in tag_links[:5]:
    print(a.attrib, a.parent.attrib if hasattr(a, 'parent') and a.parent else '')
