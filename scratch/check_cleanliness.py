import json

with open("d:/C/H/scratch/haho_moe_harvested.json", "r", encoding="utf-8") as f:
    data = json.load(f)

genres = data['genres']
playlists = data['playlists']
formats = data['formats']

print(f"Total genres: {len(genres)}")
empty_names = [g for g in genres if not g['name']]
print(f"Empty genre names: {len(empty_names)}")

special_chars = [g for g in genres if any(c in g['name'] for c in ['"', '\\', '$', '\n', '\r'])]
print(f"Special chars in genre names: {len(special_chars)}")
for g in special_chars:
    print(" ", repr(g['name']))

print(f"\nTotal playlists: {len(playlists)}")
special_pl = [p for p in playlists if any(c in p['name'] for c in ['"', '\\', '$', '\n', '\r'])]
print(f"Special chars in playlist names: {len(special_pl)}")
for p in special_pl[:5]:
    print(" ", repr(p['name']))
