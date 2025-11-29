#!/bin/bash

# Directory where AppIcon.appiconset is located
ICON_DIR="ClassMateAI/Assets.xcassets/AppIcon.appiconset"
SOURCE_ICON="$ICON_DIR/AppIcon.png"

if [ ! -f "$SOURCE_ICON" ]; then
    echo "Error: AppIcon.png not found at $SOURCE_ICON"
    exit 1
fi

echo "Generating icons from $SOURCE_ICON..."

# Function to resize
# usage: resize "OutputFilename" WidthHeight
resize() {
    echo "Resizing to $2x$2: $1"
    sips -z $2 $2 "$SOURCE_ICON" --out "$ICON_DIR/$1" > /dev/null
}

# iPhone
resize "Icon-20@2x.png" 40
resize "Icon-20@3x.png" 60
resize "Icon-29@2x.png" 58
resize "Icon-29@3x.png" 87
resize "Icon-40@2x.png" 80
resize "Icon-40@3x.png" 120
resize "Icon-60@2x.png" 120
resize "Icon-60@3x.png" 180

# iPad
resize "Icon-20.png" 20
# Icon-20@2x.png already generated (40)
resize "Icon-29.png" 29
# Icon-29@2x.png already generated (58)
resize "Icon-40.png" 40
# Icon-40@2x.png already generated (80)
resize "Icon-76.png" 76
resize "Icon-76@2x.png" 152
resize "Icon-83.5@2x.png" 167

echo "Done! All icons generated."

