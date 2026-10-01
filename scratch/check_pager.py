import sys
sys.stdout.reconfigure(encoding='utf-8')

from scrapling.fetchers import Fetcher
from bs4 import BeautifulSoup
import re

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentai.sh/',
}

resp_com = Fetcher.get('https://hentai.sh/community', headers=headers)
html_com = resp_com.body.decode('utf-8', errors='ignore')
soup = BeautifulSoup(html_com, 'html.parser')

pager = soup.find('nav', class_='pagination')
if pager:
    for a in pager.find_all('a'):
        print(a.get('href'), a.text.strip())
