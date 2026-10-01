from scrapling.fetchers import Fetcher
from bs4 import BeautifulSoup

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://www.onlyhentaistuff.com/',
}

# Fetch a category page
res_cat_item = Fetcher.get('https://www.onlyhentaistuff.com/categories/animal-girls/', headers=headers)
soup_cat_item = BeautifulSoup(res_cat_item.body, 'html.parser')
articles_cat = soup_cat_item.select('article, .post, .item, .video-item')
print(f'Category animal-girls items: {len(articles_cat)}')
if articles_cat:
    a = articles_cat[0].select_one('a')
    img = articles_cat[0].select_one('img')
    print('Sample cat video:', a.get('href') if a else None, img.get('src') if img else None)

# Fetch a tag page
res_tag_item = Fetcher.get('https://www.onlyhentaistuff.com/tags/ahegao/', headers=headers)
soup_tag_item = BeautifulSoup(res_tag_item.body, 'html.parser')
articles_tag = soup_tag_item.select('article, .post, .item, .video-item')
print(f'Tag ahegao items: {len(articles_tag)}')
heading = soup_tag_item.select_one('h1, h2, .headline')
print('Tag heading:', heading.get_text(strip=True) if heading else None)
