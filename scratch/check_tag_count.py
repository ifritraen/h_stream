from scrapling.fetchers import Fetcher
import re

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://www.hentaicity.com/',
}

fetcher = Fetcher()
res = fetcher.get('https://www.hentaicity.com/tags/video/3d+anal', headers=headers)
html = res.body.decode('utf-8', errors='ignore')

# Search for total count or numbers near title
# e.g. "Showing 1-20 of 145 videos" or similar
matches = re.findall(r'(\d+[\d,]*\s+(?:videos|results|items))', html, re.IGNORECASE)
print("Regex matches for video count:", matches)

# Check pagination numbers
page_links = res.css('.pagination a, .pages a, a.page')
for p in page_links:
    print("Page link:", p.attrib, p.get_all_text())
