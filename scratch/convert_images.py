import os
import sys

# Ensure dependencies are installed
try:
    from PIL import Image
    import pillow_heif
    pillow_heif.register_heif_opener()
except ImportError:
    import subprocess
    print("Installing required dependencies (pillow, pillow-heif)...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "pillow", "pillow-heif"])
    from PIL import Image
    import pillow_heif
    pillow_heif.register_heif_opener()

assets_dir = r"e:\Projects\Money_Tracker\assets\credit_card_images"
output_dir = assets_dir

avif_files = [f for f in os.listdir(assets_dir) if f.endswith(".avif")]

for file in avif_files:
    avif_path = os.path.join(assets_dir, file)
    webp_name = file.rsplit(".", 1)[0] + ".webp"
    webp_path = os.path.join(output_dir, webp_name)
    
    print(f"Converting {file} to {webp_name}...")
    try:
        img = Image.open(avif_path)
        
        # Resize to max 600px width while preserving aspect ratio
        max_width = 600
        if img.width > max_width:
            w_percent = (max_width / float(img.width))
            h_size = int((float(img.height) * float(w_percent)))
            img = img.resize((max_width, h_size), Image.Resampling.LANCZOS)
            print(f"  Resized from {img.width}x{img.height} to {max_width}x{h_size}")
            
        img.save(webp_path, "WEBP", quality=85)
        print(f"  Saved to {webp_path}")
    except Exception as e:
        print(f"  Error converting {file}: {e}")

print("Image conversion completed successfully.")
