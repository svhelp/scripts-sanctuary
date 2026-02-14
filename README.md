# Scripts Sanctuary

This repository contains a collection of utility scripts for various tasks.

## 📂 contact-list (Deprecated)

⚠️ **Note:** The scripts in this directory are deprecated due to performance issues. A new, optimized implementation is available here: [ImgWarehouse](https://github.com/svhelp/ImgWarehouse).

---

## 📂 tag-spaces-stats

A Python script to generate a JSON report of files in a directory, including their size and tags extracted from TagSpaces sidecar files.

### Features
- Recursively scans a directory.
- Lists files with their relative path, name, and size (in MB).
- Ignores `.ts` directories during the scan.
- Reads TagSpaces tags from sidecar JSON files (located in `.ts` subdirectories).
- Outputs the result as a formatted JSON.

### Usage

```bash
cd tag-spaces-stats
python main.py [directory_path]
```

- `directory_path`: (Optional) The root directory to scan. Defaults to the current directory (`.`).

### Output Format

```json
[
    {
        "path": "relative/path/to/file.ext",
        "name": "file.ext",
        "size": 1.5,
        "tags": ["Tag1", "Tag2"]
    }
]
```

---

## 📂 tt-sync

A tool to sync and download TikTok favorites using `yt-dlp`.

### Setup
1.  Place your TikTok data export (or list of favorites) in `temp/update.json`.
2.  (Optional) Place your `cookies.txt` or `www.tiktok.com_cookies.txt` in the `secrets/` directory to enable downloading of age-restricted or private videos.

### Usage

```bash
cd tt-sync
python main.py [options]
```

### Options

- `--mode {merge,download,all}`:
    - `merge`: Only merges new links from `temp/update.json` into the main database (`temp/data.json`).
    - `download`: Only downloads videos for unprocessed items in `temp/data.json`.
    - `all`: (Default) Merges new items and then starts downloading.
- `--retry-failed`: Retry processing items that were previously marked as failed.
- `--retry-error-content "text"`: Only retry items where the previous error message contained the specified text.

### Workflow
1.  **Merge**: Reads `temp/update.json` and adds new unique links to `temp/data.json`.
2.  **Download**: Iterates through `temp/data.json`. verified downloads are saved to `storage/` using the format `date_uploader_id.ext`.
3.  **Update**: Updates `temp/data.json` with success/failure status and downloaded video metadata. Backups are created in `temp/`.

