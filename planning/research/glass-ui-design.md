# Glass UI Design in Swift UI

## Overview
Glassmorphism (glass UI) creates a premium, modern aesthetic with translucent backgrounds, subtle borders, and layered depth. Perfect for the Circles app's premium positioning.

## What is Glassmorphism?

### Key Characteristics
1. **Translucent Backgrounds**: Frosted glass effect
2. **Background Blur**: Content behind shows through
3. **Subtle Borders**: Light borders for definition
4. **Layered Shadows**: Depth and hierarchy
5. **Soft Colors**: Muted, desaturated palette

### Apple's Implementation
iOS provides native materials for glass effects:
- `.ultraThinMaterial`
- `.thinMaterial`
- `.regularMaterial`
- `.thickMaterial`
- `.ultraThickMaterial`

## SwiftUI Implementation

### 1. Basic Glass Card
```swift
struct GlassCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

// Usage
GlassCard {
    VStack {
        Text("Sarah Chen")
            .font(.headline)
        Text("Friend")
            .font(.caption)
    }
}
```

### 2. Glass Background
```swift
struct GlassBackground: View {
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.3),
                    Color.purple.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Blur layer
            .blur(radius: 100)
            
            // Glass overlay
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
        }
    }
}
```

### 3. Contact Card with Glass Effect
```swift
struct ContactCard: View {
    let contact: Contact
    
    var body: some View {
        HStack(spacing: 16) {
            // Profile photo with glass border
            AsyncImage(url: contact.photoURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Circle()
                    .fill(.gray.opacity(0.3))
            }
            .frame(width: 60, height: 60)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(.white.opacity(0.3), lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(contact.relationshipType)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                // Relationship meter
                RelationshipMeter(value: contact.relationshipScore)
            }
            
            Spacer()
            
            // Last contacted
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(contact.daysSinceLastContact)d")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Circle()
                    .fill(contact.urgencyColor)
                    .frame(width: 8, height: 8)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}
```

### 4. Relationship Meter with Glass Effect
```swift
struct RelationshipMeter: View {
    let value: Double // 0.0 to 1.0
    
    var meterColor: Color {
        switch value {
        case 0.75...:
            return .green
        case 0.5..<0.75:
            return .yellow
        case 0.25..<0.5:
            return .orange
        default:
            return .red
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Capsule()
                    .fill(.quaternary)
                    .frame(height: 6)
                
                // Progress
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [meterColor, meterColor.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * value, height: 6)
            }
        }
        .frame(height: 6)
    }
}
```

### 5. Glass Navigation Bar
```swift
struct GlassNavigationBar: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            Spacer()
            
            Button(action: action) {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(
            .regularMaterial,
            in: RoundedRectangle(cornerRadius: 0, style: .continuous)
        )
    }
}
```

### 6. Glass Bottom Sheet
```swift
struct GlassBottomSheet<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 3)
                .fill(.secondary.opacity(0.5))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
            
            // Content
            content
                .padding()
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: -5)
    }
}
```

### 7. Glass Button
```swift
struct GlassButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.medium)
            }
            .font(.body)
            .foregroundStyle(.primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(.white.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}
```

### 8. Floating Action Button (FAB)
```swift
struct GlassFAB: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.5), lineWidth: 2)
                )
                .shadow(color: .blue.opacity(0.4), radius: 15, x: 0, y: 8)
        }
    }
}
```

## Advanced Techniques

### 1. Depth and Layering
```swift
struct LayeredGlassView: View {
    var body: some View {
        ZStack {
            // Back layer
            RoundedRectangle(cornerRadius: 24)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
                .padding(8)
            
            // Front layer
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
        }
    }
}
```

### 2. Animated Glass Effects
```swift
struct PulsatingGlassCircle: View {
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .fill(.ultraThinMaterial)
            .overlay(
                Circle()
                    .stroke(.white.opacity(0.3), lineWidth: 2)
            )
            .scaleEffect(isAnimating ? 1.1 : 1.0)
            .opacity(isAnimating ? 0.8 : 1.0)
            .animation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}
```

### 3. Gradient Mesh Background (iOS 18+)
```swift
import SwiftUI

@available(iOS 18.0, *)
struct MeshGradientBackground: View {
    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                .blue, .purple, .pink,
                .cyan, .indigo, .purple,
                .mint, .blue, .purple
            ]
        )
        .ignoresSafeArea()
        .overlay(.ultraThinMaterial)
    }
}
```

## Color Palette for Glass UI

