import sys
sys.stdout.reconfigure(encoding='utf-8')

from scrapling.fetchers import Fetcher
import re
from bs4 import BeautifulSoup

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentai.sh/',
}

resp_com = Fetcher.get('https://hentai.sh/community', headers=headers)
html_com = resp_com.body.decode('utf-8', errors='ignore')
soup = BeautifulSoup(html_com, 'html.parser')

playlist_cards = soup.find_all('a', href=re.compile(r'/playlist/'))
print(f"Total playlist cards on community page: {len(playlist_cards)}")

# Check if there is pagination on community
pagination = soup.find_all(attrs={"class": re.compile(r'pagination|pager|page', re.I)})
print("Pagination elements:", pagination)

# Check query params like ?page=2
resp_com2 = Fetcher.get('https://hentai.sh/community?page=2', headers=headers)
html_com2 = resp_com2.body.decode('utf-8', errors='ignore')
soup2 = BeautifulSoup(html_com2, 'html.parser')
cards2 = soup2.find_all('a', href=re.compile(r'/playlist/'))
print(f"Page 2 cards: {len(cards2)}")

# Let's inspect the cards in detail
playlists = []
for card in playlist_cards:
    href = card.get('href', '')
    slug = href.split('/playlist/')[-1].strip('/')
    img = card.find('img')
    img_src = img.get('src') if img else ''
    
    # parse inner elements
    # Typical card structure:
    # Let's inspect the HTML of the first card
    playlists.append({
        'slug': slug,
        'href': href,
        'img': img_src,
        'html': str(card)
    })

print(f"Sample card 0 HTML:\n{playlists[0]['html']}\n")
