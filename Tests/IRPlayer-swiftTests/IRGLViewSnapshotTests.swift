import UIKit
import XCTest
@testable import IRPlayer_swift

final class IRGLViewSnapshotTests: XCTestCase {

    func testInitDoesNotPrintMetalSetupDebugOutput() {
        let output = captureStandardOutput {
            _ = IRGLView(frame: .zero)
        }

        XCTAssertEqual(output, "")
    }

    func testCreateImageFromFramebufferReturnsImageForZeroSizedView() {
        let view = IRGLView(frame: .zero)

        let image = view.createImageFromFramebuffer()

        XCTAssertEqual(image.size, .zero)
    }

    func testPlayerInitializerStoresAbstractPlayerAndBuildsDefaultModes() {
        let player = IRPlayerImp.player()
        player.manager = nil

        let view = IRGLView(frame: CGRect(x: 0, y: 0, width: 12, height: 8), player: player)

        XCTAssertTrue(view.abstractPlayer === player)
        XCTAssertFalse(view.getRenderModes().isEmpty)
        XCTAssertNotNil(view.getCurrentRenderMode())
        withExtendedLifetime(player) {}
    }

    func testLayoutAndQueueHelpersRemainCallable() {
        let view = IRGLView(frame: CGRect(x: 0, y: 0, width: 12, height: 8))
        var didRunInQueue = false

        view.layoutSubviews()
        view.runSyncInQueue {
            didRunInQueue = true
        }
        view.clearCanvas()
        let snapshotView = IRGLView(frame: .zero)
        snapshotView.doSnapShot()

        XCTAssertTrue(didRunInQueue)
        XCTAssertTrue(snapshotView.willDoSnapshot)
        snapshotView.willDoSnapshot = false
    }

    func testCreateImageFromFramebufferReturnsImageForNonZeroView() {
        let view = IRGLView(frame: CGRect(x: 0, y: 0, width: 12, height: 8))

        let image = view.createImageFromFramebuffer()

        XCTAssertEqual(image.size.width, 12, accuracy: 0.0001)
        XCTAssertEqual(image.size.height, 8, accuracy: 0.0001)
    }

    func testSendVideoFrameStoresCurrentFrameDimensions() {
        let view = IRGLView(frame: .zero)
        let frame = IRFFVideoFrame()
        frame.width = 123
        frame.height = 45

        view.send(videoFrame: frame)

        XCTAssertEqual(view.lastFrameWidth, 123)
        XCTAssertEqual(view.lastFrameHeight, 45)
    }

    func testRendererCleanupBranchesRemainCallable() {
        let view = IRGLView(frame: .zero)

        view.rendererType = .empty
        view.cleanViewIgnore()
        view.rendererType = .AVPlayerLayer
        view.cleanViewIgnore()
        view.rendererType = .AVPlayerPixelBufferVR
        view.cleanViewIgnore()
        view.rendererType = .FFmpegPixelBuffer
        view.cleanViewIgnore()
        view.rendererType = .FFmpegPixelBufferVR
        view.cleanViewIgnore()

        XCTAssertEqual(view.rendererType, .FFmpegPixelBufferVR)
    }

    func testDegreeScrollDelegatesThroughCurrentProgram() {
        let view = IRGLView(frame: .zero)
        let mode = IRGLRenderMode2D()
        let transformController = ViewRecordingTransformController()

        view.setRenderModes([mode])
        _ = view.choose(renderMode: mode, withImmediatelyRenderOnce: false)
        mode.program?.tramsformController = transformController

        view.scroll(byDegreeX: 3, degreeY: -4)

        XCTAssertEqual(transformController.degreeScrolls.map { "\($0.x),\($0.y)" }, ["3.0,-4.0"])
    }

