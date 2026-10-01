from scrapling.fetchers import Fetcher
import re

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaifreak.org/',
}

fetcher = Fetcher()

# 1. Harvest all tags/genres from pick-your-drug with their counts
p = fetcher.get('https://hentaifreak.org/pick-your-drug/', headers=headers, timeout=15)
entry = p.css('.entry-content')[0]

tags_found = []
# Each tag link usually has text and next sibling or parent with count (count)
for a in entry.css('a'):
    href = a.attrib.get('href', '').strip()
    text = a.get_all_text().strip()
    if '/tags/' in href:
        parent = a.parent
        parent_text = parent.get_all_text() if parent else ""
        match = re.search(r'\((\d+)\)', parent_text)
        count = int(match.group(1)) if match else 0
        slug = href.rstrip('/').split('/')[-1]
        tags_found.append({
            'name': text,
            'slug': slug,
            'href': href,
            'count': count
        })

print(f"Total tags extracted from pick-your-drug: {len(tags_found)}")
# Sort by count descending
tags_by_count = sorted(tags_found, key=lambda x: x['count'], reverse=True)
print("\nTop 30 tags by count:")
for t in tags_by_count[:30]:
    print(f"  {t['name']} ({t['slug']}): count={t['count']}, url={t['href']}")

# 2. Check year tags vs content tags vs studio tags
year_tags = [t for t in tags_found if re.match(r'^\d{4}$', t['name'])]
print(f"\nYear tags: {[t['name'] for t in year_tags]}")

# 3. Check categories
# Let's see what category links or category classes exist across the site
categories_harvested = []
# Let's inspect category links if any exist in the page
cat_links = p.css('a[href*="/category/"]')
print(f"Direct /category/ links: {len(cat_links)}")
for c in cat_links:
    print(c.attrib, c.get_all_text().strip())

