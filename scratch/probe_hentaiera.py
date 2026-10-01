import json
from scrapling.fetchers import Fetcher

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaiera.com/',
}

print("Fetching categories...")
cat_page = Fetcher.get('https://hentaiera.com/categories/', headers=headers)
print("Categories status:", cat_page.status)

# Print some of the HTML around categories
with open('scratch/categories.html', 'w', encoding='utf-8') as f:
    f.write(cat_page.body.decode('utf-8', errors='ignore'))

print("Fetching tags...")
tag_page = Fetcher.get('https://hentaiera.com/tags/', headers=headers)
print("Tags status:", tag_page.status)

with open('scratch/tags.html', 'w', encoding='utf-8') as f:
    f.write(tag_page.body.decode('utf-8', errors='ignore'))

print("Done saving raw HTML files to scratch/")
