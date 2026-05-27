//
//  Models.swift
//  RunningApp
//
//  Created by Karla Pisonic on 22.05.2026..
//

import Foundation
import SwiftData
import CoreLocation
 
@Model
final class Activity {
    var id: UUID
    var date: Date
    var distance: Double
    var duration: TimeInterval
    var ownerProfileID: String
 
    var area: Double = 0
    var isClosed: Bool = false
 
    var coordinateData: [Double]
 
    init(date: Date,
         distance: Double,
         duration: TimeInterval,
         coordinates: [CLLocationCoordinate2D],
         ownerProfileID: String) {
        self.id = UUID()
        self.date = date
        self.distance = distance
        self.duration = duration
        self.ownerProfileID = ownerProfileID
        self.coordinateData = coordinates.flatMap { [$0.latitude, $0.longitude] }
 
        self.isClosed = GeoMath.isClosedLoop(coordinates)
        self.area = self.isClosed ? GeoMath.enclosedArea(coordinates) : 0
    }
 
    var coordinates: [CLLocationCoordinate2D] {
        stride(from: 0, to: coordinateData.count, by: 2).map {
            CLLocationCoordinate2D(latitude: coordinateData[$0], longitude: coordinateData[$0 + 1])
        }
    }
 
    var paceMinPerKm: Double {
        guard distance > 0 else { return 0 }
        return (duration / 60) / (distance / 1000)
    }
 
    var areaDisplay: String {
        guard area > 0 else { return "—" }
        if area >= 10_000 {
            return String(format: "%.2f ha", area / 10_000)
        }
        return String(format: "%.0f m²", area)
    }
}
 
@Model
final class Profile {
    var id: String
    var name: String
    var joinedDate: Date
    var colorHex: String
 
    init(name: String, colorHex: String) {
        self.id = UUID().uuidString
        self.name = name
        self.joinedDate = Date()
        self.colorHex = colorHex
    }
}
