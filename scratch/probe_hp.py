import json
from scrapling.fetchers import Fetcher

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaiparadise.tv/',
}

endpoints = [
    'https://hentaiparadise.tv/wp-json/wp/v2/taxonomies',
    'https://hentaiparadise.tv/wp-json/wp/v2/categories?per_page=100',
    'https://hentaiparadise.tv/wp-json/wp/v2/tags?per_page=100',
    'https://hentaiparadise.tv/wp-json/wp/v2/genres?per_page=100',
    'https://hentaiparadise.tv/sitemap_index.xml',
    'https://hentaiparadise.tv/wp-sitemap.xml',
    'https://hentaiparadise.tv/robots.txt',
]

for url in endpoints:
    try:
        r = Fetcher.get(url, headers=headers)
        print(f"{url} -> status: {r.status}, length: {len(r.body)}")
        if 'json' in url and r.status == 200:
            data = json.loads(r.body)
            if isinstance(data, dict):
                print("  Keys:", list(data.keys()))
            elif isinstance(data, list):
                sample = [x.get("name") for x in data[:5]]
                print(f"  Count: {len(data)}, Sample: {sample}")
        elif 'xml' in url and r.status == 200:
            print("  XML preview:", r.body[:300].decode('utf-8', errors='ignore'))
        elif 'robots.txt' in url and r.status == 200:
            print("  robots preview:", r.body[:300].decode('utf-8', errors='ignore'))
    except Exception as e:
        print(f"{url} -> error: {e}")
