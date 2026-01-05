# StoreKit 2 and Monetization Research

## Overview
StoreKit 2 is Apple's modern framework for implementing in-app purchases and subscriptions in iOS apps. It provides a Swift-first API with async/await support, making it ideal for implementing paid features.

## Key Features of StoreKit 2

### 1. Modern Swift APIs
- **Async/Await Support**: Leverages Swift's modern concurrency model
- **Swift-Native**: Built specifically for Swift, providing type-safe APIs
- **Cleaner Code**: More readable and maintainable than StoreKit 1

### 2. Built-In Security
- **JWS Signed Transactions**: Cryptographically signed in JSON Web Signature format
- **Local Receipt Validation**: On-device validation without server roundtrips
- **Enhanced Security**: Reduced fraud risk with built-in verification

### 3. SwiftUI Integration
- **ProductView**: Display individual products
- **SubscriptionStoreView**: Present subscription options
- **StoreView**: Comprehensive store interface
- **Automatic Localization**: Handles pricing and descriptions across regions

### 4. Subscription Management
- Simplified handling of auto-renewable subscriptions
- Built-in subscription status checks
- Grace period and billing issue management
- Renewal information tracking

## Implementation Steps

### 1. Setup in App Store Connect
1. Log in to App Store Connect
2. Navigate to "My Apps" → Select app
3. Go to "Features" → "In-App Purchases"
4. Add products (consumable, non-consumable, or subscription)
5. Define product identifiers, pricing, and descriptions

### 2. StoreKit Configuration File (Development)
- Create StoreKit Configuration file in Xcode
- Define test products for local testing
- Specify product details (ID, type, pricing)
- Enables testing without App Store Connect

### 3. Fetch Products
```swift
import StoreKit

// Fetch products asynchronously
let products = try await Product.products(for: ["product_id_1", "product_id_2"])
```

### 4. Display Products
```swift
// Use built-in SwiftUI views
SubscriptionStoreView()

// Or custom implementation
ForEach(products) { product in
    ProductView(id: product.id)
}
```

### 5. Handle Purchases
```swift
// Purchase a product
let result = try await product.purchase()

// Handle transaction
switch result {
case .success(let verification):
    // Unlock features
case .userCancelled:
    // Handle cancellation
case .pending:
    // Handle pending state
}
```

### 6. Transaction Verification
```swift
// Transactions are automatically signed and verified
for await result in Transaction.updates {
    guard case .verified(let transaction) = result else {
        continue
    }
    // Process verified transaction
    await transaction.finish()
}
```

## Recommended Monetization Strategy

### For Circles App
1. **Free Tier**:
   - Limited contacts (e.g., 20-30 contacts)
   - Basic features (list view, basic notes)
   - Limited widget functionality
   
2. **Premium Tier** (Subscription):
   - Unlimited contacts
   - Full relationship graph visualization
   - AI gift suggestions
   - Voice note transcription and summarization
   - Advanced reminders and customization
   - Priority features and updates

3. **Pricing Model**:
   - Monthly: $4.99
   - Annual: $39.99 (save 33%)
   - Free trial: 7 or 14 days

### Feature Gating Strategy
- Core relationship tracking: Free
- Advanced visualization (graph): Premium
- AI-powered features: Premium
- Unlimited contacts: Premium
- Advanced customization: Premium

## Third-Party Solutions

### RevenueCat
- **Pros**:
  - Simplifies IAP implementation
  - Cross-platform support
  - Analytics and customer management
  - Server-side receipt validation
  - Remote configuration
- **Cons**:
  - Additional dependency
  - Pricing based on monthly tracked revenue
- **Use Case**: Good for apps needing multi-platform support and advanced analytics

### Iaptic StoreKit 2
- **Pros**:
  - Lightweight Swift package
  - Enterprise-grade validation
  - Real-time fraud detection
  - Server-side validation
- **Cons**:
  - Additional cost
  - More complex setup
- **Use Case**: Apps requiring enhanced security and validation

## Testing

### 1. Xcode StoreKit Testing
- Test IAPs without App Store connection
- Simulate purchase scenarios
- Test failures, refunds, and cancellations
- No real charges incurred

### 2. Sandbox Testing
- Test on physical devices
- Use sandbox Apple ID accounts
- Verify complete purchase flow
- Test subscription renewals

### 3. TestFlight
- Beta test with real users
- Verify IAPs in production-like environment
- Get feedback on purchase flow

## Best Practices

1. **Always Validate Receipts**: Use StoreKit 2's built-in validation
2. **Handle All Transaction States**: Success, failure, pending, cancelled
3. **Implement Restore Purchases**: Required for non-consumables and subscriptions
4. **Clear Communication**: Explain benefits of premium features
5. **Graceful Degradation**: App should work well in free tier
6. **Privacy Compliance**: Don't track user purchases without consent
7. **Test Thoroughly**: Use both StoreKit testing and sandbox

## Recommended Implementation for Circles

### Architecture
```
StoreManager (Singleton)
├── Product Fetching
├── Purchase Handling  
├── Transaction Observation
├── Entitlement Management
└── Subscription Status

Features/UI
├── Paywall View (SwiftUI)
├── Subscription Management
└── Feature Gates
```

### Feature Gates
```swift
@Published var isPremium: Bool = false

func checkFeature() -> Bool {
    return isPremium || contactCount < 30
}
```

## Resources

- [Apple StoreKit Documentation](https://developer.apple.com/documentation/storekit)
- [StoreKit 2 Overview](https://developer.apple.com/storekit/)
- [RevenueCat StoreKit 2 Guide](https://www.revenuecat.com/blog/engineering/revenuecat-sdk-5-0-the-storekit-2-update/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

## Key Takeaways

1. **Use StoreKit 2**: Modern, Swift-native, more secure
2. **Start Simple**: Basic subscription model for MVP
3. **Test Extensively**: Use Xcode testing + sandbox
4. **Consider Third-Party**: RevenueCat if needing advanced features
5. **Clear Value Prop**: Make premium benefits obvious
6. **7-Day Free Trial**: Industry standard, increases conversions
