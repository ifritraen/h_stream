from scrapling.fetchers import Fetcher

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://haho.moe/',
    'Cookie': 'loop-view=thumb;',
}

fetcher = Fetcher()

# Check raw html of /genre cards
page_genre = fetcher.get("https://haho.moe/genre", headers=headers, timeout=15)
cards = page_genre.css('ul.loop > li')
print("=== /genre raw card sample ===")
if cards:
    print(cards[0].prettify() if hasattr(cards[0], 'prettify') else cards[0].get())
    print(cards[2].prettify() if hasattr(cards[2], 'prettify') else cards[2].get())

# Check raw html of /playlist cards
page_pl = fetcher.get("https://haho.moe/playlist", headers=headers, timeout=15)
pl_cards = page_pl.css('ul.loop > li')
print("\n=== /playlist raw card sample ===")
if pl_cards:
    print(pl_cards[0].prettify() if hasattr(pl_cards[0], 'prettify') else pl_cards[0].get())
    print(pl_cards[1].prettify() if hasattr(pl_cards[1], 'prettify') else pl_cards[1].get())

# Also check what a genre page looks like: e.g. https://haho.moe/genre/zdwxopnb (action)
page_action = fetcher.get("https://haho.moe/genre/zdwxopnb", headers=headers, timeout=15)
print("\n=== /genre/zdwxopnb sample ===")
action_cards = page_action.css('ul.anime-loop > li')
print(f"Action anime cards count: {len(action_cards)}")
if action_cards:
    print(action_cards[0].prettify() if hasattr(action_cards[0], 'prettify') else action_cards[0].get())

# Also check a playlist page: e.g. https://haho.moe/playlist/bwjvsvun
page_pl_item = fetcher.get("https://haho.moe/playlist/bwjvsvun", headers=headers, timeout=15)
print("\n=== /playlist/bwjvsvun sample ===")
pl_item_cards = page_pl_item.css('ul.anime-loop > li, ul.episode-loop > li, ul.loop > li')
print(f"Playlist items count: {len(pl_item_cards)}")
if pl_item_cards:
    print(pl_item_cards[0].prettify() if hasattr(pl_item_cards[0], 'prettify') else pl_item_cards[0].get())
