import AVFoundation

enum IRAVPlayerErrorPolicy {

    struct ErrorLogEventSnapshot {
        let date: Date?
        let URI: String?
        let serverAddress: String?
        let playbackSessionID: String?
        let errorStatusCode: Int
        let errorDomain: String
        let errorComment: String?
    }

    static func playbackErrorInfo(playerItem: AVPlayerItem?, player: AVPlayer?) -> IRError {
        let errorLog = playerItem?.error == nil ? nil : playerItem?.errorLog()

        return errorInfo(
            playerItemError: playerItem?.error as NSError?,
            playerError: player?.error as NSError?,
            extendedLogData: errorLog?.extendedLogData(),
            extendedLogDataStringEncoding: String.Encoding(rawValue: errorLog?.extendedLogDataStringEncoding ?? 0).rawValue,
            errorEvents: errorLog?.events.map { event in
                ErrorLogEventSnapshot(
                    date: event.date,
                    URI: event.uri,
                    serverAddress: event.serverAddress,
                    playbackSessionID: event.playbackSessionID,
                    errorStatusCode: event.errorStatusCode,
                    errorDomain: event.errorDomain,
                    errorComment: event.errorComment
                )
            }
        )
    }

    static func errorInfo(playerItemError: NSError?,
                          playerError: NSError?,
                          extendedLogData: Data?,
                          extendedLogDataStringEncoding: UInt,
                          errorEvents: [ErrorLogEventSnapshot]?) -> IRError {
        let errorInfo = IRError()

        if let playerItemError {
            errorInfo.error = playerItemError
            applyExtendedLogData(
                extendedLogData,
                stringEncoding: extendedLogDataStringEncoding,
                to: errorInfo
            )

            if let errorEvents {
                errorInfo.errorEvents = errorEvents.map { event in
                    errorEvent(
                        date: event.date,
                        URI: event.URI,
                        serverAddress: event.serverAddress,
                        playbackSessionID: event.playbackSessionID,
                        errorStatusCode: event.errorStatusCode,
                        errorDomain: event.errorDomain,
                        errorComment: event.errorComment
                    )
                }
            }
        } else if let playerError {
            errorInfo.error = playerError
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
