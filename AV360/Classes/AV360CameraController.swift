//
//  AV360CameraController.swift
//  AV360
//
//  Created by Sajid Nawaz
//  sajidnawaz993@gmail.com

import UIKit
import SceneKit
import CoreMotion

public protocol AV360CameraControllerDelegate: AnyObject {
    /**
     Called the first time the user moves the camera.

     - Note: This method is called synchronously when the camera angle is updated; an implementation should return quickly to avoid performance implications.

     - Parameter controller: The camera controller with which the user interacted.
     - Parameter method: The method by which the user moved the camera.
     */
    func userInitallyMovedCamera(withCameraController controller: AV360CameraController,
                                 cameraMovedViewMethod: AV360UserInteractionMethod)
}

@inline(__always) func distance(a: CGPoint, b: CGPoint) -> CGFloat {
    return sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2))
}

@inline(__always) func subtractPoints(a: CGPoint, b: CGPoint) -> CGPoint {
    return CGPoint(x: b.x - a.x, y: b.y - a.y)
}

/**
 The block type used for compass angle updates.

 - Parameter compassAngle: The compass angle in radians.
 */
public typealias AV360CompassAngleUpdateBlock = (_ compassAngle: Float) -> (Void)

open class AV360CameraController: NSObject, UIGestureRecognizerDelegate {

    /**
     The delegate of the controller.
     */
    open weak var delegate: AV360CameraControllerDelegate?
    /**
     A block invoked whenever the compass angle has been updated.

     - Note: This method is called synchronously from SCNSceneRendererDelegate. Its implementation should return quickly to avoid performance implications.
     */
    open var compassAngleUpdateBlock: AV360CompassAngleUpdateBlock?
    open var panRecognizer: AV360CameraPanGestureRecognizer!
    // Stored property
    private var deviceMotionPanningAxes: AV360PanningAxis!
    // Computed Property
    open var allowedDeviceMotionPanningAxes: AV360PanningAxis! {
        set {
            if deviceMotionPanningAxes != newValue {
                deviceMotionPanningAxes = newValue
                let result = AV360UpdatedPositionAndAnglesForAllowedAxes(position: self.currentPosition,
                                                                             allowedPanningAxes: deviceMotionPanningAxes)
                currentPosition = result.position
                pointOfView.eulerAngles = result.eulerAngles
            }
        }
        get {
            return deviceMotionPanningAxes
        }
    }
    // Stored property
    private var panGesturePanningAxes: AV360PanningAxis!
    // Computed Property
    open var allowedPanGesturePanningAxes: AV360PanningAxis! {
        set {
            if panGesturePanningAxes != newValue {
                panGesturePanningAxes = newValue
                let result = AV360UpdatedPositionAndAnglesForAllowedAxes(position: self.currentPosition,
                                                                             allowedPanningAxes: panGesturePanningAxes)
                currentPosition = result.position
                pointOfView.eulerAngles = result.eulerAngles
            }

        }
        get {
            return panGesturePanningAxes
        }
    }

    // private variables
    internal var view: SCNView!
    internal var motionManager: AV360MotionManagement!
    internal var motionUpdateToken: UUID?
    internal var pointOfView: SCNNode!
    internal var rotateStart: CGPoint!
    internal var rotateCurrent: CGPoint!
    internal var rotateDelta: CGPoint!
    internal var currentPosition: CGPoint!
    internal var isAnimatingReorientation = false
    internal var hasReportedInitialCameraMovement = false
    internal static let minimalRotationDistanceToReport = CGFloat(0.75)

    private override init() { }

