//
//  Graham.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 19/12/2022.
//  Copyright © 2022 Alexandre Fenyo. All rights reserved.
//

// Implémentation de l'algorithme de Graham pour déterminer l'enveloppe convexe d'un ensemble de points dans un espace à deux dimensions
// https://miashs-www.u-ga.fr/prevert/Prog/Complexite/graham.html

import CoreGraphics

struct Polygon {
    public var vertices: Array<CGPoint>

    private static func distance(_ p0: CGPoint, _ p1: CGPoint) -> Double {
        return pow((p1.x - p0.x) * (p1.x - p0.x) + (p1.y - p0.y) * (p1.y - p0.y), 0.5)
    }
    
    private static func cosin_lowest_to_vertex(lowest: CGPoint, vertex: CGPoint) -> Double {
        return (vertex.x - lowest.x) / distance(lowest, vertex)
    }

    public func computeConvexHull() {
        var lowest_vertex = vertices[0]
        let _ = vertices.map { if $0.y < lowest_vertex.y { lowest_vertex = $0 } }
        
        var vertices_except_lowest = vertices.filter { $0 != lowest_vertex }

        // tri dans le sens trigo (on teste avec > car cosinus est une fonction décroissante)
        vertices_except_lowest.sort {
            Self.cosin_lowest_to_vertex(lowest: lowest_vertex, vertex: $0) > Self.cosin_lowest_to_vertex(lowest: lowest_vertex, vertex: $1)
        }

        
        
//        other_vertices.append(contentsOf: vertices.filter { $0 != lowest_vertex })
        
        
    }
}
