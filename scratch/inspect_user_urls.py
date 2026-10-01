from scrapling.fetchers import Fetcher

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaitube.online/',
}

fetcher = Fetcher()
for url in ["https://hentaitube.online/genre", "https://hentaitube.online/tags", "https://hentaitube.online/categories"]:
    p = fetcher.get(url, headers=HEADERS, timeout=10)
    print(f"URL: {url} -> status={p.status} redirected_to={p.url if hasattr(p, 'url') else 'N/A'}")
    title = p.css('title')
    print("  Title:", title[0].text if title else "")
    h1 = p.css('h1')
    print("  H1:", [h.text for h in h1])
    # check any lists or links
    print("  Items count:", len(p.css('.item, .post, article')))
