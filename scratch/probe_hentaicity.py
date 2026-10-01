from scrapling.fetchers import Fetcher

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://www.hentaicity.com/',
}

fetcher = Fetcher()
page = fetcher.get('https://www.hentaicity.com/categories/', headers=headers, timeout=15)

print("--- Categories page links and sections ---")
# Check .item.video-category
items = page.css('.item.video-category, div.outer-item')
print(f"Total video-category items: {len(items)}")
for i, item in enumerate(items[:5]):
    a = item.css('a')
    img = item.css('img')
    title = item.css('.title, h2, h3, a::text')
    print(f"Item {i}:")
    if a:
        print("  a:", a[0].attrib, a[0].get_all_text().strip())
    if img:
        print("  img:", img[0].attrib)
    print("  all text:", item.get_all_text().strip().replace('\n', ' '))

# Check .category-item
cat_items = page.css('.category-item')
print(f"\nTotal category-item elements: {len(cat_items)}")
for i, c in enumerate(cat_items[:10]):
    a = c.css('a')
    if a:
        print(f"  cat_item {i}: href={a[0].attrib.get('href')} text={a[0].get_all_text().strip()}")
    else:
        print(f"  cat_item {i}: text={c.get_all_text().strip()} attribs={c.attrib}")

# Let's check what tags links exist
tag_links = page.css('a[href*="/tags/"]')
print(f"\nTotal tag links: {len(tag_links)}")
for a in tag_links[:10]:
    print(f"  tag: href={a.attrib.get('href')} text={a.get_all_text().strip()}")
