import os
import json
import argparse
import sys

def scan_directory(root_dir):
    files_data = []
    
    for root, dirs, files in os.walk(root_dir):
        # Modify dirs in-place to prevent os.walk from visiting .ts directories
        if '.ts' in dirs:
            dirs.remove('.ts')
            
        for file in files:
            full_path = os.path.join(root, file)
            relative_path = os.path.relpath(full_path, root_dir)
            
            try:
                size = os.path.getsize(full_path)
            except OSError:
                size = 0
                
            # Check for sidecar file in .ts directory
            ts_dir = os.path.join(root, '.ts')
            sidecar_path = os.path.join(ts_dir, f"{file}.json")
            tags = []
            
            if os.path.exists(sidecar_path):
                try:
                    with open(sidecar_path, 'r', encoding='utf-8-sig') as f:
                        data = json.load(f)
                        if "tags" in data and isinstance(data["tags"], list):
                            tags = [tag.get("title") for tag in data["tags"] if "title" in tag]
                except (json.JSONDecodeError, OSError) as e:
                    print(f"Error parsing sidecar file {sidecar_path}: {e}", file=sys.stderr)

            files_data.append({
                "path": relative_path,
                "name": file,
                "size": size / 1024 / 1024,
                "tags": tags
            })
            
    return files_data

def main():
    parser = argparse.ArgumentParser(description="Recursively scan directory and list files in JSON format.")
    parser.add_argument("directory", nargs="?", default=".", help="Directory to scan (default: current directory)")
    args = parser.parse_args()
    
    target_dir = os.path.abspath(args.directory)
    
    if not os.path.exists(target_dir):
        print(json.dumps({"error": "Directory not found"}, ensure_ascii=False))
        return

    result = scan_directory(target_dir)
    print(json.dumps(result, indent=4, ensure_ascii=False))

if __name__ == "__main__":
    main()
