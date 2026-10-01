# Generate PornHub Hentai taxonomy
dart = []
dart.append("// PornHub Hentai Dynamic Taxonomy")
dart.append("// Structured from PornHub categories & anime/hentai discovery tags.")
dart.append("import 'package:flutter/material.dart';")
dart.append("import '../../models/catalog_model.dart';")
dart.append("")

categories = [
    ("Hentai", "36", "Anime & 2D/3D Animation", "Icons.movie_filter_rounded", "/video?c=36", 125000),
    ("Cosplay", "241", "Costumes & Anime Parodies", "Icons.theater_comedy_rounded", "/video?c=241", 85000),
    ("Cartoon", "86", "Animation & Western Toons", "Icons.animation_rounded", "/video?c=86", 42000),
    ("Japanese", "111", "East Asian Anime Culture", "Icons.language_rounded", "/video?c=111", 195000),
    ("60FPS HD", "105", "High Framerate 60FPS", "Icons.speed_rounded", "/video?c=105", 34000),
    ("Gaming", "881", "Video Game 3D Parodies", "Icons.sports_esports_rounded", "/video?c=881", 62000),
    ("Parody", "201", "Live-Action & CG Parody", "Icons.smart_display_rounded", "/video?c=201", 51000),
    ("VR Animation", "vr", "Virtual Reality & 3D Immersion", "Icons.view_in_ar_rounded", "/vr", 18000),
    ("HD Anime", "hd", "1080p & 4K High Definition", "Icons.high_quality_rounded", "/hd", 280000),
    ("Big Tits", "8", "Anime Busty Archetypes", "Icons.favorite_rounded", "/video?c=8", 320000),
    ("Creampie", "15", "Climax & Internal Finishes", "Icons.whatshot_rounded", "/video?c=15", 290000),
    ("Blowjob", "13", "Oral & Fellatio Acts", "Icons.face_rounded", "/video?c=13", 310000),
    ("Anal", "35", "Anal Intercourse", "Icons.radio_button_checked_rounded", "/video?c=35", 210000),
    ("School (18+)", "88", "Uniforms & Academy Themes", "Icons.school_rounded", "/video?c=88", 175000),
    ("Bukkake", "14", "Group Climax Compilations", "Icons.opacity_rounded", "/video?c=14", 65000),
    ("Role Play", "81", "Costume & Narrative Roleplay", "Icons.masks_rounded", "/video?c=81", 140000),
    ("Threesome", "65", "FFM & MMF Triplets", "Icons.groups_rounded", "/video?c=65", 130000),
    ("Bondage", "10", "Shibari & BDSM Sequences", "Icons.lock_rounded", "/video?c=10", 88000),
    ("POV", "41", "First Person Point of View", "Icons.visibility_rounded", "/video?c=41", 240000),
    ("Solo Female", "492", "Solo Masturbation & Toys", "Icons.person_rounded", "/video?c=492", 190000),
]

tags = [
    ("Anime Hentai", "anime-hentai", "Icons.movie_rounded", 95000),
    ("3D Hentai", "3d-hentai", "Icons.view_in_ar_rounded", 45000),
    ("Overwatch", "overwatch", "Icons.sports_esports_rounded", 28000),
    ("Genshin Impact", "genshin-impact", "Icons.sports_esports_rounded", 32000),
    ("SFM", "sfm", "Icons.animation_rounded", 22000),
    ("Blender", "blender", "Icons.animation_rounded", 19000),
    ("MMD", "mmd", "Icons.animation_rounded", 18000),
    ("Uncensored", "uncensored", "Icons.lock_open_rounded", 74000),
    ("Subbed", "subbed", "Icons.subtitles_rounded", 38000),
    ("Dubbed", "dubbed", "Icons.record_voice_over_rounded", 29000),
    ("Ahegao", "ahegao", "Icons.mood_rounded", 42000),
    ("Milf Hentai", "milf-hentai", "Icons.woman_rounded", 51000),
    ("Futanari", "futanari", "Icons.transgender_rounded", 36000),
    ("Tentacle", "tentacle", "Icons.waves_rounded", 19000),
    ("Harem", "harem", "Icons.favorite_rounded", 48000),
    ("Monster Girl", "monster-girl", "Icons.cruelty_free_rounded", 17000),
    ("Dark Skin", "dark-skin", "Icons.person_rounded", 26000),
    ("Tsundere", "tsundere", "Icons.sentiment_dissatisfied_rounded", 14000),
    ("Yuri", "yuri", "Icons.favorite_border_rounded", 33000),
    ("Netorare (NTR)", "ntr", "Icons.heart_broken_rounded", 24000),
    ("Vanilla", "vanilla", "Icons.sentiment_very_satisfied_rounded", 41000),
    ("Cosplay Maid", "cosplay-maid", "Icons.cleaning_services_rounded", 22000),
    ("Bunny Girl", "bunny-girl", "Icons.cruelty_free_rounded", 25000),
    ("Goth Cosplay", "goth-cosplay", "Icons.dark_mode_rounded", 19000),
]

dart.append("/// PornHub Hentai & Anime categories")
dart.append("final List<CatalogItem> pornhubCategories = [")
for name, cid, desc, icon, ep, count in categories:
    dart.append(f'  CatalogItem(')
    dart.append(f'    name: "{name}",')
    dart.append(f'    slug: "{cid}",')
    dart.append(f'    type: CatalogType.category,')
    dart.append(f'    categoryGroup: "PornHub Channels",')
    dart.append(f'    icon: {icon},')
    dart.append(f'    count: {count},')
    dart.append(f'    description: "{desc}",')
    dart.append(f'    endpointPath: "{ep}",')
    dart.append(f'  ),')
dart.append("];")
dart.append("")

dart.append("/// PornHub anime & hentai search tags")
dart.append("final List<CatalogItem> pornhubTags = [")
for name, slug, icon, count in tags:
    dart.append(f'  CatalogItem(')
    dart.append(f'    name: "{name}",')
    dart.append(f'    slug: "{slug}",')
    dart.append(f'    type: CatalogType.tag,')
    dart.append(f'    icon: {icon},')
    dart.append(f'    count: {count},')
    dart.append(f'    endpointPath: "/video/search?search={slug}",')
    dart.append(f'  ),')
dart.append("];")
dart.append("")

dart.append("/// Dynamic ExtensionTaxonomy for PornHub Hentai")
dart.append("final ExtensionTaxonomy pornhubTaxonomy = ExtensionTaxonomy(")
dart.append("  sections: [")
dart.append("    TaxonomySection(")
dart.append('      id: "categories",')
dart.append('      title: "Hentai & Anime Categories",')
dart.append("      displayType: TaxonomyDisplayType.grid,")
dart.append("      items: pornhubCategories,")
dart.append("    ),")
dart.append("    TaxonomySection(")
dart.append('      id: "tags",')
dart.append('      title: "Anime & 3D Tags",')
dart.append("      displayType: TaxonomyDisplayType.tags,")
dart.append("      items: pornhubTags,")
dart.append("    ),")
dart.append("  ],")
dart.append(");")

with open('lib/extensions/taxonomies/pornhub_taxonomy.dart', 'w', encoding='utf-8') as f:
    f.write("\n".join(dart) + "\n")

print("Generated lib/extensions/taxonomies/pornhub_taxonomy.dart successfully!")
