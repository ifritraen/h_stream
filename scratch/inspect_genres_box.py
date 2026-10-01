from scrapling.fetchers import Fetcher

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaitube.online/',
}

fetcher = Fetcher()
page = fetcher.get("https://hentaitube.online/", headers=HEADERS, timeout=10)

genres_boxes = page.css('.genres')
print(f"Total .genres boxes: {len(genres_boxes)}")
for idx, box in enumerate(genres_boxes):
    print(f"\n--- Box {idx} class={box.attrib.get('class')} ---")
    links = box.css('a')
    print(f"Total links in box {idx}: {len(links)}")
    for a in links[:10]:
        print(f"  {a.text.strip() if a.text else ''} -> {a.attrib.get('href')} | inner: {a.get()[:100]}")
