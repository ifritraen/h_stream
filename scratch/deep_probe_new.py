from scrapling.fetchers import Fetcher
import sys
import json

sys.stdout.reconfigure(encoding='utf-8')

print("=== 1. HentaiDB ===")
try:
    hdb = Fetcher.get('https://hentaidb.xyz/')
    print('Title:', hdb.css('title::text').first)
    series_links = hdb.css('a[href^="/s/"]::attr(href)').getall()
    comic_links = hdb.css('a[href^="/comics/"]::attr(href)').getall()
    print(f'Series links count: {len(series_links)}, sample: {series_links[:5]}')
    print(f'Comic links count: {len(comic_links)}, sample: {comic_links[:5]}')

    if series_links:
        s_url = 'https://hentaidb.xyz' + series_links[0]
        s_page = Fetcher.get(s_url)
        print('Series page title:', s_page.css('title::text').first)
        episodes = s_page.css('a[href^="/e/"]::attr(href)').getall()
        print('Sample episodes:', episodes[:5])
        all_links = s_page.css('a::attr(href)').getall()
        print('Other links on series page:', [l for l in set(all_links) if not l.startswith('/e/') and not l.startswith('/s/')][:10])
except Exception as e:
    print('Error on HentaiDB:', e)

print("\n=== 2. Hentai.ht ===")
try:
    hht = Fetcher.get('https://hentai.ht/catalog')
    print('Catalog Title:', hht.css('title::text').first)
    titles = hht.css('a[href^="/title/"]::attr(href)').getall()
    print(f'Title links count: {len(titles)}, sample: {titles[:5]}')

    if titles:
        t_url = 'https://hentai.ht' + titles[0]
        t_page = Fetcher.get(t_url)
        print('Anime title:', t_page.css('title::text').first)
        all_t_links = t_page.css('a::attr(href)').getall()
        print('Links on title page:', list(set(all_t_links))[:15])
        genres = t_page.css('a[href^="/genre/"]::text, a[href^="/tag/"]::text').getall()
        print('Genres / Tags:', genres)
except Exception as e:
    print('Error on Hentai.ht:', e)
