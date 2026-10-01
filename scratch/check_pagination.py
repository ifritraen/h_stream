from scrapling.fetchers import Fetcher
from bs4 import BeautifulSoup

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://www.onlyhentaistuff.com/',
}

# Check categories pagination
res_cat = Fetcher.get('https://www.onlyhentaistuff.com/categories/', headers=headers)
soup_cat = BeautifulSoup(res_cat.body, 'html.parser')
cat_pagination = soup_cat.select('.pagination a, .paging a, ul.pagination li')
print('Cat pagination:', [p.get_text(strip=True) for p in cat_pagination])

# Check models pagination
res_models = Fetcher.get('https://www.onlyhentaistuff.com/models/', headers=headers)
soup_models = BeautifulSoup(res_models.body, 'html.parser')
models_pagination = soup_models.select('.pagination a, .paging a, ul.pagination li')
print('Models pagination:', [p.get_text(strip=True) for p in models_pagination])

# Check tags structure
res_tags = Fetcher.get('https://www.onlyhentaistuff.com/tags/', headers=headers)
soup_tags = BeautifulSoup(res_tags.body, 'html.parser')
tags_pagination = soup_tags.select('.pagination a, .paging a, ul.pagination li')
print('Tags pagination:', [p.get_text(strip=True) for p in tags_pagination])
