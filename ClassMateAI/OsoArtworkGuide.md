# Oso Mascot Artwork Guide

## Overview
Oso is a friendly Saint Bernard mascot who guides students through ClassMate AI. Currently using emoji placeholders (🐕), but designed to be replaced with custom illustrations.

## Design Specifications

### Character Design
- **Breed**: Saint Bernard
- **Personality**: Friendly, helpful, encouraging, smart
- **Age**: Young adult dog (energetic but wise)
- **Color Palette**: 
  - Primary: Warm browns and whites (classic Saint Bernard coloring)
  - Accent: Bright collar with ClassMate AI logo tag
  - Background: Soft gradients matching mood colors

### Moods & Expressions
Create illustrations for each mood state:

1. **Happy** (Default)
   - Friendly smile, tongue out
   - Relaxed posture
   - Color accent: Blue

2. **Excited**
   - Wide eyes, big smile
   - Energetic pose, maybe one paw raised
   - Color accent: Orange

3. **Thinking**
   - Paw on chin, thoughtful expression
   - Slightly tilted head
   - Color accent: Purple

4. **Celebrating**
   - Party hat or confetti around
   - Jumping or dancing pose
   - Color accent: Pink

5. **Studying**
   - Wearing reading glasses
   - Book or notes nearby
   - Focused expression
   - Color accent: Green

6. **Sleeping**
   - Curled up, eyes closed
   - "Z" symbols floating
   - Color accent: Indigo

### Technical Requirements
- **Format**: PNG with transparency or SVG
- **Size**: 512x512px minimum (for scalability)
- **Style**: Flat design with subtle gradients
- **File naming**: `oso_[mood].png` (e.g., `oso_happy.png`)

### Onboarding Specific Illustrations
Two special illustrations needed:

1. **oso_welcome.png**
   - Full body, welcoming pose
   - Waving paw
   - Extra friendly expression
   - Size: 800x800px

2. **oso_ready.png**
   - Thumbs up or encouraging gesture
   - Backpack or school supplies nearby
   - Motivational expression
   - Size: 800x800px

## Implementation Steps

### 1. Add Assets to Xcode
1. Open `Assets.xcassets` in Xcode
2. Create new Image Set for each mood
3. Drag PNG files into 1x, 2x, 3x slots (or use vector for all)

### 2. Update OnboardingView.swift
Replace emoji placeholders:

```swift
// Current (line ~52):
if page.imageName.starts(with: "oso_") {
    Text("🐕")
        .font(.system(size: 120))
}

// Replace with:
if page.imageName.starts(with: "oso_") {
    Image(page.imageName)
        .resizable()
        .scaledToFit()
        .frame(width: 180, height: 180)
}
```

### 3. Update OsoMascotView.swift
Replace emoji with images:

```swift
// Current (line ~28):
Text(mood.emoji)
    .font(.system(size: size * 0.8))

// Replace with:
Image("oso_\(mood.imageName)")
    .resizable()
    .scaledToFit()
    .frame(width: size, height: size)
```

Add `imageName` property to `OsoMood` enum:
```swift
var imageName: String {
    switch self {
    case .happy: return "happy"
    case .excited: return "excited"
    // ... etc
    }
}
```

## Design Tips
- Keep Oso's design simple and recognizable at small sizes
- Use warm, inviting colors that appeal to 12-21 year olds
- Maintain consistency across all mood variations
- Consider adding small accessories (backpack, pencil, notebook) to reinforce the study theme
- Make sure expressions are clear and easy to read

## Recommended Tools
- **Vector**: Adobe Illustrator, Figma, Affinity Designer
- **Raster**: Procreate, Adobe Photoshop
- **Free options**: Inkscape, GIMP, Canva

## Color Palette Reference
```
Primary Browns:
- Dark Brown: #8B4513
- Medium Brown: #A0522D
- Light Brown: #D2691E

White/Cream:
- Pure White: #FFFFFF
- Cream: #FFF8DC

Accent Colors (from app):
- Blue: #007AFF
- Orange: #FF9500
- Purple: #AF52DE
- Pink: #FF2D55
- Green: #34C759
- Indigo: #5856D6
```

## Future Enhancements
- Animated Oso (Lottie files)
- Seasonal variations (winter scarf, summer sunglasses)
- Interactive Oso that responds to user actions
- Oso voice lines (text-to-speech)

