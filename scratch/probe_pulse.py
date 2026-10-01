from scrapling.fetchers import Fetcher
import re

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaipulse.com/'
}

try:
    p = Fetcher.get('https://hentaipulse.com/', headers=headers, timeout=10)
    print('Home status:', p.status, 'Length:', len(p.text))
    tags = set(re.findall(r'href=[\'"]([^\'"]*(?:tag|category|genre|playlist|channel|video)[^\'"]*)[\'"]', p.text, re.IGNORECASE))
    print('Found relevant links:', len(tags))
    for t in sorted(list(tags))[:25]:
        print('  ', t)
except Exception as e:
    print('Error:', e)
