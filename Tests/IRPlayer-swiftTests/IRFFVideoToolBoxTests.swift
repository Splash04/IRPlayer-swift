import CoreMedia
import CoreVideo
import Foundation
import IRFFMpeg
import VideoToolbox
import XCTest
@testable import IRPlayer_swift

final class IRFFVideoToolBoxTests: XCTestCase {

    func testStaticPolicyWrappersRemainSourceCompatible() throws {
        var packet = AVPacket()
        var bytes = [UInt8](arrayLiteral: 0, 0, 1, 42)

        try bytes.withUnsafeMutableBufferPointer { buffer in
            let data = try XCTUnwrap(buffer.baseAddress)
            packet.data = data
            packet.size = Int32(buffer.count)

            let wrapperPacketPayload = try XCTUnwrap(IRFFVideoToolBox.packetPayload(for: packet))
            let policyPacketPayload = try XCTUnwrap(IRFFVideoToolBoxPolicy.packetPayload(for: packet))
            XCTAssertEqual(wrapperPacketPayload.data, policyPacketPayload.data)
            XCTAssertEqual(wrapperPacketPayload.size, policyPacketPayload.size)
            XCTAssertEqual(
                IRFFVideoToolBox.threeByteNALUnitsAreBounded(in: wrapperPacketPayload),
                IRFFVideoToolBoxPolicy.threeByteNALUnitsAreBounded(in: policyPacketPayload)
            )
        }

        XCTAssertEqual(
            IRFFVideoToolBox.setupValidationError(
                codecID: AV_CODEC_ID_AAC,
                extradata: nil,
                extradataSize: 0,
                firstExtradataByte: nil
            ),
            IRFFVideoToolBoxPolicy.setupValidationError(
                codecID: AV_CODEC_ID_AAC,
                extradata: nil,
                extradataSize: 0,
                firstExtradataByte: nil
            )
        )

        let wrapperNALPolicy = IRFFVideoToolBox.nalLengthSizePolicy(for: 0xFE)
        let policyNALPolicy = IRFFVideoToolBoxPolicy.nalLengthSizePolicy(for: 0xFE)
        XCTAssertEqual(wrapperNALPolicy.normalizedMarker, policyNALPolicy.normalizedMarker)
        XCTAssertEqual(wrapperNALPolicy.shouldConvertThreeByteNALUnits, policyNALPolicy.shouldConvertThreeByteNALUnits)

        XCTAssertEqual(
            IRFFVideoToolBox.nalPayloadCanAdvance(nalSize: 2, remainingByteCount: 2),
            IRFFVideoToolBoxPolicy.nalPayloadCanAdvance(nalSize: 2, remainingByteCount: 2)
        )
        XCTAssertEqual(
            IRFFVideoToolBox.decodeFrameSucceeded(status: noErr, callbackStatus: noErr, hasOutput: true),
            IRFFVideoToolBoxPolicy.decodeFrameSucceeded(status: noErr, callbackStatus: noErr, hasOutput: true)
        )
        XCTAssertEqual(
            IRFFVideoToolBox.convertedNALBlockPayload(
                memoryBlock: UnsafeMutablePointer<UInt8>(bitPattern: 1),
                demuxSize: 5,
                packetSize: 4
            )?.dataLength,
            IRFFVideoToolBoxPolicy.convertedNALBlockPayload(
                memoryBlock: UnsafeMutablePointer<UInt8>(bitPattern: 1),
                demuxSize: 5,
                packetSize: 4
            )?.dataLength
        )
        XCTAssertNil(IRFFVideoToolBox.requiredFormatDescription(nil))
        XCTAssertNil(IRFFVideoToolBoxPolicy.requiredFormatDescription(nil))
        XCTAssertNil(IRFFVideoToolBox.decodeFramePayload(session: nil, sampleBuffer: nil))
        XCTAssertNil(IRFFVideoToolBoxPolicy.decodeFramePayload(session: nil, sampleBuffer: nil))
    }

