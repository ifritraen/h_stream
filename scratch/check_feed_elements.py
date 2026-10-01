from scrapling.fetchers import Fetcher
from bs4 import BeautifulSoup

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://www.onlyhentaistuff.com/',
}

res = Fetcher.get('https://www.onlyhentaistuff.com/categories/animal-girls/', headers=headers)
soup = BeautifulSoup(res.body, 'html.parser')
elements = soup.select('article, .post, .item, .video-item')
print(f'Total elements: {len(elements)}')
for i, el in enumerate(elements):
    a = el.select_one('a')
    href = a.get('href') if a else el.get('href')
    img = el.select_one('img')
    title = el.select_one('.title')
    title_text = title.get_text(strip=True) if title else (a.get('title') if a else '')
    print(f'[{i}] tag={el.name}, class={el.get("class")}, href={href}, title={title_text}')
