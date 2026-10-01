from scrapling.fetchers import Fetcher

fetcher = Fetcher()
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaiocean.com/',
}

res = fetcher.get('https://hentaiocean.com/genre', headers=headers)
tags = res.css('a[href*="/genre/"]')
print(f'Total genre tags: {len(tags)}')
for t in tags:
    href = t.attrib.get('href')
    name = t.get_all_text().strip()
    slug = href.split('/genre/')[-1]
    print(f'{name:20} -> slug: {slug}')
