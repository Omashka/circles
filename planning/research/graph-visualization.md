# Force-Directed Graph Visualization in iOS

## Overview
Implementing a force-directed graph for visualizing relationship networks in iOS requires careful consideration of performance, interaction, and visual design.

## Available Approaches

### 1. SpriteKit (Recommended for MVP)
**Pros:**
- Apple's native 2D game framework
- Excellent performance for node-based graphics
- Built-in physics simulation can be adapted for force-directed layout
- Touch handling well-suited for graph interaction
- Supports thousands of nodes with good performance

**Cons:**
- Requires custom force-directed algorithm implementation
- Physics engine needs tuning for graph layout
- Scene management adds complexity

**Implementation Approach:**
```swift
// Each contact becomes an SKNode
// Connections are SKShapeNode lines
// Use SKPhysicsBody for repulsion
// Custom force calculations for attraction
```

### 2. SwiftUI Canvas
**Pros:**
- Native SwiftUI integration
- Modern declarative syntax
- Good for smaller graphs (<100 nodes)
- Easier to integrate with rest of SwiftUI app

**Cons:**
- Performance limitations with many nodes
- More manual work for physics/forces
- Touch handling less sophisticated than SpriteKit

**Best Use Case:**
- Smaller relationship networks
- Simpler visual requirements
- Tighter SwiftUI integration

### 3. Third-Party Libraries

#### GraphUI (Conceptual - would need to create)
Most iOS graph libraries are for charts, not network graphs. Limited options exist for force-directed graphs specifically.

#### Web-Based (D3.js in WKWebView)
**Pros:**
- Mature D3.js force-directed layout
- Rich ecosystem of graph algorithms
- Beautiful visualizations possible

**Cons:**
- WebView overhead
- Bridging between Swift and JavaScript
- Not native feel
- Performance concerns

## Recommended Implementation Strategy

### Phase 1: SpriteKit Foundation
1. **Node Representation**
   - Each contact as SKSpriteNode
   - Profile photo as texture
   - Size based on importance/relationship strength

2. **Edge Rendering**
   - SKShapeNode for connection lines
   - Different line styles (solid, dashed, arrowed)
   - Thickness based on interaction frequency
   - Labels on hover/tap

3. **Force-Directed Layout Algorithm**
```swift
class ForceDirectedGraph {
    // Repulsion between all nodes
    func calculateRepulsion(node1: Node, node2: Node) -> CGVector
    
    // Attraction for connected nodes
    func calculateAttraction(node1: Node, node2: Node) -> CGVector
    
    // Apply forces and update positions
    func simulate(deltaTime: TimeInterval)
    
    // Damping to stabilize
    var damping: CGFloat = 0.9
}
```

4. **Touch Interactions**
   - Tap node → Open profile
   - Drag node → Manual repositioning
   - Pinch → Zoom in/out
   - Pan → Move viewport
   - Tap connection → Show connection details

5. **Performance Optimizations**
   - Spatial hashing for collision detection
   - LOD (Level of Detail) - hide labels when zoomed out
   - Cull off-screen nodes
   - Update rate throttling (30-60 FPS)

### Force-Directed Algorithm Details

#### Barnes-Hut Approximation
For graphs with 100+ nodes, use Barnes-Hut algorithm:
- Divide space into quadtree
- Approximate distant node forces
- O(n log n) instead of O(n²)
- Significant performance improvement

#### Force Calculations
```swift
// Repulsion (Coulomb's law)
let distance = node1.position.distance(to: node2.position)
let repulsionForce = (k * k) / distance
let direction = (node2.position - node1.position).normalized()
let force = direction * repulsionForce

// Attraction (Hooke's law for connected nodes)
let springForce = springConstant * (distance - restLength)
let force = direction * springForce
```

