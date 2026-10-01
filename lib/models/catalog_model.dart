import 'package:flutter/material.dart';

enum CatalogType {
  category,
  genre,
  tag,
  artist,
}

enum TaxonomyDisplayType {
  grid,     // 2-column card grid (Categories, Formats, Franchises)
  tags,     // Tag chips / filter group chips (Tags, Tropes, Genres)
  artists,  // OLED creator/studio avatar cards with star ratings & counts (Top Artists, Animators, Studios)
  list,     // List view (Playlists, Channels, Rankings)
}

class CatalogItem {
  final String name;
  final String slug;
  final CatalogType type;
  final String? categoryGroup; // e.g. "Character", "Trope", "Game Parody"
  final IconData icon;
  final int count;
  final String description;
  final String? endpointPath; // optional direct URL path e.g. /genre/vanilla/

  const CatalogItem({
    required this.name,
    required this.slug,
    required this.type,
    this.categoryGroup,
    required this.icon,
    this.count = 0,
    this.description = "",
    this.endpointPath,
  });
}

class TaxonomySection {
  final String id;
  final String title;
  final TaxonomyDisplayType displayType;
  final List<CatalogItem> items;
  final IconData? icon;

  const TaxonomySection({
    required this.id,
    required this.title,
    required this.displayType,
    required this.items,
    this.icon,
  });
}

class ExtensionTaxonomy {
  final List<TaxonomySection> sections;
  final List<CatalogItem> categories;
  final List<CatalogItem> tagsAndGenres;
  final List<CatalogItem> artists;

  const ExtensionTaxonomy({
    this.sections = const [],
    this.categories = const [],
    this.tagsAndGenres = const [],
    this.artists = const [],
  });

  /// Dynamically computes effective sections for Explore tab structure.
  /// If explicit `sections` are provided by the extension, they take precedence.
  /// Otherwise, non-empty `categories`, `tagsAndGenres`, and `artists` are mapped.
  List<TaxonomySection> get effectiveSections {
    if (sections.isNotEmpty) return sections;
    final list = <TaxonomySection>[];
    if (categories.isNotEmpty) {
      list.add(TaxonomySection(
        id: "categories",
        title: "Category",
        displayType: TaxonomyDisplayType.grid,
        items: categories,
        icon: Icons.category_rounded,
      ));
    }
    if (tagsAndGenres.isNotEmpty) {
      list.add(TaxonomySection(
        id: "tags",
        title: "Tags / Genre",
        displayType: TaxonomyDisplayType.tags,
        items: tagsAndGenres,
        icon: Icons.tag_rounded,
      ));
    }
    if (artists.isNotEmpty) {
      list.add(TaxonomySection(
        id: "artists",
        title: "Top Artists",
        displayType: TaxonomyDisplayType.artists,
        items: artists,
        icon: Icons.palette_rounded,
      ));
    }
    return list;
  }

  bool get isEmpty =>
      effectiveSections.isEmpty ||
      effectiveSections.every((s) => s.items.isEmpty);

  bool get isNotEmpty => !isEmpty;

  factory ExtensionTaxonomy.fromDefaultCatalog() {
    return ExtensionTaxonomy(
      categories: CatalogRepository.categories,
      tagsAndGenres: [...CatalogRepository.genres, ...CatalogRepository.tags],
      artists: const [],
    );
  }

  static const ExtensionTaxonomy empty = ExtensionTaxonomy(
    categories: [],
    tagsAndGenres: [],
    artists: [],
    sections: [],
  );
}

