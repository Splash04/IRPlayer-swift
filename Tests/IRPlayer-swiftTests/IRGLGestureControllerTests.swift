import UIKit
import XCTest
@testable import IRPlayer_swift

final class IRGLGestureControllerTests: XCTestCase {

    func testGesturePolicyConvertsTouchPointToRenderSpace() {
        let point = IRGLGesturePolicy.renderPoint(from: CGPoint(x: 12, y: 20),
                                                 viewHeight: 100,
                                                 screenScale: 3)

        XCTAssertEqual(point.x, 36)
        XCTAssertEqual(point.y, 240)
    }

    func testGesturePolicyDefaultsInvalidInputsToZero() {
        XCTAssertEqual(
            IRGLGesturePolicy.renderPoint(from: CGPoint(x: CGFloat.nan, y: 20),
                                          viewHeight: 100,
                                          screenScale: 3),
            .zero
        )
        XCTAssertEqual(
            IRGLGesturePolicy.renderPoint(from: CGPoint(x: 12, y: 20),
                                          viewHeight: CGFloat.infinity,
                                          screenScale: 3),
            .zero
        )
        XCTAssertEqual(
            IRGLGesturePolicy.renderPoint(from: CGPoint(x: 12, y: 20),
                                          viewHeight: 100,
                                          screenScale: 0),
            .zero
        )
        XCTAssertEqual(
            IRGLGesturePolicy.renderPoint(from: CGPoint(x: 12, y: 20),
                                          viewHeight: 100,
                                          screenScale: -1),
            .zero
        )
    }

    func testGesturePolicyMapsPanRecognizerStatesToActions() {
        XCTAssertEqual(IRGLGesturePolicy.panAction(for: .began), .begin)
        XCTAssertEqual(IRGLGesturePolicy.panAction(for: .changed), .update)
        XCTAssertEqual(IRGLGesturePolicy.panAction(for: .possible), .update)
        XCTAssertEqual(IRGLGesturePolicy.panAction(for: .ended), .endWithDeceleration)
        XCTAssertEqual(IRGLGesturePolicy.panAction(for: .cancelled), .cancel)
        XCTAssertEqual(IRGLGesturePolicy.panAction(for: .failed), .cancel)
    }

    func testGesturePolicyMapsContinuousRecognizerStatesToActions() {
        XCTAssertEqual(IRGLGesturePolicy.continuousAction(for: .began), .begin)
        XCTAssertEqual(IRGLGesturePolicy.continuousAction(for: .changed), .update)
        XCTAssertEqual(IRGLGesturePolicy.continuousAction(for: .possible), .update)
        XCTAssertEqual(IRGLGesturePolicy.continuousAction(for: .ended), .end)
        XCTAssertEqual(IRGLGesturePolicy.continuousAction(for: .cancelled), .end)
        XCTAssertEqual(IRGLGesturePolicy.continuousAction(for: .failed), .end)
    }

    func testGesturePolicyShouldBeginRejectsDisabledDoubleTapAndSwipeWhileZooming() {
        XCTAssertFalse(IRGLGesturePolicy.shouldBeginGesture(superAllowsGesture: false,
                                                           isDoubleTapGesture: false,
                                                           doubleTapEnabled: true,
                                                           isSwipeGesture: false,
                                                           isProgramZooming: false))
        XCTAssertFalse(IRGLGesturePolicy.shouldBeginGesture(superAllowsGesture: true,
                                                           isDoubleTapGesture: true,
                                                           doubleTapEnabled: false,
                                                           isSwipeGesture: false,
                                                           isProgramZooming: false))
        XCTAssertFalse(IRGLGesturePolicy.shouldBeginGesture(superAllowsGesture: true,
                                                           isDoubleTapGesture: false,
                                                           doubleTapEnabled: true,
                                                           isSwipeGesture: true,
                                                           isProgramZooming: true))
        XCTAssertTrue(IRGLGesturePolicy.shouldBeginGesture(superAllowsGesture: true,
                                                          isDoubleTapGesture: true,
                                                          doubleTapEnabled: true,
                                                          isSwipeGesture: true,
                                                          isProgramZooming: false))
    }

    func testClearingCurrentModeClearsSmoothScrollMode() {
        let view = IRGLView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let smoothScroll = IRSmoothScrollController(targetView: view)
        let gestureController = IRGLGestureController()

        gestureController.smoothScroll = smoothScroll
        gestureController.currentMode = IRGLRenderMode2D()

        gestureController.currentMode = nil

        XCTAssertNil(smoothScroll.currentMode)
        withExtendedLifetime(smoothScroll) {}
    }

