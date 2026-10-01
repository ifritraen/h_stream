from scrapling.fetchers import Fetcher

fetcher = Fetcher()
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaiocean.com/',
}

res = fetcher.get('https://hentaiocean.com/genre/3D', headers=headers)
cards = res.css('.grid a, a.card, a.cell')
print('matches in 3D:', len(cards))
watch_links = [a for a in res.css('a') if '/watch/' in (a.attrib.get('href') or '')]
print('watch links in 3D:', len(watch_links))
