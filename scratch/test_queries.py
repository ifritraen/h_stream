from scrapling.fetchers import Fetcher
from bs4 import BeautifulSoup

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaiparadise.tv/',
}

queries = ['harem', 'vanilla', 'maid', 'nurse', 'milf', 'yuri', 'comedy', 'fantasy', 'beach', 'saimin', 'ntr']
for q in queries:
    r = Fetcher.get(f'https://hentaiparadise.tv/?s={q}', headers=headers)
    soup = BeautifulSoup(r.body, 'html.parser')
    posts = soup.select('article, .post, .uagb-post__inner-wrap')
    print(f'Query "{q}": status {r.status}, found {len(posts)} items')
