//
//  AV360ViewController.swift
//  AV360
//
//  Created by Sajid Nawaz
//  sajidnawaz993@gmail.com

import UIKit
import SceneKit
import AVFoundation

public protocol AV360ViewControllerDelegate: AnyObject {
    func didUpdateCompassAngle(withViewController: AV360ViewController, compassAngle: Float)
    func userInitallyMovedCameraViaMethod(withViewController: AV360ViewController, method: AV360UserInteractionMethod)
}

@inline(__always) func AV360ViewControllerSceneFrameForContainingBounds(containingBounds: CGRect, underlyingSceneSize: CGSize) -> CGRect {
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

@inline(__always) func AV360ViewControllerSceneBoundsForScreenBounds(screenBounds: CGRect) -> CGRect {
    let maxValue = max(screenBounds.size.width, screenBounds.size.height)
    let minValue = min(screenBounds.size.width, screenBounds.size.height)
    return CGRect(x: 0.0, y: 0.0, width: maxValue, height: minValue)
}

open class AV360ViewController: UIViewController, AV360CameraControllerDelegate {

    open weak var delegate: AV360ViewControllerDelegate?
    open var player: AVPlayer!
    open var motionManager: AV360MotionManagement?
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

    private var underlyingSceneSize: CGSize!
    private var sceneView: SCNView!
    private var playerScene: AV360PlayerScene!
    private var cameraController: AV360CameraController!
    private var playerView = UIView()

    public init(withAVPlayer player: AVPlayer, motionManager: AV360MotionManagement?) {
        super.init(nibName: nil, bundle: nil)
        self.player = player
        self.player.automaticallyWaitsToMinimizeStalling = false
        self.motionManager = motionManager
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    fileprivate func addPlayerViewConstraints() {
        let margins = view.layoutMarginsGuide
        NSLayoutConstraint.activate([
            playerView.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: margins.trailingAnchor)
            ])
        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraintEqualToSystemSpacingBelow(guide.topAnchor, multiplier: 1.0),
            guide.bottomAnchor.constraintEqualToSystemSpacingBelow(playerView.bottomAnchor, multiplier: 1.0)
            ])
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

        assert(player != nil, "AV360ViewController should have an AVPlayer instance")

        setup(player: player, motionManager: motionManager)

        view.backgroundColor = UIColor.black
        view.isOpaque = true
        view.clipsToBounds = true

        playerView.isUserInteractionEnabled = true
      //  playerView.translatesAutoresizingMaskIntoConstraints = false
        playerView.frame = UIScreen.main.bounds
        view.addSubview(playerView)

     //   addPlayerViewConstraints()

        sceneView.backgroundColor = UIColor.black
        sceneView.isOpaque = true
        sceneView.delegate = self
        playerView.addSubview(sceneView)

        sceneView.isPlaying = true

        cameraController.updateCameraFOV(withViewSize: UIScreen.main.bounds.size)
    }

    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sceneView.frame = AV360ViewControllerSceneFrameForContainingBounds(containingBounds: view.bounds,
                                                                               underlyingSceneSize: underlyingSceneSize)
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cameraController.startMotionUpdates()
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cameraController.stopMotionUpdates()
    }

    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
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

    internal func setup(player: AVPlayer, motionManager: AV360MotionManagement?) {
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = playerView.layer.bounds
        playerView.layer.addSublayer(playerLayer)

        let screenBounds = playerView.bounds
        let initialSceneFrame = sceneBoundsForScreenBounds(screenBounds: screenBounds)
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
    }

    public func userInitallyMovedCamera(withCameraController controller: AV360CameraController, cameraMovedViewMethod: AV360UserInteractionMethod) {
        delegate?.userInitallyMovedCameraViaMethod(withViewController: self, method: cameraMovedViewMethod)
    }

    deinit {
        sceneView.delegate = nil
    }

}

extension AV360ViewController: SCNSceneRendererDelegate {

    public func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.cameraController.updateCameraAngleForCurrentDeviceMotion()
        }
    }

}
