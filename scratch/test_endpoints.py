from scrapling.fetchers import Fetcher

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaifreak.org/',
}

fetcher = Fetcher()

test_urls = [
    'https://hentaifreak.org/tags/big-boobs/',
    'https://hentaifreak.org/tags/big-boobs/page/2/',
    'https://hentaifreak.org/tags/3d/',
    'https://hentaifreak.org/tags/uncensored-hentai/',
    'https://hentaifreak.org/tags/ahegao-hentai/',
    'https://hentaifreak.org/hentai-series/overflow-hentai-video/',
    'https://hentaifreak.org/hentai-series/overflow-hentai-video/page/2/',
]

for url in test_urls:
    try:
        p = fetcher.get(url, headers=headers, timeout=15)
        print(f"URL: {url} -> Status: {p.status}")
        articles = p.css('article, .post, .item, .freak-item')
        print(f"  Articles found: {len(articles)}")
        if articles:
            a = articles[0].css('header h2 a, a')
            img = articles[0].css('img')
            print(f"  Sample article 0: title='{a[0].get_all_text().strip() if a else ''}', href='{a[0].attrib.get('href') if a else ''}', img='{img[0].attrib.get('src') if img else ''}'")
    except Exception as e:
        print(f"Error {url}: {e}")
