import json
import yt_dlp
from tqdm import tqdm

class TqdmLogger:
    def debug(self, msg):
        # подавляем избыточные "debug" сообщения
        pass

    def warning(self, msg):
        tqdm.write(f"⚠️  {msg}")

    def error(self, msg):
        tqdm.write(f"❌ {msg}")

    def info(self, msg):
        tqdm.write(f"ℹ️  {msg}")

with open("data.json", "r", encoding="utf-8") as f:
    data = json.load(f)

try:
    if "ItemFavoriteList" in data and isinstance(data["ItemFavoriteList"], list):
        for item in tqdm(data["ItemFavoriteList"], desc="Обработка", unit="элем."):
            if isinstance(item, dict):
                if "processed" in item and item.get("processed") == True:
                    continue

                date = item.get('date')
                link = item.get('link')
                
                tqdm.write(f"Обработка ссылки: {link}")
                
                ydl_opts = {
                    'outtmpl': f'storage/{date}_%(uploader)s_%(id)s.%(ext)s',
                    "logger": TqdmLogger(),  # 👈 направляем вывод сюда
                }

                with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                    try:
                        info = ydl.extract_info(link)

                        # Добавляем поле processed
                        item["uploader"] = info.get('uploader')
                        item["id"] = info.get('id')
                        item["title"] = info.get('title')
                        item["success"] = True
                        tqdm.write(f"✅ Успешно: {info.get('title')}")
                    except Exception as e:
                        item["error"] = str(e)
                        item["success"] = False

                item["processed"] = True

    else:
        print("Поле ItemFavoriteList отсутствует или имеет неверный формат.")
    
finally:
    with open("output.json", "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)