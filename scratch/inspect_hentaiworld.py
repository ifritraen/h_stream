from scrapling.fetchers import Fetcher
import json

headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
}

fetcher = Fetcher()

resp = fetcher.get("https://www.hentaiworld.me/", headers=headers)
print("Status:", resp.status)
print("Title:", resp.css("title::text").get())

# Let's find all navigation links, genres, categories, etc.
links = resp.css("a::attr(href)").getall()
print(f"Total links: {len(links)}")

genre_links = [l for l in links if "genre" in l or "category" in l or "tag" in l]
print("Genre/Cat/Tag links:")
for l in sorted(set(genre_links)):
    print(l)

# Let's inspect nav or menu
nav_items = resp.css("nav a, ul.menu a, .navbar a, header a")
print("\nHeader/Nav menu items:")
for item in nav_items:
    text = item.css("::text").get()
    href = item.attrib.get("href", "")
    print(f"  {text} -> {href}")

with open("scratch/hentaiworld_me.html", "w", encoding="utf-8") as f:
    f.write(resp.text or "")
print("\nSaved HTML to scratch/hentaiworld_me.html. Length:", len(resp.text or ""))
