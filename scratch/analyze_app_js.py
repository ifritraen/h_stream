import re

with open("scratch/app.js", "w", encoding="utf-8") as out:
    pass

import urllib.request
req = urllib.request.Request(
    'https://hentai.ht/assets/app.js',
    headers={
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0 Safari/537.36',
        'Referer': 'https://hentai.ht/',
    }
)
with urllib.request.urlopen(req) as resp:
    js = resp.read().decode('utf-8', errors='ignore')

with open("scratch/app.js", "w", encoding="utf-8") as out:
    out.write(js)

print("Saved scratch/app.js. Now analyzing keywords...")
for kw in ['fetch(', 'http', '.m3u8', '.mp4', 'src=', 'iframe', 'player', 'cdn', 'stream']:
    matches = [m.start() for m in re.finditer(re.escape(kw), js, re.IGNORECASE)]
    print(f"Keyword '{kw}': {len(matches)} occurrences")
    for idx in matches[:3]:
        start = max(0, idx - 60)
        end = min(len(js), idx + 100)
        print(f"   [{kw} snippet]: {js[start:end]}")
