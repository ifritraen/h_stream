from scrapling.fetchers import Fetcher
from bs4 import BeautifulSoup
import re

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaiera.com/',
}

# Fetch homepage
res = Fetcher.get('https://hentaiera.com/', headers=headers)
soup = BeautifulSoup(res.body, 'html.parser')

cats = set()
for el in soup.find_all(attrs={"data-categories": True}):
    cats.add(el['data-categories'])
print("data-categories seen on homepage:", cats)

# Check all links with /category/ or similar
all_cat_links = set()
for a in soup.find_all('a', href=re.compile(r'/categor')):
    all_cat_links.add((a.get_text(strip=True), a['href']))
print("Category links on homepage:", all_cat_links)

# Let's inspect a gallery page
sample_gallery = soup.select_one('.thumb .inner_thumb a')
if sample_gallery:
    g_url = f"https://hentaiera.com{sample_gallery['href']}" if sample_gallery['href'].startswith('/') else sample_gallery['href']
    print("Fetching sample gallery:", g_url)
    g_res = Fetcher.get(g_url, headers=headers)
    g_soup = BeautifulSoup(g_res.body, 'html.parser')
    for tag_box in g_soup.select('.tag_list, .categories, .tags, .tag-container'):
        print("Tag box:", tag_box.get_text(strip=True))
