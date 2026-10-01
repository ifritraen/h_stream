from scrapling.fetchers import Fetcher
import json

fetcher = Fetcher()
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaiocean.com/',
}

actions = [
    'genres', 'genre', 'playlists', 'playlist', 'series', 'list', 'all',
    'popular', 'explore', 'tags', 'tag', 'random', 'recent', 'categories', 'category'
]

for act in actions:
    res = fetcher.get(f'https://hentaiocean.com/api?action={act}', headers=headers, timeout=10)
    body = res.body.decode('utf-8', errors='ignore').strip()
    print(f'action={act:12} -> status: {res.status}, len: {len(body)}, sample: {body[:100]}')
