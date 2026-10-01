from scrapling.fetchers import Fetcher
import re

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaverse.com/',
}

fetcher = Fetcher()

r1 = fetcher.get('https://hentaverse.com/categories/school-girl?page=1', headers=headers, timeout=10)
r2 = fetcher.get('https://hentaverse.com/categories/school-girl?page=2', headers=headers, timeout=10)

v1 = re.findall(r'/video/([a-zA-Z0-9_\-]+)', r1.body.decode('utf-8', errors='ignore'))
v2 = re.findall(r'/video/([a-zA-Z0-9_\-]+)', r2.body.decode('utf-8', errors='ignore'))

# Order preserving unique list
def unique(seq):
    seen = set()
    return [x for x in seq if not (x in seen or seen.add(x))]

u1 = unique(v1)
u2 = unique(v2)

print(f"Page 1 videos ({len(u1)}):", u1[:5])
print(f"Page 2 videos ({len(u2)}):", u2[:5])
print("Overlap between page 1 and page 2:", len(set(u1).intersection(set(u2))))
