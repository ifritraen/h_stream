from scrapling.fetchers import Fetcher

fetcher = Fetcher()
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaiocean.com/',
}

test_urls = [
    'https://hentaiocean.com/api?action=genre&name=3D',
    'https://hentaiocean.com/api?action=genre&genre=3D',
    'https://hentaiocean.com/api?action=genres',
    'https://hentaiocean.com/api?action=getgenre&name=3D',
    'https://hentaiocean.com/api?action=filter&genre=3D',
    'https://hentaiocean.com/api?action=videos',
]

for u in test_urls:
    res = fetcher.get(u, headers=headers, timeout=10)
    print(f'{u:55} -> status: {res.status}, len: {len(res.body)}')
    print(res.body.decode('utf-8', errors='ignore')[:100])
