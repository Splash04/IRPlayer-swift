//
//  IRSensorTests.swift
//  IRPlayer-swiftTests
//
//  Created by Codex on 2026/6/2.
//

import CoreGraphics
import XCTest
import UIKit
@testable import IRPlayer_swift

final class IRSensorTests: XCTestCase {

    func testMotionDeltaWrapsAcrossPositiveAndNegativeHalfTurns() {
        XCTAssertEqual(IRSensor.normalizedMotionDelta(current: CGFloat(-170), previous: CGFloat(170)), 20, accuracy: 0.0001)
        XCTAssertEqual(IRSensor.normalizedMotionDelta(current: CGFloat(170), previous: CGFloat(-170)), -20, accuracy: 0.0001)
    }

    func testMotionDeltaKeepsSmallOffsetsUnchanged() {
        XCTAssertEqual(IRSensor.normalizedMotionDelta(current: CGFloat(45), previous: CGFloat(15)), 30, accuracy: 0.0001)
        XCTAssertEqual(IRSensor.normalizedMotionDelta(current: CGFloat(-20), previous: CGFloat(15)), -35, accuracy: 0.0001)
    }

    func testMotionDeltaDefaultsNonFiniteInputsToZero() {
        XCTAssertEqual(IRSensor.normalizedMotionDelta(current: CGFloat.nan, previous: CGFloat(15)), 0)
        XCTAssertEqual(IRSensor.normalizedMotionDelta(current: CGFloat(15), previous: CGFloat.infinity), 0)
    }

    func testMotionDeltaDefaultsOverflowingDeltaToZero() {
        XCTAssertEqual(
            IRSensor.normalizedMotionDelta(current: CGFloat.greatestFiniteMagnitude,
                                           previous: -CGFloat.greatestFiniteMagnitude),
            0
        )
    }

    func testMotionScrollShiftConvertsFiniteDeltasWithoutDebugOutput() {
        let output = captureStandardOutput {
            guard let shift = IRSensor.motionScrollShift(dx: CGFloat(12.5), dy: CGFloat(-6.25)) else {
                XCTFail("Expected finite motion deltas to produce a shift")
                return
            }

            XCTAssertEqual(shift.degreeX, Float(12.5), accuracy: 0.0001)
            XCTAssertEqual(shift.degreeY, Float(-6.25), accuracy: 0.0001)
        }

        XCTAssertEqual(output, "")
    }

    func testMotionScrollShiftRejectsNonFiniteDeltas() {
        XCTAssertNil(IRSensor.motionScrollShift(dx: CGFloat.nan, dy: CGFloat(1)))
        XCTAssertNil(IRSensor.motionScrollShift(dx: CGFloat(1), dy: CGFloat.infinity))
    }

    func testReferenceAttitudePolicyCapturesMissingReferenceWithoutDebugOutput() {
        let output = captureStandardOutput {
            let policy = IRSensor.referenceAttitudePolicy(hasReferenceAttitude: false)

            XCTAssertTrue(policy.shouldCaptureReferenceAttitude)
            XCTAssertFalse(policy.shouldScroll)
        }

        XCTAssertEqual(output, "")
    }

    func testMotionDegreesMapsSupportedOrientations() throws {
        let inversePitch = Double.pi / 6
        let inverseRoll = Double.pi / 3

        let portrait = try XCTUnwrap(IRSensor.motionDegrees(inversePitchRadians: inversePitch,
                                                            inverseRollRadians: inverseRoll,
                                                            pitchDegrees: 20,
                                                            rollDegrees: 0,
                                                            orientation: .portrait))
        XCTAssertEqual(portrait.degreeX, 60, accuracy: 0.0001)
        XCTAssertEqual(portrait.degreeY, 30, accuracy: 0.0001)

        let upsideDown = try XCTUnwrap(IRSensor.motionDegrees(inversePitchRadians: inversePitch,
                                                             inverseRollRadians: inverseRoll,
                                                             pitchDegrees: -20,
                                                             rollDegrees: 0,
                                                             orientation: .portraitUpsideDown))
        XCTAssertEqual(upsideDown.degreeX, -60, accuracy: 0.0001)
        XCTAssertEqual(upsideDown.degreeY, -30, accuracy: 0.0001)

        let landscapeLeft = try XCTUnwrap(IRSensor.motionDegrees(inversePitchRadians: inversePitch,
                                                                 inverseRollRadians: inverseRoll,
                                                                 pitchDegrees: 0,
                                                                 rollDegrees: 20,
                                                                 orientation: .landscapeLeft))
        XCTAssertEqual(landscapeLeft.degreeX, -30, accuracy: 0.0001)
        XCTAssertEqual(landscapeLeft.degreeY, 60, accuracy: 0.0001)

        let landscapeRight = try XCTUnwrap(IRSensor.motionDegrees(inversePitchRadians: inversePitch,
                                                                  inverseRollRadians: inverseRoll,
                                                                  pitchDegrees: 0,
                                                                  rollDegrees: -20,
                                                                  orientation: .landscapeRight))
        XCTAssertEqual(landscapeRight.degreeX, 30, accuracy: 0.0001)
        XCTAssertEqual(landscapeRight.degreeY, -60, accuracy: 0.0001)
    }

    func testMotionDegreesRejectsUnsupportedOrOutOfThresholdOrientations() {
        XCTAssertNil(IRSensor.motionDegrees(inversePitchRadians: 0,
                                            inverseRollRadians: 0,
                                            pitchDegrees: 14.9,
                                            rollDegrees: 0,
                                            orientation: .portrait))
        XCTAssertNil(IRSensor.motionDegrees(inversePitchRadians: 0,
                                            inverseRollRadians: 0,
                                            pitchDegrees: -14.9,
                                            rollDegrees: 0,
                                            orientation: .portraitUpsideDown))
        XCTAssertNil(IRSensor.motionDegrees(inversePitchRadians: 0,
                                            inverseRollRadians: 0,
                                            pitchDegrees: 0,
                                            rollDegrees: 14.9,
                                            orientation: .landscapeLeft))
        XCTAssertNil(IRSensor.motionDegrees(inversePitchRadians: 0,
                                            inverseRollRadians: 0,
                                            pitchDegrees: 0,
                                            rollDegrees: -14.9,
                                            orientation: .landscapeRight))
        XCTAssertNil(IRSensor.motionDegrees(inversePitchRadians: 0,
                                            inverseRollRadians: 0,
                                            pitchDegrees: 0,
                                            rollDegrees: 0,
                                            orientation: .unknown))
    }
}
