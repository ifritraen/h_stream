import json

with open("d:/C/H/scratch/haho_moe_harvested.json", "r", encoding="utf-8") as f:
    data = json.load(f)

print(f"Formats: {len(data['formats'])}")
for fmt in data['formats']:
    print(" ", fmt['name'], fmt['slug'])

print(f"\nPlaylists: {len(data['playlists'])}")
for pl in data['playlists'][:10]:
    print(" ", pl['name'], f"({pl['count']} vids)", pl['slug'])

print(f"\nGenres total: {len(data['genres'])}")
# Check some known genres
popular_names = ['action', 'romance', 'comedy', 'fantasy', 'drama', 'horror', 'sci-fi', 'school', 'uncensored', 'maid', 'milf', 'yuri', 'yaoi', 'harem', '3d cg animation', 'vanilla', 'creampie', 'paizuri', 'anal', 'ahegao', 'ntr', 'netorare', 'blowjob', 'elf', 'monster girl', 'tentacles', 'magic', 'ecchi', 'bondage', 'bdsm', 'mind break', 'femdom', 'cheating', 'glasses', 'dark skin', 'swimsuit', 'cosplay', 'teacher', 'nurse', 'sister', 'incest', 'tsundere', 'kuudere', 'yandere', 'gyaru', 'gangbang', 'futanari', 'submissive', 'slave', 'demon', 'vampire', 'succubus', 'exhibitionism', 'public', 'masturbation', 'toys', 'virgin', 'uniform', 'stockings', 'bikini', 'beach', 'pov', 'urination', 'lactation', 'bbw', 'footjob', 'crossdressing', 'trap', 'glasses']

found_popular = [g for g in data['genres'] if any(p == g['name'].lower() for p in popular_names)]
print(f"Found popular hentai genres: {len(found_popular)}")
for g in found_popular[:15]:
    print(" ", g['name'], "->", g['slug'])
