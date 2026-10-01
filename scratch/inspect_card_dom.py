from scrapling.fetchers import Fetcher
from scrapling.parser import Adaptor

f = Fetcher()
r_milf = f.get('https://www.hentaiworld.me/archive?genre=milf')
doc_milf = Adaptor(r_milf.body.decode('utf-8'))

# Let's inspect the cards
cards = doc_milf.css('.film-item, .entry, .item, .anime-card, .col-6, .col-md-4, .col-lg-3, .col-xl-2, .card')
print("Candidate cards:", len(cards))

# Let's look for links that point to /play/ or /view/ or anime detail page
anime_links = doc_milf.css('a[href*="/play/"], a[href*="/view/"], a[href*="/anime/"]')
print("Anime detail links found:", len(anime_links))
for a in anime_links[:10]:
    print("  Href:", a.attrib.get('href'), "Title/Text:", a.attrib.get('title'), "img:", a.css('img::attr(src)').get())

# What classes do anime card elements have?
for el in doc_milf.css('.inner, .film-detail, .poster, .thumb, .entry-content')[:5]:
    print("Element:", el.attrib)
