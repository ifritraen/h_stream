from scrapling.fetchers import Fetcher
import re
import json
import concurrent.futures

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaifreak.org/',
}

fetcher = Fetcher()

print("1. Probing canonical routes...")
for test_url in ['https://hentaifreak.org/genres', 'https://hentaifreak.org/tags', 'https://hentaifreak.org/categories', 'https://hentaifreak.org/pick-your-drug/']:
    res = fetcher.get(test_url, headers=headers, timeout=15)
    print(f"  {test_url} -> status {res.status}")

print("\n2. Harvesting /pick-your-drug/ tags & counts...")
p = fetcher.get('https://hentaifreak.org/pick-your-drug/', headers=headers, timeout=15)
entry = p.css('.entry-content')[0]

raw_tags = []
for a in entry.css('a'):
    href = a.attrib.get('href', '').strip()
    text = a.get_all_text().strip()
    if '/tags/' in href:
        parent = a.parent
        parent_text = parent.get_all_text() if parent else ""
        match = re.search(r'\((\d+)\)', parent_text)
        count = int(match.group(1)) if match else 0
        slug = href.rstrip('/').split('/')[-1]
        raw_tags.append({
            'name': text,
            'slug': slug,
            'href': href,
            'count': count
        })

print(f"Harvested {len(raw_tags)} raw tags from pick-your-drug.")

# Let's test thumbnail fetching for top 5 tags
def fetch_tag_thumb(tag_item):
    try:
        page = fetcher.get(tag_item['href'], headers=headers, timeout=10)
        if page.status == 200:
            articles = page.css('article')
            if articles:
                img = articles[0].css('img')
                if img:
                    src = img[0].attrib.get('data-src') or img[0].attrib.get('src') or ''
                    return tag_item['slug'], src
    except Exception as e:
        pass
    return tag_item['slug'], ''

print("\n3. Testing thumbnail fetching for top 5 tags...")
for t in raw_tags[:5]:
    slug, thumb = fetch_tag_thumb(t)
    print(f"Tag {slug} -> thumb: {thumb}")
