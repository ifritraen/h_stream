from scrapling.fetchers import Fetcher
import re

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentai.sh/',
}

resp_br = Fetcher.get('https://hentai.sh/browse', headers=headers)
html_br = resp_br.body.decode('utf-8', errors='ignore')

# 1. Inspect the RSC pushes in browse page
print("=== RSC pushes in browse page ===")
pushes = re.findall(r'self\.__next_f\.push\(\[(.*?)\'\]\)', html_br, re.DOTALL)
for i, p in enumerate(pushes):
    # unescape some quotes
    cleaned = p.replace('\\"', '"').replace('\\n', '\n')
    # search for keywords
    matches = re.findall(r'["\']([a-zA-Z0-9_\-\s]{3,30})["\']', cleaned)
    # Check if there are tag/genre names
    for kw in ['tag', 'genre', 'playlist', 'brand', 'studio', 'category', 'censored', 'uncensored']:
        if kw in cleaned.lower():
            print(f"Push {i} contains '{kw}'! Sample: {cleaned[:300]}...\n")
            break

# 2. Find all script chunks in html_br
chunks = re.findall(r'src="(/_next/static/chunks/[^"]+)"', html_br)
print(f"\n=== Found {len(chunks)} JS chunks ===")

for c in set(chunks):
    chunk_url = f"https://hentai.sh{c}"
    resp_c = Fetcher.get(chunk_url, headers=headers)
    c_text = resp_c.body.decode('utf-8', errors='ignore')
    
    # check for api routes or genre lists
    for kw in ['genres', 'tags', 'playlists', 'categories', '/api/']:
        if kw in c_text.lower():
            # Find occurrences
            found = re.findall(rf'.{{0,60}}{re.escape(kw)}.{{0,60}}', c_text, re.IGNORECASE)
            print(f"Chunk {c} mentions '{kw}':")
            for f in found[:3]:
                print(f"   {f.strip()}")
