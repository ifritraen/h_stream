from scrapling.fetchers import Fetcher
import re

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaitube.online/',
}

fetcher = Fetcher()

# Check several show pages
shows = [
    "https://www.hentaitube.online/tvshows/zutto-suki-datta/",
    "https://www.hentaitube.online/tvshows/magical-moe/",
    "https://www.hentaitube.online/tvshows/kanojo-face/",
    "https://www.hentaitube.online/tvshows/meltys-quest/",
]

for url in shows:
    p = fetcher.get(url, headers=HEADERS, timeout=10)
    print(f"Show: {url}")
    for a in p.css('a'):
        href = a.attrib.get('href', '')
        text = a.text.strip() if a.text else ''
        if any(term in href for term in ['/tag/', '/tags/', '/genre/', '/category/', '/studio/']):
            print(f"  {text} -> {href}")
