from scrapling.fetchers import Fetcher

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://haho.moe/',
    'Cookie': 'loop-view=thumb;',
}

fetcher = Fetcher()
page = fetcher.get("https://haho.moe/genre/zdwxopnb", headers=headers, timeout=15)
entry_info = page.css('.entry-information, .sidebar, .card, ul.list-group')
for ei in entry_info:
    print("Entry info text:\n", "".join(ei.css('::text').getall()).strip())
