//
//  NeedleView.swift
//  compteur
//
//  Created by Alexandre Fenyo on 06/11/2024.
//

import SwiftUI

struct NeedleView: View {
    @State var size: Double
    @Binding var angle: Double

    var body: some View {
        VStack {
            ZStack {
                Triangle()
                    .fill(Color.red)
                    .frame(width: size / 6, height: size)
                    .offset(y: -size / 2)

                Triangle()
                    .stroke(style: StrokeStyle(lineWidth: 1))
                    .fill(Color.black)
                    .frame(width: size / 6, height: size)
                    .offset(y: -size / 2)

                Circle()
                    .fill(Color.red)
                    .frame(width: size / 6, height: size / 6)
                
                Circle()
                    .fill(Color.black)
                    .frame(width: 11 * size / 120, height: 11 * size / 120)

                Circle()
                    .stroke(style: StrokeStyle(lineWidth: 1))
                    .fill(Color.black)
                    .frame(width: size / 6, height: size / 6)

            }
            .rotationEffect(.degrees(angle))
        }
        .shadow(color: Color.gray.opacity(0.9), radius: 2, x: -size / 24, y: size / 24)
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

