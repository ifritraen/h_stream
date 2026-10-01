import sys
sys.stdout.reconfigure(encoding='utf-8')

from scrapling.fetchers import Fetcher
from bs4 import BeautifulSoup
import json
import re

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentai.sh/',
}

url = "https://hentai.sh/playlist/cmpsnu0xn000rirbwlmwmgjtu"
resp = Fetcher.get(url, headers=headers)
html = resp.body.decode('utf-8', errors='ignore')
soup = BeautifulSoup(html, 'html.parser')

print("Page Title:", soup.title.string if soup.title else "")
h1 = soup.find('h1')
print("H1:", h1.text if h1 else "None")

# Find video cards
cards = soup.find_all('a', href=re.compile(r'/video/'))
print(f"Total video cards: {len(cards)}")
for i, c in enumerate(cards[:5]):
    href = c.get('href')
    img = c.find('img')
    img_src = img.get('src') if img else ''
    title = c.find(['h2', 'h3', 'div', 'span'])
    text = c.get_text(separator=' | ', strip=True)
    print(f"[{i+1}] {href} | {text} | {img_src}")

# Check if there is an API endpoint for playlists or if playlist data is in RSC
idx = html.find('playlist')
print("\nCheck if playlist JSON is embedded in RSC:")
for m in re.finditer(r'\{"id":"cmpsnu0xn000rirbwlmwmgjtu".*?\}', html):
    print("Found JSON match:", m.group(0)[:300])
