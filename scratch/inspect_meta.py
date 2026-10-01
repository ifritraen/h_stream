from scrapling.fetchers import Fetcher
from bs4 import BeautifulSoup

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaiera.com/',
}

res = Fetcher.get('https://hentaiera.com/gallery/1728778/', headers=headers)
soup = BeautifulSoup(res.body, 'html.parser')

container = soup.find('div', class_='gallery_right') or soup.find('div', class_='info') or soup.find('div', id='info')
if not container:
    container = soup.find('main')

# print all elements with classes
for el in soup.select('ul.tags, .tag-container, .tag_list, .row, .container'):
    classes = el.get('class', [])
    print(f"<{el.name} class='{classes}'>")
    for li in el.find_all('li'):
        print("  LI:", li.get_text(" ", strip=True)[:100])
    for a in el.find_all('a', href=lambda h: h and any(x in h for x in ['/tag/', '/category/', '/artist/', '/character/', '/parody/'])):
        print("  A:", a.get('href'), a.get_text(strip=True))

