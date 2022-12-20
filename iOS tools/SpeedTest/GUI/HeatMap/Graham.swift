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

    private static func vector(_ p0: CGPoint, _ p1: CGPoint) -> CGPoint {
        return CGPoint(x: p1.x - p0.x, y: p1.y - p0.y)
    }

    // positif si on tourne dans le sens trigo
    private static func vector_product(_ v0: CGPoint, _ v1: CGPoint) -> Double {
        return v0.x * v1.y - v0.y * v1.x
    }

    public func computeConvexHull() {
        var lowest_vertex = vertices[0]
        let _ = vertices.map {
            if $0.y < lowest_vertex.y || ($0.y == lowest_vertex.y && $0.x < lowest_vertex.x) { lowest_vertex = $0 }}
        
        var vertices_except_lowest = vertices.filter { $0 != lowest_vertex }

        // tri dans le sens trigo (on teste avec > car cosinus est une fonction décroissante)
        vertices_except_lowest.sort {
            Self.cosin_lowest_to_vertex(lowest: lowest_vertex, vertex: $0) > Self.cosin_lowest_to_vertex(lowest: lowest_vertex, vertex: $1)
        }
        // on supprime ceux qui sont alignés sauf le plus long par groupe d'alignés
        // trouver comment modifier un tableau en cours de parcours : cf iterator d'une collection
        

        var stack = [ lowest_vertex, vertices_except_lowest[0] ]
        vertices_except_lowest.removeFirst()
        for p2 in vertices_except_lowest {
            while true {
                print(stack)
                let p0 = stack[stack.count - 2]
                let p1 = stack[stack.count - 1]
                
                print("p0=\(p0) p1=\(p1) p2=\(p2)")
                
                let orientation = Self.vector_product(Self.vector(p0, p1), Self.vector(p1, p2))
                print("vector product=\(orientation)")
                
                if orientation == 0 {
                    
                } else if orientation > 0 {
                    stack.append(p2)
                    break
                } else {
                    _ = stack.popLast()
                }
            }
        }

        print(stack)
        
    }
}
