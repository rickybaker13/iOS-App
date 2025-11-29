#!/usr/bin/env python3
"""
Simple app icon generator for ClassMateAI
Creates a basic icon with the app name for testing purposes
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_icon(size, filename):
    """Create a simple icon with the given size"""
    # Create a new image with a blue background
    img = Image.new('RGB', (size, size), color='#007AFF')
    draw = ImageDraw.Draw(img)
    
    # Try to use a system font, fallback to default if not available
    try:
        # Try to use a system font
        font_size = max(size // 8, 12)
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", font_size)
    except:
        try:
            font = ImageFont.truetype("arial.ttf", font_size)
        except:
            font = ImageFont.load_default()
    
    # Add text
    text = "NoteApp"
    text_bbox = draw.textbbox((0, 0), text, font=font)
    text_width = text_bbox[2] - text_bbox[0]
    text_height = text_bbox[3] - text_bbox[1]
    
    x = (size - text_width) // 2
    y = (size - text_height) // 2
    
    # Draw white text
    draw.text((x, y), text, fill='white', font=font)
    
    # Save the image
    img.save(filename, 'PNG')
    print(f"Created {filename}")

def main():
    """Create all required icon sizes"""
    icon_dir = "ClassMateAI/Assets.xcassets/AppIcon.appiconset"
    
    # Create directory if it doesn't exist
    os.makedirs(icon_dir, exist_ok=True)
    
    # Define required icon sizes
    icons = [
        (40, "Icon-20@2x.png"),      # iPhone 20pt @2x
        (60, "Icon-20@3x.png"),      # iPhone 20pt @3x
        (58, "Icon-29@2x.png"),      # iPhone 29pt @2x
        (87, "Icon-29@3x.png"),      # iPhone 29pt @3x
        (80, "Icon-40@2x.png"),      # iPhone 40pt @2x
        (120, "Icon-40@3x.png"),     # iPhone 40pt @3x
        (120, "Icon-60@2x.png"),     # iPhone 60pt @2x
        (180, "Icon-60@3x.png"),     # iPhone 60pt @3x
        (20, "Icon-20.png"),         # iPad 20pt @1x
        (40, "Icon-20@2x.png"),      # iPad 20pt @2x (reuse)
        (29, "Icon-29.png"),         # iPad 29pt @1x
        (58, "Icon-29@2x.png"),      # iPad 29pt @2x (reuse)
        (40, "Icon-40.png"),         # iPad 40pt @1x
        (80, "Icon-40@2x.png"),      # iPad 40pt @2x (reuse)
        (152, "Icon-76@2x.png"),     # iPad 76pt @2x
        (167, "Icon-83.5@2x.png"),   # iPad 83.5pt @2x
        (1024, "Icon-1024.png"),     # App Store
    ]
    
    # Create each icon
    for size, filename in icons:
        filepath = os.path.join(icon_dir, filename)
        create_icon(size, filepath)
    
    print("All app icons created successfully!")
    print("You can now archive and upload your app to TestFlight.")

if __name__ == "__main__":
    main() 