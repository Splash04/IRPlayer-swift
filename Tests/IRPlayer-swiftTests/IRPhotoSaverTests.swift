//
//  IRPhotoSaverTests.swift
//  IRPlayer-swiftTests
//
//  Created by Codex on 2026/6/2.
//

import XCTest
import Photos
@testable import IRPlayer_swift

final class IRPhotoSaverTests: XCTestCase {

    func testDiagnosticsAreSilentByDefault() {
        let output = captureStandardOutput {
            IRPhotoSaver.writeDiagnostic(for: .permissionNotGranted)
            IRPhotoSaver.writeDiagnostic(for: .albumUnavailable)
        }

        XCTAssertEqual(output, "")
    }

    func testDiagnosticMessageWrapperMatchesPolicy() {
        XCTAssertEqual(IRPhotoSaver.isDiagnosticOutputEnabled, IRPhotoSaverPolicy.isDiagnosticOutputEnabled)
        XCTAssertFalse(IRPhotoSaverPolicy.isDiagnosticOutputEnabled)
        XCTAssertEqual(IRPhotoSaver.diagnosticMessage(for: .permissionNotGranted),
                       IRPhotoSaverPolicy.diagnosticMessage(for: .permissionNotGranted))
        XCTAssertEqual(IRPhotoSaver.diagnosticMessage(for: .albumUnavailable),
                       IRPhotoSaverPolicy.diagnosticMessage(for: .albumUnavailable))
        XCTAssertNil(IRPhotoSaverPolicy.diagnosticMessage(for: .permissionNotGranted))
    }

    func testDiagnosticWriterWrapperMatchesPolicy() {
        let wrapperOutput = captureStandardOutput {
            IRPhotoSaver.writeDiagnostic(for: .permissionNotGranted)
        }
        let policyOutput = captureStandardOutput {
            IRPhotoSaverPolicy.writeDiagnostic(for: .permissionNotGranted)
        }

        XCTAssertEqual(wrapperOutput, policyOutput)
    }

    func testPhotoLibraryAccessIsGrantedForAuthorizedAndLimitedStatusesOnly() {
        XCTAssertTrue(IRPhotoSaverPolicy.photoLibraryAccessIsGranted(.authorized))
        XCTAssertTrue(IRPhotoSaverPolicy.photoLibraryAccessIsGranted(.limited))
        XCTAssertFalse(IRPhotoSaverPolicy.photoLibraryAccessIsGranted(.denied))
        XCTAssertFalse(IRPhotoSaverPolicy.photoLibraryAccessIsGranted(.restricted))
        XCTAssertFalse(IRPhotoSaverPolicy.photoLibraryAccessIsGranted(.notDetermined))
    }

    func testPhotoLibraryAccessWrapperMatchesPolicy() {
        XCTAssertEqual(
            IRPhotoSaver.photoLibraryAccessIsGranted(.authorized),
            IRPhotoSaverPolicy.photoLibraryAccessIsGranted(.authorized)
        )
        XCTAssertEqual(
            IRPhotoSaver.photoLibraryAccessIsGranted(.denied),
            IRPhotoSaverPolicy.photoLibraryAccessIsGranted(.denied)
        )
    }

    func testSaveDestinationUsesLibraryWhenAlbumNameIsMissing() {
        XCTAssertEqual(IRPhotoSaverPolicy.saveDestination(albumName: nil), .library)
        XCTAssertEqual(IRPhotoSaver.saveDestination(albumName: nil), .library)
    }

    func testSaveDestinationUsesAlbumWhenNameIsProvided() {
        XCTAssertEqual(IRPhotoSaverPolicy.saveDestination(albumName: "Snapshots"), .album("Snapshots"))
        XCTAssertEqual(IRPhotoSaver.saveDestination(albumName: "Snapshots"), .album("Snapshots"))
    }

    func testCreatedAlbumIdentifierRequiresSuccessAndPlaceholderID() {
        XCTAssertNil(
            IRPhotoSaverPolicy.createdAlbumIdentifier(success: false, placeholderLocalIdentifier: "album-id")
        )
        XCTAssertNil(
            IRPhotoSaverPolicy.createdAlbumIdentifier(success: true, placeholderLocalIdentifier: nil)
        )
        XCTAssertEqual(
            IRPhotoSaverPolicy.createdAlbumIdentifier(success: true, placeholderLocalIdentifier: "album-id"),
            "album-id"
        )
        XCTAssertEqual(
            IRPhotoSaver.createdAlbumIdentifier(success: true, placeholderLocalIdentifier: "album-id"),
            "album-id"
        )
    }
}
