from scrapling.fetchers import Fetcher
import re

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://www.hentaicity.com/',
}

fetcher = Fetcher()
res = fetcher.get('https://www.hentaicity.com/categories/', headers=headers)
html = res.body.decode('utf-8', errors='ignore')

# Let's find where .category-item is defined and what surrounds it
cat_items = res.css('.category-item')
print(f"Total .category-item: {len(cat_items)}")
for c in cat_items[:5]:
    print("category-item HTML:")
    print(res.prettify(c) if hasattr(res, 'prettify') else c.text)

# Also let's check what headings are above each group of tags
# In HTML, are there parent containers, headings, counts?
# Let's inspect the container holding .category-item
for p in res.css('.category-item')[:3]:
    parent = p.parent
    if parent:
        print("Parent of category-item:", parent.tag, parent.attrib)
        prev = p.previous
        if prev:
            print("Previous sibling:", prev.tag if hasattr(prev, 'tag') else prev)
