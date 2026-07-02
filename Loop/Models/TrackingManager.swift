//
//  TrackingManager.swift
//  RunningApp
//
//  Created by Karla Pisonic on 22.05.2026..
//

import Foundation
import CoreLocation
import Combine

@MainActor
final class TrackingManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    enum State {
        case idle, recording, paused
    }

    @Published var state: State = .idle
    @Published var route: [CLLocationCoordinate2D] = []
    @Published var totalDistance: CLLocationDistance = 0
    @Published var elapsedTime: TimeInterval = 0
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var hasFix = false

    private(set) var startDate: Date?

    private var lastLocation: CLLocation?
    private var accumulatedTime: TimeInterval = 0
    private var segmentStart: Date?
    private var timer: Timer?
    private var didRequestAlwaysAuthorization = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.activityType = .fitness
        manager.distanceFilter = 5
        manager.pausesLocationUpdatesAutomatically = false
    }

    func requestPermission() {
        updateAuthorization(manager.authorizationStatus)
    }

    func start() {
        requestPermission()
        guard isLocationAuthorized else { return }
        requestBackgroundPermissionIfNeeded()
        route.removeAll()
        totalDistance = 0
        elapsedTime = 0
        accumulatedTime = 0
        lastLocation = nil
        startDate = Date()
        segmentStart = Date()
        state = .recording
        startTimer()
    }

    func pause() {
        guard state == .recording else { return }

        if let seg = segmentStart {
            accumulatedTime += Date().timeIntervalSince(seg)
        }

        segmentStart = nil
        lastLocation = nil
        state = .paused
        timer?.invalidate()
    }

    func resume() {
        guard state == .paused else { return }
        segmentStart = Date()
        state = .recording
        startTimer()
    }

    func stop() {
        if let seg = segmentStart {
            accumulatedTime += Date().timeIntervalSince(seg)
        }
        elapsedTime = accumulatedTime
        segmentStart = nil
        state = .idle
        timer?.invalidate()
        timer = nil
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let seg = self.segmentStart else { return }
                self.elapsedTime = self.accumulatedTime + Date().timeIntervalSince(seg)
            }
        }
    }

    var paceMinPerKm: Double {
        guard totalDistance > 0 else { return 0 }
        return (elapsedTime / 60) / (totalDistance / 1000)
    }

    private var isLocationAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    private func updateAuthorization(_ status: CLAuthorizationStatus) {
        authorizationStatus = status
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways:
            // Only enable background updates once we actually hold Always authorization.
            manager.allowsBackgroundLocationUpdates = true
            manager.startUpdatingLocation()
        case .authorizedWhenInUse:
            manager.allowsBackgroundLocationUpdates = false
            manager.startUpdatingLocation()
        case .denied, .restricted:
            manager.allowsBackgroundLocationUpdates = false
            manager.stopUpdatingLocation()
            hasFix = false
        @unknown default:
            manager.allowsBackgroundLocationUpdates = false
            manager.stopUpdatingLocation()
            hasFix = false
        }
    }

    private func requestBackgroundPermissionIfNeeded() {
        guard authorizationStatus == .authorizedWhenInUse,
              !didRequestAlwaysAuthorization else { return }
        didRequestAlwaysAuthorization = true
        manager.requestAlwaysAuthorization()
    }

    // CoreLocation does not guarantee delegate callbacks arrive on the main thread,
    // so we mark these nonisolated and hop to the main actor ourselves before
    // touching any @Published state.
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.updateAuthorization(manager.authorizationStatus)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            for loc in locations {
                guard loc.horizontalAccuracy >= 0, loc.horizontalAccuracy < 20 else { continue }
                guard abs(loc.timestamp.timeIntervalSinceNow) < 2 else { continue }

                self.hasFix = true

                guard self.state == .recording else {
                    self.lastLocation = loc
                    continue
                }

                if let last = self.lastLocation {
                    let segment  = loc.distance(from: last)
                    let interval = loc.timestamp.timeIntervalSince(last.timestamp)

                    if interval > 0, segment / interval > 9 { continue }
                    if segment < 2 { continue }

                    self.totalDistance += segment
                    self.route.append(loc.coordinate)
                } else {
                    self.route.append(loc.coordinate)
                }
                self.lastLocation = loc
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error \(error.localizedDescription)")
    }
}
