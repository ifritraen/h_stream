from scrapling.fetchers import Fetcher
import re

fetcher = Fetcher()
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaiocean.com/',
}

res = fetcher.get('https://hentaiocean.com/sitemap.xml', headers=headers)
urls = re.findall(r'<loc>(.*?)</loc>', res.body.decode('utf-8', errors='ignore'))
print(f'Total URLs in sitemap: {len(urls)}')

categories = {}
for u in urls:
    prefix = '/'.join(u.replace('https://hentaiocean.com/', '').split('/')[:2])
    categories[prefix] = categories.get(prefix, 0) + 1

for k, v in sorted(categories.items(), key=lambda x: x[1], reverse=True)[:30]:
    print(f'{k:30}: {v}')
