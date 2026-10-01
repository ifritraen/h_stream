import sys
import io
from scrapling.fetchers import Fetcher
from bs4 import BeautifulSoup

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaipro.net/',
}

res = Fetcher.get('https://hentaipro.net/furachi-1.html', headers=headers)
soup = BeautifulSoup(res.body, 'html.parser')
print('Title:', soup.title.get_text() if soup.title else 'N/A')

# Look for tags / genres / categories
for a in soup.find_all('a'):
    href = a.get('href', '')
    text = a.get_text(strip=True)
    if 'html' not in href and href.count('/') <= 4:
        print(f"Link: {href} -> {text}")
