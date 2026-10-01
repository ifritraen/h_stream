from scrapling.fetchers import Fetcher

p = Fetcher.get('https://hentaihaven.red/brand/oz/')
print('Status:', p.status)
print('Title:', p.css('title::text').first)
links = p.css('a')
video_links = [a.attrib.get('href') for a in links if '/watch/' in a.attrib.get('href', '')]
print('Videos found:', len(video_links))
imgs = [im.attrib.get('src') for im in p.css('img')]
print('Imgs:', imgs[:5])
