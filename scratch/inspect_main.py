from scrapling.fetchers import Fetcher

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaitube.online/',
}

fetcher = Fetcher()
url = "https://www.hentaitube.online/tvshows/night-shift-nurses-kranke/"
page = fetcher.get(url, headers=HEADERS, timeout=10)

main = page.css('#single, .sheader, .single-item, #content, .content, main')
for m in main:
    print(f"Main tag={m.tag} id={m.attrib.get('id')} class={m.attrib.get('class')}")
    print(m.get()[:1500])
    break
