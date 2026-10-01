from scrapling.fetchers import Fetcher

fetcher = Fetcher()
res = fetcher.get('https://www.hentaicity.com/tags/', headers={'User-Agent': 'Mozilla/5.0'})
print("Status:", res.status)
print("Title:", res.css('title::text').get())
h1 = res.css('h1, h2')
for h in h1[:10]:
    print("Heading:", h.tag, h.get_all_text().strip())

# Check if there are any tag-specific elements
tags = res.css("a[href*='/tags/'], a[href*='/tag/']")
print("Tag links count on /tags/ page:", len(tags))
