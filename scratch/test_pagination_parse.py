from scrapling.fetchers import Fetcher

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaitube.online/',
}

fetcher = Fetcher()

for page_num in [1, 2]:
    url = f"https://www.hentaitube.online/genre/action/{page_num}" if page_num > 1 else "https://www.hentaitube.online/genre/action/"
    p = fetcher.get(url, headers=HEADERS, timeout=10)
    items = p.css('.item')
    print(f"Page {page_num} ({url}): {len(items)} items")
    for it in items[:3]:
        a = it.css('a')
        href = a[0].attrib.get('href') if a else ''
        img = it.css('img')
        src = img[0].attrib.get('src') if img else ''
        title = it.css('.title')
        t_text = title[0].text if title else (img[0].attrib.get('alt') if img else '')
        year = it.css('span')
        y_text = year[0].text if year else ''
        print(f"  Title: {t_text} | Year: {y_text} | Href: {href} | Cover: {src[:45]}...")
