import Foundation
import CoreLocation

struct StateInfo: Equatable {
    let fullName: String
    let abbreviation: String
}

@MainActor
protocol StateResolverProtocol {
    func resolveState() async -> StateInfo?
}

@MainActor
final class StateResolver: NSObject, StateResolverProtocol, CLLocationManagerDelegate {
    private let locationManager: CLLocationManager
    private let geocoder = CLGeocoder()
    private var authorizationContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?
    private var cachedState: StateInfo?

    override init() {
        locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
    }

    func resolveState() async -> StateInfo? {
        if let cachedState {
            return cachedState
        }
        guard CLLocationManager.locationServicesEnabled() else { return nil }

        var status = locationManager.authorizationStatus
        if status == .notDetermined {
            status = await requestAuthorization()
        }

        guard status == .authorizedWhenInUse || status == .authorizedAlways else { return nil }
        guard let location = await requestLocation() else { return nil }

        let resolvedState = await reverseGeocode(location: location)
        cachedState = resolvedState
        return resolvedState
    }

    private func requestAuthorization() async -> CLAuthorizationStatus {
        await withCheckedContinuation { continuation in
            authorizationContinuation = continuation
            locationManager.requestWhenInUseAuthorization()
        }
    }

    private func requestLocation() async -> CLLocation? {
        await withCheckedContinuation { continuation in
            locationContinuation = continuation
            locationManager.requestLocation()
        }
    }

    private func reverseGeocode(location: CLLocation) async -> StateInfo? {
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            for placemark in placemarks {
                if let administrativeArea = placemark.administrativeArea,
                   let state = StateLookup.info(for: administrativeArea) {
                    return state
                }
            }
        } catch {
            return nil
        }
        return nil
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationContinuation?.resume(returning: manager.authorizationStatus)
            authorizationContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            locationContinuation?.resume(returning: nil)
            locationContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            locationContinuation?.resume(returning: locations.first)
            locationContinuation = nil
        }
    }
}
