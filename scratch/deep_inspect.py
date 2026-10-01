import sys
import io
import re
from scrapling.fetchers import Fetcher
from bs4 import BeautifulSoup

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaipro.net/',
}

# Check homepage and subpages
res = Fetcher.get('https://hentaipro.net/', headers=headers)
soup = BeautifulSoup(res.body, 'html.parser')

print("Page Title:", soup.title.get_text() if soup.title else "N/A")

# Look at header/navigation/footer/sidebar
nav = soup.select('nav, header, footer, .menu, .nav, .h2-drawer, .sidebar, ul')
print(f"Nav elements count: {len(nav)}")

# Find all links on the page
links = set()
for a in soup.find_all('a'):
    href = a.get('href', '')
    text = a.get_text(strip=True)
    if href and ('http' in href or href.startswith('/')):
        links.add((href, text))

print(f"Found {len(links)} unique links:")
for href, text in sorted(links):
    print(f"  {href} -> {text}")
