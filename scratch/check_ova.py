from scrapling.fetchers import Fetcher

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://haho.moe/',
    'Cookie': 'loop-view=thumb;',
}

fetcher = Fetcher()
page_ova = fetcher.get("https://haho.moe/type/ova", headers=headers, timeout=15)
cards = page_ova.css('ul.anime-loop > li')
print(f"OVA cards count: {len(cards)}")
if cards:
    print(cards[0].prettify() if hasattr(cards[0], 'prettify') else cards[0].get())
