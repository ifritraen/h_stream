from scrapling.fetchers import Fetcher
from bs4 import BeautifulSoup

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaiera.com/',
}

res = Fetcher.get('https://hentaiera.com/gallery/1728778/', headers=headers)
soup = BeautifulSoup(res.body, 'html.parser')

for li in soup.find_all(['li', 'div', 'tr'], class_=lambda c: c and any(x in c for x in ['tag', 'category', 'info'])):
    text = li.get_text(" ", strip=True)
    if any(k in text.lower() for k in ['categor', 'tag', 'artist', 'parod', 'group', 'character', 'language']):
        print(text[:120])
