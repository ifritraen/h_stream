from scrapling.fetchers import Fetcher
from bs4 import BeautifulSoup

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaiera.com/',
}

res = Fetcher.get('https://hentaiera.com/tags/popular/', headers=headers)
soup = BeautifulSoup(res.body, 'html.parser')
thumbs = soup.select('.row.galleries .thumb')
print(f"Popular tags count on page 1: {len(thumbs)}")

for t in thumbs[:10]:
    title = t.select_one('.gallery_title a')
    count = t.select_one('.inside_p')
    img = t.select_one('img')
    img_src = img.get('data-src') if img else ''
    href = title.get('href') if title else ''
    name = title.get_text(strip=True) if title else ''
    c_val = count.get_text(strip=True) if count else ''
    print(f"Tag: {name} | Slug: {href} | Count: {c_val} | Cover: {img_src}")

