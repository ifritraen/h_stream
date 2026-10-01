from scrapling.fetchers import Fetcher
import re

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentai.sh/',
}

# Check search code in layout
resp = Fetcher.get('https://hentai.sh/_next/static/chunks/app/(site)/layout-d21565421f174797.js', headers=headers)
code = resp.body.decode('utf-8', errors='ignore')

# Find fetch calls in layout
fetches = re.findall(r'fetch\([^\)]+\)', code)
for f in fetches:
    print('Layout fetch:', f)

# Also check browse page chunk
resp_b = Fetcher.get('https://hentai.sh/_next/static/chunks/app/(site)/browse/page-b04e030b2987385a.js', headers=headers)
code_b = resp_b.body.decode('utf-8', errors='ignore')
fetches_b = re.findall(r'fetch\([^\)]+\)', code_b)
for f in fetches_b:
    print('Browse fetch:', f)
