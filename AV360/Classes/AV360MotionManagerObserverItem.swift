//
//  AV360MotionManagerObserverItem.swift
//  AV360
//
//  Created by Sajid Nawaz
//  sajidnawaz993@gmail.com

import Foundation

internal class AV360MotionManagerObserverItem {

    internal let token: UUID
    internal let preferredUpdateInterval: TimeInterval

    public init(withPreferredUpdateInterval interval: TimeInterval) {
        self.token = UUID()
        self.preferredUpdateInterval = interval
    }

}
