import json
import re

with open("d:/C/H/scratch/haho_moe_harvested.json", "r", encoding="utf-8") as f:
    data = json.load(f)

formats = data['formats']
playlists = data['playlists']
genres = data['genres']

def escape_dart_string(s):
    if not s:
        return ""
    # escape backslashes, double quotes, dollar signs
    s = s.replace('\\', '\\\\')
    s = s.replace('"', '\\"')
    s = s.replace('$', '\\$')
    s = s.replace('\n', ' ').replace('\r', ' ')
    return s

def get_genre_icon(name):
    n = name.lower()
    if any(k in n for k in ['romance', 'love', 'heart', 'affection', 'dating']):
        return "Icons.favorite_rounded"
    if any(k in n for k in ['uncensored', 'nude', 'strip']):
        return "Icons.lock_open_rounded"
    if any(k in n for k in ['action', 'fight', 'battle', 'war', 'martial', 'gun', 'weapon']):
        return "Icons.flash_on_rounded"
    if any(k in n for k in ['comedy', 'humour', 'humor', 'parody', 'funny', 'gag']):
        return "Icons.sentiment_very_satisfied_rounded"
    if any(k in n for k in ['drama', 'tragedy', 'theatre', 'theater']):
        return "Icons.theater_comedy_rounded"
    if any(k in n for k in ['fantasy', 'magic', 'witch', 'sorcery', 'fairy']):
        return "Icons.auto_awesome_rounded"
    if any(k in n for k in ['horror', 'ghost', 'demon', 'vampire', 'zombie', 'dark', 'gore', 'gothic']):
        return "Icons.dark_mode_rounded"
    if any(k in n for k in ['sci-fi', 'space', 'alien', 'mecha', 'robot', 'future', 'cyber']):
        return "Icons.rocket_launch_rounded"
    if any(k in n for k in ['school', 'student', 'teacher', 'academy', 'class', 'college', 'club']):
        return "Icons.school_rounded"
    if any(k in n for k in ['milf', 'mother', 'mature', 'aunt', 'stepmom', 'older woman']):
        return "Icons.family_restroom_rounded"
    if any(k in n for k in ['maid', 'butler', 'servant', 'clean']):
        return "Icons.cleaning_services_rounded"
    if any(k in n for k in ['nurse', 'doctor', 'hospital', 'clinic', 'medical']):
        return "Icons.medical_services_rounded"
    if any(k in n for k in ['sport', 'swim', 'soccer', 'tennis', 'gym', 'fitness']):
        return "Icons.sports_soccer_rounded"
    if any(k in n for k in ['music', 'song', 'idol', 'band', 'sing', 'dance']):
        return "Icons.music_note_rounded"
    if any(k in n for k in ['3d', 'cg', 'mmd', 'cgi', 'animation']):
        return "Icons.view_in_ar_rounded"
    if any(k in n for k in ['food', 'cooking', 'chef', 'restaurant', 'cafe']):
        return "Icons.restaurant_rounded"
    if any(k in n for k in ['game', 'gaming', 'rpg', 'mmo', 'virtual']):
        return "Icons.sports_esports_rounded"
    if any(k in n for k in ['beach', 'pool', 'summer', 'bikini', 'swimsuit', 'vacation']):
        return "Icons.beach_access_rounded"
    if any(k in n for k in ['world', 'travel', 'japan', 'earth', 'asia', 'island']):
        return "Icons.public_rounded"
    if any(k in n for k in ['work', 'office', 'boss', 'business', 'employee']):
        return "Icons.work_rounded"
    if any(k in n for k in ['elf', 'monster', 'creature', 'animal', 'kemonomimi', 'catgirl']):
        return "Icons.pest_control_rounded"
    if any(k in n for k in ['bdsm', 'bondage', 'slave', 'leash', 'collar']):
        return "Icons.link_rounded"
    if any(k in n for k in ['harem', 'multiple', 'triangle']):
        return "Icons.groups_rounded"
    if any(k in n for k in ['crime', 'police', 'cops', 'detective', 'thief', 'yakuza']):
        return "Icons.local_police_rounded"
    if any(k in n for k in ['historical', 'ancient', 'samurai', 'ninja', 'period', 'feudal']):
        return "Icons.history_edu_rounded"
    if any(k in n for k in ['supernatural', 'spirit', 'god', 'goddess', 'psychic']):
        return "Icons.psychology_rounded"
    return "Icons.tag_rounded"

format_icon_map = {
    'tv-series': 'Icons.live_tv_rounded',
    'ova': 'Icons.album_rounded',
    'movie': 'Icons.movie_rounded',
    'web': 'Icons.language_rounded',
    'music-video': 'Icons.music_note_rounded',
    'tv-special': 'Icons.stars_rounded',
    'other': 'Icons.video_library_rounded',
}