    func testSetupValidationMapsCodecAndExtradataFailures() {
        XCTAssertEqual(
            IRFFVideoToolBox.setupValidationError(codecID: AV_CODEC_ID_AAC, extradata: nil, extradataSize: 0, firstExtradataByte: nil),
            .notH264
        )
        XCTAssertEqual(
            IRFFVideoToolBox.setupValidationError(codecID: AV_CODEC_ID_H264, extradata: nil, extradataSize: 7, firstExtradataByte: nil),
            .extradataSize
        )
        XCTAssertEqual(
            IRFFVideoToolBox.setupValidationError(codecID: AV_CODEC_ID_H264, extradata: UnsafeMutablePointer<UInt8>(bitPattern: 1), extradataSize: 6, firstExtradataByte: 1),
            .extradataSize
        )
        XCTAssertEqual(
            IRFFVideoToolBox.setupValidationError(codecID: AV_CODEC_ID_H264, extradata: UnsafeMutablePointer<UInt8>(bitPattern: 1), extradataSize: 7, firstExtradataByte: 0),
            .extradataData
        )
        XCTAssertNil(
            IRFFVideoToolBox.setupValidationError(codecID: AV_CODEC_ID_H264, extradata: UnsafeMutablePointer<UInt8>(bitPattern: 1), extradataSize: 7, firstExtradataByte: 1)
        )
    }

    func testDecodeFrameSucceededRequiresStatusCallbackAndOutput() {
        XCTAssertFalse(IRFFVideoToolBoxPolicy.decodeFrameSucceeded(status: -1, callbackStatus: noErr, hasOutput: true))
        XCTAssertFalse(IRFFVideoToolBoxPolicy.decodeFrameSucceeded(status: noErr, callbackStatus: -1, hasOutput: true))
        XCTAssertFalse(IRFFVideoToolBoxPolicy.decodeFrameSucceeded(status: noErr, callbackStatus: noErr, hasOutput: false))
    }

    func testNALLengthSizePolicyNormalizesThreeByteMarker() {
        let threeBytePolicy = IRFFVideoToolBox.nalLengthSizePolicy(for: 0xFE)
        XCTAssertEqual(threeBytePolicy.normalizedMarker, 0xFF)
        XCTAssertTrue(threeBytePolicy.shouldConvertThreeByteNALUnits)

        let fourBytePolicy = IRFFVideoToolBox.nalLengthSizePolicy(for: 0xFF)
        XCTAssertEqual(fourBytePolicy.normalizedMarker, 0xFF)
        XCTAssertFalse(fourBytePolicy.shouldConvertThreeByteNALUnits)
    }

    func testThreeByteNALPayloadValidationRejectsTruncatedUnits() throws {
        try assertThreeByteNALPayload([0, 0, 1, 42], isValid: true)
        try assertThreeByteNALPayload([0, 0], isValid: false)
        try assertThreeByteNALPayload([0, 0, 5, 1, 2], isValid: false)
    }

    func testNALPayloadAdvanceValidationUsesRemainingByteCount() {
        XCTAssertTrue(IRFFVideoToolBox.nalPayloadCanAdvance(nalSize: 2, remainingByteCount: 2))
        XCTAssertFalse(IRFFVideoToolBox.nalPayloadCanAdvance(nalSize: 3, remainingByteCount: 2))
        XCTAssertFalse(IRFFVideoToolBox.nalPayloadCanAdvance(nalSize: 0, remainingByteCount: -1))
    }

    func testPacketPayloadRejectsMissingOrEmptyPacketData() {
        var packet = AVPacket()
        packet.size = 4
        XCTAssertNil(IRFFVideoToolBox.packetPayload(for: packet))

        var bytes = [UInt8](arrayLiteral: 1, 2, 3, 4)
        bytes.withUnsafeMutableBufferPointer { buffer in
            packet.data = buffer.baseAddress
            packet.size = 0
            XCTAssertNil(IRFFVideoToolBox.packetPayload(for: packet))

            packet.size = Int32(buffer.count)
            let payload = IRFFVideoToolBox.packetPayload(for: packet)
            XCTAssertEqual(payload?.data, buffer.baseAddress)
            XCTAssertEqual(payload?.size, Int32(buffer.count))
        }
    }

