//
//  IRFFDictionaryPolicy.swift
//  IRPlayer-swift
//
//  Created by Codex on 2026/6/2.
//

import Foundation
import IRFFMpeg

enum IRFFDictionaryPolicy {
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
