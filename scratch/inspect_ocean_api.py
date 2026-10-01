from scrapling.fetchers import Fetcher
import re

fetcher = Fetcher()
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaiocean.com/',
}
res = fetcher.get('https://hentaiocean.com/api-docs', headers=headers)
html = res.body.decode('utf-8', errors='ignore')

endpoints = re.findall(r'/api\?[^\s"\'<>]+', html)
print('Endpoints found in api-docs:')
for ep in sorted(set(endpoints)):
    print(' ', ep)

code_blocks = res.css('pre code, code')
print('\nCode samples in docs:')
for cb in code_blocks:
    txt = cb.get_all_text().strip()
    if 'api' in txt or 'http' in txt:
        print('---')
        print(txt)
