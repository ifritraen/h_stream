import sys
from scrapling.fetchers import Fetcher

sys.stdout.reconfigure(encoding='utf-8')

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaihaven.red/',
}

# 1. Check home page navigation and footer
p_home = Fetcher.get("https://hentaihaven.red/", headers=headers, timeout=15)
print("--- Header / Navigation Links on Home ---")
for a in p_home.css('nav a, header a, .menu a, footer a'):
    href = a.attrib.get('href', '')
    text = a.get_all_text().strip()
    print(f"  {text} -> {href}")

# 2. Check genres page structure
p_genres = Fetcher.get("https://hentaihaven.red/genres/", headers=headers, timeout=15)
print("\n--- Genres page cards ---")
# The container had class 'grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-6'
genre_cards = p_genres.css('div.grid > div, div.grid > a')
print(f"Genre items in grid: {len(genre_cards)}")
for i, c in enumerate(genre_cards[:5]):
    print(f"\nGenre card {i}:")
    print(c.html_content[:400])

# 3. Check series page structure
p_series = Fetcher.get("https://hentaihaven.red/series/", headers=headers, timeout=15)
print("\n--- Series page structure ---")
print(f"Title: {p_series.css('title::text').first}")
series_links = p_series.css('a[href*="/series/"]')
print(f"Total /series/ links: {len(series_links)}")
for a in series_links[:10]:
    print(f"  {a.get_all_text().strip()} -> {a.attrib.get('href', '')}")

# 4. Also check if there are studios / brands / categories in the HTML or sitemap!
