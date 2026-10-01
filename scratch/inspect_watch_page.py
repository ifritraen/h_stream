from scrapling.fetchers import Fetcher

fetcher = Fetcher()
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaiocean.com/',
}

res = fetcher.get('https://hentaiocean.com/watch/onaji-zemi-no-someya-san-ga-sexy-joyuu-datta-hanashi-8', headers=headers)
html = res.body.decode('utf-8', errors='ignore')

# print sections
print('compact-video-card count:', len(res.css('.compact-video-card')))
print('related count:', len(res.css('[class*=\"related\"]')))
print('playlist count:', len(res.css('[class*=\"playlist\"]')))
print('series count:', len(res.css('[class*=\"series\"]')))
for a in res.css('a'):
    href = a.attrib.get('href') or ''
    if any(k in href for k in ['series', 'playlist', 'franchise']):
        print('link with keyword:', href, a.get_all_text())
