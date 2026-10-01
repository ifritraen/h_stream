from scrapling.fetchers import Fetcher

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaifreak.org/',
}

fetcher = Fetcher()
p = fetcher.get('https://hentaifreak.org/tags/3d/', headers=headers, timeout=15)
articles = p.css('article')
if articles:
    print("Article 0 HTML:")
    print(articles[0].prettify() if hasattr(articles[0], 'prettify') else str(articles[0]))
