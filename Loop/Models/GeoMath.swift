//
//  Geomath.swift
//  RunningApp
//
//  Created by Karla Pisonic on 26.05.2026..
//

import Foundation
import CoreLocation

enum GeoMath {
  
    static let closureThreshold: CLLocationDistance = 50
 
    static func isClosedLoop(_ coords: [CLLocationCoordinate2D]) -> Bool {
        guard coords.count >= 4, let first = coords.first, let last = coords.last else {
            return false
        }
        let start = CLLocation(latitude: first.latitude, longitude: first.longitude)
        let end = CLLocation(latitude: last.latitude,  longitude: last.longitude)
        return end.distance(from: start) <= closureThreshold
    }
 
    static func enclosedArea(_ coords: [CLLocationCoordinate2D]) -> Double {
        guard coords.count >= 3 else { return 0 }
 
        let meanLat = coords.map(\.latitude).reduce(0, +) / Double(coords.count)
        let latRad = meanLat * .pi / 180
 
        let metersPerDegLat = 111_320.0
        let metersPerDegLon = 111_320.0 * cos(latRad)
 
        guard let origin = coords.first else { return 0 }
        let points: [(x: Double, y: Double)] = coords.map { c in
            let x = (c.longitude - origin.longitude) * metersPerDegLon
            let y = (c.latitude  - origin.latitude)  * metersPerDegLat
            return (x, y)
        }
 
        var sum = 0.0
        for i in 0..<points.count {
            let a = points[i]
            let b = points[(i + 1) % points.count]   
            sum += (a.x * b.y) - (b.x * a.y)
        }
        return abs(sum) / 2.0
    }
}
