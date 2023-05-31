//
//  AV360Types.swift
//  AV360
//
//  Created by Sajid Nawaz
//  sajidnawaz993@gmail.com

import Foundation

public struct AV360PanningAxis: OptionSet {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }

    static let horizontal = AV360PanningAxis(rawValue: 1 << 0)
    static let vertical = AV360PanningAxis(rawValue: 1 << 1)
}

public enum AV360UserInteractionMethod {
    case gyroscope
    case touch
}
