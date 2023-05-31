//
//  Float++.swift
//  AV360
//
//  Created by Sajid Nawaz
//  sajidnawaz993@gmail.com

import UIKit

extension Float {

    func getCGFloat() -> CGFloat {
        return CGFloat(self)
    }

}

extension CGFloat {

    func getFloat() -> Float {
        return Float(self)
    }

    func getDouble() -> Double {
        return Double(self)
    }

}
