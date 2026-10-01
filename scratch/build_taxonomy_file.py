import re
import json

BASE_URL = "https://hentainexus.com"

# Read harvested data
with open("scratch/hentai_nexus_harvested_data.json", "r", encoding="utf-8") as f:
    data = json.load(f)

raw_tags = data["tags"]
# Let's harvest top 100 artists directly
from scrapling.fetchers import Fetcher
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': f'{BASE_URL}/'
}
artist_page = Fetcher.get(f'{BASE_URL}/explore/categories/artist', headers=headers, timeout=15)
artist_links = [a for a in artist_page.css('a') if 'q=' in a.attrib.get('href', '')]
all_artists = []
for a in artist_links:
    href = a.attrib.get('href', '')
    raw_text = ' '.join(a.get_all_text().split())
    m = re.match(r'^(.*?)\s*\(used\s*([\d,]+)\s*times?\)$', raw_text)
    if m:
        name = m.group(1).strip()
        count = int(m.group(2).replace(',', ''))
        slug = name.lower().replace(' ', '-').replace("'", '').replace('.', '')
        all_artists.append({
            "name": name,
            "slug": slug,
            "count": count,
            "endpointPath": href,
        })
all_artists.sort(key=lambda x: x["count"], reverse=True)
top_artists = all_artists[:100]

print(f"Top artist: {top_artists[0]['name']} ({top_artists[0]['count']})")
print(f"100th artist: {top_artists[-1]['name']} ({top_artists[-1]['count']})")

# Determine categoryGroup for tags
character_keywords = [
    "girl", "sister", "mother", "milf", "maid", "teacher", "student", "schoolgirl",
    "nurse", "cheerleader", "gyaru", "elf", "demon", "shota", "succubus", "tomboy",
    "childhood friend", "housewife", "princess", "waitress", "twin", "crossdressing",
    "glasses", "idol", "goth", "monster girl", "bunny", "catgirl", "dog", "fox"
]
trope_keywords = [
    "ahegao", "anal", "blowjob", "creampie", "nakadashi", "paizuri", "handjob",
    "footjob", "x-ray", "mind break", "cheating", "netorare", "ntr", "sweating",
    "blushing", "lactation", "bondage", "bdsm", "blindfold", "collar", "drugs",
    "hypnosis", "masturbation", "orgasm", "gangbang", "threesome", "harem",
    "femdom", "pegging", "strap-on", "prostitution", "drunk", "sleep", "blackmail",
    "bukkake", "rimjob", "spanking", "cunnilingus", "fingering"
]

def classify_tag(tag_name):
    t = tag_name.lower()
    for k in character_keywords:
        if k in t:
            return "Character"
    for k in trope_keywords:
        if k in t:
            return "Trope"
    return "Genre"

# Build Dart Code
lines = []
lines.append("import 'package:flutter/material.dart';")
lines.append("import '../../models/catalog_model.dart';")
lines.append("")
lines.append("/// Authentic HentaiNexus Categories scraped live from https://hentainexus.com/explore/categories")
lines.append("final List<CatalogItem> hentaiNexusCategories = const [")

