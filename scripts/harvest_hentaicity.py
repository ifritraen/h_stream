"""
Live taxonomy harvester for HentaiCity (https://www.hentaicity.com).
Uses Scrapling Fetcher with anti-detection headers to scrape live categories and tags.
Extracts real names, slugs, counts, and thumbnails, and generates:
- d:\\C\\H\\lib\\extensions\\taxonomies\\hentai_city_taxonomy.dart
- scratch\\hentai_city_harvest.json
"""

import json
import os
import re
import sys
from scrapling.fetchers import Fetcher

BASE_URL = "https://www.hentaicity.com"
CATEGORIES_URL = f"{BASE_URL}/categories/"
TAGS_URL = f"{BASE_URL}/tags/"

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': f'{BASE_URL}/',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.5',
}

CATEGORY_ICONS = {
    '3d': 'Icons.view_in_ar_rounded',
    'anal': 'Icons.adjust_rounded',
    'babe': 'Icons.face_3_rounded',
    'bigdick': 'Icons.straighten_rounded',
    'bigtits': 'Icons.lens_blur_rounded',
    'blowjob': 'Icons.sentiment_satisfied_rounded',
    'cartoon': 'Icons.movie_creation_rounded',
    'comics': 'Icons.menu_book_rounded',
    'cumshot': 'Icons.water_drop_rounded',
    'fetish': 'Icons.auto_awesome_rounded',
    'futanari': 'Icons.transgender_rounded',
    'gay': 'Icons.male_rounded',
    'groupsex': 'Icons.groups_rounded',
    'hentai': 'Icons.video_library_rounded',
    'lesbian': 'Icons.female_rounded',
    'masturbation': 'Icons.touch_app_rounded',
    'mature': 'Icons.woman_rounded',
    'monster': 'Icons.pets_rounded',
    'roughsex': 'Icons.bolt_rounded',
    'teen': 'Icons.school_rounded',
    'toys': 'Icons.toys_rounded',
    'voyeur': 'Icons.visibility_rounded',
}

def get_tag_icon_and_group(name: str, slug: str):
    lower = f"{name} {slug}".lower()
    if '3d' in lower:
        return ('Icons.view_in_ar_rounded', '3D & Animation')
    elif any(k in lower for k in ['anal', 'creampie', 'cum', 'blowjob', 'squirt', 'deepthroat', 'facial']):
        return ('Icons.water_drop_rounded', 'Trope')
    elif any(k in lower for k in ['milf', 'teen', 'nurse', 'maid', 'sister', 'mom', 'babe', 'blonde', 'brunette', 'redhead', 'asian', 'latina']):
        return ('Icons.woman_rounded', 'Character')
    elif any(k in lower for k in ['monster', 'alien', 'tentacle', 'demon', 'magic', 'supernatural', 'zombie']):
        return ('Icons.pets_rounded', 'Fantasy')
    elif any(k in lower for k in ['group', '3some', 'threesome', 'gangbang', 'orgy']):
        return ('Icons.groups_rounded', 'Group')
    elif any(k in lower for k in ['cartoon', 'comic', 'animation', 'animated', 'anime']):
        return ('Icons.animation_rounded', 'Format')
    elif any(k in lower for k in ['bdsm', 'bondage', 'femdom', 'spanking', 'leather', 'latex']):
        return ('Icons.link_rounded', 'Fetish')
    elif any(k in lower for k in ['lesbian', 'yuri']):
        return ('Icons.female_rounded', 'Genre')
    elif any(k in lower for k in ['futanari', 'shemale']):
        return ('Icons.transgender_rounded', 'Trope')
    elif any(k in lower for k in ['toy', 'dildo', 'vibrator']):
        return ('Icons.toys_rounded', 'Trope')
    else:
        return ('Icons.tag_rounded', 'Tag')


