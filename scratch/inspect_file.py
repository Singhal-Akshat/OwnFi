import os

file_path = r"C:\Users\Akshat Singhal\.gemini\antigravity-ide\brain\8c12d4bd-7d6e-4b50-a1d2-7af495a48c5e\uploaded_media_1780689910600.img"
if os.path.exists(file_path):
    with open(file_path, "rb") as f:
        header = f.read(64)
        print("Header:", header)
        print("Length:", os.path.getsize(file_path))
else:
    print("File not found")
