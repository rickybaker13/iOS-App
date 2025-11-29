#!/bin/bash

# Script to fix Xcode project file issues
# Run this on your MacBook Air

echo "🔧 Fixing Xcode Project File..."
echo "================================"

cd "$(dirname "$0")"

# Check if we're in the right directory
if [ ! -f "ClassMateAI/ClassMateAI.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: project.pbxproj not found"
    echo "Please run this script from the project root directory"
    exit 1
fi

PROJECT_FILE="ClassMateAI/ClassMateAI.xcodeproj/project.pbxproj"

# Backup the project file
echo "📦 Creating backup..."
cp "$PROJECT_FILE" "${PROJECT_FILE}.backup"

# Check for common issues
echo "🔍 Checking for issues..."

# Check if file exists and is readable
if [ ! -r "$PROJECT_FILE" ]; then
    echo "❌ Error: Cannot read project file"
    exit 1
fi

# Check for merge conflict markers
if grep -q "^<<<<<<< " "$PROJECT_FILE" || grep -q "^=======" "$PROJECT_FILE" || grep -q "^>>>>>>> " "$PROJECT_FILE"; then
    echo "⚠️  Warning: Found merge conflict markers in project file"
    echo "Please resolve conflicts manually"
    exit 1
fi

# Validate basic structure
if ! grep -q "^}" "$PROJECT_FILE"; then
    echo "❌ Error: Project file appears to be missing closing brace"
    exit 1
fi

# Check for balanced braces (basic check)
OPEN_BRACES=$(grep -o '{' "$PROJECT_FILE" | wc -l | tr -d ' ')
CLOSE_BRACES=$(grep -o '}' "$PROJECT_FILE" | wc -l | tr -d ' ')

if [ "$OPEN_BRACES" != "$CLOSE_BRACES" ]; then
    echo "⚠️  Warning: Unbalanced braces detected"
    echo "Open braces: $OPEN_BRACES, Close braces: $CLOSE_BRACES"
fi

# Clean up Xcode caches
echo "🧹 Cleaning Xcode caches..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ClassMateAI/ClassMateAI.xcodeproj/project.xcworkspace/xcuserdata 2>/dev/null
rm -rf ClassMateAI/ClassMateAI.xcodeproj/xcuserdata 2>/dev/null

echo "✅ Cleanup complete"
echo ""
echo "📝 Next steps:"
echo "1. Try opening the project in Xcode:"
echo "   open ClassMateAI/ClassMateAI.xcodeproj"
echo ""
echo "2. If it still fails, try:"
echo "   - File > Open in Xcode (instead of double-clicking)"
echo "   - Check Console.app for detailed error messages"
echo ""
echo "3. If you see specific errors, share them and we can fix them"

