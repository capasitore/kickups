import SwiftUI

struct DistancePlotView: View {
    let distances: [Double]
    let isInCooldown: Bool
    
    private let maxDataPoints = 100
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background grid
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    
                    // Horizontal lines
                    for i in 0...4 {
                        let y = height * CGFloat(i) / 4
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: width, y: y))
                    }
                    
                    // Vertical lines
                    for i in 0...8 {
                        let x = width * CGFloat(i) / 8
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: height))
                    }
                }
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                
                // Distance plot
                if !distances.isEmpty {
                    let displayData = Array(distances.suffix(maxDataPoints))
                    let maxDistance = max(200.0, displayData.max() ?? 200.0)
                    
                    Path { path in
                        let width = geometry.size.width
                        let height = geometry.size.height
                        let stepX = width / CGFloat(max(displayData.count - 1, 1))
                        
                        for (index, distance) in displayData.enumerated() {
                            let x = CGFloat(index) * stepX
                            let normalizedDistance = min(distance / maxDistance, 1.0)
                            let y = height * (1.0 - CGFloat(normalizedDistance))
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(isInCooldown ? Color.green : Color.red, lineWidth: 2)
                    .animation(.easeInOut(duration: 0.3), value: isInCooldown)
                    
                    // Data points
                    let displayData = Array(distances.suffix(maxDataPoints))
                    let maxDistance = max(200.0, displayData.max() ?? 200.0)
                    
                    ForEach(Array(displayData.enumerated()), id: \.offset) { index, distance in
                        let width = geometry.size.width
                        let height = geometry.size.height
                        let stepX = width / CGFloat(max(displayData.count - 1, 1))
                        let x = CGFloat(index) * stepX
                        let normalizedDistance = min(distance / maxDistance, 1.0)
                        let y = height * (1.0 - CGFloat(normalizedDistance))
                        
                        Circle()
                            .fill(isInCooldown ? Color.green : Color.red)
                            .frame(width: 4, height: 4)
                            .position(x: x, y: y)
                    }
                }
                
                // Current distance value
                if let currentDistance = distances.last {
                    VStack {
                        HStack {
                            Spacer()
                            Text(String(format: "%.1f px", currentDistance))
                                .font(.caption)
                                .padding(4)
                                .background(Color.black.opacity(0.7))
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                        Spacer()
                    }
                    .padding(8)
                }
            }
        }
        .overlay(
            VStack {
                HStack {
                    Text("Distance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                Spacer()
            }
            .padding(8)
        )
    }
}

#Preview {
    DistancePlotView(distances: [100, 120, 80, 60, 40, 70, 90, 110, 85, 95], isInCooldown: false)
        .frame(height: 120)
        .padding()
}