    func testAddGestureReplacesExistingRotationGestureRecognizer() {
        let view = IRGLView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let gestureController = IRGLGestureController()

        gestureController.addGesture(to: view)
        gestureController.addGesture(to: view)

        let rotationRecognizers = view.gestureRecognizers?.filter { $0 is UIRotationGestureRecognizer } ?? []
        XCTAssertEqual(rotationRecognizers.count, 1)
    }

    func testRemoveGestureRemovesRotationGestureRecognizer() {
        let view = IRGLView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let gestureController = IRGLGestureController()

        gestureController.addGesture(to: view)
        gestureController.removeGesture(to: view)

        let rotationRecognizers = view.gestureRecognizers?.filter { $0 is UIRotationGestureRecognizer } ?? []
        XCTAssertTrue(rotationRecognizers.isEmpty)
    }

    func testGestureCallbacksDoNotWriteDebugOutput() {
        let gestureController = IRGLGestureController()

        let output = captureStandardOutput {
            gestureController.handlePan(UIPanGestureRecognizer())
            gestureController.handlePinch(UIPinchGestureRecognizer())
            gestureController.handleRotate(UIRotationGestureRecognizer())
            gestureController.handleDoubleTap(UITapGestureRecognizer())
        }

        XCTAssertEqual(output, "")
    }

    func testProgramZoomingDefaultsToFalseWithoutCurrentMode() {
        let gestureController = IRGLGestureController()

        XCTAssertFalse(gestureController.isProgramZooming())
    }

    func testProgramCreationAssignsSmoothScrollAsProgramDelegate() {
        let view = IRGLView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let smoothScroll = IRSmoothScrollController(targetView: view)
        let gestureController = IRGLGestureController()
        let program = IRGLProgram2D()

        gestureController.smoothScroll = smoothScroll
        gestureController.programDidCreate(program)

        XCTAssertTrue(program.delegate === smoothScroll)
        withExtendedLifetime(smoothScroll) {}
    }

    func testGestureShouldBeginRejectsDisabledDoubleTapWithoutCurrentProgram() {
        let gestureController = IRGLGestureController()

        gestureController.doubleTapEnable = false

        XCTAssertFalse(gestureController.gestureRecognizerShouldBegin(gestureController.doubleTapGR))
    }

    func testSimultaneousRecognitionAllowsSwipeWithPanWhenNotZooming() {
        let gestureController = IRGLGestureController()

        XCTAssertTrue(
            gestureController.gestureRecognizer(
                gestureController.panGR,
                shouldRecognizeSimultaneouslyWith: UISwipeGestureRecognizer()
            )
        )
    }

    func testSimultaneousRecognitionFallsBackWhenSwipeIsDisabled() {
        let gestureController = IRGLGestureController()

        gestureController.swipeEnable = false

        XCTAssertFalse(
            gestureController.gestureRecognizer(
                gestureController.panGR,
                shouldRecognizeSimultaneouslyWith: UISwipeGestureRecognizer()
            )
        )
    }

    func testPanHandlerNotifiesDelegateForCancelAndEndStates() {
        let view = IRGLView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let gestureController = IRGLGestureController()
        let delegate = RecordingGLViewDelegate()
        let pan = GLStubPanGestureRecognizer()

        gestureController.delegate = delegate
        gestureController.addGesture(to: view)

        pan.stubState = .cancelled
        gestureController.handlePan(pan)

        pan.stubState = .ended
        pan.stubVelocity = .zero
        gestureController.handlePan(pan)

        XCTAssertEqual(delegate.endDraggingWillDecelerate, [false, true])
        XCTAssertTrue(delegate.endDraggingViews.allSatisfy { $0 === view })
    }

    func testPanHandlerCoversBeginAndIgnoredUpdateWhenTouchIsOutsideProgram() {
        let gestureController = IRGLGestureController()
        let pan = GLStubPanGestureRecognizer()

        pan.stubState = .began
        pan.stubLocation = CGPoint(x: 10, y: 10)
        gestureController.handlePan(pan)

        pan.stubState = .changed
        pan.stubTranslation = CGPoint(x: 6, y: -2)
        gestureController.handlePan(pan)

        XCTAssertEqual(pan.stubTranslation, CGPoint(x: 6, y: -2))
    }