def harvest():
    fetcher = Fetcher()
    print(f"Fetching categories from {CATEGORIES_URL}...")
    cat_response = fetcher.get(CATEGORIES_URL, headers=HEADERS, timeout=15)
    print(f"Categories response status: {cat_response.status}")

    # Check tags URL as required
    print(f"Fetching tags from {TAGS_URL}...")
    tag_response = fetcher.get(TAGS_URL, headers=HEADERS, timeout=15)
    print(f"Tags response status: {tag_response.status} (Note: live site routes tags through central category hub)")

    # 1. Harvest Categories
    # Video category cards from .item.video-category
    cat_cards = cat_response.css('.item.video-category')
    categories = []
    seen_cat_slugs = set()

    for card in cat_cards:
        a = card.css('a')
        img = card.css('img')
        text = card.get_all_text().strip()

        href = a[0].attrib.get('href', '') if a else ''
        src = img[0].attrib.get('src', '') if img else ''
        alt = img[0].attrib.get('alt', '') if img else ''

        # Parse count and name from text (e.g. "3D 883")
        count_match = re.search(r'^(.*?)\s+(\d+)$', text)
        if count_match:
            name = count_match.group(1).strip()
            count = int(count_match.group(2))
        else:
            name = alt or text
            count = 0

        # Extract slug from href: /videos/straight/3d-popular.html -> 3d
        slug_match = re.search(r'/([^/]+)-popular\.html', href)
        slug = slug_match.group(1) if slug_match else name.lower().replace(' ', '')

        if slug in seen_cat_slugs:
            continue
        seen_cat_slugs.add(slug)

        endpoint = href.replace(BASE_URL, '')
        if not endpoint.startswith('/'):
            endpoint = f"/{endpoint}"

        categories.append({
            'name': name,
            'slug': slug,
            'count': count,
            'thumbnail': src,
            'endpointPath': endpoint,
            'icon': CATEGORY_ICONS.get(slug, 'Icons.category_rounded'),
            'description': f"Stream high quality {name} hentai videos on HentaiCity ({count:,} videos)" if count > 0 else f"Stream high quality {name} hentai videos on HentaiCity",
        })

    print(f"Harvested {len(categories)} categories.")

    # 2. Harvest Tags
    # From .category-item and general links on both responses
    tag_items = cat_response.css('.category-item')
    tags = []
    seen_tag_slugs = set()

    for item in tag_items:
        a = item.css('a')
        qty = item.css('.tag-quantity')
        if not a:
            continue

        href = a[0].attrib.get('href', '')
        name = a[0].get_all_text().strip()
        count_text = qty[0].get_all_text().strip() if qty else '0'
        count = int(count_text) if count_text.isdigit() else 0

        if '/tags/video/' in href:
            slug = href.replace('/tags/video/', '').strip('/')
            endpoint = f"/tags/video/{slug}"
        elif '/videos/straight/' in href:
            # Category link in list, skip as already in categories or add as tag if unique
            slug = href.replace('/videos/straight/', '').replace('-popular.html', '').strip('/')
            if slug in seen_cat_slugs:
                continue
            endpoint = f"/videos/straight/{slug}-popular.html"
        else:
            continue

        if slug in seen_tag_slugs:
            continue
        seen_tag_slugs.add(slug)

        icon, cat_group = get_tag_icon_and_group(name, slug)

        tags.append({
            'name': name,
            'slug': slug,
            'count': count,
            'thumbnail': f"https://www.hentaicity.com/images/categories/{slug.replace('+', '_')}_videos_popular.jpg",
            'endpointPath': endpoint,
            'icon': icon,
            'categoryGroup': cat_group,
            'description': f"HentaiCity anime & 3D videos tagged #{name} ({count:,} videos)" if count > 0 else f"HentaiCity anime & 3D videos tagged #{name}",
        })

    # Also check if tag_response had any extra tags
    if tag_response.status == 200:
        extra_tags = tag_response.css('.category-item, a[href*="/tags/video/"]')
        for extra in extra_tags:
            href = extra.attrib.get('href', '') if extra.tag == 'a' else (extra.css('a')[0].attrib.get('href', '') if extra.css('a') else '')
            if '/tags/video/' in href:
                slug = href.replace('/tags/video/', '').strip('/')
                if slug not in seen_tag_slugs:
                    seen_tag_slugs.add(slug)
                    name = extra.get_all_text().strip()
                    icon, cat_group = get_tag_icon_and_group(name, slug)
                    tags.append({
                        'name': name,
                        'slug': slug,
                        'count': 0,
                        'thumbnail': '',
                        'endpointPath': f"/tags/video/{slug}",
                        'icon': icon,
                        'categoryGroup': cat_group,
                        'description': f"HentaiCity videos tagged #{name}",
                    })

    print(f"Harvested {len(tags)} tags.")

    # Save to JSON
    os.makedirs('scratch', exist_ok=True)
    harvest_data = {
        'source': 'HentaiCity',
        'baseUrl': BASE_URL,
        'categoriesCount': len(categories),
        'tagsCount': len(tags),
        'categories': categories,
        'tags': tags,
    }
    with open('scratch/hentai_city_harvest.json', 'w', encoding='utf-8') as f:
        json.dump(harvest_data, f, indent=2)
    print("Saved harvest to scratch/hentai_city_harvest.json")

    # Generate Dart taxonomy file
    generate_dart_file(categories, tags)