class CatalogRepository {
  static const List<CatalogItem> categories = [
    CatalogItem(
      name: "Anime Series",
      slug: "anime-series",
      type: CatalogType.category,
      icon: Icons.live_tv_rounded,
      count: 6840,
      description: "Multi-episode serialized anime productions",
    ),
    CatalogItem(
      name: "OVA Releases",
      slug: "ova",
      type: CatalogType.category,
      icon: Icons.album_rounded,
      count: 4210,
      description: "Original Video Animation standalone releases",
    ),
    CatalogItem(
      name: "Uncensored",
      slug: "uncensored",
      type: CatalogType.category,
      icon: Icons.lock_open_rounded,
      count: 8940,
      description: "Original uncensored master studio cuts",
    ),
    CatalogItem(
      name: "Decensored",
      slug: "decensored",
      type: CatalogType.category,
      icon: Icons.auto_fix_high_rounded,
      count: 3120,
      description: "AI & artist mosaic removed restorations",
    ),
    CatalogItem(
      name: "3D / MMD / SFM",
      slug: "3d-mmd",
      type: CatalogType.category,
      icon: Icons.animation_rounded,
      count: 9450,
      description: "3D CGI, MMD, Blender & SFM animations",
    ),
    CatalogItem(
      name: "4K UHD 60FPS",
      slug: "4k-60fps",
      type: CatalogType.category,
      icon: Icons.high_quality_rounded,
      count: 2180,
      description: "Ultra high definition 60fps remastered video",
    ),
    CatalogItem(
      name: "English Dubbed",
      slug: "english-dub",
      type: CatalogType.category,
      icon: Icons.record_voice_over_rounded,
      count: 1450,
      description: "Professional English voice actor dubs",
    ),
    CatalogItem(
      name: "English Subbed",
      slug: "english-sub",
      type: CatalogType.category,
      icon: Icons.subtitles_rounded,
      count: 11200,
      description: "Original Japanese audio with English subtitles",
    ),
    CatalogItem(
      name: "Cosplay & Live Action",
      slug: "cosplay",
      type: CatalogType.category,
      icon: Icons.theater_comedy_rounded,
      count: 2430,
      description: "Authentic cosplay performances and gravure",
    ),
    CatalogItem(
      name: "Motion Doujinshi",
      slug: "motion-anime",
      type: CatalogType.category,
      icon: Icons.auto_stories_rounded,
      count: 3670,
      description: "Animated manga and voiced motion comics",
    ),
    CatalogItem(
      name: "VR 360",
      slug: "vr",
      type: CatalogType.category,
      icon: Icons.view_in_ar_rounded,
      count: 920,
      description: "Virtual Reality immersive interactive media",
    ),
    CatalogItem(
      name: "Shorts & Clips",
      slug: "shorts",
      type: CatalogType.category,
      icon: Icons.movie_creation_rounded,
      count: 4890,
      description: "Highlight moments and short animation clips",
    ),
    CatalogItem(
      name: "Ongoing Broadcasts",
      slug: "ongoing",
      type: CatalogType.category,
      icon: Icons.update_rounded,
      count: 850,
      description: "Currently airing and ongoing weekly releases",
    ),
    CatalogItem(
      name: "Completed Series",
      slug: "completed",
      type: CatalogType.category,
      icon: Icons.done_all_rounded,
      count: 7320,
      description: "Fully completed seasons and story arcs",
    ),
    CatalogItem(
      name: "Retro 90s Golden Era",
      slug: "retro",
      type: CatalogType.category,
      icon: Icons.history_edu_rounded,
      count: 1680,
      description: "Vintage hand-drawn cel animated classics",
    ),
  ];

