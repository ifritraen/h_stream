from scrapling.fetchers import Fetcher

fetcher = Fetcher()
res = fetcher.get('https://www.hentaicity.com/categories/', headers={'User-Agent': 'Mozilla/5.0'})
all_tag_links = res.css("a[href*='/tags/']")
cat_item_tag_links = res.css(".category-item a[href*='/tags/']")
print('Total tag links:', len(all_tag_links))
print('Inside .category-item:', len(cat_item_tag_links))

cat_item_hrefs = set(a.attrib.get('href', '') for a in cat_item_tag_links)
outside = [a for a in all_tag_links if a.attrib.get('href', '') not in cat_item_hrefs]
print('Outside .category-item count:', len(outside))
for a in outside[:10]:
    print('  outside:', a.attrib, a.get_all_text().strip(), a.parent.tag, a.parent.attrib)
