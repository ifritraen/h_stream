import json
import re

with open('scratch/only_hentai_stuff_raw.json', encoding='utf-8') as f:
    data = json.load(f)

tags = data['tags']

def categorize_tag(t):
    name = t['name']
    slug = t['slug'].lower()
    low = name.lower()

    if re.match(r'^\d{4}$', name):
        return 'Icons.calendar_today_rounded', 'Year / Release'
    if any(k in slug for k in ['sub', 'dub', 'rus', 'eng']):
        return 'Icons.translate_rounded', 'Audio / Subtitle'
    if any(k in slug for k in ['3d', 'sfm', 'cgi', 'blender']):
        return 'Icons.view_in_ar_rounded', 'Format'
    if 'uncensor' in slug:
        return 'Icons.lock_open_rounded', 'Censorship'
    if any(k in slug for k in ['studio', 'production', 'animation', 'film', 'media', 'soft', 'pictures', 'anime']):
        return 'Icons.business_rounded', 'Studio / Brand'
    if any(k in slug for k in ['boob', 'tit', 'oppai', 'bust', 'paizuri']):
        return 'Icons.bubble_chart_rounded', 'Body'
    if any(k in slug for k in ['creampie', 'cum', 'squirt']):
        return 'Icons.water_drop_rounded', 'Act / Fetish'
    if any(k in slug for k in ['blowjob', 'oral', 'fellatio', 'deepthroat']):
        return 'Icons.sentiment_satisfied_rounded', 'Act / Fetish'
    if any(k in slug for k in ['anal', 'ass']):
        return 'Icons.accessibility_new_rounded', 'Act / Fetish'
    if any(k in slug for k in ['school', 'student', 'teacher', 'sensei']):
        return 'Icons.school_rounded', 'Character'
    if any(k in slug for k in ['milf', 'mature', 'mother', 'mom', 'housewife']):
        return 'Icons.woman_rounded', 'Character'
    if any(k in slug for k in ['maid', 'nurse']):
        return 'Icons.medical_services_rounded', 'Character'
    if any(k in slug for k in ['monster', 'tentacle', 'demon', 'alien', 'orc', 'beast', 'goblin']):
        return 'Icons.pest_control_rounded', 'Fantasy'
    if any(k in slug for k in ['magic', 'supernatural', 'elf', 'dragon', 'angel']):
        return 'Icons.auto_awesome_rounded', 'Fantasy'
    if any(k in slug for k in ['bondage', 'bdsm', 'slave', 'forced', 'rape', 'chikan']):
        return 'Icons.link_rounded', 'Fetish'
    if any(k in slug for k in ['harem', 'group', 'orgy', 'threesome', 'gangbang']):
        return 'Icons.groups_rounded', 'Theme'
    if any(k in slug for k in ['action', 'adventure']):
        return 'Icons.sports_kabaddi_rounded', 'Theme'
    if any(k in slug for k in ['comedy', 'parody']):
        return 'Icons.theater_comedy_rounded', 'Theme'
    if any(k in slug for k in ['romance', 'love', 'vanilla']):
        return 'Icons.favorite_rounded', 'Theme'
    if any(k in slug for k in ['game', 'vr']):
        return 'Icons.sports_esports_rounded', 'Theme'
    if any(k in slug for k in ['yuri', 'lesbian']):
        return 'Icons.diversity_1_rounded', 'Theme'
    if any(k in slug for k in ['yaoi', 'gay']):
        return 'Icons.diversity_3_rounded', 'Theme'
    if any(k in slug for k in ['futa', 'shemale']):
        return 'Icons.transgender_rounded', 'Character'
    if any(k in slug for k in ['catgirl', 'neko', 'animal']):
        return 'Icons.pets_rounded', 'Character'
    if len(name.split()) == 2 and not any(char.isdigit() for char in name):
        return 'Icons.person_rounded', 'Artist / Director'
    return 'Icons.tag_rounded', 'Tag'

groups = {}
for t in tags:
    icon, grp = categorize_tag(t)
    groups[grp] = groups.get(grp, 0) + 1

for grp, cnt in sorted(groups.items(), key=lambda x: -x[1]):
    print(f'{grp}: {cnt}')
