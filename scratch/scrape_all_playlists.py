import concurrent.futures
from scrapling.fetchers import Fetcher

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://haho.moe/',
    'Cookie': 'loop-view=thumb;',
}

fetcher = Fetcher()

# Test scraping all 5 playlist pages
playlists = []
def fetch_playlist_page(page_num):
    url = f"https://haho.moe/playlist?page={page_num}" if page_num > 1 else "https://haho.moe/playlist"
    page = fetcher.get(url, headers=headers, timeout=15)
    cards = page.css('ul.loop > li')
    results = []
    for c in cards:
        title = c.css('.playlist-title::text').get()
        if not title:
            continue
        title = title.strip()
        href = c.css('.playlist-title::attr(href)').get() or ''
        slug = href.split('/playlist/')[-1].split('/')[0].strip()
        
        # image
        img = c.css('img.playlist-cover-image::attr(src)').get() or ''
        
        # user & video count
        user = c.css('.playlist-user a::text').get() or ''
        user = user.strip()
        
        count_text = c.css('.playlist-video-count::text').get() or ''
        count = 0
        if count_text:
            digits = "".join(filter(str.isdigit, count_text))
            if digits:
                count = int(digits)
        
        results.append({
            'name': title,
            'slug': slug,
            'user': user,
            'count': count,
            'image': img,
            'endpoint': f"/playlist/{slug}",
        })
    return results

with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
    futures = {executor.submit(fetch_playlist_page, p): p for p in range(1, 6)}
    for f in concurrent.futures.as_completed(futures):
        playlists.extend(f.result())

print(f"Total playlists scraped: {len(playlists)}")
if playlists:
    # sort by count descending
    playlists.sort(key=lambda x: x['count'], reverse=True)
    print("Top 5 playlists:")
    for p in playlists[:5]:
        print(" ", p)
