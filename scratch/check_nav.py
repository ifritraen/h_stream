from bs4 import BeautifulSoup
from scrapling.fetchers import Fetcher

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaiera.com/',
}

# Fetch home page
home_page = Fetcher.get('https://hentaiera.com/', headers=headers)
soup = BeautifulSoup(home_page.body, 'html.parser')

print("--- NAVBAR LINKS ON HOMEPAGE ---")
for nav in soup.find_all(['nav', 'header', 'ul', 'div'], class_=lambda c: c and any(x in c for x in ['nav', 'menu', 'header'])):
    for a in nav.find_all('a'):
        href = a.get('href')
        text = a.get_text(strip=True)
        if href and ('category' in href or 'tag' in href or 'categories' in href or 'genre' in href):
            print(f"Text: '{text}', Href: '{href}'")

print("\n--- ALL A TAGS WITH CATEGORY/TAG ---")
seen = set()
for a in soup.find_all('a'):
    href = a.get('href', '')
    if any(k in href for k in ['categor', 'tag', 'artist', 'character', 'parod']):
        if href not in seen:
            seen.add(href)
            print(f"Text: '{a.get_text(strip=True)}', Href: '{href}'")
