from scrapling.fetchers import Fetcher
import re

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaipulse.com/'
}

for url in ['https://hentaipulse.com/tags/', 'https://hentaipulse.com/genres/', 'https://hentaipulse.com/browse/']:
    try:
        p = Fetcher.get(url, headers=headers, timeout=10)
        print(f'{url} -> status: {p.status}, len: {len(p.text)}')
        if len(p.text) > 0:
            with open('scratch/tags_dump.html', 'w', encoding='utf-8') as f:
                f.write(p.text)
            print(f'Wrote {len(p.text)} bytes to scratch/tags_dump.html')
            break
    except Exception as e:
        print(f'{url} -> error: {e}')
