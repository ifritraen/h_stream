from scrapling.fetchers import Fetcher
from bs4 import BeautifulSoup

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://www.onlyhentaistuff.com/',
}

res_models = Fetcher.get('https://www.onlyhentaistuff.com/models/', headers=headers)
soup_models = BeautifulSoup(res_models.body, 'html.parser')
model_items = soup_models.select('.list-models .item, .models .item, a.item[href*="/models/"]')
print(f'Model items: {len(model_items)}')
for item in model_items[:10]:
    title = item.select_one('.title').get_text(strip=True) if item.select_one('.title') else item.get('title')
    img = item.select_one('img')
    img_src = img.get('src') or img.get('data-src') if img else None
    count_el = item.select_one('.videos, .wrap')
    count = count_el.get_text(strip=True) if count_el else ''
    print(f'Model: {title} | {item.get("href")} | {img_src} | {count}')

# If no items found with those selectors, let's see what links exist containing /models/
if not model_items:
    links = [a for a in soup_models.select('a[href*="/models/"]') if a.get('href') != 'https://www.onlyhentaistuff.com/models/']
    print(f'Other /models/ links: {len(links)}')
    for a in links[:15]:
        print(a.get('href'), a.get_text(strip=True), a.find('img'))
