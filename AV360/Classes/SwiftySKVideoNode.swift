//
//  SwiftySKVideoNodeDelegate.swift
//  AV360
//
//  Created by Sajid Nawaz
//  sajidnawaz993@gmail.com

import SpriteKit
import AVFoundation

public protocol SwiftySKVideoNodeDelegate: AnyObject {
    func videoNodeShouldAllowPlaybackToBegin(videoNode: SwiftySKVideoNode) -> Bool
}

open class SwiftySKVideoNode: SKVideoNode {

    weak var swiftyDelegate: SwiftySKVideoNodeDelegate?

    func setPaused(paused: Bool) {
        if !paused && swiftyDelegate != nil {
            if swiftyDelegate!.videoNodeShouldAllowPlaybackToBegin(videoNode: self) {
                super.play()
            }
        } else {
            super.pause()
        }
    }

}
