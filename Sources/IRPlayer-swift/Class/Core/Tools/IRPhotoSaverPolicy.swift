//
//  IRPhotoSaverPolicy.swift
//  IRPlayer-swift
//
//  Created by Codex on 2026/6/2.
//

import Foundation
import Photos

enum IRPhotoSaverPolicy {
    #if IRPhotoSaverDiagnosticOutputEnable
    static let isDiagnosticOutputEnabled = true
    #else
    static let isDiagnosticOutputEnabled = false
    #endif

    static func writeDiagnostic(for failure: IRPhotoSaver.Failure) {
        guard isDiagnosticOutputEnabled else { return }
        guard let message = diagnosticMessage(for: failure) else { return }
        print(message)
    }

    static func diagnosticMessage(for _: IRPhotoSaver.Failure) -> String? {
        nil
    }

    static func photoLibraryAccessIsGranted(_ status: PHAuthorizationStatus) -> Bool {
        status == .authorized || status == .limited
    }
}