out = []
out.append("import 'package:flutter/material.dart';")
out.append("import '../../models/catalog_model.dart';\n")

# Formats
out.append("// Authentic Haho.moe Formats scraped live via Scrapling from https://haho.moe/type")
out.append("final List<CatalogItem> hahoMoeFormats = const [")
for fmt in formats:
    icon = format_icon_map.get(fmt['slug'], 'Icons.category_rounded')
    out.append("  CatalogItem(")
    out.append(f'    name: "{escape_dart_string(fmt["name"])}",')
    out.append(f'    slug: "{escape_dart_string(fmt["slug"])}",')
    out.append("    type: CatalogType.category,")
    out.append('    categoryGroup: "Format",')
    out.append(f"    icon: {icon},")
    out.append(f'    description: "{escape_dart_string(fmt["description"])}",')
    out.append(f'    endpointPath: "{escape_dart_string(fmt["endpoint"])}",')
    out.append("  ),")
out.append("];\n")

# Playlists
out.append(f"// Authentic Haho.moe Playlists ({len(playlists)} items) scraped live via Scrapling from https://haho.moe/playlist")
out.append("final List<CatalogItem> hahoMoePlaylists = const [")
for pl in playlists:
    desc = pl.get('description') or f"{pl.get('count', 0)} videos"
    out.append("  CatalogItem(")
    out.append(f'    name: "{escape_dart_string(pl["name"])}",')
    out.append(f'    slug: "{escape_dart_string(pl["slug"])}",')
    out.append("    type: CatalogType.category,")
    out.append('    categoryGroup: "Playlist",')
    out.append("    icon: Icons.playlist_play_rounded,")
    out.append(f'    count: {pl.get("count", 0)},')
    out.append(f'    description: "{escape_dart_string(desc)}",')
    out.append(f'    endpointPath: "{escape_dart_string(pl["endpoint"])}",')
    out.append("  ),")
out.append("];\n")

# Genres
out.append(f"// Authentic Haho.moe Genres & Themes ({len(genres)} items) scraped live via Scrapling from https://haho.moe/genre")
out.append("final List<CatalogItem> hahoMoeGenres = const [")
for g in genres:
    icon = get_genre_icon(g['name'])
    desc = g.get('desc') or f"Haho.moe {g['name']} anime category"
    out.append("  CatalogItem(")
    out.append(f'    name: "{escape_dart_string(g["name"])}",')
    out.append(f'    slug: "{escape_dart_string(g["slug"])}",')
    out.append("    type: CatalogType.genre,")
    out.append('    categoryGroup: "Genre",')
    out.append(f"    icon: {icon},")
    out.append(f'    description: "{escape_dart_string(desc)}",')
    out.append(f'    endpointPath: "{escape_dart_string(g["endpoint"])}",')
    out.append("  ),")
out.append("];\n")

# Taxonomy
out.append("// Dynamic Explore Taxonomy for Haho.moe with multi-tab layout")
out.append("final ExtensionTaxonomy hahoMoeTaxonomy = ExtensionTaxonomy(")
out.append("  sections: [")
out.append("    TaxonomySection(")
out.append('      id: "genres",')
out.append('      title: "Genres & Themes",')
out.append("      displayType: TaxonomyDisplayType.tags,")
out.append("      items: hahoMoeGenres,")
out.append("      icon: Icons.tag_rounded,")
out.append("    ),")
out.append("    TaxonomySection(")
out.append('      id: "playlists",')
out.append('      title: "Playlists",')
out.append("      displayType: TaxonomyDisplayType.grid,")
out.append("      items: hahoMoePlaylists,")
out.append("      icon: Icons.playlist_play_rounded,")
out.append("    ),")
out.append("    TaxonomySection(")
out.append('      id: "formats",')
out.append('      title: "Formats",')
out.append("      displayType: TaxonomyDisplayType.grid,")
out.append("      items: hahoMoeFormats,")
out.append("      icon: Icons.video_library_rounded,")
out.append("    ),")
out.append("  ],")
out.append("  categories: hahoMoeFormats,")
out.append("  tagsAndGenres: hahoMoeGenres,")
out.append("  artists: const [],")
out.append(");\n")

with open("d:/C/H/lib/extensions/taxonomies/haho_moe_taxonomy.dart", "w", encoding="utf-8") as f:
    f.write("\n".join(out))

print("Successfully generated d:/C/H/lib/extensions/taxonomies/haho_moe_taxonomy.dart!")
