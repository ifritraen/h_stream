with open("scratch/App.js", "r", encoding="utf-8") as f:
    js = f.read()

import re
matches = list(re.finditer(r'/api/v1/playback/', js))
for m in matches:
    idx = m.start()
    print("PLAYBACK AT", idx)
    print(js[max(0, idx-200):min(len(js), idx+600)])
    print("="*40)