  static const List<CatalogItem> genres = [
    CatalogItem(
      name: "Vanilla",
      slug: "vanilla",
      type: CatalogType.genre,
      icon: Icons.sentiment_very_satisfied_rounded,
      count: 3820,
      description: "Wholesome, loving, consensual romance",
    ),
    CatalogItem(
      name: "Romance",
      slug: "romance",
      type: CatalogType.genre,
      icon: Icons.favorite_rounded,
      count: 4120,
      description: "Passionate relationships and love stories",
    ),
    CatalogItem(
      name: "Fantasy",
      slug: "fantasy",
      type: CatalogType.genre,
      icon: Icons.auto_awesome_rounded,
      count: 5240,
      description: "Magic, kingdoms, wizards and mystical realms",
    ),
    CatalogItem(
      name: "Dark Fantasy",
      slug: "dark-fantasy",
      type: CatalogType.genre,
      icon: Icons.local_fire_department_rounded,
      count: 2310,
      description: "Grimdark worlds, sorcery and dangerous demons",
    ),
    CatalogItem(
      name: "Supernatural",
      slug: "supernatural",
      type: CatalogType.genre,
      icon: Icons.blur_on_rounded,
      count: 3140,
      description: "Spirits, vampires, succubi and ghosts",
    ),
    CatalogItem(
      name: "Sci-Fi & Cyberpunk",
      slug: "sci-fi",
      type: CatalogType.genre,
      icon: Icons.memory_rounded,
      count: 1980,
      description: "Futuristic cities, cyborgs, androids and tech",
    ),
    CatalogItem(
      name: "Isekai",
      slug: "isekai",
      type: CatalogType.genre,
      icon: Icons.travel_explore_rounded,
      count: 2890,
      description: "Reincarnated into another fantasy game world",
    ),
    CatalogItem(
      name: "Action & Adventure",
      slug: "action",
      type: CatalogType.genre,
      icon: Icons.sports_martial_arts_rounded,
      count: 2750,
      description: "High-octane fights, martial arts and quests",
    ),
    CatalogItem(
      name: "Comedy & Parody",
      slug: "comedy",
      type: CatalogType.genre,
      icon: Icons.mood_rounded,
      count: 3410,
      description: "Hilarious misunderstandings and ecchi humor",
    ),
    CatalogItem(
      name: "Horror & Suspense",
      slug: "horror",
      type: CatalogType.genre,
      icon: Icons.nightlight_round,
      count: 1420,
      description: "Spooky atmospheres, tension and eerie encounters",
    ),
    CatalogItem(
      name: "Psychological & Thriller",
      slug: "psychological",
      type: CatalogType.genre,
      icon: Icons.psychology_rounded,
      count: 1890,
      description: "Mind games, psychological intrigue and tension",
    ),
    CatalogItem(
      name: "School Life",
      slug: "school-life",
      type: CatalogType.genre,
      icon: Icons.school_rounded,
      count: 4890,
      description: "After-school clubs, classrooms and festivals",
    ),
    CatalogItem(
      name: "Slice of Life",
      slug: "slice-of-life",
      type: CatalogType.genre,
      icon: Icons.wb_sunny_rounded,
      count: 2650,
      description: "Peaceful daily routines and cozy scenarios",
    ),
    CatalogItem(
      name: "Harem",
      slug: "harem",
      type: CatalogType.genre,
      icon: Icons.groups_rounded,
      count: 3950,
      description: "Surrounded by gorgeous passionate heroines",
    ),
    CatalogItem(
      name: "Drama",
      slug: "drama",
      type: CatalogType.genre,
      icon: Icons.masks_rounded,
      count: 2120,
      description: "Emotional stakes, dilemmas and relationship arcs",
    ),
    CatalogItem(
      name: "Mystery",
      slug: "mystery",
      type: CatalogType.genre,
      icon: Icons.search_rounded,
      count: 1340,
      description: "Secrets waiting to be discovered and investigated",
    ),
    CatalogItem(
      name: "Historical / Edo",
      slug: "historical",
      type: CatalogType.genre,
      icon: Icons.fort_rounded,
      count: 1190,
      description: "Feudal samurai, kunoichi and shrines",
    ),
    CatalogItem(
      name: "Mecha & Sci-Tech",
      slug: "mecha",
      type: CatalogType.genre,
      icon: Icons.smart_toy_rounded,
      count: 870,
      description: "Giant combat robots and sleek mechanized suits",
    ),
    CatalogItem(
      name: "Ecchi",
      slug: "ecchi",
      type: CatalogType.genre,
      icon: Icons.visibility_rounded,
      count: 6420,
      description: "Playful fan service, wardrobe malfunctions and teasing",
    ),
  ];