    func testConvertedNALBlockPayloadRejectsMissingOrInvalidBuffer() {
        XCTAssertNil(IRFFVideoToolBox.convertedNALBlockPayload(memoryBlock: nil, demuxSize: 4, packetSize: 4))

        var bytes = [UInt8](arrayLiteral: 1, 2, 3, 4)
        bytes.withUnsafeMutableBufferPointer { buffer in
            let pointer = buffer.baseAddress

            XCTAssertNil(IRFFVideoToolBox.convertedNALBlockPayload(memoryBlock: pointer, demuxSize: 0, packetSize: 4))
            XCTAssertNil(IRFFVideoToolBox.convertedNALBlockPayload(memoryBlock: pointer, demuxSize: 4, packetSize: 0))
            XCTAssertNil(IRFFVideoToolBox.convertedNALBlockPayload(memoryBlock: pointer, demuxSize: 4, packetSize: 5))

            let payload = IRFFVideoToolBox.convertedNALBlockPayload(memoryBlock: pointer, demuxSize: 5, packetSize: 4)
            XCTAssertEqual(payload?.memoryBlock, pointer)
            XCTAssertEqual(payload?.blockLength, 5)
            XCTAssertEqual(payload?.dataLength, 5)
        }
    }

    func testConvertedNALBlockPayloadOwnsDemuxBufferRelease() {
        var bytes = [UInt8](arrayLiteral: 1, 2, 3, 4)
        bytes.withUnsafeMutableBufferPointer { buffer in
            let payload = IRFFVideoToolBox.convertedNALBlockPayload(
                memoryBlock: buffer.baseAddress,
                demuxSize: 4,
                packetSize: 4
            )

            XCTAssertNotNil(payload?.customBlockSource.FreeBlock)
        }
    }

    func testConvertedNALBlockPayloadFreeBlockReleasesAllocatedDemuxBuffer() throws {
        guard let rawMemoryBlock = malloc(4) else {
            throw XCTSkip("Allocator unavailable")
        }
        var didReleaseMemoryBlock = false
        defer {
            if !didReleaseMemoryBlock {
                free(rawMemoryBlock)
            }
        }

        let memoryBlock = rawMemoryBlock.assumingMemoryBound(to: UInt8.self)
        let payload = try XCTUnwrap(IRFFVideoToolBox.convertedNALBlockPayload(
            memoryBlock: memoryBlock,
            demuxSize: 4,
            packetSize: 4
        ))
        let freeBlock = try XCTUnwrap(payload.customBlockSource.FreeBlock)

        freeBlock(payload.customBlockSource.refCon, rawMemoryBlock, payload.blockLength)
        didReleaseMemoryBlock = true
    }

    private func assertThreeByteNALPayload(_ bytes: [UInt8], isValid: Bool, file: StaticString = #filePath, line: UInt = #line) throws {
        var packet = AVPacket()
        var bytes = bytes

        let isBounded = try bytes.withUnsafeMutableBufferPointer { buffer in
            let data = try XCTUnwrap(buffer.baseAddress)
            packet.data = data
            packet.size = Int32(buffer.count)
            let payload = try XCTUnwrap(IRFFVideoToolBox.packetPayload(for: packet))
            return IRFFVideoToolBox.threeByteNALUnitsAreBounded(in: payload)
        }

        XCTAssertEqual(isBounded, isValid, file: file, line: line)
    }

