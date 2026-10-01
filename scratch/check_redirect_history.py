from scrapling.fetchers import Fetcher

fetcher = Fetcher()
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaiocean.com/',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
}

for u in ['https://hentaiocean.com/playlists', 'https://hentaiocean.com/series']:
    res = fetcher.get(u, headers=headers)
    print(u, 'status:', res.status, 'url:', res.url)
    print('history:', getattr(res, 'history', None))