  static const List<CatalogItem> tags = [
    // Character Archetypes
    CatalogItem(name: "Maid", slug: "maid", type: CatalogType.tag, categoryGroup: "Character", icon: Icons.cleaning_services_rounded, count: 1840),
    CatalogItem(name: "Milf", slug: "milf", type: CatalogType.tag, categoryGroup: "Character", icon: Icons.woman_rounded, count: 3120),
    CatalogItem(name: "Schoolgirl", slug: "schoolgirl", type: CatalogType.tag, categoryGroup: "Character", icon: Icons.school_rounded, count: 4190),
    CatalogItem(name: "Gyaru / Gal", slug: "gyaru", type: CatalogType.tag, categoryGroup: "Character", icon: Icons.flare_rounded, count: 1430),
    CatalogItem(name: "Monster Girl", slug: "monster-girl", type: CatalogType.tag, categoryGroup: "Character", icon: Icons.pets_rounded, count: 1950),
    CatalogItem(name: "Elf", slug: "elf", type: CatalogType.tag, categoryGroup: "Character", icon: Icons.forest_rounded, count: 2480),
    CatalogItem(name: "Dark Elf", slug: "dark-elf", type: CatalogType.tag, categoryGroup: "Character", icon: Icons.shield_moon_rounded, count: 1370),
    CatalogItem(name: "Succubus", slug: "succubus", type: CatalogType.tag, categoryGroup: "Character", icon: Icons.favorite_border_rounded, count: 1820),
    CatalogItem(name: "Catgirl / Neko", slug: "catgirl", type: CatalogType.tag, categoryGroup: "Character", icon: Icons.cruelty_free_rounded, count: 2150),
    CatalogItem(name: "Fox Girl / Kitsune", slug: "kitsune", type: CatalogType.tag, categoryGroup: "Character", icon: Icons.star_border_purple500_rounded, count: 1120),
    CatalogItem(name: "Teacher / Sensei", slug: "teacher", type: CatalogType.tag, categoryGroup: "Character", icon: Icons.menu_book_rounded, count: 1680),
    CatalogItem(name: "Nurse", slug: "nurse", type: CatalogType.tag, categoryGroup: "Character", icon: Icons.medical_services_rounded, count: 1230),
    CatalogItem(name: "Office Lady / OL", slug: "office-lady", type: CatalogType.tag, categoryGroup: "Character", icon: Icons.business_center_rounded, count: 1540),
    CatalogItem(name: "Ninja / Kunoichi", slug: "kunoichi", type: CatalogType.tag, categoryGroup: "Character", icon: Icons.sports_kabaddi_rounded, count: 980),
    CatalogItem(name: "Tomboy", slug: "tomboy", type: CatalogType.tag, categoryGroup: "Character", icon: Icons.sports_tennis_rounded, count: 890),
    CatalogItem(name: "Tsundere", slug: "tsundere", type: CatalogType.tag, categoryGroup: "Character", icon: Icons.tag_faces_rounded, count: 1460),
    CatalogItem(name: "Yandere", slug: "yandere", type: CatalogType.tag, categoryGroup: "Character", icon: Icons.heart_broken_rounded, count: 1280),
    CatalogItem(name: "Kuudere", slug: "kuudere", type: CatalogType.tag, categoryGroup: "Character", icon: Icons.ac_unit_rounded, count: 740),
    CatalogItem(name: "Princess / Royalty", slug: "princess", type: CatalogType.tag, categoryGroup: "Character", icon: Icons.workspace_premium_rounded, count: 1190),
    CatalogItem(name: "Nun / Sister", slug: "nun", type: CatalogType.tag, categoryGroup: "Character", icon: Icons.church_rounded, count: 850),
    CatalogItem(name: "Cheerleader", slug: "cheerleader", type: CatalogType.tag, categoryGroup: "Character", icon: Icons.celebration_rounded, count: 620),
    CatalogItem(name: "Vampire", slug: "vampire", type: CatalogType.tag, categoryGroup: "Character", icon: Icons.nightlight_rounded, count: 1070),
    CatalogItem(name: "Demon Girl", slug: "demon-girl", type: CatalogType.tag, categoryGroup: "Character", icon: Icons.whatshot_rounded, count: 1750),
    CatalogItem(name: "Goddess", slug: "goddess", type: CatalogType.tag, categoryGroup: "Character", icon: Icons.light_mode_rounded, count: 960),
    CatalogItem(name: "Idol", slug: "idol", type: CatalogType.tag, categoryGroup: "Character", icon: Icons.mic_rounded, count: 1340),
    CatalogItem(name: "Bunnygirl", slug: "bunnygirl", type: CatalogType.tag, categoryGroup: "Character", icon: Icons.cruelty_free_sharp, count: 1580),
    CatalogItem(name: "Swimsuit / Bikini", slug: "swimsuit", type: CatalogType.tag, categoryGroup: "Character", icon: Icons.pool_rounded, count: 2670),
    CatalogItem(name: "Knight / Paladin", slug: "knight", type: CatalogType.tag, categoryGroup: "Character", icon: Icons.shield_rounded, count: 1020),
    CatalogItem(name: "Witch / Sorceress", slug: "witch", type: CatalogType.tag, categoryGroup: "Character", icon: Icons.auto_fix_normal_rounded, count: 1180),
    CatalogItem(name: "Tanlines / Dark Skin", slug: "dark-skin", type: CatalogType.tag, categoryGroup: "Character", icon: Icons.wb_sunny_outlined, count: 2210),
    CatalogItem(name: "Glasses / Megane", slug: "glasses", type: CatalogType.tag, categoryGroup: "Character", icon: Icons.visibility_outlined, count: 1450),
    CatalogItem(name: "Short Hair", slug: "short-hair", type: CatalogType.tag, categoryGroup: "Character", icon: Icons.face_retouching_natural_rounded, count: 1820),
    CatalogItem(name: "Twin Tails", slug: "twin-tails", type: CatalogType.tag, categoryGroup: "Character", icon: Icons.face_3_rounded, count: 1930),
    CatalogItem(name: "Ponytail", slug: "ponytail", type: CatalogType.tag, categoryGroup: "Character", icon: Icons.face_4_rounded, count: 1760),
    CatalogItem(name: "Busty / Big Breasts", slug: "big-breasts", type: CatalogType.tag, categoryGroup: "Character", icon: Icons.lens_blur_rounded, count: 5300),
    CatalogItem(name: "Petite / Small Breasts", slug: "petite", type: CatalogType.tag, categoryGroup: "Character", icon: Icons.circle_outlined, count: 2980),
    CatalogItem(name: "Muscular Girl", slug: "muscular-girl", type: CatalogType.tag, categoryGroup: "Character", icon: Icons.fitness_center_rounded, count: 540),
    CatalogItem(name: "Chubby / BBW", slug: "bbw", type: CatalogType.tag, categoryGroup: "Character", icon: Icons.favorite_rounded, count: 410),

    // Tropes & Fetishes
    CatalogItem(name: "Ahegao", slug: "ahegao", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.sentiment_satisfied_alt_rounded, count: 3420),
    CatalogItem(name: "Creampie / Nakadashi", slug: "creampie", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.water_drop_rounded, count: 4950),
    CatalogItem(name: "Paizuri / Titfuck", slug: "paizuri", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.favorite_rounded, count: 2890),
    CatalogItem(name: "Mind Control / Hypnosis", slug: "mind-control", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.cyclone_rounded, count: 2310),
    CatalogItem(name: "Time Stop", slug: "time-stop", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.timer_off_rounded, count: 1420),
    CatalogItem(name: "Invisible Man", slug: "invisible", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.visibility_off_rounded, count: 890),
    CatalogItem(name: "BDSM / Bondage", slug: "bdsm", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.link_rounded, count: 2180),
    CatalogItem(name: "Tentacles", slug: "tentacles", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.hub_rounded, count: 2640),
    CatalogItem(name: "Netorare / NTR", slug: "ntr", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.broken_image_rounded, count: 2850),
    CatalogItem(name: "Netori", slug: "netori", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.sentiment_very_satisfied_rounded, count: 920),
    CatalogItem(name: "Cheating / Infidelity", slug: "cheating", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.warning_amber_rounded, count: 1870),
    CatalogItem(name: "Femdom", slug: "femdom", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.gavel_rounded, count: 2340),
    CatalogItem(name: "Footjob / Feet", slug: "footjob", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.do_not_step_rounded, count: 1690),
    CatalogItem(name: "Thigh Highs / Stockings", slug: "stockings", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.roller_shades_rounded, count: 3890),
    CatalogItem(name: "Garter Straps", slug: "garter-straps", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.line_style_rounded, count: 1120),
    CatalogItem(name: "Incest / Sister", slug: "sister", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.family_restroom_rounded, count: 3140),
    CatalogItem(name: "Mother", slug: "mother", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.woman_rounded, count: 2250),
    CatalogItem(name: "Aunt", slug: "aunt", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.person_rounded, count: 840),
    CatalogItem(name: "Cousin", slug: "cousin", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.people_outline_rounded, count: 960),
    CatalogItem(name: "Yuri / Girls Love", slug: "yuri", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.favorite_border_rounded, count: 2780),
    CatalogItem(name: "Futanari", slug: "futanari", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.transgender_rounded, count: 3620),
    CatalogItem(name: "Gangbang", slug: "gangbang", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.groups_3_rounded, count: 2150),
    CatalogItem(name: "Group / Orgy", slug: "orgy", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.diversity_3_rounded, count: 2490),
    CatalogItem(name: "Public / Exhibitionism", slug: "exhibitionism", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.park_rounded, count: 1780),
    CatalogItem(name: "Voyeurism / Peeping", slug: "voyeurism", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.remove_red_eye_rounded, count: 1320),
    CatalogItem(name: "Lingerie / Underwear", slug: "lingerie", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.checkroom_rounded, count: 2860),
    CatalogItem(name: "Sleep Sex / Somnophilia", slug: "somnophilia", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.bedtime_rounded, count: 1150),
    CatalogItem(name: "Drunk / Aphrodisiac", slug: "aphrodisiac", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.local_bar_rounded, count: 1480),
    CatalogItem(name: "X-Ray / Internal View", slug: "x-ray", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.camera_rounded, count: 2610),
    CatalogItem(name: "Lactation / Breast Milk", slug: "lactation", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.opacity_rounded, count: 1390),
    CatalogItem(name: "Blowjob / Fellatio", slug: "blowjob", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.sentiment_satisfied_rounded, count: 4210),
    CatalogItem(name: "Deepthroat", slug: "deepthroat", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.expand_more_rounded, count: 2110),
    CatalogItem(name: "Spanking", slug: "spanking", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.back_hand_rounded, count: 1270),
    CatalogItem(name: "Double Penetration", slug: "double-penetration", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.alt_route_rounded, count: 1830),
    CatalogItem(name: "Toys / Vibrators", slug: "toys", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.toys_rounded, count: 1950),
    CatalogItem(name: "Virgin / Defloration", slug: "defloration", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.flare_outlined, count: 2180),
    CatalogItem(name: "Squirting", slug: "squirting", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.water_rounded, count: 1920),
    CatalogItem(name: "Pet Play / Leash", slug: "pet-play", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.pets_outlined, count: 760),
    CatalogItem(name: "Latex / Leather", slug: "latex", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.shield_outlined, count: 840),
    CatalogItem(name: "Goth / E-Girl", slug: "goth", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.dark_mode_rounded, count: 690),
    CatalogItem(name: "Crossdressing / Traps", slug: "crossdressing", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.swap_horiz_rounded, count: 1410),
    CatalogItem(name: "Corruption / Fallen", slug: "corruption", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.trending_down_rounded, count: 1680),
    CatalogItem(name: "Blackmail", slug: "blackmail", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.lock_clock_rounded, count: 1940),
    CatalogItem(name: "Gloryhole", slug: "gloryhole", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.radio_button_checked_rounded, count: 870),
    CatalogItem(name: "POV / First Person", slug: "pov", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.videocam_rounded, count: 2430),
    CatalogItem(name: "Sweat / Glistening", slug: "sweat", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.water_drop_outlined, count: 1380),
    CatalogItem(name: "Oil / Massage", slug: "massage", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.spa_rounded, count: 1510),
    CatalogItem(name: "Onsen / Hot Springs", slug: "onsen", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.hot_tub_rounded, count: 1670),
    CatalogItem(name: "Beach / Pool", slug: "beach", type: CatalogType.tag, categoryGroup: "Trope", icon: Icons.beach_access_rounded, count: 1820),

    // Pop Culture & Game Parodies
    CatalogItem(name: "Genshin Impact", slug: "genshin-impact", type: CatalogType.tag, categoryGroup: "Game Parody", icon: Icons.auto_awesome_rounded, count: 5120),
    CatalogItem(name: "Overwatch", slug: "overwatch", type: CatalogType.tag, categoryGroup: "Game Parody", icon: Icons.gamepad_rounded, count: 4300),
    CatalogItem(name: "Fate / Grand Order", slug: "fate", type: CatalogType.tag, categoryGroup: "Game Parody", icon: Icons.shield_rounded, count: 3890),
    CatalogItem(name: "Honkai Star Rail", slug: "honkai-star-rail", type: CatalogType.tag, categoryGroup: "Game Parody", icon: Icons.rocket_launch_rounded, count: 2980),
    CatalogItem(name: "Final Fantasy", slug: "final-fantasy", type: CatalogType.tag, categoryGroup: "Game Parody", icon: Icons.auto_fix_high_rounded, count: 2450),
    CatalogItem(name: "NieR Automata / 2B", slug: "nier-automata", type: CatalogType.tag, categoryGroup: "Game Parody", icon: Icons.smart_toy_rounded, count: 2120),
    CatalogItem(name: "Dead or Alive", slug: "dead-or-alive", type: CatalogType.tag, categoryGroup: "Game Parody", icon: Icons.sports_kabaddi_rounded, count: 1840),
    CatalogItem(name: "League of Legends", slug: "league-of-legends", type: CatalogType.tag, categoryGroup: "Game Parody", icon: Icons.military_tech_rounded, count: 2670),
    CatalogItem(name: "Pokemon", slug: "pokemon", type: CatalogType.tag, categoryGroup: "Game Parody", icon: Icons.catching_pokemon_rounded, count: 1780),
    CatalogItem(name: "Azur Lane", slug: "azur-lane", type: CatalogType.tag, categoryGroup: "Game Parody", icon: Icons.directions_boat_rounded, count: 2390),
    CatalogItem(name: "Blue Archive", slug: "blue-archive", type: CatalogType.tag, categoryGroup: "Game Parody", icon: Icons.brightness_7_rounded, count: 2140),
    CatalogItem(name: "Street Fighter", slug: "street-fighter", type: CatalogType.tag, categoryGroup: "Game Parody", icon: Icons.sports_martial_arts_rounded, count: 1290),
    CatalogItem(name: "Resident Evil", slug: "resident-evil", type: CatalogType.tag, categoryGroup: "Game Parody", icon: Icons.coronavirus_rounded, count: 1560),
    CatalogItem(name: "Cyberpunk / Edgerunners", slug: "cyberpunk", type: CatalogType.tag, categoryGroup: "Game Parody", icon: Icons.memory_rounded, count: 1430),
    CatalogItem(name: "Persona Series", slug: "persona", type: CatalogType.tag, categoryGroup: "Game Parody", icon: Icons.theater_comedy_rounded, count: 1120),
    CatalogItem(name: "Naruto / Kunoichi", slug: "naruto", type: CatalogType.tag, categoryGroup: "Anime Parody", icon: Icons.flare_rounded, count: 1680),
    CatalogItem(name: "Dragon Ball", slug: "dragon-ball", type: CatalogType.tag, categoryGroup: "Anime Parody", icon: Icons.bolt_rounded, count: 980),
    CatalogItem(name: "One Piece", slug: "one-piece", type: CatalogType.tag, categoryGroup: "Anime Parody", icon: Icons.sailing_rounded, count: 1450),
    CatalogItem(name: "Bleach", slug: "bleach", type: CatalogType.tag, categoryGroup: "Anime Parody", icon: Icons.cut_rounded, count: 1120),
    CatalogItem(name: "Demon Slayer", slug: "demon-slayer", type: CatalogType.tag, categoryGroup: "Anime Parody", icon: Icons.local_fire_department_rounded, count: 1340),
    CatalogItem(name: "Chainsaw Man", slug: "chainsaw-man", type: CatalogType.tag, categoryGroup: "Anime Parody", icon: Icons.hardware_rounded, count: 1210),
    CatalogItem(name: "Spy x Family", slug: "spy-x-family", type: CatalogType.tag, categoryGroup: "Anime Parody", icon: Icons.family_restroom_rounded, count: 950),
    CatalogItem(name: "Attack on Titan", slug: "attack-on-titan", type: CatalogType.tag, categoryGroup: "Anime Parody", icon: Icons.castle_rounded, count: 780),
    CatalogItem(name: "My Hero Academia", slug: "my-hero-academia", type: CatalogType.tag, categoryGroup: "Anime Parody", icon: Icons.shield_rounded, count: 1090),
  ];

  static List<CatalogItem> getAllItems() {
    return [...categories, ...genres, ...tags];
  }
}