### Recommended Colors
```swift
extension Color {
    // Primary glass tints
    static let glassTintBlue = Color(hex: "#4A90E2")
    static let glassTintPurple = Color(hex: "#9B59B6")
    static let glassTintPink = Color(hex: "#E91E63")
    
    // Accents
    static let glassAccent = Color(hex: "#00D9FF")
    
    // Backgrounds
    static let glassBackground = Color(hex: "#F5F7FA")
    static let glassDarkBackground = Color(hex: "#1A1A2E")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
```

## Full Page Example

### Home Screen with Glass UI
```swift
struct HomeScreen: View {
    @State private var contacts: [Contact] = Contact.sampleData
    @State private var searchText = ""
    
    var body: some View {
        ZStack {
            // Background
            GlassBackground()
            
            // Content
            VStack(spacing: 0) {
                // Navigation bar
                GlassNavigationBar(title: "Kindred") {
                    // Settings action
                }
                
                // Search bar
                SearchBar(text: $searchText)
                    .padding()
                
                // Contact list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(contacts) { contact in
                            ContactCard(contact: contact)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            
            // Floating action button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    GlassFAB(icon: "plus") {
                        // Add contact
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
    }
}
```

### Search Bar
```swift
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Search people...", text: $text)
                .textFieldStyle(.plain)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    }
}
```

## Performance Considerations

### 1. Material Performance
- `.ultraThinMaterial` is most expensive (blurs most)
- Use sparingly on scrolling content
- Consider `.regularMaterial` for better performance

### 2. Shadow Optimization
```swift
// Good: Single shadow
.shadow(color: .black.opacity(0.1), radius: 10)

// Bad: Multiple shadows (expensive)
.shadow(...)
.shadow(...)
.shadow(...)
```

### 3. Lazy Loading
```swift
// Use LazyVStack/LazyHStack for long lists
LazyVStack {
    ForEach(contacts) { contact in
        ContactCard(contact: contact)
    }
}
```

## Accessibility

### Increase Contrast Mode
```swift
struct GlassCard: View {
    @Environment(\.colorSchemeContrast) var contrast
    
    var body: some View {
        content
            .background(
                contrast == .increased ? 
                .regularMaterial : .ultraThinMaterial
            )
    }
}
```

### Reduce Transparency
```swift
@Environment(\.accessibilityReduceTransparency) var reduceTransparency

var cardBackground: some ShapeStyle {
    if reduceTransparency {
        return AnyShapeStyle(.background.opacity(0.95))
    } else {
        return AnyShapeStyle(.ultraThinMaterial)
    }
}
```

## Dark Mode Support

### Adaptive Glass
Materials automatically adapt to dark mode, but you can customize:

```swift
struct AdaptiveGlassCard: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        content
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        colorScheme == .dark ? 
                        .white.opacity(0.2) : .white.opacity(0.3),
                        lineWidth: 1
                    )
            )
    }
}
```

## Testing

### Preview Different Scenarios
```swift
struct GlassCard_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Light mode
            GlassCard {
                Text("Light Mode")
            }
            .preferredColorScheme(.light)
            
            // Dark mode
            GlassCard {
                Text("Dark Mode")
            }
            .preferredColorScheme(.dark)
            
            // High contrast
            GlassCard {
                Text("High Contrast")
            }
            .environment(\.colorSchemeContrast, .increased)
        }
    }
}
```

## Best Practices

1. **Don't Overuse**: Too much glass = cluttered, hard to read
2. **Hierarchy**: More transparent = less important
3. **Contrast**: Ensure text readable on glass backgrounds
4. **Borders**: Subtle borders define glass boundaries
5. **Shadows**: Add depth, but keep them subtle
6. **Performance**: Monitor for slowdowns in complex views
7. **Accessibility**: Support reduce transparency mode
8. **Dark Mode**: Test extensively, glass looks different

## Key Takeaways

1. **Native Materials**: Use SwiftUI's built-in materials
2. **Subtle is Better**: Don't overdo effects
3. **Layer for Depth**: Multiple glass layers create hierarchy
4. **Test Everywhere**: Light, dark, accessibility modes
5. **Performance Matters**: Materials are expensive, use wisely
6. **Border + Shadow**: Essential for definition
7. **Continuous Corners**: `.continuous` style looks more premium

## Resources

- [Apple Human Interface Guidelines - Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
- [SwiftUI Materials Documentation](https://developer.apple.com/documentation/swiftui/material)
- [WWDC: What's New in SwiftUI](https://developer.apple.com/videos/play/wwdc2022/10052/)
- [Glassmorphism Design Trend](https://uxdesign.cc/glassmorphism-in-user-interfaces-1f39bb1308c9)
