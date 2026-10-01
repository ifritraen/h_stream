from scrapling.fetchers import Fetcher

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://haho.moe/',
    'Cookie': 'loop-view=thumb;',
}

fetcher = Fetcher()

# 1. Test genre feed: action (zdwxopnb)
p_genre = fetcher.get("https://haho.moe/genre/zdwxopnb", headers=headers, timeout=15)
cards_genre = p_genre.css('ul.anime-loop.loop > li > a, ul.anime-loop > li > a, ul.anime-loop li a')
print(f"Genre items parsed with _parseCards selector: {len(cards_genre)}")
for a in cards_genre[:3]:
    href = a.attrib.get('href', '')
    title = a.css('span.thumb-title::text').get() or a.attrib.get('title', '')
    img = a.css('img::attr(src)').get()
    print(f"  Anime: {title} | {href} | {img}")

# 2. Test format feed: ova
p_type = fetcher.get("https://haho.moe/type/ova", headers=headers, timeout=15)
cards_type = p_type.css('ul.anime-loop.loop > li > a, ul.anime-loop > li > a, ul.anime-loop li a')
print(f"\nType items parsed with _parseCards selector: {len(cards_type)}")
for a in cards_type[:3]:
    href = a.attrib.get('href', '')
    title = a.css('span.thumb-title::text').get() or a.attrib.get('title', '')
    img = a.css('img::attr(src)').get()
    print(f"  Type Anime: {title} | {href} | {img}")

# 3. Test playlist feed: bwjvsvun (1980s Uncensored)
p_pl = fetcher.get("https://haho.moe/playlist/bwjvsvun", headers=headers, timeout=15)
# In playlist page, let's see what selectors match
pl_vids = p_pl.css('li[id^="video_"], ul.loop > li, ul.episode-loop > li')
print(f"\nPlaylist items found: {len(pl_vids)}")
for v in pl_vids[:3]:
    href = v.css('a::attr(href)').get() or ''
    title_anm = v.css('.vdo_ttl_anm::text').get() or ''
    title_eps = v.css('.vdo_ttl_eps::text').get() or ''
    title = f"{title_anm} - {title_eps}".strip(" -")
    if not title:
        title = v.css('.thumb-title::text, .title::text').get() or ''
    img = v.css('img::attr(src)').get() or ''
    print(f"  PL Video: {title} | {href} | {img}")
