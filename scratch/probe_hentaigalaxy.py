import sys
import json
from scrapling.fetchers import Fetcher

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
}

candidates = [
    'https://hentaigalaxy.me',
    'https://hentaigalaxy.tv',
    'https://hentaigalaxy.xyz',
    'https://hentaigalaxy.com',
    'https://hentaigalaxy.net',
    'https://hentaigalaxy.org',
    'https://galaxyhentai.com',
    'https://galaxyhentai.tv',
]

active_base = None

print("--- Probing Candidate Domains ---")
for base in candidates:
    try:
        print(f"Checking {base} ...")
        res = Fetcher.get(base, headers={**headers, 'Referer': base + '/'}, timeout=10)
        print(f"  Status: {res.status}")
        if res.status == 200 and len(res.body) > 500:
            print(f"  FOUND ACTIVE BASE: {base} (Length: {len(res.body)})")
            active_base = base
            with open('scratch/hentaigalaxy_home.html', 'w', encoding='utf-8') as f:
                f.write(res.body.decode('utf-8', errors='ignore'))
            break
    except Exception as e:
        print(f"  Error {base}: {e}")

if not active_base:
    print("No candidate base returned 200. Testing endpoints on https://hentaigalaxy.me anyway...")
    active_base = 'https://hentaigalaxy.me'

endpoints = [
    '/',
    '/categories/',
    '/category/',
    '/genres/',
    '/genre/',
    '/tags/',
    '/series/',
    '/popular/',
    '/trending/',
]

for ep in endpoints:
    url = f"{active_base}{ep}"
    try:
        res = Fetcher.get(url, headers={**headers, 'Referer': active_base + '/'}, timeout=8)
        print(f"Endpoint {url} -> {res.status} (Length: {len(res.body)})")
        if res.status == 200:
            fn = ep.strip('/').replace('/', '_') or 'root'
            with open(f"scratch/hentaigalaxy_{fn}.html", 'w', encoding='utf-8') as f:
                f.write(res.body.decode('utf-8', errors='ignore'))
    except Exception as e:
        print(f"Endpoint {url} -> Error: {e}")
