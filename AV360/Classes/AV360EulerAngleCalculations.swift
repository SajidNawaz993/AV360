//
//  AV360EulerAngleCalculations.swift
//  AV360
//
//  Created by Sajid Nawaz
//  sajidnawaz993@gmail.com

import SceneKit
import CoreMotion

struct AV360EulerAngleCalculationResult {
    var position: CGPoint!
    var eulerAngles: SCNVector3!
}

let AV360EulerAngleCalculationNoiseThresholdDefault = CGFloat(0.12)
let AV360EulerAngleCalculationDefaultReferenceCompassAngle = Float(3.14)

let AV360EulerAngleCalculationRotationRateDampingFactor = Double(0.02)
let AV360EulerAngleCalculationYFovDefault = CGFloat(60.0)
let AV360EulerAngleCalculationYFovMin = CGFloat(40.0)
let AV360EulerAngleCalculationYFovMax = CGFloat(120.0)
let AV360EulerAngleCalculationYFovFunctionSlope = CGFloat(-33.01365882011044)
let AV360EulerAngleCalculationYFovFunctionConstant = CGFloat(118.599244406)

// MARK: Inline Functions

@inline(__always) func AV360EulerAngleCalculationResultMake(position: CGPoint, eulerAngles: SCNVector3) -> AV360EulerAngleCalculationResult {
    var result = AV360EulerAngleCalculationResult()
    result.position = position
    result.eulerAngles = eulerAngles
    return result
}

@inline(__always) func AV360AdjustPositionForAllowedAxes(position: CGPoint, allowedPanningAxes: AV360PanningAxis) -> CGPoint {
    var position = position
    let suppressXaxis = (UInt8(allowedPanningAxes.rawValue) & UInt8(AV360PanningAxis.horizontal.rawValue)) == 0
    let suppressYaxis = (UInt8(allowedPanningAxes.rawValue) & UInt8(AV360PanningAxis.vertical.rawValue)) == 0
    if suppressXaxis == true {
        position.x = 0
    }
    if suppressYaxis == true {
        position.y = 0
    }
    return position
}

@inline(__always) func AV360UnitRotationForCameraRotation(cameraRotation: Float) -> Float {
    let oneRotation = Float(2.0 * .pi)
    let rawResult = fmodf(cameraRotation, oneRotation)
    let accuracy = Float(0.0001)
    let difference = Float(oneRotation - fabsf(rawResult))
    let wrappedAround = (difference < accuracy) ? 0 : rawResult
    return wrappedAround
}

@inline(__always) func AV360Clamp(x: CGFloat, low: CGFloat, high: CGFloat) -> CGFloat {
    return (((x) > (high)) ? (high) : (((x) < (low)) ? (low) : (x)))
}

// MARK: Calculations

func AV360UpdatedPositionAndAnglesForAllowedAxes(position: CGPoint,
                                                     allowedPanningAxes: AV360PanningAxis) -> AV360EulerAngleCalculationResult {
    let position = AV360AdjustPositionForAllowedAxes(position: position, allowedPanningAxes: allowedPanningAxes)
    let eulerAngles = SCNVector3Make(position.y.getFloat(), position.x.getFloat(), 0)
    return AV360EulerAngleCalculationResult(position: position, eulerAngles: eulerAngles)
}

func AV360DeviceMotionCalculation(position: CGPoint,
                                      rotationRate: CMRotationRate,
                                      orientation: UIInterfaceOrientation,
                                      allowedPanningAxes: AV360PanningAxis,
                                      noiseThreshold: Double) -> AV360EulerAngleCalculationResult {
    var rotationRate = rotationRate

    if fabs(rotationRate.x) < noiseThreshold {
        rotationRate.x = 0
    }
    if fabs(rotationRate.y) < noiseThreshold {
        rotationRate.y = 0
    }

    var position = position
    if orientation.isLandscape {
        if orientation == .landscapeLeft {
            position = CGPoint(x: position.x + CGFloat(rotationRate.x * AV360EulerAngleCalculationRotationRateDampingFactor * -1),
                               y: position.y + CGFloat(rotationRate.y * AV360EulerAngleCalculationRotationRateDampingFactor))
        } else {
            position = CGPoint(x: position.x + CGFloat(rotationRate.x * AV360EulerAngleCalculationRotationRateDampingFactor),
                                   y: position.y + CGFloat(rotationRate.y * AV360EulerAngleCalculationRotationRateDampingFactor * -1))
        }
    } else {
        position = CGPoint(x: position.x + CGFloat(rotationRate.y * AV360EulerAngleCalculationRotationRateDampingFactor),
                           y: position.y - CGFloat(rotationRate.x * AV360EulerAngleCalculationRotationRateDampingFactor * -1))
    }
    position = CGPoint(x: position.x,
                       y: AV360Clamp(x: position.y, low: -.pi / 2, high: .pi / 2))
    position = AV360AdjustPositionForAllowedAxes(position: position, allowedPanningAxes: allowedPanningAxes)

    let eulerAngles = SCNVector3Make(position.y.getFloat(), position.x.getFloat(), 0)
    return AV360EulerAngleCalculationResultMake(position: position, eulerAngles: eulerAngles)
}

func AV360PanGestureChangeCalculation(position: CGPoint,
                                          rotateDelta: CGPoint,
                                          viewSize: CGSize,
                                          allowedPanningAxes: AV360PanningAxis) -> AV360EulerAngleCalculationResult {
    // The y multiplier is 0.4 and not 0.5 because 0.5 felt too uncomfortable.
    var position = CGPoint(x: position.x + 2 * .pi * rotateDelta.x / viewSize.width * 0.5,
                           y: position.y + 2 * .pi * rotateDelta.y / viewSize.height * 0.4)
    position.y = AV360Clamp(x: position.y, low: -.pi / 2, high: .pi / 2)
    position = AV360AdjustPositionForAllowedAxes(position: position, allowedPanningAxes: allowedPanningAxes)
    let eulerAngles = SCNVector3Make(position.y.getFloat(), position.x.getFloat(), 0)
    return AV360EulerAngleCalculationResultMake(position: position, eulerAngles: eulerAngles)
}

func AV360OptimalYFovForViewSize(viewSize: CGSize) -> CGFloat {
    var yFov: CGFloat!
    if viewSize.height > 0 {
        let ratio = viewSize.width / viewSize.height
        let slope = AV360EulerAngleCalculationYFovFunctionSlope
        yFov = (slope * ratio) + AV360EulerAngleCalculationYFovFunctionConstant
        yFov = min(max(yFov, AV360EulerAngleCalculationYFovMin), AV360EulerAngleCalculationYFovMax)
    } else {
        yFov = AV360EulerAngleCalculationYFovDefault
    }
    return yFov
}

func AV360CompassAngleForEulerAngles(eulerAngles: SCNVector3) -> Float {
    return AV360UnitRotationForCameraRotation(cameraRotation: (-1.0 * eulerAngles.y) + AV360EulerAngleCalculationDefaultReferenceCompassAngle)
}
