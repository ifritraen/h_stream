from scrapling.fetchers import Fetcher
import re
import json

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentai.sh/',
}

# 1. Fetch library?tab=playlists
resp_pl = Fetcher.get('https://hentai.sh/library?tab=playlists', headers=headers)
html_pl = resp_pl.body.decode('utf-8', errors='ignore')

print("Playlists page HTML len:", len(html_pl))

# Check for all occurrences of playlist in html_pl
for m in re.finditer(r'playlist', html_pl, re.IGNORECASE):
    start = max(0, m.start() - 100)
    end = min(len(html_pl), m.end() + 150)
    print("--- Playlist context in HTML ---")
    print(html_pl[start:end])

# 2. Check community page
print("\n=== Fetching https://hentai.sh/community ===")
resp_com = Fetcher.get('https://hentai.sh/community', headers=headers)
html_com = resp_com.body.decode('utf-8', errors='ignore')
print("Community status:", resp_com.status, "len:", len(html_com))
for m in re.finditer(r'playlist', html_com, re.IGNORECASE):
    start = max(0, m.start() - 100)
    end = min(len(html_com), m.end() + 150)
    print("--- Playlist context in Community ---")
    print(html_com[start:end])
