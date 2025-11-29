//
//  ColorScheme.swift
//  ClassMateAI
//
//  Updated for Dark Mode support
//

import SwiftUI
import UIKit

extension Color {
    // MARK: - Adaptive Colors for Dark/Light Mode
    
    /// Main background color (Light: White/Off-white, Dark: Black/Dark Gray)
    static let mateBackground = Color(uiColor: UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? .systemBackground : UIColor(red: 0.98, green: 0.98, blue: 0.99, alpha: 1)
    })
    
    /// Secondary background for cards/grouped content
    static let mateCardBackground = Color(uiColor: UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? .secondarySystemBackground : .white
    })
    
    /// Background for small elements (icons, buttons)
    static let mateElementBackground = Color(uiColor: .secondarySystemFill)
    
    /// Primary brand color (Adaptive Blue)
    static let matePrimary = Color(uiColor: UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1) : UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1)
    })
    
    /// Secondary accent color (Adaptive Gray)
    static let mateSecondary = Color(uiColor: UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? .secondaryLabel : .secondaryLabel
    })
    
    /// Main text color (Adaptive Black/White)
    static let mateText = Color(uiColor: UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? .label : .label
    })
    
    /// Border color (Adaptive Gray)
    static let mateBorder = Color(uiColor: UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? .separator : .opaqueSeparator
    })
    
    /// Success/Green color
    static let mateGreen = Color(uiColor: UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? .systemGreen : .systemGreen
    })
    
    /// Warning/Orange color
    static let mateOrange = Color(uiColor: UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? .systemOrange : .systemOrange
    })
    
    /// Error/Red color
    static let mateRed = Color(uiColor: UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? .systemRed : .systemRed
    })
}
