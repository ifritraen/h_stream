import sys
import io
from scrapling.fetchers import Fetcher
from bs4 import BeautifulSoup

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaipro.net/',
}

res = Fetcher.get('https://hentaipro.net/vanilla/', headers=headers)
soup = BeautifulSoup(res.body, 'html.parser')

for a in soup.find_all('a'):
    href = a.get('href', '')
    text = a.get_text(strip=True)
    if any(k in href for k in ['/2', '/page/', '?page=', 'page/2']):
        print(f"Pagin link: {href} -> text: '{text}'")

# Also check page 2 directly
res2 = Fetcher.get('https://hentaipro.net/vanilla/2/', headers=headers)
print("Page /vanilla/2/ status:", res2.status)
res3 = Fetcher.get('https://hentaipro.net/vanilla/page/2/', headers=headers)
print("Page /vanilla/page/2/ status:", res3.status)
