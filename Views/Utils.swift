//
//  WhiskerStyles.swift
//  Whisker
//
//  Created by Julia Yu on 5/5/25.
//

import SwiftUI

// MARK: - Font Registration Helper
func registerFonts() {
    UIFont.familyNames.forEach { familyName in
        print("Font family: \(familyName)")
        UIFont.fontNames(forFamilyName: familyName).forEach { fontName in
            print("- Font: \(fontName)")
        }
    }
}

// MARK: - Shared Style Constants
struct WhiskerStyles {
    static let primaryColor = Color(hex: "#F0A04B")
    static let textColor = Color(hex: "#353535")
    static let backgroundColor = Color(hex: "#FBF9F5")
    static let facebookColor = Color(red: 0.23, green: 0.35, blue: 0.6)
    
    struct Fonts {
            static let title = Font.custom("Grandstander", size: 30)
            static let bodyRegular = Font.custom("Sarabun", size: 16)
            static let bodyLight = Font.custom("Sarabun", size: 14).weight(.light)
            static let bodyMedium = Font.custom("Sarabun", size: 18).weight(.medium)
            static let buttonText = Font.custom("Sarabun", size: 18).weight(.semibold)
            

            static func bodyLight(size: CGFloat) -> Font {
                return Font.custom("Sarabun", size: size).weight(.light)
            }
        }
}

// MARK: - Text Field Styles
struct WhiskerTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.white)
            .cornerRadius(2)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .foregroundColor(WhiskerStyles.textColor)
            .font(WhiskerStyles.Fonts.bodyRegular)
    }
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(WhiskerStyles.Fonts.buttonText)
            .foregroundColor(WhiskerStyles.textColor)
            .frame(maxWidth: .infinity)
            .padding()
            .background(WhiskerStyles.primaryColor)
            .cornerRadius(10)
    }
}

struct SocialButtonStyle: ViewModifier {
    var background: Color
    var foreground: Color
    
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .padding()
            .background(background)
            .foregroundColor(foreground)
            .cornerRadius(15)
    }
}

// MARK: - View Extensions
extension View {
    func whiskerTextField() -> some View {
        self.modifier(WhiskerTextFieldStyle())
    }
    
    func primaryButton() -> some View {
        self.modifier(PrimaryButtonStyle())
    }
    
    func socialButton(background: Color, foreground: Color) -> some View {
        self.modifier(SocialButtonStyle(background: background, foreground: foreground))
    }
}
