//
//  Graham.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 19/12/2022.
//  Copyright © 2022 Alexandre Fenyo. All rights reserved.
//

// Implémentation de l'algorithme de Graham pour déterminer l'enveloppe convexe d'un ensemble de points dans un plan
// https://miashs-www.u-ga.fr/prevert/Prog/Complexite/graham.html

import CoreGraphics
import Foundation

extension CGPoint: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
      }
}

public struct DistanceCache {
    public let width: UInt16
    public let height: UInt16
    public let vertices: Set<CGPoint>
    public let distance: [UInt16]
    
    public func getDistance(x: UInt16, y: UInt16) -> UInt16 {
        // ne doit plus arriver, était lié à une persistance du cache en cas de changement d'image de fond
        if Int(x) + Int(y) * Int(width) >= Int(width) * Int(height) {
            return 0
        }
        return distance[Int(x) + Int(y) * Int(width)]
    }
}

struct Polygon {
    public var vertices: Array<CGPoint>

    public init(vertices: Array<CGPoint>) {
        self.vertices = vertices
    }

    private static func distance(_ p0: CGPoint, _ p1: CGPoint) -> Double {
        return squareDistance(p0, p1).squareRoot()
    }

    private static func squareDistance(_ p0: CGPoint, _ p1: CGPoint) -> Double {
        return (p1.x - p0.x) * (p1.x - p0.x) + (p1.y - p0.y) * (p1.y - p0.y)
    }

    private static func cosinLowestToVertex(lowest: CGPoint, vertex: CGPoint) -> Double {
        return (vertex.x - lowest.x) / distance(lowest, vertex)
    }

    private static func vector(_ p0: CGPoint, _ p1: CGPoint) -> CGPoint {
        return CGPoint(x: p1.x - p0.x, y: p1.y - p0.y)
    }

    private static func vectorProduct(_ v0: CGPoint, _ v1: CGPoint) -> Double {
        return v0.x * v1.y - v0.y * v1.x
    }

    private static func scalarProduct(_ v0: CGPoint, _ v1: CGPoint) -> Double {
        return v0.x * v1.x + v0.y * v1.y
    }

    // algo qui ne fonctionne que si le polygone est convexe
    public func isInside(_ p: CGPoint) -> Bool {
        if vertices.count < 3 { return true }
        let sign = Self.vectorProduct(Self.vector(p, vertices[vertices.count - 1]), Self.vector(p, vertices[0])) < 0
        for idx in 1..<vertices.count {
            if (Self.vectorProduct(Self.vector(p, vertices[idx - 1]), Self.vector(p, vertices[idx])) < 0) != sign { return false }
        }
        return true
    }

    private static func distanceToLine(line_p0: CGPoint, line_p1: CGPoint, p: CGPoint) -> Double {
        abs(vectorProduct(vector(line_p0, line_p1), vector(line_p0, p))) / distance(line_p0, line_p1)
    }
    
    private static func distanceToSegment(line_p0: CGPoint, line_p1: CGPoint, p: CGPoint) -> Double {
        let sc0 = scalarProduct(vector(line_p0, line_p1), vector(line_p0, p))
        let sc1 = scalarProduct(vector(line_p1, line_p0), vector(line_p1, p))
        if sc0 <= 0 || sc1 <= 0 {
            return [ distance(line_p0, p), distance(line_p1, p) ].min()!
        }
        return distanceToLine(line_p0: line_p0, line_p1: line_p1, p: p)
    }

    public func distanceToPolygon(_ p: CGPoint) -> Double {
        if isInside(p) { return 0 }
        var distances = vertices.map { Self.distance($0, p) }
        for i in 0..<vertices.count {
            distances.append(Self.distanceToSegment(line_p0: vertices[i], line_p1: vertices[i + 1 == vertices.count ? 0 : i + 1], p: p))
        }
        return distances.min()!
    }

    public mutating func computeConvexHull() {
        // on supprime les doublons
        var unique_vertices = Set<CGPoint>()
        _ = vertices.map { unique_vertices.insert($0) }
        vertices = Array(unique_vertices)
        
        // on cherche le sommet le plus en bas à gauche
        var lowest_vertex = vertices[0]
        _ = vertices.map {
            if $0.y < lowest_vertex.y || ($0.y == lowest_vertex.y && $0.x < lowest_vertex.x) { lowest_vertex = $0 }}
        
        // les autres sommets sont mis de côté
        var vertices_except_lowest = vertices.filter { $0 != lowest_vertex }

        // tri dans le sens trigo (on teste avec > car cosinus est une fonction décroissante)
        vertices_except_lowest.sort {
            Self.cosinLowestToVertex(lowest: lowest_vertex, vertex: $0) > Self.cosinLowestToVertex(lowest: lowest_vertex, vertex: $1)
        }
        
        // on supprime ceux qui sont alignés sauf le plus long par groupe d'alignés
        var prev_vertex = vertices_except_lowest.first!
        for next_vertex in (vertices_except_lowest.filter { $0 != prev_vertex }) {
            if Self.vectorProduct(Self.vector(lowest_vertex, prev_vertex), Self.vector(lowest_vertex, next_vertex)) == 0 {
                if Self.squareDistance(lowest_vertex, prev_vertex) < Self.squareDistance(lowest_vertex, next_vertex) {
                    vertices_except_lowest.remove(at: vertices_except_lowest.firstIndex(of: prev_vertex)!)
                    prev_vertex = next_vertex
                } else {
                    vertices_except_lowest.remove(at: vertices_except_lowest.firstIndex(of: next_vertex)!)
                }
            } else {
                prev_vertex = next_vertex
            }
        }

        // on parcourt les sommets dans l'ordre trigo et on supprime ceux qui sont à l'intérieur du polygone
        var stack = [ lowest_vertex, vertices_except_lowest[0] ]
        vertices_except_lowest.removeFirst()
        for p2 in vertices_except_lowest {
            while true {
                let p0 = stack[stack.count - 2]
                let p1 = stack[stack.count - 1]
                let orientation = Self.vectorProduct(Self.vector(p0, p1), Self.vector(p1, p2))
                if orientation > 0 {
                    stack.append(p2)
                    break
                } else {
                    _ = stack.popLast()
                }
            }
        }

        vertices = stack
    }
}
