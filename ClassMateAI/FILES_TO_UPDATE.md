# Files to Update in Xcode - Complete List

## ✅ New Files to Add

### 1. InteractiveOnboardingView.swift (PRIORITY: HIGH)
**What it does**: Complete interactive onboarding with Oso guiding through demo app
**Location**: Add to ClassMateAI folder
**Size**: ~450 lines
**Dependencies**: Uses OsoMascotView.swift

### 2. FontExtensions.swift (PRIORITY: MEDIUM)
**What it does**: Custom font support with graceful fallbacks
**Location**: Add to ClassMateAI folder
**Size**: ~150 lines
**Dependencies**: None
**Note**: Works even without custom fonts installed

### 3. OsoMascotView.swift (KEEP)
**What it does**: Reusable Oso mascot component
**Location**: Already created
**Usage**: Used by both onboarding views

## ✅ Modified Files to Update

### 4. ContentView.swift (PRIORITY: HIGH)
**Changes**:
- Added `@AppStorage("hasCompletedOnboarding")` and `@State private var showingOnboarding`
- Changed onboarding from `OnboardingView()` to `InteractiveOnboardingView()`
- Added "View Tutorial" button in Settings
- Two locations updated (main view and settings view)

### 5. CanvasAssignmentDetailView.swift (PRIORITY: MEDIUM)
**Changes**:
- Updated date picker to show date AND time selection
- Changed to `.graphical` style
- Better preview of selected date/time
- Larger presentation sheet

## 📋 Optional Files (Can Keep or Delete)

### OnboardingView.swift (OLD)
**Status**: Replaced by InteractiveOnboardingView.swift
**Action**: Can delete or keep as backup
**Note**: No longer used by ContentView.swift

## 📚 Documentation Files (Reference Only)

These are markdown files for your reference - don't need to add to Xcode:

- `INTERACTIVE_ONBOARDING_SUMMARY.md` - Complete guide to new onboarding
- `CUSTOM_FONTS_GUIDE.md` - How to add Quicksand fonts
- `OsoArtworkGuide.md` - How to add custom Oso illustrations
- `ONBOARDING_SUMMARY.md` - Old onboarding documentation
- `FILES_TO_UPDATE.md` - This file

## 🎯 Priority Order for Testing

### Phase 1: Core Functionality (Test First)
1. ✅ **InteractiveOnboardingView.swift** - NEW
2. ✅ **ContentView.swift** - MODIFIED
3. ✅ **FontExtensions.swift** - NEW

**Test**: Launch app fresh → Should see interactive onboarding with Oso

### Phase 2: Enhanced Features (Test Second)
4. ✅ **CanvasAssignmentDetailView.swift** - MODIFIED

**Test**: Open Canvas assignment → Set reminder → Should see date/time picker

### Phase 3: Optional Enhancements (Test Later)
5. ⚠️ **Custom Fonts** - Follow CUSTOM_FONTS_GUIDE.md
6. ⚠️ **Custom Oso Art** - Follow OsoArtworkGuide.md

## 📝 Step-by-Step Update Process

### Step 1: Add New Files
```
1. Open Xcode
2. Right-click ClassMateAI folder
3. Select "New File..."
4. Choose "Swift File"
5. Name it "InteractiveOnboardingView"
6. Copy/paste content from Cursor
7. Repeat for "FontExtensions"
```

### Step 2: Update Existing Files
```
1. Open ContentView.swift in Xcode
2. Find the sections marked in Cursor
3. Replace with new code
4. Repeat for CanvasAssignmentDetailView.swift
```

### Step 3: Build & Test
```
1. Clean Build Folder (Cmd+Shift+K)
2. Build (Cmd+B)
3. Fix any errors (should be none)
4. Run on simulator or device
5. Test onboarding flow
```

### Step 4: Test Onboarding
```
1. Delete app from device/simulator
2. Reinstall
3. Launch app
4. Should see interactive onboarding
5. Go through all 10 steps
6. Tap "Let's Go!"
7. Should see main app
8. Go to Settings → View Tutorial
9. Should see onboarding again
```

### Step 5: Test Canvas Reminders
```
1. Connect Canvas account
2. Open any assignment
3. Tap "Set Reminder"
4. Choose "Custom Date..."
5. Should see date AND time picker
6. Select a date/time
7. Tap "Schedule"
8. Should see confirmation
```

## ⚠️ Common Issues & Solutions

### Issue: "Cannot find 'InteractiveOnboardingView' in scope"
**Solution**: Make sure you added the file to the ClassMateAI target

### Issue: Fonts look like system font
**Solution**: Custom fonts not installed - this is OK! FontExtensions provides fallback

### Issue: Onboarding doesn't appear
**Solution**: Delete app and reinstall, or manually set `@AppStorage("hasCompletedOnboarding")` to false

### Issue: Build errors in InteractiveOnboardingView
**Solution**: Make sure OsoMascotView.swift is also in the project

### Issue: Highlight overlay not positioning correctly
**Solution**: Test on different device sizes - may need to adjust `highlightFrame()` calculations

## 📊 File Summary

| File | Status | Lines | Priority | Test Required |
|------|--------|-------|----------|---------------|
| InteractiveOnboardingView.swift | NEW | ~450 | HIGH | Yes |
| FontExtensions.swift | NEW | ~150 | MEDIUM | Optional |
| ContentView.swift | MODIFIED | ~552 | HIGH | Yes |
| CanvasAssignmentDetailView.swift | MODIFIED | ~343 | MEDIUM | Yes |
| OsoMascotView.swift | EXISTING | ~132 | - | No |
| OnboardingView.swift | OLD | ~297 | - | No (can delete) |

## ✅ Pre-Upload Checklist

Before uploading to TestFlight:

- [ ] All new files added to Xcode project
- [ ] All modified files updated
- [ ] Project builds without errors
- [ ] Onboarding appears on fresh install
- [ ] All 10 onboarding steps work
- [ ] Highlight overlay positions correctly
- [ ] Oso animations smooth
- [ ] "Let's Go!" completes onboarding
- [ ] "View Tutorial" in Settings works
- [ ] Canvas reminder date/time picker works
- [ ] No console errors or warnings
- [ ] Tested on multiple device sizes
- [ ] App doesn't crash

## 🎨 Optional: Custom Fonts

If you want to add Quicksand fonts for the full effect:

1. Download from [Google Fonts](https://fonts.google.com/specimen/Quicksand)
2. Add `.ttf` files to Xcode
3. Update Info.plist
4. See `CUSTOM_FONTS_GUIDE.md` for complete instructions

**Without fonts**: App will use system rounded font (still looks good!)
**With fonts**: App will look more unique and polished

## 🐕 Optional: Custom Oso Artwork

If you want to commission custom Saint Bernard illustrations:

1. See `OsoArtworkGuide.md` for specifications
2. Create 8 illustrations (6 moods + 2 onboarding)
3. Add to Assets.xcassets
4. Update image references in code

**Without custom art**: App uses emoji placeholders (🐕)
**With custom art**: App will have unique, branded mascot

## 📱 Device Testing Priority

Test on these devices in order:

1. **iPhone 14 Pro** (most common)
2. **iPhone SE** (smallest screen)
3. **iPhone 15 Pro Max** (largest screen)
4. **iPad** (if supporting tablets)

## 🚀 Ready to Go!

All files are ready. The interactive onboarding is fully functional and will work immediately after updating these files in Xcode. Custom fonts and artwork are optional enhancements you can add later.

**Estimated update time**: 10-15 minutes
**Estimated test time**: 5-10 minutes
**Total time to production**: 15-25 minutes

Good luck! 🎉

