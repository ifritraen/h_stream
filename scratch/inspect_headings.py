from scrapling.fetchers import Fetcher

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaitube.online/',
}

fetcher = Fetcher()
page = fetcher.get("https://hentaitube.online/", headers=HEADERS, timeout=10)

# Check widgets / sidebar / headings
for sidebar in page.css('.sidebar, aside, .widget, .side, .releases, .genres'):
    print(f"Widget/Sidebar class: {sidebar.attrib.get('class')}")
    h = sidebar.css('h1, h2, h3, h4, h5, .title, .widget-title')
    for heading in h:
        print(f"  Heading: {heading.text.strip() if heading.text else ''}")
