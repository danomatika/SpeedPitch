//
//  Location.swift
//  SpeedPitch
//
//  Created by Dan Wilcox on 6/24/21.
//  Copyright © 2021 Dan Wilcox. All rights reserved.
//

import UIKit
import CoreLocation

/// location manager event delegate
protocol LocationDelegate {
	func locationAuthorizationRestricted(_ location: Location)
	func locationAuthorizationDenied(_ location: Location)
	func locationDidUpdateSpeed(_ location: Location, speed: Double, accuracy: Double)
}

/// location manager
class Location : NSObject,  CLLocationManagerDelegate {
	let manager = CLLocationManager()
	var delegate: LocationDelegate?

	fileprivate var _isEnabled: Bool = false
	var isEnabled: Bool {
		get {return _isEnabled}
	}

	fileprivate var _initialLocation: Bool = false

	override init() {
		super.init()
		manager.delegate = self
		manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
		manager.distanceFilter = kCLDistanceFilterNone;
		manager.pausesLocationUpdatesAutomatically = false
		manager.allowsBackgroundLocationUpdates = true
	}

	@discardableResult func enable() -> Bool {
		_isEnabled = false
		if CLLocationManager.locationServicesEnabled() {
			_initialLocation = true
			if CLLocationManager.authorizationStatus() == .denied {
				print("Location: denied")
				delegate?.locationAuthorizationDenied(self)
			}
			else if CLLocationManager.authorizationStatus() == .restricted {
				print("Location: restricted")
				delegate?.locationAuthorizationRestricted(self)
			}
			else {
				print("Location: enabled")
				manager.startUpdatingLocation()
				manager.requestWhenInUseAuthorization()
				_isEnabled = true
			}
		}
		else {
			print("Location: disabled or not available on this device")
		}
		return _isEnabled
	}

	@discardableResult func disable() -> Bool {
		if CLLocationManager.locationServicesEnabled() {
			manager.stopUpdatingLocation()
		}
		_isEnabled = false
		return _isEnabled
	}

	// MARK: CLLocationManagerDelegate

	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		var statusString: String
		switch status {
		case .restricted:
			statusString = "restricted"
			break
		case .denied:
			statusString = "denied"
			if CLLocationManager.locationServicesEnabled() {
				manager.stopUpdatingLocation()
			}
			break
		case .authorizedWhenInUse:
			statusString = "when in use"
			break
		case .authorizedAlways:
			statusString = "always"
			break
		case .notDetermined:
			statusString = "not determined"
			break
		default:
			statusString = "unknown"
			break
		}
		print("Location: authorization \(statusString)")
	}

	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		if _initialLocation { // ignore stale initial location when starting
			if let location = locations[0] as CLLocation? {
				if(abs(location.timestamp.timeIntervalSinceNow) > 1.0) {
					_initialLocation = false
					return // dump extra locations until next update
				}
			}
		}
		if self.delegate != nil {
			for location in locations {
				self.delegate?.locationDidUpdateSpeed(
					self,
					speed: max(location.speed * 3.6, -1.0), // convert m/s -> km/h
					accuracy: location.speedAccuracy
				)
			}
		}
	}

	func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
		print("Location: updates paused")
	}

	func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
		print("Location: updates resumed")
	}

	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		print("Location: failed with error \(error)")
	}
}