    func testOutputCallbackIgnoresMissingRefConAndUpdatesDecoderState() {
        IRFFVideoToolBox.handleOutputCallback(refCon: nil, status: -1, imageBuffer: nil)

        var codecContext = AVCodecContext()
        withUnsafeMutablePointer(to: &codecContext) { context in
            let videoToolBox = IRFFVideoToolBox.videoToolBox(with: context)
            let refCon = UnsafeMutableRawPointer(Unmanaged.passUnretained(videoToolBox).toOpaque())

            IRFFVideoToolBox.handleOutputCallback(refCon: refCon, status: -2, imageBuffer: nil)

            XCTAssertEqual(videoToolBox.decodeStatus, -2)
            XCTAssertNil(videoToolBox.decodeOutput)
        }
    }

    func testTrySetupVTSessionReturnsFalseForInvalidContextAndHonorsCachedToken() {
        var codecContext = AVCodecContext()
        codecContext.codec_id = AV_CODEC_ID_AAC

        withUnsafeMutablePointer(to: &codecContext) { context in
            let videoToolBox = IRFFVideoToolBox.videoToolBox(with: context)

            XCTAssertFalse(videoToolBox.trySetupVTSession())
            XCTAssertFalse(videoToolBox.vtSessionToken)

            videoToolBox.vtSessionToken = true

            XCTAssertTrue(videoToolBox.trySetupVTSession())
        }
    }

    func testSetupVTSessionNormalizesThreeByteNALMarkerBeforeSessionAttempt() {
        var codecContext = AVCodecContext()
        codecContext.codec_id = AV_CODEC_ID_H264
        codecContext.width = 0
        codecContext.height = 0

        var extradata = [UInt8](arrayLiteral: 1, 0, 0, 0, 0xFE, 0, 0)
        extradata.withUnsafeMutableBufferPointer { buffer in
            codecContext.extradata = buffer.baseAddress
            codecContext.extradata_size = Int32(buffer.count)

            withUnsafeMutablePointer(to: &codecContext) { context in
                let videoToolBox = IRFFVideoToolBox.videoToolBox(with: context)

                do {
                    try videoToolBox.setupVTSession()
                } catch {
                    XCTAssertTrue(
                        [.createFormatDescription, .createSession].contains(error as? IRFFVideoToolBoxErrorCode)
                    )
                }
                XCTAssertEqual(buffer[4], 0xFF)
                XCTAssertTrue(videoToolBox.needConvertNALSize3To4)
                XCTAssertNil(videoToolBox.imageBuffer())

                videoToolBox.cleanVTSession()
                XCTAssertFalse(videoToolBox.needConvertNALSize3To4)
                XCTAssertFalse(videoToolBox.vtSessionToken)
            }
        }
    }

    func testSendPacketShortCircuitsForInvalidSetupMissingPacketAndMissingFormatDescription() {
        var codecContext = AVCodecContext()
        codecContext.codec_id = AV_CODEC_ID_AAC

        withUnsafeMutablePointer(to: &codecContext) { context in
            let videoToolBox = IRFFVideoToolBox.videoToolBox(with: context)

            XCTAssertFalse(videoToolBox.sendPacket(AVPacket()))

            videoToolBox.vtSessionToken = true

            XCTAssertFalse(videoToolBox.sendPacket(AVPacket()))

            var bytes = [UInt8](arrayLiteral: 0, 0, 0, 1)
            bytes.withUnsafeMutableBufferPointer { buffer in
                let packet = makePacket(data: buffer.baseAddress, size: buffer.count)

                XCTAssertFalse(videoToolBox.sendPacket(packet))
                XCTAssertEqual(videoToolBox.decodeStatus, noErr)
                XCTAssertNil(videoToolBox.decodeOutput)
            }
        }
    }

    func testSendPacketRejectsUnboundedThreeByteNALPayloadBeforeConversion() {
        var codecContext = AVCodecContext()

        withUnsafeMutablePointer(to: &codecContext) { context in
            let videoToolBox = IRFFVideoToolBox.videoToolBox(with: context)
            videoToolBox.vtSessionToken = true
            videoToolBox.needConvertNALSize3To4 = true

            var bytes = [UInt8](arrayLiteral: 0, 0, 5, 1, 2)
            bytes.withUnsafeMutableBufferPointer { buffer in
                let packet = makePacket(data: buffer.baseAddress, size: buffer.count)

                XCTAssertFalse(videoToolBox.sendPacket(packet))
                XCTAssertEqual(videoToolBox.decodeStatus, noErr)
                XCTAssertNil(videoToolBox.decodeOutput)
            }
        }
    }