    func testRenderModeSelectionRequiresRegisteredMode() {
        let view = IRGLView(frame: .zero)
        let firstMode = IRGLRenderMode2D()
        let secondMode = IRGLRenderMode2D()
        let externalMode = IRGLRenderMode2D()

        view.setRenderModes([firstMode, secondMode])

        XCTAssertEqual(view.getRenderModes().count, 2)
        XCTAssertTrue(view.getCurrentRenderMode() === firstMode)
        XCTAssertFalse(view.choose(renderMode: nil, withImmediatelyRenderOnce: false))
        XCTAssertFalse(view.choose(renderMode: externalMode, withImmediatelyRenderOnce: false))

        XCTAssertTrue(view.choose(renderMode: secondMode, withImmediatelyRenderOnce: false))
        XCTAssertTrue(view.getCurrentRenderMode() === secondMode)
        XCTAssertTrue(secondMode.program != nil)
    }

    func testResetAllViewportConvertsFiniteDimensions() {
        let view = IRGLView(frame: .zero)

        view.resetAllViewport(w: 320.9, h: 180.2, resetTransform: false)

        XCTAssertEqual(view.viewprotRange, CGRect(x: 0, y: 0, width: 320, height: 180))
    }

    func testResetAllViewportIgnoresInvalidDimensions() {
        let view = IRGLView(frame: .zero)
        view.resetAllViewport(w: 320, h: 180, resetTransform: false)

        view.resetAllViewport(w: .infinity, h: 180, resetTransform: false)

        XCTAssertEqual(view.viewprotRange, CGRect(x: 0, y: 0, width: 320, height: 180))
    }

