from scrapling.fetchers import Fetcher

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaitube.online/',
}

fetcher = Fetcher()
url = "https://www.hentaitube.online/tvshows/night-shift-nurses-kranke/"
page = fetcher.get(url, headers=HEADERS, timeout=10)

content = page.css('.sinfo, .content, .single_item, .data, .custom_fields, .extra')
for c in content[:5]:
    print("Class:", c.attrib.get('class'))
    for a in c.css('a'):
        print(f"  Link: text='{a.text}' href='{a.attrib.get('href')}'")
