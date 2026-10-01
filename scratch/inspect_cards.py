from scrapling.fetchers import Fetcher
import json
import re

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaverse.com/',
}

fetcher = Fetcher()
r = fetcher.get('https://hentaverse.com/categories/school-girl', headers=headers, timeout=10)

links = r.css('a[href*="/video/"]')
print(f"Total /video/ links: {len(links)}")
for i, a in enumerate(links[:3]):
    print(f"\n--- Card {i+1} ---")
    print("Href:", a.attrib.get('href'))
    print("All Text:", repr(a.get_all_text().strip()))
    img = a.css('img')
    if img:
        print("Img attributes:", img[0].attrib)
    else:
        # Check parent
        p = a.parent
        print("Parent tag:", p.tag if p else None)
        if p:
            print("Parent img:", [x.attrib for x in p.css('img')])
