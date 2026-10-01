from scrapling.fetchers import Fetcher

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaitube.online/',
}

fetcher = Fetcher()
url = "https://www.hentaitube.online/tvshows/night-shift-nurses-kranke/"
page = fetcher.get(url, headers=HEADERS, timeout=10)

main = page.css('.content')
if main:
    text = main[0].get()
    # find episode or video or title
    print(text[1500:4000])
