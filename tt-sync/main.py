import json
import os
import sys
from datetime import datetime
import yt_dlp
from tqdm import tqdm

class TqdmLogger:
    def debug(self, msg):
        # suppress redundant "debug" messages
        pass

    def warning(self, msg):
        tqdm.write(f"⚠️  {msg}")

    def error(self, msg):
        tqdm.write(f"❌ {msg}")

    def info(self, msg):
        tqdm.write(f"ℹ️  {msg}")

DATA_FILE = os.path.join("temp", "data.json")
OUTPUT_FILE = os.path.join("temp", "output.json")

if not os.path.exists(DATA_FILE):
    print(f"Error: File '{DATA_FILE}' not found.")
    sys.exit(1)

with open(DATA_FILE, "r", encoding="utf-8") as f:
    data = json.load(f)

try:
    if "ItemFavoriteList" in data and isinstance(data["ItemFavoriteList"], list):
        for item in tqdm(data["ItemFavoriteList"], desc="Processing", unit="elem."):
            if isinstance(item, dict):
                if "processed" in item and item.get("processed") == True:
                    continue

                date = item.get('date')
                link = item.get('link')
                
                tqdm.write(f"Processing link: {link}")
                
                ydl_opts = {
                    'outtmpl': f'storage/{date}_%(uploader)s_%(id)s.%(ext)s',
                    "logger": TqdmLogger(),  # 👈 redirect output here
                }

                with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                    try:
                        info = ydl.extract_info(link)

                        # Add processed field
                        item["uploader"] = info.get('uploader')
                        item["id"] = info.get('id')
                        item["title"] = info.get('title')
                        item["success"] = True
                        tqdm.write(f"✅ Success: {info.get('title')}")
                    except Exception as e:
                        item["error"] = str(e)
                        item["success"] = False

                item["processed"] = True

    else:
        print("ItemFavoriteList field is missing or has invalid format.")
    
finally:
    if not os.path.exists("temp"):
        os.makedirs("temp")
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

# Rename files upon successful completion
timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
backup_name = f"data[{timestamp}].json"
backup_path = os.path.join("temp", backup_name)
try:
    # Check that output file exists before changing anything
    if os.path.exists(OUTPUT_FILE):
        if os.path.exists(DATA_FILE):
            os.rename(DATA_FILE, backup_path)
        
        os.rename(OUTPUT_FILE, DATA_FILE)
        print(f"✅ Files successfully updated:\n   data.json -> {backup_name}\n   output.json -> data.json")
except OSError as e:
    print(f"❌ Error renaming files: {e}")