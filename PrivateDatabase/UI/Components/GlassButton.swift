//
//  GlassButton.swift
//  Circles
//

import SwiftUI

/// A glass-styled button with translucent background and customizable styling
struct GlassButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    var style: ButtonStyle = .primary
    var size: ButtonSize = .medium
    
    init(
        _ title: String,
        icon: String? = nil,
        style: ButtonStyle = .primary,
        size: ButtonSize = .medium,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.action = action
        self.style = style
        self.size = size
    }
    
    @ViewBuilder
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(size.iconFont)
                }
                
                Text(title)
                    .font(size.textFont)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(style.foregroundColor)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .frame(maxWidth: .infinity)
            .background(backgroundMaterialForStyle)
            .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
                    .stroke(style.borderColor, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
    
    private var backgroundMaterialForStyle: AnyShapeStyle {
        if #available(iOS 18.0, *) {
            // Liquid Glass UI for iOS 18+
            // Note: .liquidGlass requires iOS 18+ and may need Xcode beta
            // Using enhanced ultraThinMaterial as fallback until API is available
            switch style {
            case .primary:
                return AnyShapeStyle(.ultraThinMaterial)
            case .secondary:
                return AnyShapeStyle(.thinMaterial)
            case .destructive:
                return AnyShapeStyle(.red.opacity(0.2))
            case .ghost:
                return AnyShapeStyle(.clear)
            }
        } else {
            switch style {
            case .primary:
                return AnyShapeStyle(.ultraThinMaterial)
            case .secondary:
                return AnyShapeStyle(.thinMaterial)
            case .destructive:
                return AnyShapeStyle(.red.opacity(0.2))
            case .ghost:
                return AnyShapeStyle(.clear)
            }
        }
    }
}

// MARK: - Button Style

extension GlassButton {
    enum ButtonStyle {
        case primary
        case secondary
        case destructive
        case ghost
        
        
        var foregroundColor: Color {
            switch self {
            case .primary:
                return .primary
            case .secondary:
                return .secondary
            case .destructive:
                return .red
            case .ghost:
                return .primary
            }
        }
        
        var borderColor: Color {
            switch self {
            case .primary, .secondary:
                return .white.opacity(0.2)
            case .destructive:
                return .red.opacity(0.3)
            case .ghost:
                return .clear
            }
        }
    }
}

// MARK: - Button Size

extension GlassButton {
    enum ButtonSize {
        case small
        case medium
        case large
        
        var horizontalPadding: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 16
            case .large: return 20
            }
        }
        
        var verticalPadding: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 12
            case .large: return 16
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 16
            case .large: return 20
            }
        }
        
        var textFont: Font {
            switch self {
            case .small: return .subheadline
            case .medium: return .body
            case .large: return .title3
            }
        }
        
        var iconFont: Font {
            switch self {
            case .small: return .caption
            case .medium: return .body
            case .large: return .title3
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        GlassBackground()
        
        VStack(spacing: 16) {
            GlassButton("Add Contact", icon: "plus", style: .primary) {}
            GlassButton("Save", style: .secondary) {}
            GlassButton("Delete", icon: "trash", style: .destructive) {}
            GlassButton("Cancel", style: .ghost) {}
            
            HStack {
                GlassButton("Small", size: .small) {}
                GlassButton("Large", size: .large) {}
            }
        }
        .padding()
    }
}

