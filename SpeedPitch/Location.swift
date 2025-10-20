//
//  Location.swift
//  SpeedPitch
//
//  Created by Dan Wilcox on 6/24/21.
//  Copyright © 2021 Dan Wilcox. All rights reserved.
//

import UIKit
import CoreLocation

/// location manager event delegate, speed is m/s
protocol LocationDelegate {
	func locationAuthorizationRestricted(_ location: Location)
	func locationAuthorizationDenied(_ location: Location)
	func locationDidUpdateSpeed(_ location: Location, speed: Double, accuracy: Double)
}

/// location manager
class Location : NSObject,  CLLocationManagerDelegate {

	let manager = CLLocationManager()
	var delegate: LocationDelegate?
	var isEnabled: Bool {
		get {return _isEnabled}
	}

	fileprivate var _isEnabled: Bool = false
	fileprivate var _initialLocation: Bool = false

	override init() {
		super.init()
		manager.delegate = self
		manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
		manager.distanceFilter = kCLDistanceFilterNone;
		manager.pausesLocationUpdatesAutomatically = false
		manager.allowsBackgroundLocationUpdates = true
	}

	func enable() {
		_isEnabled = false
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

	func disable() {
		manager.stopUpdatingLocation()
		_isEnabled = false
	}

	// MARK: CLLocationManagerDelegate

	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		switch status {
		case .restricted:
			print("Location: authorization restricted")
			break
		case .denied:
			print("Location: authorization denied")
			break
		case .authorizedWhenInUse:
			print("Location: authorization when in use")
			manager.startUpdatingLocation()
			_isEnabled = true
			return
		case .authorizedAlways:
			print("Location: authorization always")
			manager.startUpdatingLocation()
			_isEnabled = true
			return
		case .notDetermined:
			print("Location: authorization not determined")
			break
		default:
			print("Location: authorization unknown")
			break
		}
		_isEnabled = false
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
		if delegate != nil {
			for location in locations {
				delegate?.locationDidUpdateSpeed(
					self,
					speed: location.speed,
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

}
