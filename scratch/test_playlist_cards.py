import sys
sys.stdout.reconfigure(encoding='utf-8')

from scrapling.fetchers import Fetcher
from bs4 import BeautifulSoup

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentai.sh/',
}

url = "https://hentai.sh/playlist/cmqzjk0wg00a4irsjti3o813v"
resp = Fetcher.get(url, headers=headers)
soup = BeautifulSoup(resp.body.decode('utf-8', errors='ignore'), 'html.parser')

cards = soup.select('article, .post, .item, .sh-item, .video-card, a.video-card')
print(f"Cards found matching selector: {len(cards)}")
for i, c in enumerate(cards):
    href = c.get('href') if c.name == 'a' else (c.find('a').get('href') if c.find('a') else '')
    img = c.find('img')
    src = img.get('src') or img.get('data-src') if img else ''
    h = c.find(['h2', 'h3', '.title'])
    title = h.text.strip() if h else (img.get('alt', '') if img else '')
    print(f"Card {i+1}: title='{title}', href='{href}', img='{src}'")