#### Constants to Tune
- `k` (repulsion strength): 1000-5000
- `springConstant`: 0.1-0.5
- `restLength`: 100-200 points
- `damping`: 0.8-0.95
- `maxVelocity`: 50-100 points/frame

### Visual Design Considerations

#### Node Styling
- **Profile Photo**: Circular with border
- **Size**: 40-60pt diameter base
- **Border Color**: Relationship type
- **Shadow**: Depth and hierarchy
- **Badge**: Notification/reminder indicator

####Connection Styling
- **Solid Line**: Family, close friends (thickness 2-4pt)
- **Dashed Line**: Acquaintances (thickness 1-2pt)
- **Arrowed Line**: "Introduced by" relationship
- **Color**: Subtle, not overwhelming
- **Labels**: Small, only on hover/selection

#### Glass UI Integration
```swift
// Apply glassmorphism to info panels
.background(.ultraThinMaterial)
.overlay(
    RoundedRectangle(cornerRadius: 16)
        .stroke(.white.opacity(0.2), lineWidth: 1)
)
```

## Interaction Patterns

### Drag-and-Drop Connection Creation
1. Long press on node A
2. Drag to node B
3. Release - show connection type sheet
4. Save connection with metadata

### Connection Info Sheet
```swift
// When tapping connection line
Sheet:
- Connection type (Sibling, Friend, etc.)
- "How you met" context
- Date established
- Who introduced (if applicable)
- Edit/Delete options
```

### Zoom Levels
- **Far**: Show overall structure, hide labels
- **Medium**: Show names, relationship types
- **Close**: Full detail, connection context

## Performance Targets

### Metrics
- 60 FPS with 100 nodes, 150 edges
- 30 FPS with 500 nodes, 750 edges
- <500ms initial layout time
- Smooth zoom/pan

### Memory Management
- Reuse node sprites
- Lazy load profile images
- Release off-screen resources
- Monitor texture memory

## Testing Considerations

1. **Graph Sizes**: Test with 10, 50, 100, 500 nodes
2. **Dense vs Sparse**: Vary connection density
3. **Edge Cases**: Single node, disconnected clusters
4. **Device Performance**: Test on older iPhones (iPhone 11)
5. **Accessibility**: VoiceOver navigation of graph

## Libraries to Consider (Limited iOS Options)

### Charts (Built-in)
- Not suitable for network graphs
- Good for data visualization only

### Custom Implementation (Recommended)
- Full control over behavior
- Optimized for specific use case
- Native integration
- Best performance

## Alternative: Simplified Circle Layout

For MVP, consider simpler layout:
- Ego-centric: User in center
- Rings by relationship type
- Manual clustering by groups
- Less computation, still visual

## Implementation Timeline Estimate

- **Week 1**: SpriteKit setup, node rendering
- **Week 2**: Force algorithm, basic layout
- **Week 3**: Touch interactions, zoom/pan
- **Week 4**: Visual polish, performance optimization
- **Week 5**: Connection creation, editing
- **Week 6**: Testing, bug fixes

## Key Takeaways

1. **SpriteKit is Best Choice**: Native, performant, flexible
2. **Custom Force Algorithm**: No perfect library exists
3. **Start Simple**: Get basic layout working first
4. **Optimize Early**: Performance critical for good UX
5. **Touch is Crucial**: Make interactions intuitive
6. **Visual Polish**: Glass UI, animations matter

## Code Structure

```
GraphView/
├── GraphScene.swift (SKScene)
├── ContactNode.swift (SKSpriteNode subclass)
├── ConnectionEdge.swift (SKShapeNode wrapper)
├── ForceSimulation.swift (Algorithm)
├── GraphInteractionHandler.swift (Touch logic)
└── GraphLayoutEngine.swift (Positioning)
```

## Resources

- Apple SpriteKit Documentation
- Force-Directed Graph Drawing algorithms (academic papers)
- D3.js force documentation (algorithm reference)
- iOS Human Interface Guidelines (touch targets, gestures)
