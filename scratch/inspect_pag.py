from scrapling.fetchers import Fetcher

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaitube.online/',
}

fetcher = Fetcher()
page = fetcher.get("https://hentaitube.online/genre/uncensored/", headers=HEADERS, timeout=10)

pag = page.css('#paginacao, .paginacao')
for p in pag:
    print("PAGINACAO HTML:", p.get())