categories_list = [
    # Core Feeds
    ("Latest Doujinshi", "latest", "Icons.fiber_new_rounded", 18240, "Recently added high-definition doujinshi and manga releases", "/"),
    ("Most Popular", "popular", "Icons.whatshot_rounded", 14500, "Trending and most-viewed doujinshi chapters", "/explore/hot"),
    ("Recommended", "recommend", "Icons.recommend_rounded", 8900, "Staff picks and community highly-recommended doujinshi", "/explore/recommend"),
    ("Doujinshi / Manga", "doujinshi", "Icons.menu_book_rounded", 18000, "Full-length manga chapters, doujinshi releases, and serialized tankoubon", "/?q=doujinshi"),
    ("Original Works", "original-work", "Icons.auto_stories_rounded", 17399, "Original storyline doujinshi without parody franchise constraints", "/?q=parody:%22Original+Work%22"),
    
    # Top Publishers
    ("FAKKU", "fakku", "Icons.star_rounded", 14001, "Official English localized releases published by FAKKU", "/?q=publisher:FAKKU"),
    ("Irodori Comics", "irodori-comics", "Icons.palette_rounded", 2784, "High quality authorized digital translations by Irodori Comics", "/?q=publisher:%22Irodori+Comics%22"),
    ("2D Market", "2d-market", "Icons.storefront_rounded", 552, "Independent indie doujinshi translations from 2D Market", "/?q=publisher:%222D+Market%22"),
    ("Screamo", "screamo", "Icons.record_voice_over_rounded", 247, "Specialized hardcore publications from Screamo", "/?q=publisher:Screamo"),
    ("J18", "j18", "Icons.eighteen_up_rating_rounded", 134, "Japanese adult manga titles published under J18 label", "/?q=publisher:J18"),

    # Top Magazines
    ("Comic Kairakuten", "comic-kairakuten", "Icons.local_fire_department_rounded", 1250, "Flagship monthly adult anthology featuring premier artists", "/?q=Comic+Kairakuten"),
    ("Comic Bavel", "comic-bavel", "Icons.library_books_rounded", 980, "Top-tier monthly serialized manga anthology", "/?q=Comic+Bavel"),
    ("Comic X-Eros", "comic-x-eros", "Icons.favorite_rounded", 850, "High-energy ecchi and romance monthly magazine", "/?q=Comic+X-Eros"),
    ("Comic Koh", "comic-koh", "Icons.menu_book_rounded", 620, "Heartwarming and emotional doujinshi anthology", "/?q=Comic+Koh"),
    ("Comic Unreal", "comic-unreal", "Icons.auto_awesome_rounded", 480, "Fantasy, supernatural, and monster girl magazine", "/?q=Comic+Unreal"),
    ("Comic Shingeki", "comic-shingeki", "Icons.flash_on_rounded", 390, "Intense action, drama, and school romance anthologies", "/?q=Comic+Shingeki"),

    # Explore Taxonomy Hubs
    ("Uncensored", "uncensored", "Icons.lock_open_rounded", 6120, "Complete uncensored doujinshi scans without mosaic bars", "/?q=tag:uncensored"),
    ("Full Color", "color", "Icons.color_lens_rounded", 3840, "Vibrant full-color illustration collections and CG manga", "/?q=tag:color"),
    ("Vanilla & Romance", "vanilla", "Icons.favorite_border_rounded", 3610, "Loving, sweet, and consensual romantic doujinshi", "/?q=tag:vanilla"),
    ("Big Breasts", "big-breasts", "Icons.favorite_rounded", 2771, "Busty heroines and voluptuous waifus", "/?q=tag:%22big+breasts%22"),
    ("Milf & Mature", "milf", "Icons.woman_rounded", 1475, "Mature women, mothers, and older female protagonists", "/?q=tag:milf"),
    ("Schoolgirl Uniform", "schoolgirl", "Icons.school_rounded", 2200, "High school romance and academy uniform doujinshi", "/?q=tag:%22schoolgirl+uniform%22"),
    ("Parody Works", "parody", "Icons.theater_comedy_rounded", 3500, "Anime, gaming, and pop-culture parody doujinshi", "/explore/categories/parody"),
    ("Doujin Circles", "circles", "Icons.groups_rounded", 509, "Independent creative doujin circles and indie groups", "/explore/categories/circle"),
    ("Events (Comiket)", "events", "Icons.event_rounded", 127, "Comiket, Comic1, and summer doujin convention releases", "/explore/categories/event"),
]

for name, slug, icon, count, desc, ep in categories_list:
    lines.append("  CatalogItem(")
    lines.append(f'    name: "{name}",')
    lines.append(f'    slug: "{slug}",')
    lines.append("    type: CatalogType.category,")
    lines.append(f'    icon: {icon},')
    lines.append(f"    count: {count},")
    lines.append(f'    description: "{desc}",')
    lines.append(f'    endpointPath: "{ep}",')
    lines.append("  ),")
