import SwiftUI
import UIKit

// MARK: - Custom Font Extension
// This provides a graceful fallback to system rounded fonts if custom fonts aren't installed

extension Font {
    // MARK: - Quicksand Fonts (with fallback)
    
    static func quicksandRegular(size: CGFloat) -> Font {
        if UIFont(name: "Quicksand-Regular", size: size) != nil {
            return .custom("Quicksand-Regular", size: size)
        }
        return .system(size: size, weight: .regular, design: .rounded)
    }
    
    static func quicksandMedium(size: CGFloat) -> Font {
        if UIFont(name: "Quicksand-Medium", size: size) != nil {
            return .custom("Quicksand-Medium", size: size)
        }
        return .system(size: size, weight: .medium, design: .rounded)
    }
    
    static func quicksandBold(size: CGFloat) -> Font {
        if UIFont(name: "Quicksand-Bold", size: size) != nil {
            return .custom("Quicksand-Bold", size: size)
        }
        return .system(size: size, weight: .bold, design: .rounded)
    }
    
    // MARK: - Semantic Font Styles
    // Use these throughout the app for consistency
    
    /// Large titles (28pt, bold)
    static var appTitle: Font {
        .quicksandBold(size: 28)
    }
    
    /// Section headlines (20pt, bold)
    static var appHeadline: Font {
        .quicksandBold(size: 20)
    }
    
    /// Subheadlines (18pt, medium)
    static var appSubheadline: Font {
        .quicksandMedium(size: 18)
    }
    
    /// Body text (16pt, regular)
    static var appBody: Font {
        .quicksandRegular(size: 16)
    }
    
    /// Emphasized body text (16pt, medium)
    static var appBodyMedium: Font {
        .quicksandMedium(size: 16)
    }
    
    /// Small text (14pt, regular)
    static var appCaption: Font {
        .quicksandRegular(size: 14)
    }
    
    /// Button text (17pt, bold)
    static var appButton: Font {
        .quicksandBold(size: 17)
    }
    
    // MARK: - Onboarding Styles
    
    /// Onboarding body text (17pt, medium)
    static var onboardingBody: Font {
        .quicksandMedium(size: 17)
    }
    
    /// Onboarding titles (22pt, bold)
    static var onboardingTitle: Font {
        .quicksandBold(size: 22)
    }
    
    /// Onboarding caption/tips (15pt, medium)
    static var onboardingCaption: Font {
        .quicksandMedium(size: 15)
    }
}

// MARK: - Font Utilities

extension Font {
    /// Check if custom fonts are installed
    static var hasCustomFonts: Bool {
        UIFont(name: "Quicksand-Regular", size: 12) != nil
    }
    
    /// Print all available fonts (for debugging)
    static func printAvailableFonts() {
        print("=== Available Font Families ===")
        for family in UIFont.familyNames.sorted() {
            print("\nFamily: \(family)")
            let names = UIFont.fontNames(forFamilyName: family)
            for name in names {
                print("  - \(name)")
            }
        }
        print("\n=== Custom Fonts Status ===")
        print("Quicksand installed: \(hasCustomFonts)")
    }
}

// MARK: - Text Style Modifiers

extension View {
    /// Apply app title style
    func appTitleStyle() -> some View {
        self.font(.appTitle)
    }
    
    /// Apply app headline style
    func appHeadlineStyle() -> some View {
        self.font(.appHeadline)
    }
    
    /// Apply app body style
    func appBodyStyle() -> some View {
        self.font(.appBody)
    }
    
    /// Apply onboarding body style
    func onboardingBodyStyle() -> some View {
        self.font(.onboardingBody)
    }
}
