import AVFoundation

enum IRAVPlayerErrorPolicy {

    static func playbackErrorInfo(playerItem: AVPlayerItem?, player: AVPlayer?) -> IRError {
        let errorInfo = IRError()

        if let playerItemError = playerItem?.error {
            errorInfo.error = playerItemError as NSError

            let errorLog = playerItem?.errorLog()
            applyExtendedLogData(
                errorLog?.extendedLogData(),
                stringEncoding: String.Encoding(rawValue: errorLog?.extendedLogDataStringEncoding ?? 0).rawValue,
                to: errorInfo
            )

            if let errorEvents = errorLog?.events {
                errorInfo.errorEvents = errorEvents.map { event in
                    errorEvent(
                        date: event.date,
                        URI: event.uri,
                        serverAddress: event.serverAddress,
                        playbackSessionID: event.playbackSessionID,
                        errorStatusCode: event.errorStatusCode,
                        errorDomain: event.errorDomain,
                        errorComment: event.errorComment
                    )
                }
            }
        } else if let playerError = player?.error {
            errorInfo.error = playerError as NSError
        } else {
            errorInfo.error = NSError(domain: "AVPlayer playback error", code: -1, userInfo: nil)
        }

        return errorInfo
    }

    static func applyExtendedLogData(_ data: Data?, stringEncoding: UInt, to errorInfo: IRError) {
        guard let data, !data.isEmpty else { return }
        errorInfo.extendedLogData = data
        errorInfo.extendedLogDataStringEncoding = stringEncoding
    }

    static func errorEvent(date: Date?,
                           URI: String?,
                           serverAddress: String?,
                           playbackSessionID: String?,
                           errorStatusCode: Int,
                           errorDomain: String,
                           errorComment: String?) -> IRErrorEvent {
        let errorEvent = IRErrorEvent()
        errorEvent.date = date
        errorEvent.URI = URI
        errorEvent.serverAddress = serverAddress
        errorEvent.playbackSessionID = playbackSessionID
        errorEvent.errorStatusCode = errorStatusCode
        errorEvent.errorDomain = errorDomain
        errorEvent.errorComment = errorComment
        return errorEvent
    }
}
