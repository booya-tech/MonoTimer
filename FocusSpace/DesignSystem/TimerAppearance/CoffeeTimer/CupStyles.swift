//
//  CupStyles.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 10/7/25.
//

import SwiftUI

/// Available cup styles
enum CupStyle {
    case glass      // Current trapezoid style
    case mug        // Rounded mug with handle
    case minimal    // Simple rounded rectangle
}

// MARK: - Type-erased Shape Wrapper
struct AnyShape: Shape {
    private let _path: (CGRect) -> Path
    
    init<S: Shape>(_ shape: S) {
        _path = { rect in
            shape.path(in: rect)
        }
    }
    
    func path(in rect: CGRect) -> Path {
        _path(rect)
    }
}

// MARK: - Glass Cup Shape (Coffee Mug with Handle)
struct GlassCupShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        // Main mug body - tall rounded rectangle
        let mugWidth = width * 0.75
        let mugHeight = height * 0.85
        let mugLeft = (width - mugWidth) / 2
        let mugTop = height * 0.08
        let cornerRadius: CGFloat = 20
        
        // Draw main mug body ONLY
        let mugRect = CGRect(
            x: mugLeft,
            y: mugTop,
            width: mugWidth,
            height: mugHeight
        )
        path.addRoundedRect(in: mugRect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
        
        return path
    }
}

// MARK: - Glass Cup Handle (Separate for stroke only)
struct GlassCupHandleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        let mugWidth = width * 0.75
        let mugHeight = height * 0.85
        let mugLeft = (width - mugWidth) / 2
        let mugTop = height * 0.08
        
        // Handle - D-shaped on the right
        let handleTop = mugTop + mugHeight * 0.28
        let handleBottom = mugTop + mugHeight * 0.68
        let handleLeft = mugLeft + mugWidth
        let handleRight = mugLeft + mugWidth + (width * 0.2)
        let handleMid = (handleTop + handleBottom) / 2
        
        // Outer curve
        path.move(to: CGPoint(x: handleLeft, y: handleTop))
        path.addCurve(
            to: CGPoint(x: handleLeft, y: handleBottom),
            control1: CGPoint(x: handleRight, y: handleTop + (handleMid - handleTop) * 0.4),
            control2: CGPoint(x: handleRight, y: handleBottom - (handleBottom - handleMid) * 0.4)
        )
        
        // Inner curve (for handle thickness)
        path.move(to: CGPoint(x: handleLeft, y: handleTop + 10))
        path.addCurve(
            to: CGPoint(x: handleLeft, y: handleBottom - 10),
            control1: CGPoint(x: handleRight - 18, y: handleTop + (handleMid - handleTop) * 0.45 + 10),
            control2: CGPoint(x: handleRight - 18, y: handleBottom - (handleBottom - handleMid) * 0.45 - 10)
        )
        
        return path
    }
}

// MARK: - Mug Cup Shape (Realistic Coffee Mug)
struct MugCupShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        // Main mug body with subtle taper
        let topWidth = width * 0.68
        let bottomWidth = width * 0.58
        let mugHeight = height * 0.88
        let startY = height * 0.08
        
        // Left side (slightly tapered)
        let topLeft = (width - topWidth) / 2
        let bottomLeft = (width - bottomWidth) / 2
        
        // Right side
        let topRight = topLeft + topWidth
        let bottomRight = bottomLeft + bottomWidth
        
        // Draw mug body with rounded corners
        path.move(to: CGPoint(x: topLeft + 10, y: startY))
        
        // Top rim (curved)
        path.addQuadCurve(
            to: CGPoint(x: topRight - 10, y: startY),
            control: CGPoint(x: width * 0.5, y: startY - 5)
        )
        
        // Right top corner
        path.addQuadCurve(
            to: CGPoint(x: topRight, y: startY + 10),
            control: CGPoint(x: topRight, y: startY)
        )
        
        // Right side taper
        path.addLine(to: CGPoint(x: bottomRight, y: startY + mugHeight - 15))
        
        // Bottom right corner
        path.addQuadCurve(
            to: CGPoint(x: bottomRight - 15, y: startY + mugHeight),
            control: CGPoint(x: bottomRight, y: startY + mugHeight)
        )
        
        // Bottom base
        path.addLine(to: CGPoint(x: bottomLeft + 15, y: startY + mugHeight))
        
        // Bottom left corner
        path.addQuadCurve(
            to: CGPoint(x: bottomLeft, y: startY + mugHeight - 15),
            control: CGPoint(x: bottomLeft, y: startY + mugHeight)
        )
        
        // Left side taper
        path.addLine(to: CGPoint(x: topLeft, y: startY + 10))
        
        // Top left corner
        path.addQuadCurve(
            to: CGPoint(x: topLeft + 10, y: startY),
            control: CGPoint(x: topLeft, y: startY)
        )
        
        // Handle (more realistic C-shape)
        let handlePath = Path { p in
            let handleTopY = startY + mugHeight * 0.25
            let handleBottomY = startY + mugHeight * 0.65
            let handleStartX = topRight - 5
            let handleOuterX = width * 0.92
            
            // Handle outer curve
            p.move(to: CGPoint(x: handleStartX, y: handleTopY))
            p.addCurve(
                to: CGPoint(x: handleStartX, y: handleBottomY),
                control1: CGPoint(x: handleOuterX, y: handleTopY + 15),
                control2: CGPoint(x: handleOuterX, y: handleBottomY - 15)
            )
            
            // Handle inner curve (thickness)
            p.move(to: CGPoint(x: handleStartX - 8, y: handleTopY + 5))
            p.addCurve(
                to: CGPoint(x: handleStartX - 8, y: handleBottomY - 5),
                control1: CGPoint(x: handleOuterX - 15, y: handleTopY + 18),
                control2: CGPoint(x: handleOuterX - 15, y: handleBottomY - 18)
            )
        }
//        path.addPath(handlePath)
        
        return path
    }
}

// MARK: - Minimal Cup Shape (Simple Rounded Rectangle)
struct MinimalCupShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        // Simple rounded rectangle
        let cupRect = CGRect(
            x: width * 0.2,
            y: height * 0.05,
            width: width * 0.6,
            height: height * 0.9
        )
        path.addRoundedRect(in: cupRect, cornerSize: CGSize(width: 15, height: 15))
        
        return path
    }
}
