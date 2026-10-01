from scrapling.fetchers import Fetcher

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://haho.moe/',
    'Cookie': 'loop-view=thumb;',
}

fetcher = Fetcher()
page = fetcher.get("https://haho.moe/anime/roxm2i6e", headers=headers, timeout=15)
genres = page.css('li.genre span.value a, div.genre-tree ul > li > a, a[href*="/genre/"]')
print(f"Genres on anime page: {len(genres)}")
for g in genres:
    print(" ", g.attrib.get('href', ''), "->", g.css('::text').get())

meta_items = page.css('ul.list-group li, .entry-information li, .meta li')
print(f"\nMeta items: {len(meta_items)}")
for m in meta_items:
    print(" ", "".join(m.css('::text').getall()).strip().replace('\n', ' '))
