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

extension CGPoint : Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
      }
}

struct Polygon {
    public var vertices: Array<CGPoint>

    private static func distance(_ p0: CGPoint, _ p1: CGPoint) -> Double {
        return pow((p1.x - p0.x) * (p1.x - p0.x) + (p1.y - p0.y) * (p1.y - p0.y), 0.5)
    }

    private static func square_distance(_ p0: CGPoint, _ p1: CGPoint) -> Double {
        return (p1.x - p0.x) * (p1.x - p0.x) + (p1.y - p0.y) * (p1.y - p0.y)
    }

    private static func cosin_lowest_to_vertex(lowest: CGPoint, vertex: CGPoint) -> Double {
        return (vertex.x - lowest.x) / distance(lowest, vertex)
    }

    private static func vector(_ p0: CGPoint, _ p1: CGPoint) -> CGPoint {
        return CGPoint(x: p1.x - p0.x, y: p1.y - p0.y)
    }

    // positif si on tourne dans le sens trigo
    private static func vector_product(_ v0: CGPoint, _ v1: CGPoint) -> Double {
        return v0.x * v1.y - v0.y * v1.x
    }

    public mutating func computeConvexHull() {
        // on supprime les doublons
        var unique_vertices = Set<CGPoint>()
        _ = vertices.map { unique_vertices.insert($0) }
        vertices = Array(unique_vertices)
        
        // on cherche le sommet le plus en bas à gauche
        var lowest_vertex = vertices[0]
        let _ = vertices.map {
            if $0.y < lowest_vertex.y || ($0.y == lowest_vertex.y && $0.x < lowest_vertex.x) { lowest_vertex = $0 }}
        
        // les autres sommets sont mis de côté
        var vertices_except_lowest = vertices.filter { $0 != lowest_vertex }

        // tri dans le sens trigo (on teste avec > car cosinus est une fonction décroissante)
        vertices_except_lowest.sort {
            Self.cosin_lowest_to_vertex(lowest: lowest_vertex, vertex: $0) > Self.cosin_lowest_to_vertex(lowest: lowest_vertex, vertex: $1)
        }
        
        // on supprime ceux qui sont alignés sauf le plus long par groupe d'alignés
        var prev_vertex = vertices_except_lowest.first!
        for next_vertex in (vertices_except_lowest.filter { $0 != prev_vertex }) {
            if Self.vector_product(Self.vector(lowest_vertex, prev_vertex), Self.vector(lowest_vertex, next_vertex)) == 0 {
                if Self.square_distance(lowest_vertex, prev_vertex) < Self.square_distance(lowest_vertex, next_vertex) {
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
                let orientation = Self.vector_product(Self.vector(p0, p1), Self.vector(p1, p2))
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
