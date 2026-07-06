//
//  IRGesturePolicyTests.swift
//  IRPlayer-swiftTests
//
//  Created by Codex on 2026/6/2.
//

import UIKit
import XCTest
@testable import IRPlayer_swift

final class IRGesturePolicyTests: XCTestCase {

    func testPanDirectionUsesDominantVelocityAxis() {
        XCTAssertEqual(IRGesturePolicy.panDirection(forVelocity: CGPoint(x: 20, y: 5)), .horizontal)
        XCTAssertEqual(IRGesturePolicy.panDirection(forVelocity: CGPoint(x: -4, y: 9)), .vertical)
        XCTAssertEqual(IRGesturePolicy.panDirection(forVelocity: CGPoint(x: 7, y: -7)), .unknown)
    }

    func testPanDirectionDefaultsNonFiniteVelocityToUnknown() {
        XCTAssertEqual(IRGesturePolicy.panDirection(forVelocity: CGPoint(x: CGFloat.nan, y: 5)), .unknown)
        XCTAssertEqual(IRGesturePolicy.panDirection(forVelocity: CGPoint(x: 5, y: CGFloat.infinity)), .unknown)
    }

    func testPanMovingDirectionUsesTranslationAndPanAxis() {
        XCTAssertEqual(IRGesturePolicy.panMovingDirection(forTranslation: CGPoint(x: 4, y: 0),
                                                         panDirection: .horizontal), .right)
        XCTAssertEqual(IRGesturePolicy.panMovingDirection(forTranslation: CGPoint(x: -4, y: 0),
                                                         panDirection: .horizontal), .left)
        XCTAssertEqual(IRGesturePolicy.panMovingDirection(forTranslation: CGPoint(x: 0, y: 4),
                                                         panDirection: .vertical), .bottom)
        XCTAssertEqual(IRGesturePolicy.panMovingDirection(forTranslation: CGPoint(x: 0, y: -4),
                                                         panDirection: .vertical), .top)
        XCTAssertEqual(IRGesturePolicy.panMovingDirection(forTranslation: CGPoint(x: 0, y: 0),
                                                         panDirection: .unknown), .unknown)
    }

    func testPanMovingDirectionDefaultsNonFiniteTranslationToUnknown() {
        XCTAssertEqual(IRGesturePolicy.panMovingDirection(forTranslation: CGPoint(x: CGFloat.nan, y: 1),
                                                         panDirection: .horizontal), .unknown)
        XCTAssertEqual(IRGesturePolicy.panMovingDirection(forTranslation: CGPoint(x: 1, y: CGFloat.infinity),
                                                         panDirection: .vertical), .unknown)
    }

    func testPanLocationUsesTargetMidpoint() {
        XCTAssertEqual(IRGesturePolicy.panLocation(forTouchX: 51, targetWidth: 100), .right)
        XCTAssertEqual(IRGesturePolicy.panLocation(forTouchX: 50, targetWidth: 100), .left)
        XCTAssertEqual(IRGesturePolicy.panLocation(forTouchX: 10, targetWidth: 0), .unknown)
        XCTAssertEqual(IRGesturePolicy.panLocation(forTouchX: CGFloat.nan, targetWidth: 100), .unknown)
    }

    func testPanMovingAxisUsesDominantTranslationAxis() {
        XCTAssertEqual(IRGesturePolicy.panMovingAxis(forTranslation: CGPoint(x: 10, y: 2)), .horizontal)
        XCTAssertEqual(IRGesturePolicy.panMovingAxis(forTranslation: CGPoint(x: 2, y: -10)), .vertical)
        XCTAssertEqual(IRGesturePolicy.panMovingAxis(forTranslation: CGPoint(x: 5, y: 5)), .unknown)
        XCTAssertEqual(IRGesturePolicy.panMovingAxis(forTranslation: CGPoint(x: CGFloat.nan, y: 5)), .unknown)
    }

