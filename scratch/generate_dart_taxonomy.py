import json
import re

with open("scratch/hentai_tube_harvest.json", "r", encoding="utf-8") as f:
    items = json.load(f)

# Icon mapping helper
def get_icon(slug, name):
    s = slug.lower()
    if '3d' in s:
        return 'Icons.view_in_ar_rounded'
    elif 'action' in s or 'martial' in s:
        return 'Icons.sports_martial_arts_rounded'
    elif 'adventure' in s:
        return 'Icons.explore_rounded'
    elif 'ahegao' in s:
        return 'Icons.face_retouching_natural_rounded'
    elif 'anal' in s:
        return 'Icons.adjust_rounded'
    elif 'blowjob' in s or 'deepthroat' in s or 'facial' in s or 'tits-fuck' in s:
        return 'Icons.record_voice_over_rounded'
    elif 'bondage' in s or 'slaves' in s or 'torture' in s:
        return 'Icons.lock_rounded'
    elif 'brainwashed' in s or 'mind-break' in s or 'hypnosis' in s:
        return 'Icons.psychology_rounded'
    elif 'cat-girl' in s or 'animal' in s:
        return 'Icons.pets_rounded'
    elif 'comedy' in s:
        return 'Icons.sentiment_very_satisfied_rounded'
    elif 'cosplay' in s:
        return 'Icons.theater_comedy_rounded'
    elif 'creampie' in s or 'internal-cumshot' in s or 'squirting' in s or 'urination' in s:
        return 'Icons.water_drop_rounded'
    elif 'dark-skin' in s:
        return 'Icons.brightness_low_rounded'
    elif 'demons' in s or 'vampire' in s or 'succubus' in s:
        return 'Icons.local_fire_department_rounded'
    elif 'doctor' in s or 'nurses' in s or 'female-doctor' in s:
        return 'Icons.medical_services_rounded'
    elif 'drama' in s:
        return 'Icons.movie_filter_rounded'
    elif 'dubbed' in s:
        return 'Icons.volume_up_rounded'
    elif 'ecchi' in s:
        return 'Icons.flare_rounded'
    elif 'elf' in s:
        return 'Icons.forest_rounded'
    elif 'eroge' in s:
        return 'Icons.videogame_asset_rounded'
    elif 'fantasy' in s:
        return 'Icons.auto_awesome_rounded'
    elif 'teacher' in s or 'school' in s or 'megane' in s:
        return 'Icons.school_rounded'
    elif 'femdom' in s or 'humiliation' in s:
        return 'Icons.gavel_rounded'
    elif 'footjob' in s:
        return 'Icons.pan_tool_alt_rounded'
    elif 'futanari' in s:
        return 'Icons.transgender_rounded'
    elif 'gangbang' in s or 'harem' in s or 'three-some' in s:
        return 'Icons.groups_rounded'
    elif 'gyaru' in s:
        return 'Icons.auto_fix_high_rounded'
    elif 'historical' in s:
        return 'Icons.history_edu_rounded'
    elif 'housewife' in s or 'widow' in s:
        return 'Icons.home_rounded'
    elif 'incest' in s:
        return 'Icons.family_restroom_rounded'
    elif 'large-breasts' in s or 'milf' in s:
        return 'Icons.lens_blur_rounded'
    elif 'maid' in s:
        return 'Icons.cleaning_services_rounded'
    elif 'police' in s:
        return 'Icons.local_police_rounded'
    elif 'pov' in s:
        return 'Icons.camera_alt_rounded'
    elif 'pregnant' in s:
        return 'Icons.child_care_rounded'
    elif 'princess' in s:
        return 'Icons.workspace_premium_rounded'
    elif 'public-sex' in s:
        return 'Icons.public_rounded'
    elif 'romance' in s or 'vanilla' in s:
        return 'Icons.favorite_rounded'
    elif 'sci-fi' in s:
        return 'Icons.rocket_launch_rounded'
    elif 'sports' in s or 'swimsuit' in s:
        return 'Icons.fitness_center_rounded'
    elif 'supernatural' in s or 'super-power' in s or 'magical' in s:
        return 'Icons.bolt_rounded'
    elif 'tentacles' in s:
        return 'Icons.hub_rounded'
    elif 'uncensored' in s:
        return 'Icons.lock_open_rounded'
    elif 'yuri' in s:
        return 'Icons.favorite_border_rounded'
    else:
        return 'Icons.tag_rounded'

