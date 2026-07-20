import CoreLocation
import Foundation

final class PermissionService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var locationStatus: CLAuthorizationStatus
    @Published private(set) var isRequestingLocationPermission = false

    private let manager = CLLocationManager()
    var onAuthorizationChanged: (() -> Void)?

    override init() {
        locationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
    }

    var canReadWiFiName: Bool {
        locationStatus == .authorized || locationStatus == .authorizedAlways
    }

    var isDenied: Bool {
        locationStatus == .denied || locationStatus == .restricted
    }

    func requestLocationPermission() {
        guard locationStatus == .notDetermined else {
            onAuthorizationChanged?()
            return
        }

        isRequestingLocationPermission = true
        manager.requestWhenInUseAuthorization()

        // On macOS the authorization sheet is not always presented until the
        // app actually starts a location request. We immediately stop again
        // after the authorization callback and never retain any coordinates.
        manager.startUpdatingLocation()

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self, self.locationStatus == .notDetermined else { return }
            self.isRequestingLocationPermission = false
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationStatus = manager.authorizationStatus
        if locationStatus != .notDetermined {
            isRequestingLocationPermission = false
            manager.stopUpdatingLocation()
        }
        onAuthorizationChanged?()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        manager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard locationStatus != .notDetermined else { return }
        isRequestingLocationPermission = false
        manager.stopUpdatingLocation()
    }
}
