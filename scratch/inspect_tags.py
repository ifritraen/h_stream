from scrapling.fetchers import Fetcher
import re

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://www.hentaicity.com/',
}

fetcher = Fetcher()
res = fetcher.get('https://www.hentaicity.com/categories/', headers=headers)
html = res.body.decode('utf-8', errors='ignore')

# Search for all links to /tags/
tag_matches = re.findall(r'<a\s+[^>]*href=["\'](/tags/[^"\']+)["\'][^>]*>(.*?)</a>', html)
print(f"Total /tags/ links in page: {len(tag_matches)}")
unique_tags = {}
for href, text in tag_matches:
    clean_text = re.sub(r'<[^>]+>', '', text).strip()
    # slug
    slug = href.replace('/tags/video/', '').strip('/')
    if slug not in unique_tags:
        unique_tags[slug] = {
            'name': clean_text,
            'href': href,
            'slug': slug
        }

print(f"Unique tags: {len(unique_tags)}")
for s, data in list(unique_tags.items())[:20]:
    print(f"  {s}: name='{data['name']}', href='{data['href']}'")

# Check if there are other links or tabs:
tab_sections = re.findall(r'<div[^>]*id=["\']tab\d+["\'][^>]*>(.*?)</div>', html, re.DOTALL)
print(f"\nTab sections found: {len(tab_sections)}")
for i, tab in enumerate(tab_sections):
    links_in_tab = re.findall(r'<a\s+[^>]*href=["\']([^"\']+)["\'][^>]*>(.*?)</a>', tab)
    print(f"Tab {i} has {len(links_in_tab)} links")
    for h, t in links_in_tab[:5]:
        print(f"    {h} -> {re.sub(r'<[^>]+>', '', t).strip()}")
