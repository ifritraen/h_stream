import re
from scrapling.fetchers import Fetcher
from bs4 import BeautifulSoup

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://www.onlyhentaistuff.com/',
}

# 1. Tags
res_tags = Fetcher.get('https://www.onlyhentaistuff.com/tags/', headers=headers)
soup_tags = BeautifulSoup(res_tags.body, 'html.parser')
tag_links = soup_tags.select('a[href*="/tags/"]')
print(f'Total tag links: {len(tag_links)}')
for a in tag_links[:10]:
    print(a.get('href'), a.get_text(strip=True))

# 2. Models / Directors (Studios)
res_models = Fetcher.get('https://www.onlyhentaistuff.com/models/', headers=headers)
print(f'Models status: {res_models.status}, final_url: {res_models.url}')
soup_models = BeautifulSoup(res_models.body, 'html.parser')
model_cards = soup_models.select('a.item, .item, article, a[href*="/models/"]')
print(f'Total models/directors cards: {len(model_cards)}')
if model_cards:
    print('Sample model card:')
    print(str(model_cards[0])[:400])

# 3. Categories in detail
res_cat = Fetcher.get('https://www.onlyhentaistuff.com/categories/', headers=headers)
soup_cat = BeautifulSoup(res_cat.body, 'html.parser')
cat_cards = soup_cat.select('a.item')
print(f'Total cat_cards: {len(cat_cards)}')
for c in cat_cards[:5]:
    title = c.select_one('.title').get_text(strip=True) if c.select_one('.title') else c.get('title')
    img = c.select_one('img')
    img_src = img.get('src') or img.get('data-src') if img else None
    count_el = c.select_one('.videos')
    count = count_el.get_text(strip=True) if count_el else ''
    rating_el = c.select_one('.rating')
    rating = rating_el.get_text(strip=True) if rating_el else ''
    print(f'Cat: title={title}, href={c.get("href")}, img={img_src}, count={count}, rating={rating}')
