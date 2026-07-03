import Foundation

enum IRFFDecoderAudioPolicy {

    static func audioPacketError(fromPacketResult packetResult: Int) -> NSError? {
        return IRFFCheckErrorCode(Int32(packetResult), errorCode: IRFFDecoderErrorCode.codecAudioSendPacket.rawValue)
    }

    static func bufferedDurationTransition(bufferedDuration: TimeInterval, endOfFile: Bool) -> IRFFDecoder.BufferedDurationTransition {
        let normalizedDuration = bufferedDuration.isFinite && bufferedDuration > 0.000001 ? bufferedDuration : 0
        return IRFFDecoder.BufferedDurationTransition(
            bufferedDuration: normalizedDuration,
            shouldFinishPlayback: normalizedDuration <= 0 && endOfFile
        )
    }

    static func shouldFetchAudioFrame(closed: Bool,
                                      seeking: Bool,
                                      buffering: Bool,
                                      paused: Bool,
                                      playbackFinished: Bool,
                                      audioEnabled: Bool) -> Bool {
        return !closed && !seeking && !buffering && !paused && !playbackFinished && audioEnabled
    }
}

enum IRFFDecoderBufferingPolicy {

    static func statusTransition(buffering: Bool,
                                 bufferedDuration: TimeInterval,
                                 endOfFile: Bool,
                                 isLiveStream: Bool,
                                 minBufferedDuration: TimeInterval,
                                 bufferingStartTime: TimeInterval,
                                 currentTime: TimeInterval) -> IRFFDecoder.BufferingStatusTransition {
        if buffering {
            let bufferingElapsed = currentTime - bufferingStartTime
            let maxDuration: TimeInterval = isLiveStream ? 1.0 : 2.0
            let minThreshold: TimeInterval = isLiveStream ? 0.2 : 0.3
            let effectiveMinBufferedDuration: TimeInterval = isLiveStream ? 0 : minBufferedDuration
            let shouldExitBuffering = (bufferedDuration >= effectiveMinBufferedDuration) ||
                                      endOfFile ||
                                      (bufferingElapsed > maxDuration && bufferedDuration >= minThreshold)

            if shouldExitBuffering {
                return IRFFDecoder.BufferingStatusTransition(buffering: false, bufferingStartTime: 0)
            }
        } else if bufferedDuration <= 0.2 && !endOfFile && !isLiveStream {
            return IRFFDecoder.BufferingStatusTransition(buffering: true, bufferingStartTime: currentTime)
        } else if bufferedDuration <= 0.05 && !endOfFile && isLiveStream {
            return IRFFDecoder.BufferingStatusTransition(buffering: true, bufferingStartTime: currentTime)
        }

        return IRFFDecoder.BufferingStatusTransition(
            buffering: buffering,
            bufferingStartTime: bufferingStartTime
        )
    }
}