    func testPanMovingAxisDisableDecisionMatchesConfiguredDisabledAxes() {
        XCTAssertTrue(IRGesturePolicy.isPanMovingAxisDisabled(.vertical, disabledAxes: .vertical))
        XCTAssertTrue(IRGesturePolicy.isPanMovingAxisDisabled(.horizontal, disabledAxes: .horizontal))
        XCTAssertFalse(IRGesturePolicy.isPanMovingAxisDisabled(.vertical, disabledAxes: .horizontal))
        XCTAssertFalse(IRGesturePolicy.isPanMovingAxisDisabled(.horizontal, disabledAxes: .vertical))
        XCTAssertFalse(IRGesturePolicy.isPanMovingAxisDisabled(.unknown, disabledAxes: .all))
    }

    func testPanRecognizerStateActionMapsBeganChangedAndFinishedStates() {
        XCTAssertEqual(IRGesturePolicy.panAction(for: .began), .begin)
        XCTAssertEqual(IRGesturePolicy.panAction(for: .changed), .change)
        XCTAssertEqual(IRGesturePolicy.panAction(for: .ended), .end)
        XCTAssertEqual(IRGesturePolicy.panAction(for: .cancelled), .end)
        XCTAssertEqual(IRGesturePolicy.panAction(for: .failed), .end)
        XCTAssertNil(IRGesturePolicy.panAction(for: .possible))
    }

    func testPinchRecognizerStateActionOnlyEndsOnEndedState() {
        XCTAssertEqual(IRGesturePolicy.pinchAction(for: .ended), .end)
        XCTAssertNil(IRGesturePolicy.pinchAction(for: .began))
        XCTAssertNil(IRGesturePolicy.pinchAction(for: .changed))
        XCTAssertNil(IRGesturePolicy.pinchAction(for: .cancelled))
        XCTAssertNil(IRGesturePolicy.pinchAction(for: .failed))
        XCTAssertNil(IRGesturePolicy.pinchAction(for: .possible))
    }

    func testSimultaneousRecognitionRejectsUnknownOtherRecognizerAndMultiTouch() {
        XCTAssertFalse(IRGesturePolicy.shouldRecognizeSimultaneously(otherRecognizerIsManaged: false,
                                                                     gestureIsPan: false,
                                                                     panTranslation: nil,
                                                                     disabledPanMovingAxes: .none,
                                                                     numberOfTouches: 1))
        XCTAssertFalse(IRGesturePolicy.shouldRecognizeSimultaneously(otherRecognizerIsManaged: true,
                                                                     gestureIsPan: false,
                                                                     panTranslation: nil,
                                                                     disabledPanMovingAxes: .none,
                                                                     numberOfTouches: 2))
    }

    func testSimultaneousRecognitionAllowsDisabledPanAxisToPassThrough() {
        XCTAssertTrue(IRGesturePolicy.shouldRecognizeSimultaneously(otherRecognizerIsManaged: true,
                                                                    gestureIsPan: true,
                                                                    panTranslation: CGPoint(x: 10, y: 0),
                                                                    disabledPanMovingAxes: .horizontal,
                                                                    numberOfTouches: 2))
        XCTAssertTrue(IRGesturePolicy.shouldRecognizeSimultaneously(otherRecognizerIsManaged: true,
                                                                    gestureIsPan: true,
                                                                    panTranslation: nil,
                                                                    disabledPanMovingAxes: .horizontal,
                                                                    numberOfTouches: 2))
    }
}

final class IRGestureControllerCallbackTests: XCTestCase {

    func testSingleTapCallbackReceivesController() {
        let controller = IRGestureController()
        var receivedController: IRGestureController?

        controller.singleTapped = { callbackController in
            receivedController = callbackController
        }

        controller.handleSingleTap(UITapGestureRecognizer())

        XCTAssertTrue(receivedController === controller)
    }

