from scrapling.fetchers import Fetcher
import re
import json

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentai.sh/',
}

# 1. Inspect playlists page
print("=== Fetching https://hentai.sh/playlists ===")
resp_pl = Fetcher.get('https://hentai.sh/playlists', headers=headers)
html_pl = resp_pl.body.decode('utf-8', errors='ignore')
print('Playlists final URL:', resp_pl.url)
print('Playlists HTML len:', len(html_pl))

links_pl = re.findall(r'href=["\'](/[^"\']+)["\']', html_pl)
print('Sample unique links on playlists page:', sorted(set(links_pl))[:40])

# 2. Inspect browse page
print("\n=== Fetching https://hentai.sh/browse ===")
resp_br = Fetcher.get('https://hentai.sh/browse', headers=headers)
html_br = resp_br.body.decode('utf-8', errors='ignore')
print('Browse final URL:', resp_br.url)
print('Browse HTML len:', len(html_br))

links_br = re.findall(r'href=["\'](/[^"\']+)["\']', html_br)
print('Sample unique links on browse page:', sorted(set(links_br))[:40])

# 3. Check for any API requests or data in Next.js JS bundles
# Let's find all chunks
chunks = re.findall(r'src="(/_next/static/chunks/[^"]+)"', html_br)
print('\nJS Chunks:', chunks[:10])
