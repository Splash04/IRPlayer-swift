import XCTest
@testable import IRPlayer_swift

final class IRFFDictionaryPolicyTests: XCTestCase {

    func testFoundationDictionaryReturnsNilForMissingDictionary() {
        XCTAssertNil(IRFFDictionaryPolicy.foundationDictionary(from: nil))
    }

    func testCStringDecodingRejectsMissingAndMalformedUTF8Pointers() throws {
        XCTAssertNil(IRFFDictionaryPolicy.string(fromCString: nil))

        let invalidValue: [CChar] = [-1, 0]
        try invalidValue.withUnsafeBufferPointer { buffer in
            let value = try XCTUnwrap(buffer.baseAddress)
            XCTAssertNil(IRFFDictionaryPolicy.string(fromCString: value))
        }
    }

    func testCStringDecodingReturnsValidUTF8Strings() {
        "Camera 1".withCString { value in
            XCTAssertEqual(IRFFDictionaryPolicy.string(fromCString: value), "Camera 1")
        }
    }

    func testFoundationDictionaryEntriesBridgeValidCStringPairsAndSkipMalformedPairs() throws {
        let invalidValue: [CChar] = [-1, 0]

        try invalidValue.withUnsafeBufferPointer { invalidBuffer in
            let invalidCString = try XCTUnwrap(invalidBuffer.baseAddress)
            "language".withCString { languageKey in
                "eng".withCString { languageValue in
                    "title".withCString { titleKey in
                        let bridgedDictionary = IRFFDictionaryPolicy.foundationDictionary(entries: [
                            (key: languageKey, value: languageValue),
                            (key: titleKey, value: invalidCString)
                        ])

                        XCTAssertEqual(bridgedDictionary?["language"], "eng")
                        XCTAssertNil(bridgedDictionary?["title"])
                        XCTAssertEqual(bridgedDictionary?.count, 1)
                    }
                }
            }
        }
    }
}
