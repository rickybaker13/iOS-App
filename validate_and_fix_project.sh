#!/bin/bash

# Script to validate and potentially fix Xcode project file on macOS
# Run this on your MacBook Air

echo "🔍 Validating Xcode Project File..."
echo "===================================="

cd "$(dirname "$0")"

PROJECT_FILE="ClassMateAI/ClassMateAI.xcodeproj/project.pbxproj"

if [ ! -f "$PROJECT_FILE" ]; then
    echo "❌ Error: project.pbxproj not found"
    exit 1
fi

# Validate with plutil
echo "📋 Validating project file format..."
if plutil -lint "$PROJECT_FILE" 2>&1; then
    echo "✅ Project file format is valid"
else
    echo "❌ Project file format has errors"
    echo "Attempting to convert to XML and back to fix..."
    plutil -convert xml1 "$PROJECT_FILE" -o "${PROJECT_FILE}.xml"
    plutil -convert binary1 "${PROJECT_FILE}.xml" -o "$PROJECT_FILE"
    rm -f "${PROJECT_FILE}.xml"
    echo "✅ Converted project file format"
fi

# Check for common issues
echo ""
echo "🔍 Checking for common issues..."

# Check for duplicate UUIDs
echo "Checking for duplicate UUIDs..."
DUPLICATES=$(grep -oE '1A2B3C4D5E6F[0-9A-F]{4}' "$PROJECT_FILE" | sort | uniq -d)
if [ -z "$DUPLICATES" ]; then
    echo "✅ No duplicate UUIDs found"
else
    echo "⚠️  Warning: Found duplicate UUIDs:"
    echo "$DUPLICATES"
fi

# Check for missing closing braces
OPEN_BRACES=$(grep -o '{' "$PROJECT_FILE" | wc -l | tr -d ' ')
CLOSE_BRACES=$(grep -o '}' "$PROJECT_FILE" | wc -l | tr -d ' ')
if [ "$OPEN_BRACES" = "$CLOSE_BRACES" ]; then
    echo "✅ Braces are balanced ($OPEN_BRACES open, $CLOSE_BRACES close)"
else
    echo "❌ Unbalanced braces: $OPEN_BRACES open, $CLOSE_BRACES close"
fi

# Clean Xcode caches
echo ""
echo "🧹 Cleaning Xcode caches..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ClassMateAI/ClassMateAI.xcodeproj/project.xcworkspace/xcuserdata 2>/dev/null
rm -rf ClassMateAI/ClassMateAI.xcodeproj/xcuserdata 2>/dev/null
echo "✅ Caches cleaned"

echo ""
echo "📝 Next steps:"
echo "1. Try opening the project: open ClassMateAI/ClassMateAI.xcodeproj"
echo "2. If it still fails, try creating a new project and importing files"
echo "3. Check Xcode Console for detailed error messages"