    func testImageBufferReturnsOnlySuccessfulDecodeOutput() throws {
        var codecContext = AVCodecContext()

        try withUnsafeMutablePointer(to: &codecContext) { context in
            let videoToolBox = IRFFVideoToolBox.videoToolBox(with: context)

            XCTAssertNil(videoToolBox.imageBuffer())

            var pixelBuffer: CVPixelBuffer?
            let status = CVPixelBufferCreate(
                nil,
                4,
                4,
                kCVPixelFormatType_32BGRA,
                nil,
                &pixelBuffer
            )
            XCTAssertEqual(status, kCVReturnSuccess)
            let imageBuffer = try XCTUnwrap(pixelBuffer)

            videoToolBox.decodeStatus = noErr
            videoToolBox.decodeOutput = imageBuffer

            XCTAssertTrue(videoToolBox.imageBuffer() === imageBuffer)

            videoToolBox.decodeStatus = -1

            XCTAssertNil(videoToolBox.imageBuffer())

            videoToolBox.decodeStatus = noErr
            videoToolBox.cleanDecodeInfo()

            XCTAssertNil(videoToolBox.imageBuffer())
        }
    }

    func testReleaseDoesNotPrintDebugOutput() {
        var codecContext = AVCodecContext()

        let output = withUnsafeMutablePointer(to: &codecContext) { context in
            var videoToolBox: IRFFVideoToolBox? = IRFFVideoToolBox.videoToolBox(with: context)
            XCTAssertNotNil(videoToolBox)

            return captureStandardOutput {
                videoToolBox = nil
            }
        }

        XCTAssertEqual(output, "")
    }

    func testFormatDescriptionExtensionsIncludeExpectedAVCCAtom() throws {
        let extradata = [UInt8](arrayLiteral: 1, 2, 3, 4)

        let extensions: NSDictionary = try extradata.withUnsafeBufferPointer { buffer in
            let pointer = try XCTUnwrap(buffer.baseAddress)
            return IRFFVideoToolBox.makeFormatDescriptionExtensions(extradata: pointer, extradataSize: Int32(buffer.count)) as NSDictionary
        }

        let atoms = try XCTUnwrap(extensions["SampleDescriptionExtensionAtoms"] as? NSDictionary)
        let avcC = try XCTUnwrap(atoms["avcC"] as? Data)
        XCTAssertEqual(Array(avcC), extradata)
        XCTAssertEqual(extensions["CVImageBufferChromaLocationBottomField"] as? String, "left")
        XCTAssertEqual(extensions["CVImageBufferChromaLocationTopField"] as? String, "left")
        XCTAssertEqual(extensions["FullRangeVideo"] as? Bool, false)
    }

    func testFormatDescriptionExtensionsClampInvalidExtradataSize() throws {
        let extradata = [UInt8](arrayLiteral: 1)

        let extensions: NSDictionary = try extradata.withUnsafeBufferPointer { buffer in
            let pointer = try XCTUnwrap(buffer.baseAddress)
            return IRFFVideoToolBox.makeFormatDescriptionExtensions(extradata: pointer, extradataSize: -1) as NSDictionary
        }

        let atoms = try XCTUnwrap(extensions["SampleDescriptionExtensionAtoms"] as? NSDictionary)
        let avcC = try XCTUnwrap(atoms["avcC"] as? Data)
        XCTAssertEqual(avcC.count, 0)
    }

