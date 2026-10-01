from scrapling.fetchers import Fetcher
import re

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentai.sh/',
}

resp_b = Fetcher.get('https://hentai.sh/_next/static/chunks/app/(site)/browse/page-b04e030b2987385a.js', headers=headers)
code_b = resp_b.body.decode('utf-8', errors='ignore')

# Let's inspect everything around props, tags, brands, genres
print("Length of browse page chunk:", len(code_b))

# Let's look for all occurrences of 'tags', 'brands', 'playlists', 'genres'
for m in re.finditer(r'(?:tags|brands|playlists|genres)', code_b, re.IGNORECASE):
    start = max(0, m.start() - 100)
    end = min(len(code_b), m.end() + 100)
    print("--- Context ---")
    print(code_b[start:end])
