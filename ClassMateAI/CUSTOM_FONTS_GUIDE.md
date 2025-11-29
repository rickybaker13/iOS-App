# Custom Fonts Guide for ClassMate AI

## Overview
To make the app more unique and appealing to 12-21 year olds, we're using custom fonts instead of the standard iOS system font. The interactive onboarding uses "Quicksand" - a friendly, rounded font perfect for educational apps.

## Recommended Fonts

### Primary Font: Quicksand
- **Style**: Rounded, friendly, modern
- **Use**: Headings, Oso's speech, buttons
- **Download**: [Google Fonts - Quicksand](https://fonts.google.com/specimen/Quicksand)
- **Weights needed**: Regular (400), Medium (500), Bold (700)

### Alternative Options:
1. **Poppins** - Clean, geometric, professional yet friendly
2. **Nunito** - Rounded, playful, great for young audiences
3. **Comfortaa** - Very rounded, casual, fun
4. **Fredoka** - Bold, friendly, great for headings
5. **DM Sans** - Modern, clean, readable

## Installation Steps

### 1. Download Font Files
1. Go to [Google Fonts](https://fonts.google.com/)
2. Search for "Quicksand"
3. Click "Download family"
4. Extract the ZIP file
5. You'll need these files:
   - `Quicksand-Regular.ttf`
   - `Quicksand-Medium.ttf`
   - `Quicksand-Bold.ttf`

### 2. Add Fonts to Xcode Project
1. In Xcode, right-click on the `ClassMateAI` folder
2. Select "Add Files to ClassMateAI..."
3. Navigate to your downloaded font files
4. Select all three `.ttf` files
5. **Important**: Check "Copy items if needed"
6. **Important**: Check "ClassMateAI" under "Add to targets"
7. Click "Add"

### 3. Register Fonts in Info.plist
1. Open `Info.plist` in Xcode
2. Right-click in the file and select "Add Row"
3. Type "Fonts provided by application" (it will auto-complete to `UIAppFonts`)
4. Expand the array and add three items:
   - Item 0: `Quicksand-Regular.ttf`
   - Item 1: `Quicksand-Medium.ttf`
   - Item 2: `Quicksand-Bold.ttf`

### 4. Verify Font Names
Add this temporary code to verify font installation (in `ContentView.onAppear`):

```swift
.onAppear {
    // Print all available fonts (remove after verification)
    for family in UIFont.familyNames.sorted() {
        let names = UIFont.fontNames(forFamilyName: family)
        print("Family: \(family) Font names: \(names)")
    }
}
```

Look for "Quicksand" in the console output. The exact names might be:
- `Quicksand-Regular`
- `Quicksand-Medium`
- `Quicksand-Bold`

### 5. Create Font Extension (Recommended)
Create a new file `FontExtensions.swift`:

```swift
import SwiftUI

extension Font {
    // Quicksand fonts
    static func quicksandRegular(size: CGFloat) -> Font {
        return .custom("Quicksand-Regular", size: size)
    }
    
    static func quicksandMedium(size: CGFloat) -> Font {
        return .custom("Quicksand-Medium", size: size)
    }
    
    static func quicksandBold(size: CGFloat) -> Font {
        return .custom("Quicksand-Bold", size: size)
    }
    
    // Semantic font styles
    static var appTitle: Font {
        .quicksandBold(size: 28)
    }
    
    static var appHeadline: Font {
        .quicksandBold(size: 20)
    }
    
    static var appBody: Font {
        .quicksandRegular(size: 16)
    }
    
    static var appBodyMedium: Font {
        .quicksandMedium(size: 16)
    }
    
    static var appCaption: Font {
        .quicksandRegular(size: 14)
    }
    
    static var osoSpeech: Font {
        .quicksandMedium(size: 17)
    }
    
    static var osoTitle: Font {
        .quicksandBold(size: 22)
    }
}
```

### 6. Update InteractiveOnboardingView.swift
Replace the `.custom()` calls with fallbacks:

```swift
// Current (line ~165):
.font(.custom("Quicksand-Bold", size: 22))

// Replace with (if font isn't installed yet):
.font(.system(size: 22, weight: .bold, design: .rounded))

// Or use the extension (after creating FontExtensions.swift):
.font(.osoTitle)
```

## Applying Fonts Throughout the App

### Priority Areas:
1. **Onboarding** - Already implemented
2. **Navigation titles** - Main screens
3. **Buttons** - All CTAs
4. **Cards** - Subject cards, lecture cards
5. **Oso tips** - Any Oso speech bubbles

### Example Updates:

#### ContentView.swift
```swift
// Navigation title
.navigationTitle("ClassMate.ai")
.font(.appTitle) // Add this modifier

// Subject names
Text(subject.name)
    .font(.appHeadline)

// Lecture titles
Text(lecture.title)
    .font(.appBody)
```

#### Buttons
```swift
Button("Add Subject") {
    // action
}
.font(.appBodyMedium)
```

## Fallback Strategy

If custom fonts aren't loaded, use iOS system font with `.rounded` design:

```swift
extension Font {
    static func quicksandBold(size: CGFloat) -> Font {
        // Try custom font first
        if UIFont(name: "Quicksand-Bold", size: size) != nil {
            return .custom("Quicksand-Bold", size: size)
        }
        // Fallback to system rounded
        return .system(size: size, weight: .bold, design: .rounded)
    }
}
```

## Testing

### Checklist:
- [ ] Fonts appear in Xcode Project Navigator
- [ ] Info.plist has `UIAppFonts` array with all font files
- [ ] Console shows font family when printing `UIFont.familyNames`
- [ ] Onboarding displays custom font (not system font)
- [ ] Text is readable at all sizes
- [ ] Font looks good on different devices (SE, regular, Pro Max)

### Common Issues:

**Problem**: Fonts not loading
- **Solution**: Check Info.plist spelling exactly matches file names
- **Solution**: Verify "Copy items if needed" was checked
- **Solution**: Clean build folder (Cmd+Shift+K) and rebuild

**Problem**: Wrong font name in code
- **Solution**: Print `UIFont.familyNames` to see exact names
- **Solution**: Font name in code might differ from file name

**Problem**: Fonts look too bold/thin
- **Solution**: Try different weight (Regular vs Medium vs Bold)
- **Solution**: Adjust size slightly

## Color Pairing with Fonts

Custom fonts work best with your existing color scheme:

```swift
Text("Welcome!")
    .font(.osoTitle)
    .foregroundStyle(
        LinearGradient(
            colors: [.purple, .purple.opacity(0.7)],
            startPoint: .leading,
            endPoint: .trailing
        )
    )
```

## Performance Notes

- Custom fonts are loaded once at app launch
- No performance impact after initial load
- `.ttf` files are small (typically 50-200KB each)
- Total size impact: ~150-600KB for 3 font weights

## Future Enhancements

1. **Variable Fonts**: Use `.ttf` variable fonts for smoother weight transitions
2. **Icon Font**: Create custom icon font for unique app icons
3. **Animated Text**: Use custom fonts with text animations
4. **Localization**: Ensure fonts support international characters

---

**Quick Start**: Download Quicksand from Google Fonts, add to Xcode, update Info.plist, and you're done! The onboarding already uses the custom font names, so it will automatically look better once installed.