    func testPinchAndRotateHandlersCoverEndBeginAndIgnoredUpdateStates() {
        let gestureController = IRGLGestureController()
        let pinch = GLStubPinchGestureRecognizer()
        let rotation = GLStubRotationGestureRecognizer()

        pinch.stubState = .ended
        gestureController.handlePinch(pinch)
        pinch.stubState = .began
        gestureController.handlePinch(pinch)
        pinch.stubState = .changed
        gestureController.handlePinch(pinch)

        rotation.stubState = .ended
        gestureController.handleRotate(rotation)
        rotation.stubState = .began
        gestureController.handleRotate(rotation)
        rotation.stubState = .changed
        rotation.rotation = 0.5
        gestureController.handleRotate(rotation)

        XCTAssertEqual(rotation.rotation, 0.5)
    }

    func testUpdateRotationDelegatesToCurrentProgramTransform() {
        let gestureController = IRGLGestureController()
        let mode = IRGLRenderMode2D()
        let program = IRGLProgram2D()
        let transformController = RecordingTransformController()

        program.tramsformController = transformController
        mode.program = program
        gestureController.currentMode = mode

        gestureController.updateRotation(.pi)

        XCTAssertEqual(transformController.rotations, [-180])
    }

    func testDoubleTapInsideProgramInstallsResetBlockFor2DTransform() {
        let gestureController = IRGLGestureController()
        let mode = IRGLRenderMode2D()
        let program = IRGLProgram2D(
            pixelFormat: .RGB_IRPixelFormat,
            viewportRange: CGRect(x: -1, y: -1, width: 2, height: 2),
            parameter: nil
        )

        program.tramsformController = IRGLTransformController2D(viewportWidth: 2, viewportHeight: 2)
        mode.program = program
        gestureController.currentMode = mode

        gestureController.handleDoubleTap(UITapGestureRecognizer())

        XCTAssertNotNil(program.doResetToDefaultScaleBlock)
    }
}

private final class RecordingGLViewDelegate: NSObject, IRGLViewDelegate {
    private(set) var endDraggingViews: [IRGLView?] = []
    private(set) var endDraggingWillDecelerate: [Bool] = []

    func glViewDidEndDragging(_ view: IRGLView?, willDecelerate: Bool) {
        endDraggingViews.append(view)
        endDraggingWillDecelerate.append(willDecelerate)
    }

    func glViewWillBeginDragging(_ view: IRGLView?) {}

    func glViewWillBeginZooming(_ view: IRGLView?) {}

    func glViewDidEndDecelerating(_ view: IRGLView?) {}

    func glViewDidEndZooming(_ view: IRGLView?, atScale scale: CGFloat) {}

    func glViewDidScroll(toBounds view: IRGLView?) {}
}

private final class GLStubPanGestureRecognizer: UIPanGestureRecognizer {
    var stubState: UIGestureRecognizer.State = .possible
    var stubLocation: CGPoint = .zero
    var stubTranslation: CGPoint = .zero
    var stubVelocity: CGPoint = .zero

    override var state: UIGestureRecognizer.State {
        get { stubState }
        set { stubState = newValue }
    }

    override func location(in view: UIView?) -> CGPoint {
        stubLocation
    }

    override func translation(in view: UIView?) -> CGPoint {
        stubTranslation
    }

    override func setTranslation(_ translation: CGPoint, in view: UIView?) {
        stubTranslation = translation
    }

    override func velocity(in view: UIView?) -> CGPoint {
        stubVelocity
    }
}

private final class GLStubPinchGestureRecognizer: UIPinchGestureRecognizer {
    var stubState: UIGestureRecognizer.State = .possible
    var stubLocation: CGPoint = .zero

    override var state: UIGestureRecognizer.State {
        get { stubState }
        set { stubState = newValue }
    }

    override func location(in view: UIView?) -> CGPoint {
        stubLocation
    }
}

private final class GLStubRotationGestureRecognizer: UIRotationGestureRecognizer {
    var stubState: UIGestureRecognizer.State = .possible
    var stubLocation: CGPoint = .zero

    override var state: UIGestureRecognizer.State {
        get { stubState }
        set { stubState = newValue }
    }

    override func location(in view: UIView?) -> CGPoint {
        stubLocation
    }
}

private final class RecordingTransformController: IRGLTransformController {
    private(set) var rotations: [Float] = []

    override func rotate(degree: Float) {
        rotations.append(degree)
    }
}
