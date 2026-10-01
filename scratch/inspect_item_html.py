import re
from scrapling.fetchers import Fetcher

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaitube.online/',
}

fetcher = Fetcher()
page = fetcher.get("https://hentaitube.online/genre/uncensored/", headers=HEADERS, timeout=10)

cards = page.css('.item')
if cards:
    print("=== ITEM HTML ===")
    print(cards[0].get())

print("\n=== ALL LINKS ON PAGE WITH 'page' or numbers ===")
for a in page.css('a'):
    href = a.attrib.get('href', '')
    if any(p in href for p in ['page', 'paged', '/2', '?p=']):
        print(f"Pagination link: text='{a.text}' href='{href}'")

# Check footer or navigation
print("\n=== DIVS WITH CLASS OR ID CONTAINING page, nav, pagin ===")
for el in page.css('[class*="page"], [class*="pagin"], [class*="nav"], [id*="page"], [id*="pagin"]'):
    print(f"El: tag={el.tag} class={el.attrib.get('class')} id={el.attrib.get('id')}")