    func testPanCallbacksFollowRecognizerStates() {
        let controller = IRGestureController()
        let pan = StubPanGestureRecognizer()
        var began: (direction: IRPanDirection, location: IRPanLocation)?
        var changed: (direction: IRPanDirection, location: IRPanLocation, velocity: CGPoint)?
        var ended: (direction: IRPanDirection, location: IRPanLocation)?

        controller.beganPan = { _, direction, location in
            began = (direction, location)
        }
        controller.changedPan = { _, direction, location, velocity in
            changed = (direction, location, velocity)
        }
        controller.endedPan = { _, direction, location in
            ended = (direction, location)
        }

        pan.stubState = .began
        pan.stubVelocity = CGPoint(x: 12, y: 3)
        controller.handlePan(pan)

        pan.stubState = .changed
        pan.stubTranslation = CGPoint(x: -4, y: 0)
        pan.stubVelocity = CGPoint(x: -6, y: 1)
        controller.handlePan(pan)

        pan.stubState = .ended
        controller.handlePan(pan)

        XCTAssertEqual(began?.direction, .horizontal)
        XCTAssertEqual(began?.location, .unknown)
        XCTAssertEqual(changed?.direction, .horizontal)
        XCTAssertEqual(changed?.location, .unknown)
        XCTAssertEqual(changed?.velocity, CGPoint(x: -6, y: 1))
        XCTAssertEqual(ended?.direction, .horizontal)
        XCTAssertEqual(ended?.location, .unknown)
        XCTAssertEqual(controller.panMovingDirection, .left)
    }

    func testPinchCallbackRunsOnlyWhenRecognizerEnds() {
        let controller = IRGestureController()
        let pinch = StubPinchGestureRecognizer()
        var receivedScales: [CGFloat] = []

        controller.pinched = { _, scale in
            receivedScales.append(scale)
        }

        pinch.stubState = .changed
        pinch.scale = 1.25
        controller.handlePinch(pinch)

        pinch.stubState = .ended
        pinch.scale = 1.75
        controller.handlePinch(pinch)

        XCTAssertEqual(receivedScales, [1.75])
    }

    func testSimultaneousRecognitionDependsOnManagedOtherRecognizer() {
        let controller = IRGestureController()

        XCTAssertTrue(
            controller.gestureRecognizer(
                controller.singleTapGR,
                shouldRecognizeSimultaneouslyWith: controller.doubleTapGR
            )
        )
        XCTAssertFalse(
            controller.gestureRecognizer(
                controller.singleTapGR,
                shouldRecognizeSimultaneouslyWith: UITapGestureRecognizer()
            )
        )
    }

    func testPanGestureShouldBeginWhenMovingAxisIsAllowed() {
        let controller = IRGestureController()

        XCTAssertTrue(controller.gestureRecognizerShouldBegin(controller.panGR))
    }

    func testSimultaneousRecognitionEvaluatesManagedPanRecognizer() {
        let controller = IRGestureController()

        XCTAssertTrue(
            controller.gestureRecognizer(
                controller.panGR,
                shouldRecognizeSimultaneouslyWith: controller.pinchGR
            )
        )
    }
}

private final class StubPanGestureRecognizer: UIPanGestureRecognizer {
    var stubState: UIGestureRecognizer.State = .possible
    var stubTranslation: CGPoint = .zero
    var stubVelocity: CGPoint = .zero

    override var state: UIGestureRecognizer.State {
        get { stubState }
        set { stubState = newValue }
    }

    override func translation(in view: UIView?) -> CGPoint {
        stubTranslation
    }

    override func velocity(in view: UIView?) -> CGPoint {
        stubVelocity
    }
}

private final class StubPinchGestureRecognizer: UIPinchGestureRecognizer {
    var stubState: UIGestureRecognizer.State = .possible

    override var state: UIGestureRecognizer.State {
        get { stubState }
        set { stubState = newValue }
    }
}
