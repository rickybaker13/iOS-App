# Instructions to Fix Xcode Project on MacBook Air

If you're still getting "[PBXFileReferencebuildPhase]" errors after pulling the latest changes, try these steps:

## Option 1: Clean Xcode Caches (Try This First)

```bash
cd ~/Documents/iOS-App

# Clean Xcode derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Clean project user data
rm -rf ClassMateAI/ClassMateAI.xcodeproj/project.xcworkspace/xcuserdata
rm -rf ClassMateAI/ClassMateAI.xcodeproj/xcuserdata

# Clean build folder if it exists
rm -rf ClassMateAI/build
```

Then try opening the project again.

## Option 2: Verify You Have Latest Code

```bash
cd ~/Documents/iOS-App
git pull origin main
git log --oneline -1
# Should show: d3b6910 Fix build phase UUID conflicts...
```

## Option 3: Create New Project and Import Files

If the above doesn't work, create a fresh Xcode project:

1. Open Xcode
2. File → New → Project
3. Choose "iOS" → "App"
4. Name it "ClassMateAI"
5. Choose a location (different from your current project)
6. Once created, close Xcode
7. Copy all `.swift` files from your current project to the new one
8. Add files to the new project in Xcode (right-click → Add Files)

## Option 4: Check Xcode Version

Make sure you're using a compatible Xcode version:
- Xcode 15.0 or later recommended
- Check: Xcode → About Xcode

## If Still Having Issues

Share:
1. Your Xcode version
2. The exact error message
3. Output of: `plutil -lint ClassMateAI/ClassMateAI.xcodeproj/project.pbxproj`

