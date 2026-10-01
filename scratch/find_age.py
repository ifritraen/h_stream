with open("scratch/app.js", "r", encoding="utf-8") as f:
    js = f.read()

import re
matches = list(re.finditer(r'age-confirmation', js))
for m in matches:
    idx = m.start()
    print("MATCH AT", idx)
    print(js[max(0, idx-300):min(len(js), idx+300)])
    print("="*40)
