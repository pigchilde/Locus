import CoreLocation
import Foundation

final class PermissionService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var locationStatus: CLAuthorizationStatus
    @Published private(set) var isRequestingLocationPermission = false
    @Published private(set) var didAuthorizationPromptTimeOut = false

    private let manager = CLLocationManager()
    var onAuthorizationChanged: (() -> Void)?
    var onAuthorizationRequestStarted: (() -> Void)?
    var onAuthorizationRequestFinished: (() -> Void)?

    override init() {
        locationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
    }

    var canReadWiFiName: Bool {
        locationStatus == .authorized || locationStatus == .authorizedAlways
    }

    var isDenied: Bool {
        locationStatus == .denied
            || locationStatus == .restricted
            || didAuthorizationPromptTimeOut
    }

    func requestLocationPermission() {
        guard locationStatus == .notDetermined else {
            onAuthorizationChanged?()
            return
        }

        isRequestingLocationPermission = true
        didAuthorizationPromptTimeOut = false
        onAuthorizationRequestStarted?()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            guard let self, self.locationStatus == .notDetermined else { return }
            self.manager.requestWhenInUseAuthorization()

            // On macOS the authorization sheet is not always presented until
            // the app starts a location request. Coordinates are never retained.
            self.manager.startUpdatingLocation()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
            guard let self, self.locationStatus == .notDetermined else { return }
            self.cancelLocationPermissionRequest(offerSettings: true)
        }
    }

    func cancelLocationPermissionRequest(offerSettings: Bool = false) {
        guard isRequestingLocationPermission else { return }
        isRequestingLocationPermission = false
        didAuthorizationPromptTimeOut = offerSettings
        manager.stopUpdatingLocation()
        onAuthorizationRequestFinished?()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationStatus = manager.authorizationStatus
        if locationStatus != .notDetermined {
            isRequestingLocationPermission = false
            didAuthorizationPromptTimeOut = false
            manager.stopUpdatingLocation()
            onAuthorizationRequestFinished?()
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
        onAuthorizationRequestFinished?()
    }
}