def get_category_group(slug):
    s = slug.lower()
    if s in ['3d', 'dubbed', 'x-ray', 'pov', 'uncensored']:
        return 'Format & Visual'
    elif s in ['cat-girl', 'doctor', 'elf', 'female-doctor', 'female-teacher', 'gyaru', 'horny-slut', 'housewife', 'maid', 'megane', 'milf', 'nuns', 'nurses', 'office-ladies', 'police', 'pregnant', 'princess', 'school-girls', 'slaves', 'succubus', 'trap', 'tsundere', 'vampire', 'virgins', 'widow']:
        return 'Characters & Archetypes'
    elif s in ['action', 'adventure', 'comedy', 'drama', 'fantasy', 'historical', 'martial-arts', 'romance', 'sci-fi', 'seinen', 'sports', 'super-power', 'supernatural', 'vanilla', 'yuri']:
        return 'Themes & Settings'
    elif s in ['anal', 'blowjob', 'bukakke', 'creampie', 'deepthroat', 'double-penatration', 'facesitting', 'facial', 'footjob', 'internal-cumshot', 'rim-job', 'squirting', 'three-some', 'tits-fuck', 'urination']:
        return 'Acts & Positions'
    elif s in ['beastiality', 'blackmail', 'bondage', 'brainwashed', 'cosplay', 'dark-skin', 'ecchi', 'eroge', 'femdom', 'futanari', 'gangbang', 'gore', 'harem', 'humiliation', 'incest', 'inflation', 'lactation', 'large-breasts', 'magical-girls', 'mind-break', 'molestation', 'public-sex', 'rape', 'scat', 'shimapan', 'stocking', 'strap-on', 'strapped-on', 'swimsuit', 'tentacles', 'torture', 'toys', 'train-molestation']:
        return 'Fetish & Tropes'
    else:
        return 'Genres'

def get_description(name, slug):
    n = name.replace("'", "")
    s = slug.lower()
    if s == 'uncensored':
        return "Complete uncensored HentaiTube video releases and decensored master cuts"
    elif s == '3d':
        return "High fidelity 3D CGI animation, SFM, and Blender render productions"
    elif s == 'romance':
        return "Tender affection, romantic intimacy, and heartwarming connections"
    elif s == 'vanilla':
        return "Pure consensual pleasure, sweet encounters, and gentle passion"
    elif s == 'action':
        return "High-stakes battles, ninja warfare, supernatural combat, and adrenaline"
    elif s == 'adventure':
        return "Exciting journeys, fantasy expeditions, and dungeon conquests"
    elif s == 'fantasy':
        return "Mystical kingdoms, magic spells, elves, and enchanting realms"
    elif s == 'harem':
        return "Lucky protagonists surrounded by multiple alluring partners"
    elif s == 'school-girls':
        return "Academy campus settings, student uniforms, and classroom romance"
    elif s == 'milf':
        return "Voluptuous mature women, experienced housewives, and older partners"
    elif s == 'tentacles':
        return "Extraterrestrial organisms, mystical appendages, and deep-sea beasts"
    elif s == 'large-breasts':
        return "Bountiful cleavage, voluptuous figures, and generous proportions"
    elif s == 'creampie':
        return "Intense internal climaxes and passionate completions"
    elif s == 'maid':
        return "Devoted mansion attendants, French aprons, and personal hospitality"
    elif s == 'yuri':
        return "Beautiful girls-love romance, feminine intimacy, and sweet bonds"
    elif s == 'futanari':
        return "Hermaphrodite beauties with both feminine allure and endowed power"
    elif s == 'dubbed':
        return "English voice-acted releases and localized audio tracks"
    elif s == 'pov':
        return "First-person perspective immersion putting you directly in the scene"
    else:
        return f"Popular {n} anime videos and themed episodes on HentaiTube"

print("Generating Dart code...")
dart_lines = []
dart_lines.append("// GENERATED LIVE TAXONOMY FOR HENTAITUBE")
dart_lines.append("// Scraped live via Scrapling from https://hentaitube.online/genre, https://hentaitube.online/tags, https://hentaitube.online/categories")
dart_lines.append(f"// Total Live Genres Harvested: {len(items)}")
dart_lines.append("import 'package:flutter/material.dart';")
dart_lines.append("import '../../models/catalog_model.dart';\n")

