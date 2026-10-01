from scrapling.fetchers import Fetcher

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://haho.moe/',
    'Cookie': 'loop-view=thumb;',
}

fetcher = Fetcher()

for slug in ['bwjvsvun', 'ieixvoxs', '89kqayxv']:
    url = f"https://haho.moe/playlist/{slug}"
    p = fetcher.get(url, headers=headers, timeout=15)
    
    # Check playlist items
    vids = p.css('li[id^="video_"], ul.loop > li, ul.episode-loop > li')
    print(f"\nPlaylist {slug}: {len(vids)} items found")
    for v in vids[:3]:
        href = v.css('a::attr(href)').get() or ''
        title_anm = v.css('.vdo_ttl_anm::text').get() or ''
        title_eps = v.css('.vdo_ttl_eps::text').get() or ''
        title = f"{title_anm} - {title_eps}".strip(" -")
        if not title:
            title = "".join(v.css('.label ::text, .title ::text, span.thumb-title ::text').getall()).strip()
        img = v.css('img::attr(src)').get() or v.css('img::attr(data-src)').get() or ''
        print(f"  Item: title='{title}', href='{href}', img='{img}'")
