import XCTest
@testable import IRPlayer_swift

final class IRPlayerImpLazyPlayerTests: XCTestCase {

    func testPlayerVolumeConvertsFiniteValues() {
        XCTAssertEqual(IRPlayerVolume.normalizedFloat(from: 0.5), 0.5, accuracy: 0.0001)
    }

    func testPlayerVolumeDefaultsNilAndNonFiniteValuesToZero() {
        XCTAssertEqual(IRPlayerVolume.normalizedFloat(from: nil), 0)
        XCTAssertEqual(IRPlayerVolume.normalizedFloat(from: .nan), 0)
        XCTAssertEqual(IRPlayerVolume.normalizedFloat(from: .infinity), 0)
    }

    func testLazyPlayerFactoriesReturnExistingPlayersOrCreateNewOnes() {
        let abstractPlayer = IRPlayerImp.player()
        abstractPlayer.manager = nil

        let existingAVPlayer = IRAVPlayer(abstractPlayer: abstractPlayer)
        XCTAssertTrue(IRPlayerImp.makeAVPlayerIfNeeded(existingAVPlayer, abstractPlayer: abstractPlayer) === existingAVPlayer)

        let createdAVPlayer = IRPlayerImp.makeAVPlayerIfNeeded(nil, abstractPlayer: abstractPlayer)
        XCTAssertTrue(createdAVPlayer.abstractPlayer === abstractPlayer)

        let existingFFPlayer = IRFFPlayer.player(with: abstractPlayer)
        XCTAssertTrue(IRPlayerImp.makeFFPlayerIfNeeded(existingFFPlayer, abstractPlayer: abstractPlayer) === existingFFPlayer)

        let createdFFPlayer = IRPlayerImp.makeFFPlayerIfNeeded(nil, abstractPlayer: abstractPlayer)
        XCTAssertTrue(createdFFPlayer.abstractPlayer === abstractPlayer)

        withExtendedLifetime((existingAVPlayer, createdAVPlayer, existingFFPlayer, createdFFPlayer, abstractPlayer)) {}
    }

    func testPlaybackPropertiesFallBackToDefaultsForEmptyReplacement() {
        let player = IRPlayerImp.player()
        player.manager = nil

        player.replaceEmpty()

        XCTAssertEqual(player.state, .none)
        XCTAssertEqual(player.presentationSize, .zero)
        XCTAssertEqual(player.bitrate, 0)
        XCTAssertEqual(player.progress, 0)
        XCTAssertEqual(player.duration, 0)
        XCTAssertEqual(player.playableTime, 0)
        XCTAssertFalse(player.seeking)
        withExtendedLifetime(player) {}
    }

    func testPlaybackPropertiesReadAVPlayerReplacementDefaults() {
        let player = IRPlayerImp.player()
        player.manager = nil
        player.decoder = IRPlayerDecoder.AVPlayerDecoder()

        player.replaceVideoWithURL(contentURL: NSURL(string: "https://example.com/video.mp4"))

        XCTAssertEqual(player.state, .none)
        XCTAssertEqual(player.presentationSize, .zero)
        XCTAssertEqual(player.bitrate, 0)
        XCTAssertEqual(player.progress, 0)
        XCTAssertEqual(player.duration, 0)
        XCTAssertEqual(player.playableTime, 0)
        XCTAssertFalse(player.seeking)
        withExtendedLifetime(player) {}
    }

    func testPlaybackPropertiesReadFFmpegReplacementDefaults() {
        let player = IRPlayerImp.player()
        player.manager = nil
        player.decoder = IRPlayerDecoder.FFmpegDecoder()

        player.replaceVideoWithURL(contentURL: NSURL(fileURLWithPath: "/tmp/missing.flv"))

        XCTAssertNotEqual(player.state, .playing)
        XCTAssertEqual(player.presentationSize, .zero)
        XCTAssertEqual(player.bitrate, 0)
        XCTAssertEqual(player.progress, 0)
        XCTAssertEqual(player.duration, 0)
        XCTAssertEqual(player.playableTime, 0)
        XCTAssertFalse(player.seeking)
        withExtendedLifetime(player) {}
    }

    func testViewConfigurationForwardsToDisplayView() throws {
        let player = IRPlayerImp.player()
        player.manager = nil
        let displayView = try XCTUnwrap(player.view as? IRGLView)
        let firstMode = IRGLRenderMode2D()
        let secondMode = IRGLRenderMode2D()

        player.renderModes = [firstMode, secondMode]
        player.selectRenderMode(renderMode: secondMode)
        player.viewGravityMode = .resizeAspectFill
        player.updateGraphicsViewFrame(frame: CGRect(x: 1, y: 2, width: 120, height: 80))

        XCTAssertEqual(player.renderModes?.count, 2)
        XCTAssertTrue(displayView.getCurrentRenderMode() === secondMode)
        XCTAssertEqual(displayView.frame, CGRect(x: 1, y: 2, width: 120, height: 80))
        withExtendedLifetime(player) {}
    }

    func testSetupPlayerViewReplacesExistingPlayerSubviews() throws {
        let player = IRPlayerImp.player()
        player.manager = nil
        let container = try XCTUnwrap(player.view)
        let firstSubview = UIView()
        let secondSubview = UIView()

        player.setupPlayerView(firstSubview)
        player.setupPlayerView(secondSubview)

        XCTAssertFalse(secondSubview.translatesAutoresizingMaskIntoConstraints)
        XCTAssertNil(firstSubview.superview)
        XCTAssertTrue(secondSubview.superview === container)
        XCTAssertEqual(container.subviews, [secondSubview])
        withExtendedLifetime(player) {}
    }

    func testScrollToBoundsDoesNotPrintDebugOutput() {
        let player = IRPlayerImp.player()

        let output = captureStandardOutput {
            player.glViewDidScroll(toBounds: nil)
        }

        XCTAssertEqual(output, "")
        withExtendedLifetime(player) {}
    }

    func testReleaseDoesNotPrintDebugOutput() {
        var player: IRPlayerImp? = IRPlayerImp.player()
        XCTAssertNotNil(player)

        let output = captureStandardOutput {
            player = nil
        }

        XCTAssertEqual(output, "")
    }
}
