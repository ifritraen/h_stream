import re
from scrapling.fetchers import Fetcher

headers = {'User-Agent': 'Mozilla/5.0'}
res = Fetcher.get('https://hentaipro.net/sitemap.xml', headers=headers)
content = res.body if isinstance(res.body, str) else res.body.decode('utf-8', errors='ignore')
urls = re.findall(r'<loc>(.*?)</loc>', content)

non_html = [u for u in urls if not u.endswith('.html')]
print(f"Total non-html: {len(non_html)}")

categories = []
series = []
years = []
others = []

for u in non_html:
    path = u.replace('https://sexhentai.net', '').replace('https://hentaipro.net', '')
    if path.startswith('/series/'):
        series.append(path)
    elif path.startswith('/year/'):
        years.append(path)
    else:
        categories.append(path)

print(f"Categories / Tags: {len(categories)}")
for c in categories:
    print("  Cat/Tag:", c)

print(f"Years: {len(years)}")
print(f"Series: {len(series)}")
