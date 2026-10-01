from scrapling.fetchers import Fetcher

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://haho.moe/',
    'Cookie': 'loop-view=thumb;',
}

fetcher = Fetcher()
page = fetcher.get("https://haho.moe/genre/zdwxopnb", headers=headers, timeout=15)
print("Title:", page.css('title::text').get())
print("Heading:", page.css('h1::text, h2::text').getall())
print("Pagination:", page.css('ul.pagination a::text').getall())
print("Last page link:", page.css('ul.pagination li a::attr(href)').getall())
print("Breadcrumbs:", page.css('.breadcrumb ::text').getall())
