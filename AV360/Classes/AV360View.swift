//
//  AV360View.swift
//  AV360
//
//  Created by Sajid Nawaz
//  sajidnawaz993@gmail.com

import UIKit
import SceneKit
import AVFoundation

public protocol AV360ViewDelegate: AnyObject {
    func didUpdateCompassAngle(withViewController: AV360View, compassAngle: Float)
    func userInitallyMovedCameraViaMethod(withView: AV360View, method: AV360UserInteractionMethod)
}

@inline(__always) func AV360ViewSceneFrameForContainingBounds(containingBounds: CGRect, underlyingSceneSize: CGSize) -> CGRect {
    if underlyingSceneSize.equalTo(CGSize.zero) {
        return containingBounds
    }

    let containingSize = containingBounds.size
    let heightRatio = containingSize.height / underlyingSceneSize.height
    let widthRatio = containingSize.width / underlyingSceneSize.width
    var targetSize: CGSize!
    if heightRatio > widthRatio {
        targetSize = CGSize(width: underlyingSceneSize.width * heightRatio, height: underlyingSceneSize.height * heightRatio)
    } else {
        targetSize = CGSize(width: underlyingSceneSize.width * widthRatio, height: underlyingSceneSize.height * widthRatio)
    }

    var targetFrame = CGRect.zero
    targetFrame.size = targetSize
    targetFrame.origin.x = (containingBounds.size.width - targetSize.width) / 2.0
    targetFrame.origin.y = (containingBounds.size.height - targetSize.height) / 2.0

    return targetFrame
}

@inline(__always) func AV360ViewSceneBoundsForScreenBounds(screenBounds: CGRect) -> CGRect {
    let maxValue = max(screenBounds.size.width, screenBounds.size.height)
    let minValue = min(screenBounds.size.width, screenBounds.size.height)
    return CGRect(x: 0.0, y: 0.0, width: maxValue, height: minValue)
}

open class AV360View: UIView {

    open weak var delegate: AV360ViewDelegate?
    open var player: AVPlayer!
    open var motionManager: AV360MotionManagement!
    open var compassAngle: Float! {
        return cameraController.compassAngle()
    }
    open var panRecognizer: AV360CameraPanGestureRecognizer! {
        return cameraController.panRecognizer
    }
    open var allowedDeviceMotionPanningAxes: AV360PanningAxis {
        set {
            cameraController.allowedDeviceMotionPanningAxes = newValue
        }
        get {
            return cameraController.allowedDeviceMotionPanningAxes
        }
    }
    open var allowedPanGesturePanningAxes: AV360PanningAxis {
        set {
            cameraController.allowedPanGesturePanningAxes = newValue
        }
        get {
            return cameraController.allowedPanGesturePanningAxes
        }
    }
    open var cameraController: AV360CameraController!

    private var underlyingSceneSize: CGSize!
    private var sceneView: SCNView!
    private var playerScene: AV360PlayerScene!

    public init(withFrame frame: CGRect,
                player: AVPlayer,
                motionManager: AV360MotionManagement?) {
        super.init(frame: frame)
        self.player = player
        self.player.automaticallyWaitsToMinimizeStalling = false
        self.motionManager = motionManager
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    open func setup(player: AVPlayer, motionManager: AV360MotionManagement?) {
        let initialSceneFrame = sceneBoundsForScreenBounds(screenBounds: bounds)
        underlyingSceneSize = initialSceneFrame.size
        sceneView = SCNView(frame: initialSceneFrame)
        playerScene = AV360PlayerScene(withAVPlayer: player, view: sceneView)
        self.motionManager = motionManager
        cameraController = AV360CameraController(withView: sceneView, motionManager: self.motionManager)
        cameraController.delegate = self
        weak var weakSelf = self
        cameraController.compassAngleUpdateBlock = { compassAngle in
            guard let strongSelf = weakSelf else {
                return
            }
            strongSelf.delegate?.didUpdateCompassAngle(withViewController: strongSelf,
                                                       compassAngle: strongSelf.compassAngle)
        }

        backgroundColor = UIColor.black
        isOpaque = true

        /// Prevent the edges of the "aspect-fill" resized player scene from being
        /// visible beyond the bounds of self.view.
        clipsToBounds = true

        sceneView.backgroundColor = UIColor.black
        sceneView.isOpaque = true
        sceneView.delegate = self
        addSubview(sceneView)

        sceneView.isPlaying = true

        cameraController.updateCameraFOV(withViewSize: bounds.size)
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        sceneView.frame = AV360ViewSceneFrameForContainingBounds(containingBounds: bounds,
                                                                     underlyingSceneSize: underlyingSceneSize)
    }

    override open func didMoveToWindow() {
        super.didMoveToWindow()
        cameraController.startMotionUpdates()
    }

    open func stopMotionUpdates() {
        cameraController.stopMotionUpdates()
    }

    open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { context in
            SCNTransaction.animationDuration = coordinator.transitionDuration
            self.cameraController.updateCameraFOV(withViewSize: size)
        }) { context in
            if !context.isCancelled {
                SCNTransaction.animationDuration = 0
            }
        }
    }

    open func play() {
        playerScene.play()
    }

    open func pause() {
        playerScene.pause()
    }

    open func reorientVerticalCameraAngleToHorizon(animated: Bool) {
        cameraController.reorientVerticalCameraAngleToHorizon(animated: animated)
    }

    internal func sceneBoundsForScreenBounds(screenBounds: CGRect) -> CGRect {
        let maxValue = max(screenBounds.size.width, screenBounds.size.height)
        let minValue = min(screenBounds.size.width, screenBounds.size.height)
        return CGRect(x: 0.0, y: 0.0, width: maxValue, height: minValue)
    }

    deinit {
        sceneView.delegate = nil
    }

}

extension AV360View: AV360CameraControllerDelegate {

    public func userInitallyMovedCamera(withCameraController controller: AV360CameraController,
                                        cameraMovedViewMethod: AV360UserInteractionMethod) {
        delegate?.userInitallyMovedCameraViaMethod(withView: self, method: cameraMovedViewMethod)
    }

}

extension AV360View: SCNSceneRendererDelegate {

    public func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.cameraController.updateCameraAngleForCurrentDeviceMotion()
        }
    }

}
