//
//  IRPhotoSaver.swift
//  IRPlayer
//
//  Created by Phil on 2025/11/24.
//

import Photos
import UIKit

enum IRPhotoSaver {

    enum Failure {
        case permissionNotGranted
        case albumUnavailable
    }

    static func save(_ image: UIImage, toAlbum albumName: String? = nil) {
        requestPermission { granted in
            guard granted else {
                writeDiagnostic(for: .permissionNotGranted)
                return
            }

            switch Self.saveDestination(albumName: albumName) {
            case .library:
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                })
                return

            case .album(let albumName):
                fetchOrCreateAlbum(named: albumName) { album in
                    guard let album = album else {
                        writeDiagnostic(for: .albumUnavailable)
                        return
                    }

                    PHPhotoLibrary.shared().performChanges({
                        let createAsset = PHAssetChangeRequest.creationRequestForAsset(from: image)
                        guard let placeholder = createAsset.placeholderForCreatedAsset else { return }

                        if let albumChange = PHAssetCollectionChangeRequest(for: album) {
                            albumChange.addAssets([placeholder] as NSArray)
                        }
                    })
                }
            }
        }
    }

    static func writeDiagnostic(for failure: Failure) {
        IRPhotoSaverPolicy.writeDiagnostic(for: failure)
    }

    static var isDiagnosticOutputEnabled: Bool {
        IRPhotoSaverPolicy.isDiagnosticOutputEnabled
    }

    static func diagnosticMessage(for failure: Failure) -> String? {
        IRPhotoSaverPolicy.diagnosticMessage(for: failure)
    }

    static func photoLibraryAccessIsGranted(_ status: PHAuthorizationStatus) -> Bool {
        IRPhotoSaverPolicy.photoLibraryAccessIsGranted(status)
    }

    static func saveDestination(albumName: String?) -> IRPhotoSaverPolicy.SaveDestination {
        IRPhotoSaverPolicy.saveDestination(albumName: albumName)
    }

    static func createdAlbumIdentifier(success: Bool, placeholderLocalIdentifier: String?) -> String? {
        IRPhotoSaverPolicy.createdAlbumIdentifier(success: success,
                                                  placeholderLocalIdentifier: placeholderLocalIdentifier)
    }

    private static func requestPermission(completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            completion(Self.photoLibraryAccessIsGranted(status))
        }
    }

    private static func fetchOrCreateAlbum(named name: String,
                                           completion: @escaping (PHAssetCollection?) -> Void) {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "title = %@", name)
        let result = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: options)

        if let existing = result.firstObject {
            completion(existing)
            return
        }

        var placeholder: PHObjectPlaceholder?

        PHPhotoLibrary.shared().performChanges({
            let create = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: name)
            placeholder = create.placeholderForCreatedAssetCollection
        }) { success, _ in
            guard let id = Self.createdAlbumIdentifier(success: success,
                                                       placeholderLocalIdentifier: placeholder?.localIdentifier) else {
                completion(nil)
                return
            }
            let fetch = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [id], options: nil)
            completion(fetch.firstObject)
        }
    }
}