# Covers Map
dart_lines.append("/// Authentic category and genre thumbnail posters harvested live from HentaiTube")
dart_lines.append("final Map<String, String> hentaiTubeCovers = const {")
for it in items:
    if it['thumbnail']:
        dart_lines.append(f'  "{it["slug"]}": "{it["thumbnail"]}",')
dart_lines.append("};\n")

# Top Categories (Grid)
# Select 30 top categories for the Grid view
top_category_slugs = [
    'uncensored', '3d', 'action', 'adventure', 'romance', 'vanilla', 'harem',
    'school-girls', 'milf', 'fantasy', 'comedy', 'supernatural', 'demons',
    'tentacles', 'large-breasts', 'creampie', 'maid', 'nurses', 'yuri',
    'futanari', 'sci-fi', 'pov', 'dubbed', 'mind-break', 'cosplay',
    'dark-skin', 'public-sex', 'housewife', 'super-power', 'ecchi'
]

dart_lines.append("/// Authentic HentaiTube Primary Categories for 2-column dynamic Grid view")
dart_lines.append("final List<CatalogItem> hentaiTubeCategories = const [")

# Add special portal cards first
dart_lines.append("""  CatalogItem(
    name: "Full Hentai Archive",
    slug: "hentai-list",
    type: CatalogType.category,
    categoryGroup: "Portals",
    icon: Icons.video_library_rounded,
    count: 1450,
    description: "Complete chronological catalog of all subbed hentai series and OVAs",
    endpointPath: "/hentai-list/",
  ),""")

cat_items = []
slug_to_item = {it['slug']: it for it in items}

for slug in top_category_slugs:
    it = slug_to_item.get(slug)
    if not it:
        continue
    name = it['name']
    if slug == 'uncensored':
        name = "Uncensored Hentai"
    elif slug == '3d':
        name = "3D Animation"
    elif slug == 'large-breasts':
        name = "Big Breasts / Oppai"
    elif slug == 'school-girls':
        name = "School & Academy"
    elif slug == 'yuri':
        name = "Yuri / Girls Love"

    icon = get_icon(slug, name)
    group = get_category_group(slug)
    count = it['count']
    desc = get_description(name, slug)
    path = it['endpointPath']

    dart_lines.append(f"""  CatalogItem(
    name: "{name}",
    slug: "{slug}",
    type: CatalogType.category,
    categoryGroup: "{group}",
    icon: {icon},
    count: {count},
    description: "{desc}",
    endpointPath: "{path}",
  ),""")

dart_lines.append("];\n")

# All Genres (Tags)
dart_lines.append("/// Authentic HentaiTube Genres & Tags harvested live for dynamic Chips wrap view")
dart_lines.append("final List<CatalogItem> hentaiTubeGenres = const [")

for it in items:
    slug = it['slug']
    name = it['name']
    icon = get_icon(slug, name)
    group = get_category_group(slug)
    count = it['count']
    desc = get_description(name, slug)
    path = it['endpointPath']

    dart_lines.append(f"""  CatalogItem(
    name: "{name}",
    slug: "{slug}",
    type: CatalogType.genre,
    categoryGroup: "{group}",
    icon: {icon},
    count: {count},
    description: "{desc}",
    endpointPath: "{path}",
  ),""")

dart_lines.append("];\n")

# ExtensionTaxonomy
dart_lines.append("""/// Dynamic Explore Taxonomy for HentaiTube extension
final ExtensionTaxonomy hentaiTubeTaxonomy = ExtensionTaxonomy(
  sections: [
    TaxonomySection(
      id: "categories",
      title: "Categories",
      displayType: TaxonomyDisplayType.grid,
      items: hentaiTubeCategories,
      icon: Icons.category_rounded,
    ),
    TaxonomySection(
      id: "genres",
      title: "Genres",
      displayType: TaxonomyDisplayType.tags,
      items: hentaiTubeGenres,
      icon: Icons.tag_rounded,
    ),
  ],
  categories: hentaiTubeCategories,
  tagsAndGenres: hentaiTubeGenres,
);
""")

code = "\n".join(dart_lines)
with open("lib/extensions/taxonomies/hentai_tube_taxonomy.dart", "w", encoding="utf-8") as f:
    f.write(code)

print(f"Generated lib/extensions/taxonomies/hentai_tube_taxonomy.dart successfully with {len(items)} genres!")
