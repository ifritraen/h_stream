from scrapling.fetchers import Fetcher

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaitube.online/',
}

fetcher = Fetcher()
page = fetcher.get("https://hentaitube.online/", headers=HEADERS, timeout=10)

sidebar = page.css('.sidebar')
if sidebar:
    print(sidebar[0].get()[:2000])
