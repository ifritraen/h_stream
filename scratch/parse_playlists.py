from scrapling.fetchers import Fetcher
import re
from bs4 import BeautifulSoup

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentai.sh/',
}

# 1. Parse community page cards
resp_com = Fetcher.get('https://hentai.sh/community', headers=headers)
html_com = resp_com.body.decode('utf-8', errors='ignore')
soup = BeautifulSoup(html_com, 'html.parser')

playlist_cards = soup.find_all('a', href=re.compile(r'/playlist/'))
print(f"Found {len(playlist_cards)} playlist elements")

for i, card in enumerate(playlist_cards[:10]):
    href = card.get('href', '')
    img = card.find('img')
    img_src = img.get('src') if img else ''
    img_alt = img.get('alt') if img else ''
    text = card.get_text(separator=' | ', strip=True)
    print(f"[{i+1}] href: {href}")
    print(f"     img_src: {img_src}")
    print(f"     img_alt: {img_alt}")
    print(f"     text: {text}")

# 2. Check the playlist page structure
resp_pl = Fetcher.get('https://hentai.sh/playlist/cmpsnu0xn000rirbwlmwmgjtu', headers=headers)
html_pl = resp_pl.body.decode('utf-8', errors='ignore')
soup_pl = BeautifulSoup(html_pl, 'html.parser')

print("\n=== Playlist page details ===")
for tag in ['h1', 'h2', 'h3', 'title', 'meta']:
    found = soup_pl.find_all(tag)
    for f in found[:3]:
        print(f"[{tag}] {f}")
