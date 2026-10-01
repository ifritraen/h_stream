import sys
import io
import json
import re
from scrapling.fetchers import Fetcher
from bs4 import BeautifulSoup

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaipro.net/',
}

for path in ['/categories/', '/tags/', '/genres/', '/']:
    url = f'https://hentaipro.net{path}'
    try:
        res = Fetcher.get(url, headers=headers)
        soup = BeautifulSoup(res.body, 'html.parser')
        with open(f'scratch/page_{path.replace("/", "_")}.html', 'w', encoding='utf-8') as f:
            f.write(res.body if isinstance(res.body, str) else res.body.decode('utf-8', errors='ignore'))
        print(f"URL: {url} -> status: {res.status}, title: {soup.title.string if soup.title else 'None'}")
    except Exception as e:
        print(f"Error {url}: {e}")
