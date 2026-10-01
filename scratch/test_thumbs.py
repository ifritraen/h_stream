import json
from scrapling.fetchers import Fetcher

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
}

test_urls = [
    ('Italiano', 'https://hentaizone.me/italiano/'),
    ('Hentai Tette Grosse', 'https://hentaizone.me/hentai-tette-grosse/'),
    ('Video Hentai Sub Ita', 'https://hentaizone.me/hentai-sub-ita/'),
    ('Bondage', 'https://hentaizone.me/bondage/'),
    ('Milf', 'https://hentaizone.me/milf-hentai/'),
    ('creampie', 'https://hentaizone.me/tag/creampie/'),
    ('Ahegao', 'https://hentaizone.me/tag/ahegao/'),
    ('squirt', 'https://hentaizone.me/tag/squirt/'),
]

for name, url in test_urls:
    res = Fetcher.get(url, headers=headers)
    img = None
    for a in res.css('article, .post, .elementor-post'):
        imgs = a.css('img')
        if imgs:
            src = imgs[0].attrib.get('data-src') or imgs[0].attrib.get('src')
            if src and src.startswith('http'):
                img = src
                break
    print(f"{name}: {img}")
