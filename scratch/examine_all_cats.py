from scrapling.fetchers import Fetcher

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://www.hentaicity.com/',
}

fetcher = Fetcher()
res = fetcher.get('https://www.hentaicity.com/categories/', headers=headers)
html = res.body.decode('utf-8', errors='ignore')

# Find where "All Categories and Tags" begins
idx = html.find("All Categories and Tags")
print("Found 'All Categories and Tags' at index:", idx)
if idx != -1:
    snippet = html[idx:idx+3000]
    print("Snippet:")
    print(snippet[:1500])

    # Let's see what tag links or lists follow it
    import re
    all_links = re.findall(r'<a\s+[^>]*href=["\']([^"\']+)["\'][^>]*>(.*?)</a>', html[idx:])
    print(f"\nTotal links after 'All Categories and Tags': {len(all_links)}")
    for href, text in all_links[:30]:
        clean_text = re.sub(r'<[^>]+>', '', text).strip()
        print(f"  {href} -> {clean_text}")
