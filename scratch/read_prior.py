import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

with open(r'transcript_full.jsonl', 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()
    for idx in range(max(0, 4720), min(4735, len(lines))):
        d = json.loads(lines[idx])
        s_idx = d.get("step_index")
        src = d.get("source")
        print(f"=== Line {idx} (Step {s_idx}, Source: {src}) ===")
        cnt = d.get('content')
        if cnt:
            print(cnt[:800])
        else:
            print("[No content or tool call]")
