from scrapling.fetchers import Fetcher
import json
import re

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaverse.com/',
}

fetcher = Fetcher()
r = fetcher.get('https://hentaverse.com/categories/school-girl', headers=headers, timeout=10)
html = r.body.decode('utf-8', errors='ignore')

# Save full category page html
with open('scratch/cat_page_full.html', 'w', encoding='utf-8') as f:
    f.write(html)

pos = html.find('"videos":')
print("Position of '\"videos\":':", pos)
if pos != -1:
    print(html[pos:pos+1000])
