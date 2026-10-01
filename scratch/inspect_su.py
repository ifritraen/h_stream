with open("scratch/app.js", "r", encoding="utf-8") as f:
    js = f.read()

idx = js.find("async function Su")
if idx != -1:
    print(js[idx:idx+800])
else:
    print("Su not found, searching age-confirmation:")
    for m in [m.start() for m in re.finditer("age-confirmation", js)]:
        print(js[max(0, m-200):min(len(js), m+300)])
