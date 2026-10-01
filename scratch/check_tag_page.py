import sys
sys.stdout.reconfigure(encoding='utf-8')
from scrapling.fetchers import Fetcher

f = Fetcher()
r = f.get('https://hentaistream.xxx/tag/anime/', headers={'User-Agent': 'Mozilla/5.0'})
print('Status:', r.status)
articles = r.css('article, .video-block, .item, .post, .vid_item, .thumb')
print('Articles count:', len(articles))
print('Sample article HTML:')
if articles:
    print(articles[0].get()[:300])

pagination = [a.attrib.get('href') for a in r.css('a[href*="page"]')]
print('Pagination links:', pagination[:10])

# Also check video cards selector on hentaistream
all_divs = r.css('div[class*="video"], div[class*="item"], div[class*="post"], div[class*="card"], div[class*="thumb"]')
print('Potential card classes:', set([d.attrib.get('class') for d in all_divs]))
