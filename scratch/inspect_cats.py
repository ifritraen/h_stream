import json
from scrapling.fetchers import Fetcher
from bs4 import BeautifulSoup

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaiparadise.tv/',
}

# Categories
r_cats = Fetcher.get('https://hentaiparadise.tv/wp-json/wp/v2/categories?per_page=100', headers=headers)
cats = json.loads(r_cats.body)
print('=== WP REST CATEGORIES ===')
for c in cats:
    print(f"ID: {c.get('id')}, Name: {c.get('name')}, Slug: {c.get('slug')}, Count: {c.get('count')}, Link: {c.get('link')}")

# WP Sitemap
r_sitemap = Fetcher.get('https://hentaiparadise.tv/wp-sitemap.xml', headers=headers)
soup = BeautifulSoup(r_sitemap.body, 'xml')
print('=== SITEMAPS IN WP-SITEMAP ===')
for loc in soup.find_all('loc'):
    print(loc.text)