    func testReloadViewFrameFillsSuperviewWhenAspectIsUnset() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 180))
        let view = IRGLView(frame: .zero)
        container.addSubview(view)

        view.aspect = 0
        view.reloadViewFrame()

        XCTAssertEqual(view.frame, container.bounds)
    }

    func testReloadViewFrameLetterboxesWiderContent() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 240))
        let view = IRGLView(frame: .zero)
        container.addSubview(view)

        view.aspect = 2
        view.reloadViewFrame()

        XCTAssertEqual(view.frame.origin.x, 0, accuracy: 0.0001)
        XCTAssertEqual(view.frame.origin.y, 40, accuracy: 0.0001)
        XCTAssertEqual(view.frame.width, 320, accuracy: 0.0001)
        XCTAssertEqual(view.frame.height, 160, accuracy: 0.0001)
    }

    func testReloadViewFramePillarboxesTallerContent() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 180))
        let view = IRGLView(frame: .zero)
        container.addSubview(view)

        view.aspect = 1
        view.reloadViewFrame()

        XCTAssertEqual(view.frame.origin.x, 70, accuracy: 0.0001)
        XCTAssertEqual(view.frame.origin.y, 0, accuracy: 0.0001)
        XCTAssertEqual(view.frame.width, 180, accuracy: 0.0001)
        XCTAssertEqual(view.frame.height, 180, accuracy: 0.0001)
    }

    func testReloadViewFrameUsesSuperviewFrameForMatchingAspect() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 180))
        let view = IRGLView(frame: .zero)
        container.addSubview(view)

        view.aspect = 320.0 / 180.0
        view.reloadViewFrame()

        XCTAssertEqual(view.frame, container.bounds)
    }

    func testDrawablePixelSizeRejectsInvalidDimensions() {
        XCTAssertNil(IRGLView.drawablePixelSize(from: CGSize(width: 0, height: 1)))
        XCTAssertNil(IRGLView.drawablePixelSize(from: CGSize(width: 1, height: CGFloat.nan)))
        XCTAssertNil(IRGLView.drawablePixelSize(from: CGSize(width: CGFloat.infinity, height: 1)))
        XCTAssertNil(IRGLView.drawablePixelSize(from: CGSize(width: CGFloat(Int.max) * 2, height: 1)))
    }

    func testDrawablePixelSizeConvertsFinitePositiveDimensions() {
        let size = IRGLView.drawablePixelSize(from: CGSize(width: 320.9, height: 180.2))

        XCTAssertEqual(size?.width, 320)
        XCTAssertEqual(size?.height, 180)
    }

    func testDrawablePixelSizeWrapperMatchesPolicy() {
        let input = CGSize(width: 320.9, height: 180.2)

        XCTAssertEqual(IRGLView.drawablePixelSize(from: input)?.width,
                       IRGLViewPolicy.drawablePixelSize(from: input)?.width)
        XCTAssertEqual(IRGLView.drawablePixelSize(from: input)?.height,
                       IRGLViewPolicy.drawablePixelSize(from: input)?.height)
        XCTAssertNil(IRGLViewPolicy.drawablePixelSize(from: CGSize(width: CGFloat.nan, height: 1)))
    }

    func testTexUVTextureLayoutRejectsInvalidOrOverflowingInputs() {
        XCTAssertNil(IRGLView.texUVTextureLayout(width: 0, height: 1))
        XCTAssertNil(IRGLView.texUVTextureLayout(width: 1, height: 0))
        XCTAssertNil(IRGLView.texUVTextureLayout(width: Int.max, height: 2))
        XCTAssertNil(IRGLView.texUVTextureLayout(width: Int.max / 8, height: 9))
    }

    func testTexUVTextureLayoutCalculatesRGFloatRows() {
        let layout = IRGLView.texUVTextureLayout(width: 3, height: 2)

        XCTAssertEqual(layout?.bytesPerRow, 24)
        XCTAssertEqual(layout?.totalByteCount, 48)
    }

    func testTexUVTextureLayoutWrapperMatchesPolicy() {
        let wrapper = IRGLView.texUVTextureLayout(width: 3, height: 2)
        let policy = IRGLViewPolicy.texUVTextureLayout(width: 3, height: 2)

        XCTAssertEqual(wrapper?.bytesPerRow, policy?.bytesPerRow)
        XCTAssertEqual(wrapper?.totalByteCount, policy?.totalByteCount)
        XCTAssertNil(IRGLViewPolicy.texUVTextureLayout(width: Int.max, height: 2))
    }

    func testTranslationVectorRejectsInvalidScopeValues() {
        XCTAssertEqual(IRGLViewPolicy.translationVector(for: nil), SIMD2<Float>(repeating: 0))
        XCTAssertEqual(
            IRGLViewPolicy.translationVector(for: IRGLScope2D(scaleX: 1, scaleY: 1, offsetX: 0, offsetY: 0, panDegree: 0, w: 0, h: 100)),
            SIMD2<Float>(repeating: 0)
        )
        XCTAssertEqual(
            IRGLViewPolicy.translationVector(for: IRGLScope2D(scaleX: .nan, scaleY: 1, offsetX: 0, offsetY: 0, panDegree: 0, w: 100, h: 100)),
            SIMD2<Float>(repeating: 0)
        )
        XCTAssertEqual(
            IRGLViewPolicy.translationVector(for: IRGLScope2D(scaleX: 1, scaleY: 1, offsetX: .infinity, offsetY: 0, panDegree: 0, w: 100, h: 100)),
            SIMD2<Float>(repeating: 0)
        )
    }

    func testTranslationVectorCalculatesOverflowingAxesFromOffsets() {
        let scope = IRGLScope2D(scaleX: 2, scaleY: 1.5, offsetX: 25, offsetY: 10, panDegree: 0, w: 200, h: 100)
        let vector = IRGLViewPolicy.translationVector(for: scope)

        XCTAssertEqual(vector.x, -0.5, accuracy: 0.0001)
        XCTAssertEqual(vector.y, 0.2, accuracy: 0.0001)
    }

    func testTranslationVectorZerosAxesThatFitInsideViewport() {
        let scope = IRGLScope2D(scaleX: 0.75, scaleY: 1.25, offsetX: 80, offsetY: 20, panDegree: 0, w: 200, h: 100)
        let vector = IRGLViewPolicy.translationVector(for: scope)

        XCTAssertEqual(vector.x, 0, accuracy: 0.0001)
        XCTAssertEqual(vector.y, -0.25, accuracy: 0.0001)

        let fittedScope = IRGLScope2D(scaleX: 0.75, scaleY: 0.5, offsetX: 80, offsetY: 20, panDegree: 0, w: 200, h: 100)
        XCTAssertEqual(IRGLViewPolicy.translationVector(for: fittedScope), SIMD2<Float>(repeating: 0))
    }

    func testFittedImageTransformCalculatesAspectFitScaleAndCentering() throws {
        let transform = try XCTUnwrap(
            IRGLView.fittedImageTransform(imageExtent: CGRect(x: 0, y: 0, width: 400, height: 200),
                                          targetRect: CGRect(x: 0, y: 0, width: 100, height: 100),
                                          contentMode: .scaleAspectFit)
        )

        XCTAssertEqual(transform.scaleX, 0.25, accuracy: 0.0001)
        XCTAssertEqual(transform.scaleY, 0.25, accuracy: 0.0001)
        XCTAssertEqual(transform.translationX, 0, accuracy: 0.0001)
        XCTAssertEqual(transform.translationY, 25, accuracy: 0.0001)
    }

    func testFittedImageTransformWrapperMatchesPolicy() throws {
        let imageExtent = CGRect(x: 10, y: 5, width: 400, height: 200)
        let targetRect = CGRect(x: 0, y: 0, width: 100, height: 100)

        let wrapper = try XCTUnwrap(
            IRGLView.fittedImageTransform(imageExtent: imageExtent,
                                          targetRect: targetRect,
                                          contentMode: .scaleAspectFit)
        )
        let policy = try XCTUnwrap(
            IRGLViewPolicy.fittedImageTransform(imageExtent: imageExtent,
                                                targetRect: targetRect,
                                                contentMode: .scaleAspectFit)
        )

        XCTAssertEqual(wrapper.scaleX, policy.scaleX, accuracy: 0.0001)
        XCTAssertEqual(wrapper.scaleY, policy.scaleY, accuracy: 0.0001)
        XCTAssertEqual(wrapper.translationX, policy.translationX, accuracy: 0.0001)
        XCTAssertEqual(wrapper.translationY, policy.translationY, accuracy: 0.0001)
    }

    func testFittedImageTransformCalculatesAspectFillScaleAndCentering() throws {
        let transform = try XCTUnwrap(
            IRGLView.fittedImageTransform(imageExtent: CGRect(x: 0, y: 0, width: 400, height: 200),
                                          targetRect: CGRect(x: 0, y: 0, width: 100, height: 100),
                                          contentMode: .scaleAspectFill)
        )

        XCTAssertEqual(transform.scaleX, 0.5, accuracy: 0.0001)
        XCTAssertEqual(transform.scaleY, 0.5, accuracy: 0.0001)
        XCTAssertEqual(transform.translationX, -50, accuracy: 0.0001)
        XCTAssertEqual(transform.translationY, 0, accuracy: 0.0001)
    }

    func testFittedImageTransformCalculatesScaleToFillIndependentAxes() throws {
        let transform = try XCTUnwrap(
            IRGLView.fittedImageTransform(imageExtent: CGRect(x: 0, y: 0, width: 400, height: 200),
                                          targetRect: CGRect(x: 0, y: 0, width: 100, height: 80),
                                          contentMode: .scaleToFill)
        )

        XCTAssertEqual(transform.scaleX, 0.25, accuracy: 0.0001)
        XCTAssertEqual(transform.scaleY, 0.4, accuracy: 0.0001)
        XCTAssertEqual(transform.translationX, 0, accuracy: 0.0001)
        XCTAssertEqual(transform.translationY, 0, accuracy: 0.0001)
    }

    func testFittedImageTransformRejectsInvalidGeometry() {
        XCTAssertNil(
            IRGLView.fittedImageTransform(imageExtent: CGRect(x: 0, y: 0, width: 0, height: 200),
                                          targetRect: CGRect(x: 0, y: 0, width: 100, height: 100),
                                          contentMode: .scaleAspectFit)
        )
        XCTAssertNil(
            IRGLView.fittedImageTransform(imageExtent: CGRect(x: 0, y: 0, width: 400, height: 200),
                                          targetRect: CGRect(x: 0, y: 0, width: CGFloat.nan, height: 100),
                                          contentMode: .scaleAspectFit)
        )
    }
}

private final class ViewRecordingTransformController: IRGLTransformController {
    private(set) var degreeScrolls: [(x: Float, y: Float)] = []

    override func scroll(degreeX: Float, degreeY: Float) {
        degreeScrolls.append((degreeX, degreeY))
    }
}
