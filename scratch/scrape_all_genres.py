import concurrent.futures
from scrapling.fetchers import Fetcher

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://haho.moe/',
    'Cookie': 'loop-view=thumb;',
}

fetcher = Fetcher()

def fetch_genre_page(page_num):
    url = f"https://haho.moe/genre?page={page_num}" if page_num > 1 else "https://haho.moe/genre"
    page = fetcher.get(url, headers=headers, timeout=15)
    cards = page.css('ul.loop > li')
    results = []
    for c in cards:
        a = c.css('a')
        if not a:
            continue
        href = a.css('::attr(href)').get() or ''
        title = a.css('::attr(title)').get() or c.css('.thumb-title::text').get() or ''
        title = title.strip()
        desc = a.css('::attr(data-content)').get() or ''
        desc = desc.strip()
        if desc == "No description.":
            desc = ""
        img = c.css('img::attr(src)').get() or ''
        slug = href.split('/genre/')[-1].split('/')[0].strip()
        
        results.append({
            'name': title,
            'slug': slug,
            'desc': desc,
            'image': img,
            'has_real_image': not ('placeholder' in img or img == ''),
            'endpoint': f"/genre/{slug}",
        })
    return results

genres = []
with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
    futures = {executor.submit(fetch_genre_page, p): p for p in range(1, 30)}
    for f in concurrent.futures.as_completed(futures):
        genres.extend(f.result())

print(f"Total genres scraped: {len(genres)}")
genres_with_real_img = [g for g in genres if g['has_real_image']]
print(f"Genres with real image: {len(genres_with_real_img)}")
genres_with_desc = [g for g in genres if g['desc']]
print(f"Genres with description: {len(genres_with_desc)}")

# Sample genres
print("\nSample genres with real image:")
for g in genres_with_real_img[:10]:
    print(" ", g['name'], "->", g['slug'], "|", g['image'])
