//
//  AV360MotionManager.swift
//  AV360
//
//  Created by Sajid Nawaz
//  sajidnawaz993@gmail.com

import CoreMotion

/**
 Expectations that must be fulfilled by an appliation-wide "wrapper" around
 CMMotionManager for AV360Player's use.

 Per Apple's documentation, it is recommended that an application will have no
 more than one `CMMotionManager`, otherwise performance could degrade.

 A host application is free to provide a custom class conforming to
 `AV360MotionManagement`. If your application does not use a CMMotionManager
 outside of AV360Player, I recommend that you use the shared instance of
 `AV360MotionManager`, a ready-made class that already conforms to
 `AV360MotionManagement`.
 */
public protocol AV360MotionManagement {

    /**
     Determines whether device motion hardware and APIs are available.
     */
    var deviceMotionAvailable: Bool { get }
    /**
     Determines whether the receiver is currently providing motion updates.
     */
    var deviceMotionActive: Bool { get }
    /**
     Returns the latest sample of device motion data, or nil if none is available.
     */
    var deviceMotion: CMDeviceMotion? { get }

    /**
     Begins updating device motion, if it hasn't begun already.

     - Parameter preferredUpdateInterval: The requested update interval. The actual
     interval used should resolve to the shortest requested interval among the
     active requests.

     - Returns: A token which the caller should use to balance this call with a
     call to `stopUpdating`.

     - Warning: Callers should balance a call to `startUpdating` with a call to
     `stopUpdating`, otherwise device motion will continue to be updated indefinitely.
     */
    func startUpdating(preferredUpdateInterval: TimeInterval) -> UUID
    /**
     Requests that device motion updates be stopped. If there are other active
     observers that still require device motion updates, motion updates will not be
     stopped.

     The device motion update interval may be raised or lowered after a call to
     `stopUpdating`, as the interval will resolve to the shortest interval among
     the active observers.

     - Parameter token: The token received from a call to `startUpdating`.

     - Warning: Callers should balance a call to `startUpdating` with a call to
     `stopUpdating`, otherwise device motion will continue to be updated indefinitely.
     */
    func stopUpdating(token: UUID)

}

/**
 A reference implementation of `AV360MotionManagement`. Your host application
 can provide another implementation if so desired.

 - SeeAlso: `AV360ViewController`.
 */
open class AV360MotionManager: AV360MotionManagement {

    /**
     The shared, app-wide `AV360MotionManager`.
     */
    public static let shared = AV360MotionManager()

    internal var observerItems = [UUID: AV360MotionManagerObserverItem]()
    internal let motionManager = CMMotionManager()
    internal static let preferredUpdateInterval = TimeInterval(1.0 / 60.0)

    // MARK: Init

    private init() {
        motionManager.deviceMotionUpdateInterval = AV360MotionManager.preferredUpdateInterval
    }

    // MARK: AV360MotionManagement

    public var deviceMotionAvailable: Bool {
        return motionManager.isDeviceMotionAvailable
    }

    public var deviceMotionActive: Bool {
        return motionManager.isDeviceMotionActive
    }

    public var deviceMotion: CMDeviceMotion? {
        return motionManager.deviceMotion
    }

    public func startUpdating(preferredUpdateInterval: TimeInterval) -> UUID {
        assert(OperationQueue.current == OperationQueue.main, "AV360MotionManager should be used on main queue")
        let previousCount = observerItems.count
        let observerItem = AV360MotionManagerObserverItem(withPreferredUpdateInterval: preferredUpdateInterval)
        observerItems[observerItem.token] = observerItem
        motionManager.deviceMotionUpdateInterval = resolvedUpdateInterval()
        if observerItems.count > 0 && previousCount == 0 {
            motionManager.startDeviceMotionUpdates()
        }
        return observerItem.token
    }

    public func stopUpdating(token: UUID) {
        assert(OperationQueue.current == OperationQueue.main, "AV360MotionManager should be used on main queue")
        let previousCount = observerItems.count
        observerItems.removeValue(forKey: token)
        motionManager.deviceMotionUpdateInterval = resolvedUpdateInterval()
        if observerItems.count > 0 && previousCount == 0 {
            motionManager.stopDeviceMotionUpdates()
        }
    }

    // MARK: Internal

    internal func numberOfObservers() -> Int {
        return observerItems.count
    }

    internal func resolvedUpdateInterval() -> TimeInterval {
        let observerItemValues = observerItems.values
        if observerItemValues.isEmpty {
            return AV360MotionManager.preferredUpdateInterval
        }
        let item = observerItemValues.min { $0.preferredUpdateInterval > $1.preferredUpdateInterval }
        if let item = item {
            return item.preferredUpdateInterval
        }
        return AV360MotionManager.preferredUpdateInterval
    }

}
