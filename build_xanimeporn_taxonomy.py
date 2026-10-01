import json
import html
import re

with open('xanimeporn_harvest_raw.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

categories = data['categories']
category_covers = data['category_covers']
series_list = data['series']

# Sort categories by video count descending
categories.sort(key=lambda c: c['count'], reverse=True)

# Icon mapping for categories
category_meta = {
    'big-tits': ('Icons.bubble_chart_rounded', 'Body', 'Enormous bust, oppai, and voluptuous character streams'),
    'censored': ('Icons.lock_rounded', 'Censorship', 'Standard Japanese broadcast releases with mosaic censorship'),
    'school': ('Icons.school_rounded', 'Setting', 'School uniforms, classroom romances, and academy tales'),
    'domination': ('Icons.sports_kabaddi_rounded', 'Theme', 'Power dynamics, female dominance, submission, and bondage'),
    'uncensored': ('Icons.lock_open_rounded', 'Censorship', 'Direct decensored master cuts and uncensored OVA releases'),
    'harem': ('Icons.diversity_1_rounded', 'Theme', 'Multiple heroines pursuing a single protagonist'),
    'romance': ('Icons.favorite_rounded', 'Theme', 'Passionate romantic entanglements and heartfelt affection'),
    'incest': ('Icons.family_restroom_rounded', 'Theme', 'Sister, mother, cousin, and family relationship tales'),
    'small-tits': ('Icons.blur_linear_rounded', 'Body', 'Petite, slender, and modest bust heroines'),
    'yuri': ('Icons.female_rounded', 'Theme', 'Girls-love, female romances, and lesbian relationships'),
    'betrayal': ('Icons.heart_broken_rounded', 'Theme', 'Infidelity, heartbreak, stolen lovers, and dramatic twists'),
    'monsters': ('Icons.pest_control_rounded', 'Character', 'Creatures, fantasy beasts, goblins, and demon encounters'),
    'tentacles': ('Icons.waves_rounded', 'Fetish', 'Alien and demonic tentacle creatures and organic bonds'),
    'comedy': ('Icons.sentiment_very_satisfied_rounded', 'Theme', 'Hilarious misunderstandings and lighthearted anime romps'),
    'futanari': ('Icons.transgender_rounded', 'Character', 'Hermaphrodite heroines with dual endowments'),
    'maid': ('Icons.cleaning_services_rounded', 'Character', 'French maid uniforms, mansion servants, and cafe service'),
    'shotacon': ('Icons.child_care_rounded', 'Character', 'Younger male protagonists and older heroine pairings'),
    'action': ('Icons.flash_on_rounded', 'Theme', 'High-octane battles, martial arts, ninja, and fantasy action'),
    'nurse': ('Icons.medical_services_rounded', 'Character', 'Hospital clinics, medical examinations, and nurse outfits'),
    'yaoi': ('Icons.male_rounded', 'Theme', 'Boys-love, male romances, and BL storylines'),
}

# Curated tags & tropes
curated_tropes = [
    ("3D / CGI", "3d", "Trope", "Icons.view_in_ar_rounded", "High-fidelity 3D CGI, Blender, and MMD animations"),
    ("POV", "pov", "Trope", "Icons.visibility_rounded", "First-person point-of-view immersive experiences"),
    ("Cosplay", "cosplay", "Theme", "Icons.theater_comedy_rounded", "Costume roleplay, anime disguises, and themed outfits"),
    ("Milf", "milf", "Character", "Icons.woman_rounded", "Mature women, stepmothers, neighbors, and housewives"),
    ("Creampie", "creampie", "Trope", "Icons.water_drop_rounded", "Internal climaxes and unprotected romance scenes"),
    ("Dark Skin", "dark-skin", "Character", "Icons.wb_sunny_rounded", "Tanned beauties, gyarus, and sun-kissed heroines"),
    ("Glasses", "glasses", "Character", "Icons.smart_display_rounded", "Intellectual and shy heroines with megane glasses"),
    ("Gyaru", "gyaru", "Character", "Icons.flare_rounded", "Trendy gal fashion, bleached hair, and energetic style"),
    ("Ahegao", "ahegao", "Trope", "Icons.sentiment_satisfied_alt_rounded", "Exaggerated ecstasy expressions and rolled-back eyes"),
    ("Netorare (NTR)", "netorare", "Theme", "Icons.heart_broken_rounded", "Stolen lovers, emotional drama, and illicit infidelity"),
    ("Vanilla", "vanilla", "Theme", "Icons.favorite_border_rounded", "Sweet, consensual, wholesome, and pure romance"),
    ("Bondage & BDSM", "bondage", "Fetish", "Icons.link_rounded", "Rope restraint, handcuffs, and disciplinary play"),
    ("Swimsuit", "swimsuit", "Attire", "Icons.pool_rounded", "Bikinis, school swimsuits, and beach vacations"),
    ("Teacher", "teacher", "Character", "Icons.history_edu_rounded", "School sensei, private tutors, and instructor liaisons"),
    ("Elves", "elves", "Character", "Icons.forest_rounded", "Pointy-eared high elves, dark elves, and fantasy maidens"),
    ("Ninja", "ninja", "Character", "Icons.sports_martial_arts_rounded", "Kunoichi stealth warriors and covert shinobi combatants"),
    ("Magic & Supernatural", "magic", "Theme", "Icons.auto_awesome_rounded", "Spellcasters, magical girls, and supernatural forces"),
    ("Fantasy", "fantasy", "Theme", "Icons.castle_rounded", "Isekai realms, sword and sorcery, and dungeon quests"),
    ("Shorts & Clips", "shorts", "Format", "Icons.play_circle_outline_rounded", "Fast anime shorts, high-speed series clips, and highlights"),
    ("Idol", "idol", "Character", "Icons.star_rounded", "Pop singing stars, concert performers, and showbiz idols"),
    ("Succubus", "succubus", "Character", "Icons.local_fire_department_rounded", "Demonic temptresses, dream visitors, and sensual familiars"),
    ("Hypnosis", "hypnosis", "Theme", "Icons.psychology_rounded", "Mind control, altered trance states, and hypnotic obedience"),
    ("Time Stop", "time-stop", "Theme", "Icons.timer_rounded", "Temporal manipulation, frozen clocks, and secret freedoms"),
    ("Public & Outdoor", "public", "Setting", "Icons.park_rounded", "Open parks, commuter trains, rooftops, and risky outdoor spots"),
    ("Lactation", "lactation", "Body", "Icons.opacity_rounded", "Busty mothers, milk production, and maternal care"),
    ("Group Sex", "group-sex", "Act", "Icons.groups_rounded", "Threesomes, orgies, and multi-partner intimate encounters"),
    ("Blowjob & Oral", "oral", "Act", "Icons.sentiment_satisfied_rounded", "Fellatio, oral pleasure, and deep throat scenes"),
    ("Anal", "anal", "Act", "Icons.accessibility_new_rounded", "Backdoor intimacy and specialized adult sequences"),
    ("Masturbation", "masturbation", "Act", "Icons.front_hand_rounded", "Private solo pleasure and intimate self-exploration"),
    ("Twins", "twins", "Character", "Icons.people_outline_rounded", "Identical and fraternal twin sister pairings"),
    ("Virgin", "virgin", "Theme", "Icons.volunteer_activism_rounded", "First-time experiences and innocent awakening moments"),
    ("Bunny Girl", "bunny-girl", "Attire", "Icons.cruelty_free_rounded", "Casino bunny suits, floppy ears, and playful costumes"),
    ("Catgirl / Neko", "neko", "Character", "Icons.pets_rounded", "Feline ears, tails, and playful pet tendencies"),
    ("Demon", "demon", "Character", "Icons.whatshot_rounded", "Underworld rulers, horns, and demonic nobility"),
    ("Princess", "princess", "Character", "Icons.military_tech_rounded", "Noble royalty, castle mistresses, and high-born heiresses"),
]

# Select 120 authentic top series from series_list
selected_series = series_list[:120]

def clean_dart_str(s):
    return s.replace('\\', '\\\\').replace('"', '\\"').replace('$', '\\$')

lines = []
lines.append("// GENERATED LIVE TAXONOMY FOR XANIMEPOHN (xanimeporn.com)")
lines.append("// Harvested live via Scrapling Fetcher from https://xanimeporn.com/category-sitemap.xml and https://xanimeporn.com/hentai-list/")
lines.append(f"// Total Live Categories Harvested: {len(categories)}")
lines.append(f"// Total Authentic Hentai Series Harvested: {len(series_list)}")
lines.append(f"// Total Curated Tropes & Series Selected: {len(curated_tropes) + len(selected_series)}")
lines.append("import 'package:flutter/material.dart';")
lines.append("import '../../models/catalog_model.dart';")
lines.append("")
lines.append("/// Authentic category cover posters scraped live from Xanimeporn")
lines.append("final Map<String, String> xanimepornCategoryCovers = const {")
for k, v in category_covers.items():
    lines.append(f'  "{clean_dart_str(k)}": "{clean_dart_str(v)}",')
lines.append("};")
lines.append("")
lines.append("/// Authentic Xanimeporn Categories scraped live from https://xanimeporn.com/category-sitemap.xml")
lines.append("final List<CatalogItem> xanimepornCategories = const [")
for c in categories:
    slug = c['slug']
    name = c['name']
    count = c['count']
    icon, group, default_desc = category_meta.get(slug, ('Icons.category_rounded', 'Category', f'Stream {count} {name} videos on Xanimeporn'))
    lines.append("  CatalogItem(")
    lines.append(f'    name: "{clean_dart_str(name)}",')
    lines.append(f'    slug: "{clean_dart_str(slug)}",')
    lines.append("    type: CatalogType.category,")
    lines.append(f'    categoryGroup: "{clean_dart_str(group)}",')
    lines.append(f"    icon: {icon},")
    lines.append(f"    count: {count},")
    lines.append(f'    description: "{clean_dart_str(default_desc)}",')
    lines.append(f'    endpointPath: "/{clean_dart_str(slug)}/",')
    lines.append("  ),")
lines.append("];")
lines.append("")
lines.append("/// Authentic Xanimeporn Tags, Tropes & Hentai Series scraped live")
lines.append("final List<CatalogItem> xanimepornTags = const [")
# 1. Curated tropes & tags
for name, slug, group, icon, desc in curated_tropes:
    lines.append("  CatalogItem(")
    lines.append(f'    name: "{clean_dart_str(name)}",')
    lines.append(f'    slug: "{clean_dart_str(slug)}",')
    lines.append("    type: CatalogType.tag,")
    lines.append(f'    categoryGroup: "{clean_dart_str(group)}",')
    lines.append(f"    icon: {icon},")
    lines.append(f'    description: "{clean_dart_str(desc)}",')
    lines.append(f'    endpointPath: "/{clean_dart_str(slug)}/",')
    lines.append("  ),")

# 2. Authentic Anime Series from /hentai-list/
for s in selected_series:
    name = s['name']
    slug = s['slug']
    lines.append("  CatalogItem(")
    lines.append(f'    name: "{clean_dart_str(name)}",')
    lines.append(f'    slug: "{clean_dart_str(slug)}",')
    lines.append("    type: CatalogType.tag,")
    lines.append('    categoryGroup: "Anime Series",')
    lines.append("    icon: Icons.movie_filter_rounded,")
    lines.append(f'    description: "Stream {clean_dart_str(name)} anime episodes on Xanimeporn",')
    lines.append(f'    endpointPath: "/{clean_dart_str(slug)}/",')
    lines.append("  ),")
lines.append("];")
lines.append("")
lines.append("/// Dynamic Explore Taxonomy for Xanimeporn with Categories (grid) and Tags (tags)")
lines.append("final ExtensionTaxonomy xanimepornTaxonomy = ExtensionTaxonomy(")
lines.append("  sections: [")
lines.append("    TaxonomySection(")
lines.append('      id: "categories",')
lines.append('      title: "Categories",')
lines.append("      displayType: TaxonomyDisplayType.grid,")
lines.append("      items: xanimepornCategories,")
lines.append("      icon: Icons.category_rounded,")
lines.append("    ),")
lines.append("    TaxonomySection(")
lines.append('      id: "tags",')
lines.append('      title: "Tags",')
lines.append("      displayType: TaxonomyDisplayType.tags,")
lines.append("      items: xanimepornTags,")
lines.append("      icon: Icons.tag_rounded,")
lines.append("    ),")
lines.append("  ],")
lines.append("  categories: xanimepornCategories,")
lines.append("  tagsAndGenres: xanimepornTags,")
lines.append(");")
lines.append("")

output_path = r'd:\C\H\lib\extensions\taxonomies\xanimeporn_taxonomy.dart'
with open(output_path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines))

print(f"Generated {output_path} successfully ({len(lines)} lines)!")
