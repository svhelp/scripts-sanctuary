import json
import os
import re
from collections import Counter

data_file = os.path.join("temp", "data.json")

if not os.path.exists(data_file):
    print(f"File {data_file} not found.")
    exit(1)

with open(data_file, "r", encoding="utf-8") as f:
    data = json.load(f)

def normalize_error(msg):
    # Strip ANSI escape codes
    msg = re.sub(r'\x1b\[[0-9;]*m', '', msg)
    # Strip yt-dlp prefix: "ERROR: [Extractor] <video_id>: " -> "ERROR: [Extractor] "
    msg = re.sub(r'(\[[\w:]+\])\s+\d+:\s+', r'\1 ', msg)
    return msg.strip()

errors = []
if "ItemFavoriteList" in data and isinstance(data["ItemFavoriteList"], list):
    for item in data["ItemFavoriteList"]:
        if item.get("success") == False and "error" in item:
            errors.append(normalize_error(item["error"]))

if not errors:
    print("No errors found.")
else:
    counter = Counter(errors)
    print(f"Found {len(errors)} errors:")
    for error, count in counter.most_common():
        print(f"{count}: {error}")
