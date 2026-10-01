from scrapling.fetchers import Fetcher

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://haho.moe/',
    'Cookie': 'loop-view=thumb;',
}

fetcher = Fetcher()

# Check /genre page structure
page_genre = fetcher.get("https://haho.moe/genre", headers=headers, timeout=15)
print("=== /genre pagination & cards ===")
genre_pagination = page_genre.css('ul.pagination a::attr(href)').getall()
print("Genre pagination links:", genre_pagination)

genre_cards = page_genre.css('ul.loop > li, .genre-loop > li')
print(f"Genre cards count on page 1: {len(genre_cards)}")
for card in genre_cards[:5]:
    href = card.css('a::attr(href)').get() or ''
    title = "".join(card.css('.label ::text, .title ::text, a ::text').getall()).strip()
    src = card.css('img::attr(src)').get() or card.css('img::attr(data-src)').get() or ''
    badge = "".join(card.css('.badge ::text, .count ::text, .overlay ::text').getall()).strip()
    print(f"Genre: href={href}, title={title}, img={src}, badge={badge}")

# Check /playlist page structure
page_pl = fetcher.get("https://haho.moe/playlist", headers=headers, timeout=15)
print("\n=== /playlist pagination & cards ===")
pl_pagination = page_pl.css('ul.pagination a::attr(href)').getall()
print("Playlist pagination links:", pl_pagination)
pl_cards = page_pl.css('ul.loop > li, .playlist-loop > li, ul.anime-loop > li')
print(f"Playlist cards count on page 1: {len(pl_cards)}")
for card in pl_cards[:5]:
    href = card.css('a::attr(href)').get() or ''
    title = "".join(card.css('.label ::text, .title ::text, span.thumb-title ::text').getall()).strip()
    src = card.css('img::attr(src)').get() or card.css('img::attr(data-src)').get() or ''
    overlay = "".join(card.css('.overlay ::text, .badge ::text, .count ::text, .top-overlay ::text, .bottom-overlay ::text').getall()).strip()
    print(f"Playlist: href={href}, title={title}, img={src}, overlay={overlay}")

# Check /anime filter controls / formats
page_anime = fetcher.get("https://haho.moe/anime", headers=headers, timeout=15)
print("\n=== /anime filters & sort options ===")
sort_options = page_anime.css('select option, .sort-group a, .filter-group a, .dropdown-menu a')
for opt in sort_options:
    val = opt.attrib.get('value', '') or opt.attrib.get('href', '')
    txt = "".join(opt.css('::text').getall()).strip()
    print(f"Option: {val} -> {txt}")
