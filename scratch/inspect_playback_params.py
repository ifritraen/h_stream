with open("scratch/App.js", "r", encoding="utf-8") as f:
    js = f.read()

idx = js.find("/api/v1/playback/")
print(js[max(0, idx-400):idx+400])
