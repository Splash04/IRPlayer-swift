//
//  IRFFDictionaryPolicy.swift
//  IRPlayer-swift
//
//  Created by Codex on 2026/6/2.
//

import Foundation
import IRFFMpeg

enum IRFFDictionaryPolicy {
    static func avDictionary(entries: [(key: String, value: String)]) -> AVDictionary? {
        var avDictionary = AVDictionary(rawPointer: nil)

        for entry in entries {
            let result = entry.key.withCString { key in
                entry.value.withCString { value in
                    av_dict_set(&avDictionary.rawPointer, key, value, 0)
                }
            }

            guard result >= 0 else {
                freeAVDictionary(&avDictionary)
                return nil
            }
        }

        return avDictionary.rawPointer == nil ? nil : avDictionary
    }

    static func freeAVDictionary(_ avDictionary: inout AVDictionary) {
        av_dict_free(&avDictionary.rawPointer)
    }

    static func string(fromCString cString: UnsafePointer<CChar>?) -> String? {
        guard let cString else { return nil }
        return String(validatingUTF8: cString)
    }

    static func foundationDictionary(from avDictionary: OpaquePointer?) -> [String: String]? {
        guard let avDictionary = avDictionary else { return nil }

        var entries: [(key: UnsafePointer<CChar>?, value: UnsafePointer<CChar>?)] = []
        var entry: UnsafeMutablePointer<AVDictionaryEntry>? = nil

        while let nextEntry = av_dict_get(avDictionary, "", entry, AV_DICT_IGNORE_SUFFIX) {
            entries.append((key: UnsafePointer(nextEntry.pointee.key),
                            value: UnsafePointer(nextEntry.pointee.value)))
            entry = nextEntry
        }

        return foundationDictionary(entries: entries)
    }

    static func foundationDictionary(entries: [(key: UnsafePointer<CChar>?, value: UnsafePointer<CChar>?)]) -> [String: String]? {
        var dictionary: [String: String] = [:]

        for entry in entries {
            if let keyString = string(fromCString: entry.key),
               let valueString = string(fromCString: entry.value) {
                dictionary[keyString] = valueString
            }
        }

        return dictionary.isEmpty ? nil : dictionary
    }
}
