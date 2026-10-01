from scrapling.fetchers import Fetcher
import concurrent.futures
import time

fetcher = Fetcher()
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaiocean.com/',
}

test_genres = ['3D', 'Uncensored', 'Milf', 'Creampie', 'Big Boobs']

def fetch_genre(g):
    t0 = time.time()
    res = fetcher.get(f'https://hentaiocean.com/genre/{g}', headers=headers, timeout=10)
    cards = res.css('a.cell.card, a.card, .grid a[href*=\"/watch/\"]')
    first_img = ''
    if cards:
        img = cards[0].css('img::attr(src)').get() or ''
        first_img = img
    return g, res.status, len(cards), first_img, time.time() - t0

with concurrent.futures.ThreadPoolExecutor(max_workers=5) as ex:
    results = list(ex.map(fetch_genre, test_genres))

for r in results:
    print(r)