    func testRequiredFormatDescriptionRejectsMissingDescription() throws {
        XCTAssertNil(IRFFVideoToolBox.requiredFormatDescription(nil))

        var formatDescription: CMFormatDescription?
        let status = CMVideoFormatDescriptionCreate(
            allocator: nil,
            codecType: kCMVideoCodecType_H264,
            width: 16,
            height: 8,
            extensions: nil,
            formatDescriptionOut: &formatDescription
        )

        XCTAssertEqual(status, noErr)
        let payload = try XCTUnwrap(IRFFVideoToolBox.requiredFormatDescription(formatDescription))
        let dimensions = CMVideoFormatDescriptionGetDimensions(payload)
        XCTAssertEqual(dimensions.width, 16)
        XCTAssertEqual(dimensions.height, 8)
    }

    func testDecodeFramePayloadRejectsMissingInputs() {
        XCTAssertNil(IRFFVideoToolBox.decodeFramePayload(session: nil, sampleBuffer: nil))
    }

    func testDecodeFramePayloadWrapsValidInputs() throws {
        var createdFormatDescription: CMFormatDescription?
        let formatStatus = CMVideoFormatDescriptionCreate(
            allocator: nil,
            codecType: kCMVideoCodecType_H264,
            width: 16,
            height: 8,
            extensions: nil,
            formatDescriptionOut: &createdFormatDescription
        )
        XCTAssertEqual(formatStatus, noErr)
        let formatDescription = try XCTUnwrap(createdFormatDescription)

        let pixelBufferAttributes: [CFString: Any] = [
            kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
            kCVPixelBufferWidthKey: 16,
            kCVPixelBufferHeightKey: 8,
            kCVPixelBufferIOSurfacePropertiesKey: [:]
        ]

        var session: VTDecompressionSession?
        var callbackRecord = VTDecompressionOutputCallbackRecord()
        let sessionStatus = VTDecompressionSessionCreate(
            allocator: nil,
            formatDescription: formatDescription,
            decoderSpecification: nil,
            imageBufferAttributes: pixelBufferAttributes as CFDictionary,
            outputCallback: &callbackRecord,
            decompressionSessionOut: &session
        )
        guard sessionStatus == noErr, let session else {
            throw XCTSkip("VideoToolbox decompression session unavailable")
        }
        defer { VTDecompressionSessionInvalidate(session) }

        var sampleBuffer: CMSampleBuffer?
        let sampleStatus = CMSampleBufferCreate(
            allocator: nil,
            dataBuffer: nil,
            dataReady: true,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: formatDescription,
            sampleCount: 0,
            sampleTimingEntryCount: 0,
            sampleTimingArray: nil,
            sampleSizeEntryCount: 0,
            sampleSizeArray: nil,
            sampleBufferOut: &sampleBuffer
        )
        XCTAssertEqual(sampleStatus, noErr)

        let payload = try XCTUnwrap(IRFFVideoToolBox.decodeFramePayload(session: session, sampleBuffer: sampleBuffer))
        XCTAssertTrue(VTDecompressionSessionCanAcceptFormatDescription(payload.session, formatDescription: formatDescription))
        XCTAssertEqual(CFGetTypeID(payload.sampleBuffer), CMSampleBufferGetTypeID())
    }

    func testDecodeFrameSuccessRequiresAllStatusesAndOutput() {
        XCTAssertTrue(IRFFVideoToolBox.decodeFrameSucceeded(status: noErr, callbackStatus: noErr, hasOutput: true))
        XCTAssertFalse(IRFFVideoToolBox.decodeFrameSucceeded(status: -1, callbackStatus: noErr, hasOutput: true))
        XCTAssertFalse(IRFFVideoToolBox.decodeFrameSucceeded(status: noErr, callbackStatus: -1, hasOutput: true))
        XCTAssertFalse(IRFFVideoToolBox.decodeFrameSucceeded(status: noErr, callbackStatus: noErr, hasOutput: false))
    }

    private func makePacket(data: UnsafeMutablePointer<UInt8>?, size: Int) -> AVPacket {
        var packet = AVPacket()
        packet.data = data
        packet.size = Int32(size)
        return packet
    }
}
