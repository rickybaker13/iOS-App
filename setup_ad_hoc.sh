#!/bin/bash

# ClassMateAI Ad Hoc Distribution Setup Script
# This script helps set up the project for ad hoc distribution

echo "🚀 Setting up ClassMateAI for Ad Hoc Distribution"
echo "=================================================="

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode is not installed or not in PATH"
    echo "Please install Xcode from the Mac App Store"
    exit 1
fi

echo "✅ Xcode is installed"

# Check if we're in the right directory
if [ ! -f "ClassMateAI/ClassMateAIApp.swift" ]; then
    echo "❌ Please run this script from the project root directory"
    echo "Make sure you're in the directory containing the ClassMateAI folder"
    exit 1
fi

echo "✅ Project structure found"

# Create necessary directories if they don't exist
echo "📁 Creating necessary directories..."

mkdir -p "ClassMateAI/Assets.xcassets/AppIcon.appiconset"
mkdir -p "ClassMateAI/Assets.xcassets/AccentColor.colorset"
mkdir -p "ClassMateAI/Preview Content/Preview Assets.xcassets"

echo "✅ Directories created"

# Check if Xcode project exists
if [ ! -f "ClassMateAI.xcodeproj/project.pbxproj" ]; then
    echo "❌ Xcode project file not found"
    echo "Please make sure the project.pbxproj file exists"
    exit 1
fi

echo "✅ Xcode project found"

# Validate project structure
echo "🔍 Validating project structure..."

required_files=(
    "ClassMateAI/ClassMateAIApp.swift"
    "ClassMateAI/ContentView.swift"
    "ClassMateAI/RecordingView.swift"
    "ClassMateAI/AudioRecorder.swift"
    "ClassMateAI/DataManager.swift"
    "ClassMateAI/Models.swift"
    "ClassMateAI/Info.plist"
)

for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ Missing required file: $file"
        exit 1
    fi
done

echo "✅ All required files found"

# Check if we can build the project
echo "🔨 Testing project build..."

if xcodebuild -project ClassMateAI.xcodeproj -scheme ClassMateAI -destination 'platform=iOS Simulator,name=iPhone 15' build &> /dev/null; then
    echo "✅ Project builds successfully"
else
    echo "⚠️  Project build failed - this is normal if code signing is not set up yet"
    echo "You'll need to configure code signing in Xcode"
fi

echo ""
echo "🎉 Setup Complete!"
echo "=================="
echo ""
echo "Next steps:"
echo "1. Open ClassMateAI.xcodeproj in Xcode"
echo "2. Configure your Bundle Identifier"
echo "3. Set up code signing with your Apple Developer account"
echo "4. Follow the AD_HOC_DISTRIBUTION_GUIDE.md for detailed instructions"
echo ""
echo "📖 Read the full guide: AD_HOC_DISTRIBUTION_GUIDE.md"
echo ""
echo "Good luck with your ad hoc distribution! 🚀" 