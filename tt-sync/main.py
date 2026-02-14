import json
import os
import sys
from datetime import datetime
import argparse
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

# Parse command line arguments
parser = argparse.ArgumentParser(description="Process TikTok favorites")
parser.add_argument("--retry-failed", action="store_true", default=False, help="Retry processing items that previously failed (success=False)")
parser.add_argument("--retry-error-content", type=str, metavar="snippet", help="Only retry items where the error message contains this text")
parser.add_argument("--mode", choices=["merge", "download", "all"], default="all", help="Operation mode: merge (update from update.json), download (download videos), or all (both)")
args = parser.parse_args()

DATA_FILE = os.path.join("temp", "data.json")
OUTPUT_FILE = os.path.join("temp", "output.json")
UPDATE_FILE = os.path.join("temp", "update.json")

# Cookies file handling
SECRETS_DIR = "secrets"
COOKIES_FILES = ["www.tiktok.com_cookies.txt", "cookies.txt"]
COOKIES_PATH = None

if os.path.exists(SECRETS_DIR):
    for cookie_file in COOKIES_FILES:
        path = os.path.join(SECRETS_DIR, cookie_file)
        if os.path.exists(path):
            COOKIES_PATH = path
            break

if COOKIES_PATH:
    print(f"Using cookies from: {COOKIES_PATH}")
else:
    print("No cookies file found in secrets directory.")

def merge_update():
    if not os.path.exists(UPDATE_FILE):
        if args.mode == "merge":
            print(f"Error: Update file '{UPDATE_FILE}' not found.")
        return

    print(f"Merging data from '{UPDATE_FILE}'...")
    
    if not os.path.exists(DATA_FILE):
        print(f"Data file '{DATA_FILE}' not found, creating new one.")
        data = {"ItemFavoriteList": []}
    else:
        with open(DATA_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)

    with open(UPDATE_FILE, "r", encoding="utf-8") as f:
        update_data = json.load(f)
        
    # Finding items in update_data (handle TikTok export structure)
    new_items = []
    if "ItemFavoriteList" in update_data:
       new_items = update_data["ItemFavoriteList"]
    else:
        print("Could not find 'ItemFavoriteList' in update.json")
        return

    if "ItemFavoriteList" not in data:
        data["ItemFavoriteList"] = []

    existing_links = {item.get("link") for item in data["ItemFavoriteList"] if item.get("link")}
    
    added_count = 0
    for item in new_items:
        # Handle key capitalization (Link -> link, Date -> date)
        link = item.get("Link") or item.get("link")
        date = item.get("Date") or item.get("date")
        
        if link and link not in existing_links:
            new_entry = {
                "link": link,
                "date": date
            }
            data["ItemFavoriteList"].append(new_entry)
            existing_links.add(link)
            added_count += 1
            
    if added_count > 0:
        with open(DATA_FILE, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        print(f"✅ Successfully added {added_count} new items to data.json.")
    else:
        print("No new items found to merge.")

# Execute merge if needed
if args.mode in ["merge", "all"]:
    merge_update()

if args.mode == "merge":
    print("Merge mode complete.")
    sys.exit(0)

if not os.path.exists(DATA_FILE):
    print(f"Error: File '{DATA_FILE}' not found.")
    sys.exit(1)

with open(DATA_FILE, "r", encoding="utf-8") as f:
    data = json.load(f)

try:
    # Statistics
    stats_total = 0
    stats_ignored = 0
    stats_success = 0
    stats_error = 0

    if "ItemFavoriteList" in data and isinstance(data["ItemFavoriteList"], list):
        for item in tqdm(data["ItemFavoriteList"], desc="Processing", unit="elem."):
            if isinstance(item, dict):
                stats_total += 1

                if item.get("processed") == True:
                    if not args.retry_failed or item.get("success") == True:
                        stats_ignored += 1
                        continue

                    if args.retry_error_content:
                        # If retry_error_content is specified, check if it's in the error message
                        error_msg = item.get("error", "")
                        if not args.retry_error_content in error_msg:
                            # print(f"Error: '{error_msg}' Part: '{args.retry_error_content}'.")
                            stats_ignored += 1
                            continue

                date = item.get('date')
                link = item.get('link')
                
                tqdm.write(f"Processing link: {link}")
                
                ydl_opts = {
                    'outtmpl': f'storage/{date}_%(uploader)s_%(id)s.%(ext)s',
                    "logger": TqdmLogger(),  # 👈 redirect output here
                }
                
                if COOKIES_PATH:
                    ydl_opts["cookiefile"] = COOKIES_PATH

                with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                    try:
                        info = ydl.extract_info(link)

                        # Add processed field
                        item["uploader"] = info.get('uploader')
                        item["id"] = info.get('id')
                        item["title"] = info.get('title')
                        item["success"] = True
                        stats_success += 1
                        tqdm.write(f"✅ Success: {info.get('title')}")
                    except Exception as e:
                        item["error"] = str(e)
                        item["success"] = False
                        stats_error += 1

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

print(f"\nStatistics:")
print(f"Total:   {stats_total}")
print(f"Ignored: {stats_ignored}")
print(f"Success: {stats_success}")
print(f"Errors:  {stats_error}")