def generate_dart_file(categories, tags):
    target_path = "d:\\C\\H\\lib\\extensions\\taxonomies\\hentai_city_taxonomy.dart"
    os.makedirs(os.path.dirname(target_path), exist_ok=True)

    lines = []
    lines.append("// GENERATED LIVE TAXONOMY FOR HENTAICITY")
    lines.append("// Scraped live via Scrapling from https://www.hentaicity.com/categories/")
    lines.append("// Total Categories: " + str(len(categories)))
    lines.append("// Total Tags: " + str(len(tags)))
    lines.append("import 'package:flutter/material.dart';")
    lines.append("import '../../models/catalog_model.dart';")
    lines.append("")
    lines.append("/// Authentic HentaiCity Categories scraped live")
    lines.append("final List<CatalogItem> hentaiCityCategories = const [")

    for c in categories:
        escaped_name = c['name'].replace('"', '\\"')
        escaped_desc = c['description'].replace('"', '\\"')
        lines.append("  CatalogItem(")
        lines.append(f'    name: "{escaped_name}",')
        lines.append(f'    slug: "{c["slug"]}",')
        lines.append("    type: CatalogType.category,")
        lines.append('    categoryGroup: "Category",')
        lines.append(f"    icon: {c['icon']},")
        lines.append(f"    count: {c['count']},")
        lines.append(f'    description: "{escaped_desc}",')
        lines.append(f'    endpointPath: "{c["endpointPath"]}",')
        lines.append("  ),")

    lines.append("];")
    lines.append("")
    lines.append("/// Authentic HentaiCity Tags scraped live")
    lines.append("final List<CatalogItem> hentaiCityTags = const [")

    for t in tags:
        escaped_name = t['name'].replace('"', '\\"')
        escaped_desc = t['description'].replace('"', '\\"')
        escaped_group = t['categoryGroup'].replace('"', '\\"')
        lines.append("  CatalogItem(")
        lines.append(f'    name: "{escaped_name}",')
        lines.append(f'    slug: "{t["slug"]}",')
        lines.append("    type: CatalogType.tag,")
        lines.append(f'    categoryGroup: "{escaped_group}",')
        lines.append(f"    icon: {t['icon']},")
        lines.append(f"    count: {t['count']},")
        lines.append(f'    description: "{escaped_desc}",')
        lines.append(f'    endpointPath: "{t["endpointPath"]}",')
        lines.append("  ),")

    lines.append("];")
    lines.append("")
    lines.append("/// HentaiCity Explorer Taxonomy with dynamic Grid Categories and Tags")
    lines.append("final ExtensionTaxonomy hentaiCityTaxonomy = ExtensionTaxonomy(")
    lines.append("  sections: [")
    lines.append("    TaxonomySection(")
    lines.append('      id: "categories",')
    lines.append('      title: "Categories",')
    lines.append("      displayType: TaxonomyDisplayType.grid,")
    lines.append("      items: hentaiCityCategories,")
    lines.append("      icon: Icons.category_rounded,")
    lines.append("    ),")
    lines.append("    TaxonomySection(")
    lines.append('      id: "tags",')
    lines.append('      title: "Tags & Tropes",')
    lines.append("      displayType: TaxonomyDisplayType.tags,")
    lines.append("      items: hentaiCityTags,")
    lines.append("      icon: Icons.tag_rounded,")
    lines.append("    ),")
    lines.append("  ],")
    lines.append("  categories: hentaiCityCategories,")
    lines.append("  tagsAndGenres: hentaiCityTags,")
    lines.append(");")
    lines.append("")

    content = "\n".join(lines)
    with open(target_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Written Dart taxonomy to {target_path}")


if __name__ == '__main__':
    harvest()
