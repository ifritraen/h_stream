from scrapling.fetchers import Fetcher

fetcher = Fetcher()
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaiocean.com/',
}

res = fetcher.get('https://hentaiocean.com/watch/onaji-zemi-no-someya-san-ga-sexy-joyuu-datta-hanashi-8', headers=headers)
for c in res.css('.compact-video-card'):
    a = c.css('a')[0]
    title = c.css('.compact-title::text').get() or c.get_all_text().strip()
    print(a.attrib.get('href'), '->', title)
