from scrapling.fetchers import Fetcher
import json

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaifreak.org/',
}

fetcher = Fetcher()

# 1. Inspect pick-your-drug
page = fetcher.get('https://hentaifreak.org/pick-your-drug/', headers=headers, timeout=15)

print("=== PICK YOUR DRUG CONTENT SECTIONS ===")
content = page.css('.entry-content, article, main, #content')
for c in content:
    print("Class:", c.attrib.get('class'), "Id:", c.attrib.get('id'))
    # look at headings
    headings = c.css('h1, h2, h3, h4, h5')
    for h in headings:
        print("  Heading:", h.tag, h.get_all_text().strip())
    # look at divs or blocks
    divs = c.css('div')
    print("  Total divs:", len(divs))

# Let's save the raw HTML of entry-content to inspect
if content:
    with open('scratch/pick_your_drug_content.html', 'w', encoding='utf-8') as f:
        f.write(content[0].prettify() if hasattr(content[0], 'prettify') else str(content[0]))

# 2. Inspect view-all-series
print("\n=== VIEW ALL SERIES ===")
page2 = fetcher.get('https://hentaifreak.org/view-all-series/', headers=headers, timeout=15)
print("Series page status:", page2.status)
series_links = page2.css('a[href*="-hentai-video"], a[href*="hentaifreak.org"]')
print("Total links:", len(series_links))
content2 = page2.css('.entry-content, article, main, #content')
if content2:
    with open('scratch/view_all_series_content.html', 'w', encoding='utf-8') as f:
        f.write(content2[0].prettify() if hasattr(content2[0], 'prettify') else str(content2[0]))
