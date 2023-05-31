//
//  AV360PlayerScene.swift
//  AV360
//
//  Created by Sajid Nawaz
//  sajidnawaz993@gmail.com

import SceneKit
import SpriteKit
import AVFoundation

open class AV360PlayerScene: SCNScene {

    public let camera = SCNCamera()
    private var videoPlaybackIsPaused: Bool!
    private var videoNode: SwiftySKVideoNode!
    private var cameraNode: SCNNode! {
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3Make(0.0, 0.0, 0.0)
        return cameraNode
    }
    private var player: AVPlayer!

    public init(withAVPlayer player: AVPlayer, view: SCNView) {
        super.init()
        self.videoPlaybackIsPaused = true
        self.player = player
        self.rootNode.addChildNode(self.cameraNode)
        let scene = getScene()
        videoNode = getVideoNode(withPlayer: self.player, scene: scene)
        scene.addChild(videoNode)
        self.rootNode.addChildNode(getSphereNode(scene: scene))
        view.scene = self
        view.pointOfView = cameraNode
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func play() {
        videoPlaybackIsPaused = false
        player.play()
        videoNode.isPaused = false
    }

    func pause() {
        videoPlaybackIsPaused = true
        player.pause()
        videoNode.isPaused = true
    }

    internal func getScene() -> SKScene {
        let assetTrack = player.currentItem?.asset.tracks(withMediaType: .video).first
        let assetDimensions = assetTrack != nil ? __CGSizeApplyAffineTransform(assetTrack!.naturalSize, assetTrack!.preferredTransform) :
            CGSize(width: 1280.0, height: 1280.0)
        let scene = SKScene(size: CGSize(width: fabsf(assetDimensions.width.getFloat()).getCGFloat(),
                                         height: fabsf(assetDimensions.height.getFloat()).getCGFloat()))
        scene.shouldRasterize = true
        scene.scaleMode = .aspectFit
        scene.addChild(getVideoNode(withPlayer: player, scene: scene))
        return scene
    }

    internal func getVideoNode(withPlayer player: AVPlayer, scene: SKScene) -> SwiftySKVideoNode {
        let videoNode = SwiftySKVideoNode(avPlayer: player)
        videoNode.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        videoNode.size = scene.size
        videoNode.yScale = -1
        videoNode.xScale = -1
        videoNode.swiftyDelegate = self
        return videoNode
    }

    internal func getSphereNode(scene: SKScene) -> SCNNode {
        let sphereNode = SCNNode()
        sphereNode.position = SCNVector3Make(0.0, 0.0, 0.0)
        sphereNode.geometry = SCNSphere(radius: 100.0)
        sphereNode.geometry?.firstMaterial?.diffuse.contents = scene
        sphereNode.geometry?.firstMaterial?.diffuse.minificationFilter = .linear
        sphereNode.geometry?.firstMaterial?.diffuse.magnificationFilter = .linear
        sphereNode.geometry?.firstMaterial?.isDoubleSided = true
        return sphereNode
    }

}

extension AV360PlayerScene: SwiftySKVideoNodeDelegate {

    public func videoNodeShouldAllowPlaybackToBegin(videoNode: SwiftySKVideoNode) -> Bool {
        return !self.videoPlaybackIsPaused
    }

}