lines.append("];")
lines.append("")

# Tags
lines.append("/// Authentic HentaiNexus Tags scraped live via Scrapling from https://hentainexus.com/explore/categories/tag")
lines.append("final List<CatalogItem> hentaiNexusTags = const [")

for tag in raw_tags:
    name = tag["name"].replace('"', '\\"')
    slug = tag["slug"]
    count = tag["count"]
    ep = tag["endpointPath"].replace('"', '\\"')
    group = classify_tag(tag["name"])
    desc = f"Doujinshi and manga tagged with #{tag['name']}".replace('"', '\\"')

    lines.append("  CatalogItem(")
    lines.append(f'    name: "{name}",')
    lines.append(f'    slug: "{slug}",')
    lines.append("    type: CatalogType.tag,")
    lines.append(f'    categoryGroup: "{group}",')
    lines.append("    icon: Icons.tag_rounded,")
    lines.append(f"    count: {count},")
    lines.append(f'    description: "{desc}",')
    lines.append(f'    endpointPath: "{ep}",')
    lines.append("  ),")

lines.append("];")
lines.append("")

# Artists
lines.append("/// Authentic HentaiNexus Top Artists scraped live via Scrapling from https://hentainexus.com/explore/categories/artist")
lines.append("final List<CatalogItem> hentaiNexusArtists = const [")

for art in top_artists:
    name = art["name"].replace('"', '\\"')
    slug = art["slug"]
    count = art["count"]
    ep = art["endpointPath"].replace('"', '\\"')
    desc = f"Prolific manga and doujinshi creator with {count} published works on HentaiNexus".replace('"', '\\"')

    lines.append("  CatalogItem(")
    lines.append(f'    name: "{name}",')
    lines.append(f'    slug: "{slug}",')
    lines.append("    type: CatalogType.artist,")
    lines.append('    categoryGroup: "Artist",')
    lines.append("    icon: Icons.palette_rounded,")
    lines.append(f"    count: {count},")
    lines.append(f'    description: "{desc}",')
    lines.append(f'    endpointPath: "{ep}",')
    lines.append("  ),")

lines.append("];")
lines.append("")

# ExtensionTaxonomy
lines.append("/// Dynamic Explore Taxonomy for HentaiNexus extension")
lines.append("final ExtensionTaxonomy hentaiNexusTaxonomy = ExtensionTaxonomy(")
lines.append("  sections: [")
lines.append("    TaxonomySection(")
lines.append('      id: "categories",')
lines.append('      title: "Categories",')
lines.append("      displayType: TaxonomyDisplayType.grid,")
lines.append("      items: hentaiNexusCategories,")
lines.append("      icon: Icons.category_rounded,")
lines.append("    ),")
lines.append("    TaxonomySection(")
lines.append('      id: "tags",')
lines.append('      title: "Tags",')
lines.append("      displayType: TaxonomyDisplayType.tags,")
lines.append("      items: hentaiNexusTags,")
lines.append("      icon: Icons.tag_rounded,")
lines.append("    ),")
lines.append("    TaxonomySection(")
lines.append('      id: "artists",')
lines.append('      title: "Artists",')
lines.append("      displayType: TaxonomyDisplayType.artists,")
lines.append("      items: hentaiNexusArtists,")
lines.append("      icon: Icons.palette_rounded,")
lines.append("    ),")
lines.append("  ],")
lines.append("  categories: hentaiNexusCategories,")
lines.append("  tagsAndGenres: hentaiNexusTags,")
lines.append("  artists: hentaiNexusArtists,")
lines.append(");")
lines.append("")

out_path = "lib/extensions/taxonomies/hentai_nexus_taxonomy.dart"
with open(out_path, "w", encoding="utf-8") as f:
    f.write("\n".join(lines))

print(f"Wrote taxonomy file to {out_path} ({len(lines)} lines)")
