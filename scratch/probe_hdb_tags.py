from scrapling.fetchers import Fetcher
import sys
import urllib.parse

sys.stdout.reconfigure(encoding='utf-8')

page = Fetcher.get('https://hentaidb.xyz/')
tag_links = page.css('a[href*="tag="]::attr(href)').getall()
tag_names = [urllib.parse.unquote(l.split('tag=')[-1]) for l in tag_links]
print('Tags on homepage:', list(set(tag_names)))

series_links = page.css('a[href^="/s/"]::attr(href)').getall()
all_tags = set(tag_names)
for s in series_links[1:8]:
    sp = Fetcher.get('https://hentaidb.xyz' + s)
    t = sp.css('a[href*="tag="]::text').getall()
    all_tags.update(t)
    print(f'{s}: {t}')

print('\nTotal unique tags discovered:', len(all_tags))
print('Discovered tags sample:', sorted(list(all_tags)))
