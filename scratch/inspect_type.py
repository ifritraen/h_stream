from scrapling.fetchers import Fetcher

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://haho.moe/',
    'Cookie': 'loop-view=thumb;',
}

fetcher = Fetcher()
page_type = fetcher.get("https://haho.moe/type", headers=headers, timeout=15)
print(f"Status: {page_type.status}")
cards = page_type.css('ul.loop > li')
print(f"Type items: {len(cards)}")
for c in cards:
    href = c.css('a::attr(href)').get() or ''
    title = "".join(c.css('.label ::text, .title ::text, a ::text').getall()).strip()
    img = c.css('img::attr(src)').get() or ''
    desc = c.css('a::attr(data-content)').get() or ''
    print(f"Type: href={href}, title={title}, img={img}, desc={desc}")
