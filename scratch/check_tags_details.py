from scrapling.fetchers import Fetcher
from bs4 import BeautifulSoup
import re

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://www.onlyhentaistuff.com/',
}

# Tags
res_tags = Fetcher.get('https://www.onlyhentaistuff.com/tags/', headers=headers)
soup_tags = BeautifulSoup(res_tags.body, 'html.parser')
tag_links = soup_tags.select('a[href*="/tags/"]')
print(f'Total tag links: {len(tag_links)}')
for a in tag_links[10:25]:
    parent = a.parent
    print(f'Tag: {a.get_text(strip=True)} | href={a.get("href")} | parent_text={parent.get_text(strip=True)}')

# Let's inspect model items: do they have images?
res_models = Fetcher.get('https://www.onlyhentaistuff.com/models/', headers=headers)
soup_models = BeautifulSoup(res_models.body, 'html.parser')
model_items = soup_models.select('.list-models .item, .models .item, a.item[href*="/models/"]')
if model_items:
    print('\nModel HTML sample:')
    print(str(model_items[0]))