    /**
     Designated initializer.

     - Parameter view: The view whose camera AV360CameraController will manage.

     - Parameter motionManager: A class conforming to AV360MotionManagement. Ideally the
     same motion manager should be shared throughout an application, since multiple
     active managers can degrade performance.

     - SeeAlso: `AV360MotionManagement`
     */
    init(withView view: SCNView, motionManager: AV360MotionManagement?) {
        super.init()

        assert(view.pointOfView != nil, "AV360CameraController must be initialized with a view with a non-nil pointOfView node.")
        assert(view.pointOfView?.camera != nil, "AV360CameraController must be initialized with a view with a non-nil camera node for view.pointOfView.")

        pointOfView = view.pointOfView
        self.view = view
        currentPosition = CGPoint(x: 3.14, y: 0.0)
        allowedDeviceMotionPanningAxes = AV360PanningAxis(rawValue: AV360PanningAxis.horizontal.rawValue | AV360PanningAxis.vertical.rawValue)
        allowedPanGesturePanningAxes = AV360PanningAxis(rawValue: AV360PanningAxis.horizontal.rawValue | AV360PanningAxis.vertical.rawValue)

        panRecognizer = AV360CameraPanGestureRecognizer(target: self, action: #selector(AV360CameraController.handlePan(recognizer:)))
        panRecognizer.delegate = self
        self.view.addGestureRecognizer(panRecognizer)

        self.motionManager = motionManager
        hasReportedInitialCameraMovement = false
    }

    open func startMotionUpdates() {
        guard let motionManager = self.motionManager else {
            return
        }
        let preferredMotionUpdateInterval = TimeInterval(1.0 / 60.0)
        motionUpdateToken = motionManager.startUpdating(preferredUpdateInterval: preferredMotionUpdateInterval)
    }

    open func stopMotionUpdates() {
        guard let motionManager = self.motionManager, let motionUpdateToken = self.motionUpdateToken else {
            return
        }
        motionManager.stopUpdating(token: motionUpdateToken)
        self.motionUpdateToken = nil
    }

    /**
     Returns the current compass angle in radians
     */
    func compassAngle() -> Float {
        return AV360CompassAngleForEulerAngles(eulerAngles: pointOfView.eulerAngles)
    }

    @objc open func handlePan(recognizer: UIPanGestureRecognizer) {
        if self.isAnimatingReorientation {
            return
        }

        let point = recognizer.location(in: view)
        switch recognizer.state {
        case .began:
            rotateStart = point
        case .changed:
            rotateCurrent = point
            rotateDelta = subtractPoints(a: self.rotateStart, b: self.rotateCurrent)
            rotateStart = rotateCurrent
            let result = AV360PanGestureChangeCalculation(position: currentPosition,
                                                              rotateDelta: rotateDelta,
                                                              viewSize: view.bounds.size,
                                                              allowedPanningAxes: allowedPanGesturePanningAxes)
            currentPosition = result.position
            pointOfView.eulerAngles = result.eulerAngles
            compassAngleUpdateBlock?(compassAngle())
            reportInitialCameraMovementIfNeeded(withMethod: .touch)
        default:
            break
        }
    }

    /**
     Updates the camera angle based on the current device motion. It's assumed that this method will be called
     many times a second during SceneKit rendering updates.
     */
    func updateCameraAngleForCurrentDeviceMotion() {
        guard let motionManager = self.motionManager else {
            return
        }

        if isAnimatingReorientation {
            return
        }

        guard let rotationRate = motionManager.deviceMotion?.rotationRate else {
            return
        }
        let orientation =  UIWindow.orientation
        let result = AV360DeviceMotionCalculation(position: currentPosition,
                                                      rotationRate: rotationRate,
                                                      orientation: orientation,
                                                      allowedPanningAxes: allowedDeviceMotionPanningAxes,
                                                      noiseThreshold: Double(AV360EulerAngleCalculationNoiseThresholdDefault))
        currentPosition = result.position
        pointOfView.eulerAngles = result.eulerAngles
        compassAngleUpdateBlock?(compassAngle())

        if distance(a: CGPoint.zero, b: currentPosition) > AV360CameraController.minimalRotationDistanceToReport {
            reportInitialCameraMovementIfNeeded(withMethod: .gyroscope)
        }
    }

    /**
     Updates the yFov of the camera to provide the optimal viewing angle for a given view size. Portrait videos will use a wider angle than landscape videos.

     - Parameter viewSize: `AV360ViewController` view size
     */
    func updateCameraFOV(withViewSize viewSize: CGSize) {
        pointOfView.camera?.fieldOfView = AV360OptimalYFovForViewSize(viewSize: viewSize)
    }

    /**
     Reorients the camera's vertical angle component so it's pointing directly at the horizon.

     - Parameter animated: Passing `YES` will animate the change with a standard duration.
     */
    func reorientVerticalCameraAngleToHorizon(animated: Bool) {
        if animated {
            isAnimatingReorientation = true
            SCNTransaction.begin()
            SCNTransaction.animationDuration = CATransaction.animationDuration()
        }

        var position = currentPosition
        position?.y = 0
        currentPosition = position

        var eulerAngles = pointOfView.eulerAngles
        eulerAngles.x = 0
        pointOfView.eulerAngles = eulerAngles

        if animated {
            SCNTransaction.completionBlock = {
                SCNTransaction.animationDuration = 0
                self.isAnimatingReorientation = false
            }
            SCNTransaction.commit()
        }
    }

    func reportInitialCameraMovementIfNeeded(withMethod method: AV360UserInteractionMethod) {
        if !hasReportedInitialCameraMovement {
            hasReportedInitialCameraMovement = true
            delegate?.userInitallyMovedCamera(withCameraController: self, cameraMovedViewMethod: method)
        }
    }

}
