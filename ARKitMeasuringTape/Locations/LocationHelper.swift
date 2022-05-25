//
//  LocationHelper.swift
//  ARKitMeasuringTape
//
//  Created by Karina gurachevskaya on 24.05.22.
//  Copyright © 2022 Sai Sandeep. All rights reserved.
//

import Foundation
import CoreLocation

struct LocationHelper {
    func coordinates(startingCoordinates: CLLocationCoordinate2D, atDistance: Double, atAngle: Double) -> CLLocationCoordinate2D {
        // https://www.igismap.com/formula-to-find-bearing-or-heading-angle-between-two-points-latitude-longitude/
        //        latitude of second point = la2 = asin(sin la1 * cos Ad + cos la1 * sin Ad * cos θ)
        //        longitude of second point = lo2 = lo1 + atan2(sin θ * sin Ad * cos la1 , cos Ad – sin la1 * sin la2)
                
        let distanceRadians = atDistance / 1_000 / 6371 // 6,371 = Earth's radius in km

        let bearingRadians = degreesToRadians(atAngle)
        let fromLatRadians = degreesToRadians(startingCoordinates.latitude)
        let fromLonRadians = degreesToRadians(startingCoordinates.longitude)

        let toLatRadians = asin(sin(fromLatRadians) * cos(distanceRadians) + cos(fromLatRadians) * sin(distanceRadians) * cos(bearingRadians))
        var toLonRadians = fromLonRadians + atan2(sin(bearingRadians) * sin(distanceRadians) * cos(fromLatRadians), cos(distanceRadians) - sin(fromLatRadians) * sin(toLatRadians));

        toLonRadians = fmod((toLonRadians + 3 * .pi), (2 * .pi)) - .pi

        let lat = radiansToDegrees(toLatRadians)
        let lon = radiansToDegrees(toLonRadians)

        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    private func degreesToRadians(_ x: Double) -> Double {
        return .pi * x / 180.0
    }
    
    private func radiansToDegrees(_ x: Double) -> Double {
        return x * 180.0 / .pi
    }
}
