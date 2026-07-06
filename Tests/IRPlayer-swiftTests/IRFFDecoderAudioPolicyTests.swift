import XCTest
@testable import IRPlayer_swift

final class IRFFDecoderAudioPolicyTests: XCTestCase {

    func testAudioPacketErrorUsesPacketResult() throws {
        XCTAssertNil(IRFFDecoderAudioPolicy.audioPacketError(fromPacketResult: 0))

        let error = try XCTUnwrap(IRFFDecoderAudioPolicy.audioPacketError(fromPacketResult: -1))
        XCTAssertEqual(error.code, IRFFDecoderErrorCode.codecAudioSendPacket.rawValue)
        XCTAssertTrue(error.domain.contains("ffmpeg code: -1"))
    }

    func testBufferedDurationTransitionNormalizesTinyDurationsAndMarksFinishedAtEndOfFile() {
        XCTAssertEqual(
            IRFFDecoderAudioPolicy.bufferedDurationTransition(bufferedDuration: 0.0000001, endOfFile: false),
            IRFFDecoder.BufferedDurationTransition(bufferedDuration: 0, shouldFinishPlayback: false)
        )
        XCTAssertEqual(
            IRFFDecoderAudioPolicy.bufferedDurationTransition(bufferedDuration: 0, endOfFile: true),
            IRFFDecoder.BufferedDurationTransition(bufferedDuration: 0, shouldFinishPlayback: true)
        )
        XCTAssertEqual(
            IRFFDecoderAudioPolicy.bufferedDurationTransition(bufferedDuration: 0.5, endOfFile: true),
            IRFFDecoder.BufferedDurationTransition(bufferedDuration: 0.5, shouldFinishPlayback: false)
        )
    }

    func testBufferedDurationTransitionNormalizesNonFiniteDurations() {
        XCTAssertEqual(
            IRFFDecoderAudioPolicy.bufferedDurationTransition(bufferedDuration: .nan, endOfFile: true),
            IRFFDecoder.BufferedDurationTransition(bufferedDuration: 0, shouldFinishPlayback: true)
        )
        XCTAssertEqual(
            IRFFDecoderAudioPolicy.bufferedDurationTransition(bufferedDuration: .infinity, endOfFile: false),
            IRFFDecoder.BufferedDurationTransition(bufferedDuration: 0, shouldFinishPlayback: false)
        )
    }

    func testShouldFetchAudioFrameRequiresActiveAudioPlaybackState() {
        XCTAssertTrue(
            IRFFDecoderAudioPolicy.shouldFetchAudioFrame(
                closed: false,
                seeking: false,
                buffering: false,
                paused: false,
                playbackFinished: false,
                audioEnabled: true
            )
        )
        XCTAssertFalse(
            IRFFDecoderAudioPolicy.shouldFetchAudioFrame(
                closed: true,
                seeking: false,
                buffering: false,
                paused: false,
                playbackFinished: false,
                audioEnabled: true
            )
        )
        XCTAssertFalse(
            IRFFDecoderAudioPolicy.shouldFetchAudioFrame(
                closed: false,
                seeking: true,
                buffering: false,
                paused: false,
                playbackFinished: false,
                audioEnabled: true
            )
        )
        XCTAssertFalse(
            IRFFDecoderAudioPolicy.shouldFetchAudioFrame(
                closed: false,
                seeking: false,
                buffering: true,
                paused: false,
                playbackFinished: false,
                audioEnabled: true
            )
        )
        XCTAssertFalse(
            IRFFDecoderAudioPolicy.shouldFetchAudioFrame(
                closed: false,
                seeking: false,
                buffering: false,
                paused: true,
                playbackFinished: false,
                audioEnabled: true
            )
        )
        XCTAssertFalse(
            IRFFDecoderAudioPolicy.shouldFetchAudioFrame(
                closed: false,
                seeking: false,
                buffering: false,
                paused: false,
                playbackFinished: true,
                audioEnabled: true
            )
        )
        XCTAssertFalse(
            IRFFDecoderAudioPolicy.shouldFetchAudioFrame(
                closed: false,
                seeking: false,
                buffering: false,
                paused: false,
                playbackFinished: false,
                audioEnabled: false
            )
        )
    }

    func testBufferingStatusTransitionEntersRegularBufferingAtLowDuration() {
        XCTAssertEqual(
            IRFFDecoderBufferingPolicy.statusTransition(
                buffering: false,
                bufferedDuration: 0.2,
                endOfFile: false,
                isLiveStream: false,
                minBufferedDuration: 1.5,
                bufferingStartTime: 0,
                currentTime: 42
            ),
            IRFFDecoder.BufferingStatusTransition(buffering: true, bufferingStartTime: 42)
        )
    }

    func testBufferingStatusTransitionEntersLiveBufferingAtCriticalDuration() {
        XCTAssertEqual(
            IRFFDecoderBufferingPolicy.statusTransition(
                buffering: false,
                bufferedDuration: 0.05,
                endOfFile: false,
                isLiveStream: true,
                minBufferedDuration: 1.5,
                bufferingStartTime: 0,
                currentTime: 42
            ),
            IRFFDecoder.BufferingStatusTransition(buffering: true, bufferingStartTime: 42)
        )
        XCTAssertEqual(
            IRFFDecoderBufferingPolicy.statusTransition(
                buffering: false,
                bufferedDuration: 0.1,
                endOfFile: false,
                isLiveStream: true,
                minBufferedDuration: 1.5,
                bufferingStartTime: 7,
                currentTime: 42
            ),
            IRFFDecoder.BufferingStatusTransition(buffering: false, bufferingStartTime: 7)
        )
    }

    func testBufferingStatusTransitionExitsWhenBufferedDurationMeetsThreshold() {
        XCTAssertEqual(
            IRFFDecoderBufferingPolicy.statusTransition(
                buffering: true,
                bufferedDuration: 1.5,
                endOfFile: false,
                isLiveStream: false,
                minBufferedDuration: 1.5,
                bufferingStartTime: 10,
                currentTime: 11
            ),
            IRFFDecoder.BufferingStatusTransition(buffering: false, bufferingStartTime: 0)
        )
    }

    func testBufferingStatusTransitionExitsAfterRegularTimeout() {
        XCTAssertEqual(
            IRFFDecoderBufferingPolicy.statusTransition(
                buffering: true,
                bufferedDuration: 0.3,
                endOfFile: false,
                isLiveStream: false,
                minBufferedDuration: 1.5,
                bufferingStartTime: 10,
                currentTime: 12.1
            ),
            IRFFDecoder.BufferingStatusTransition(buffering: false, bufferingStartTime: 0)
        )
    }
}
