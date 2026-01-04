// BinaryInputContentTests.swift
// AGUISwift

import XCTest
@testable import AGUICore

/// Tests for the BinaryInputContent type
final class BinaryInputContentTests: XCTestCase {
    // MARK: - Initialization Tests

    func testInitWithURL() {
        let content = BinaryInputContent(
            mimeType: "image/png",
            url: "https://example.com/image.png"
        )

        XCTAssertEqual(content.mimeType, "image/png")
        XCTAssertEqual(content.url, "https://example.com/image.png")
        XCTAssertNil(content.id)
        XCTAssertNil(content.data)
        XCTAssertNil(content.filename)
        XCTAssertEqual(content.type, "binary")
    }

    func testInitWithID() {
        let content = BinaryInputContent(
            mimeType: "application/pdf",
            id: "file-123"
        )

        XCTAssertEqual(content.mimeType, "application/pdf")
        XCTAssertEqual(content.id, "file-123")
        XCTAssertNil(content.url)
        XCTAssertNil(content.data)
    }

    func testInitWithData() {
        let base64Data = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg=="

        let content = BinaryInputContent(
            mimeType: "image/png",
            data: base64Data
        )

        XCTAssertEqual(content.mimeType, "image/png")
        XCTAssertEqual(content.data, base64Data)
        XCTAssertNil(content.id)
        XCTAssertNil(content.url)
    }

    func testInitWithAllFields() throws {
        let content = try BinaryInputContent(
            mimeType: "image/jpeg",
            id: "img-456",
            url: "https://example.com/photo.jpg",
            data: "base64data",
            filename: "vacation.jpg"
        )

        XCTAssertEqual(content.mimeType, "image/jpeg")
        XCTAssertEqual(content.id, "img-456")
        XCTAssertEqual(content.url, "https://example.com/photo.jpg")
        XCTAssertEqual(content.data, "base64data")
        XCTAssertEqual(content.filename, "vacation.jpg")
    }

    func testInitWithFilename() {
        let content = BinaryInputContent(
            mimeType: "application/pdf",
            url: "https://docs.example.com/report.pdf",
            filename: "quarterly-report.pdf"
        )

        XCTAssertEqual(content.filename, "quarterly-report.pdf")
    }

    // MARK: - Validation Tests

    func testInitFailsWithoutSourceFields() {
        XCTAssertThrowsError(
            try BinaryInputContent.validate(
                mimeType: "image/png",
                id: nil,
                url: nil,
                data: nil
            )
        ) { error in
            guard case BinaryInputContent.ValidationError.noSourceProvided = error else {
                XCTFail("Expected ValidationError.noSourceProvided but got \(error)")
                return
            }
        }
    }

    // MARK: - InputContent Protocol Conformance Tests

    func testConformsToInputContent() {
        let content: any InputContent = BinaryInputContent(
            mimeType: "image/png",
            url: "https://example.com/test.png"
        )

        XCTAssertEqual(content.type, "binary")
    }

    func testMixedInputContentArray() {
        let contents: [any InputContent] = [
            TextInputContent(text: "Check this image:"),
            BinaryInputContent(mimeType: "image/png", url: "https://example.com/photo.png"),
            TextInputContent(text: "What do you see?")
        ]

        XCTAssertEqual(contents.count, 3)
        XCTAssertEqual(contents[0].type, "text")
        XCTAssertEqual(contents[1].type, "binary")
        XCTAssertEqual(contents[2].type, "text")
    }

    // MARK: - Encoding Tests

    func testEncodingWithURL() throws {
        let content = BinaryInputContent(
            mimeType: "image/jpeg",
            url: "https://example.com/test.jpg"
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let encoded = try encoder.encode(content)
        let json = String(data: encoded, encoding: .utf8)

        XCTAssertNotNil(json)
        XCTAssertTrue(json?.contains("\"type\"") ?? false)
        XCTAssertTrue(json?.contains("\"binary\"") ?? false)
        XCTAssertTrue(json?.contains("\"mimeType\"") ?? false)
        XCTAssertTrue(json?.contains("\"url\"") ?? false)
    }

    func testEncodedStructure() throws {
        let content = BinaryInputContent(
            mimeType: "audio/mp3",
            id: "audio-123",
            filename: "song.mp3"
        )

        let encoded = try JSONEncoder().encode(content)
        let json = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]

        XCTAssertEqual(json?["type"] as? String, "binary")
        XCTAssertEqual(json?["mimeType"] as? String, "audio/mp3")
        XCTAssertEqual(json?["id"] as? String, "audio-123")
        XCTAssertEqual(json?["filename"] as? String, "song.mp3")
    }

    // MARK: - Decoding Tests

    func testDecodingWithURL() throws {
        let json = """
        {
            "type": "binary",
            "mimeType": "image/png",
            "url": "https://example.com/image.png"
        }
        """

        let decoder = JSONDecoder()
        let content = try decoder.decode(BinaryInputContent.self, from: Data(json.utf8))

        XCTAssertEqual(content.type, "binary")
        XCTAssertEqual(content.mimeType, "image/png")
        XCTAssertEqual(content.url, "https://example.com/image.png")
        XCTAssertNil(content.id)
        XCTAssertNil(content.data)
    }

    func testDecodingWithID() throws {
        let json = """
        {
            "type": "binary",
            "mimeType": "application/pdf",
            "id": "doc-456"
        }
        """

        let decoder = JSONDecoder()
        let content = try decoder.decode(BinaryInputContent.self, from: Data(json.utf8))

        XCTAssertEqual(content.id, "doc-456")
    }

    func testDecodingWithData() throws {
        let json = """
        {
            "type": "binary",
            "mimeType": "image/png",
            "data": "iVBORw0KGgo="
        }
        """

        let decoder = JSONDecoder()
        let content = try decoder.decode(BinaryInputContent.self, from: Data(json.utf8))

        XCTAssertEqual(content.data, "iVBORw0KGgo=")
    }

    func testDecodingWithAllFields() throws {
        let json = """
        {
            "type": "binary",
            "mimeType": "image/jpeg",
            "id": "img-789",
            "url": "https://example.com/photo.jpg",
            "data": "base64data",
            "filename": "photo.jpg"
        }
        """

        let decoder = JSONDecoder()
        let content = try decoder.decode(BinaryInputContent.self, from: Data(json.utf8))

        XCTAssertEqual(content.mimeType, "image/jpeg")
        XCTAssertEqual(content.id, "img-789")
        XCTAssertEqual(content.url, "https://example.com/photo.jpg")
        XCTAssertEqual(content.data, "base64data")
        XCTAssertEqual(content.filename, "photo.jpg")
    }

    func testDecodingFailsWithoutMimeType() {
        let json = """
        {
            "type": "binary",
            "url": "https://example.com/file"
        }
        """

        let decoder = JSONDecoder()
        XCTAssertThrowsError(try decoder.decode(BinaryInputContent.self, from: Data(json.utf8))) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testDecodingFailsWithoutAnySource() {
        let json = """
        {
            "type": "binary",
            "mimeType": "image/png"
        }
        """

        let decoder = JSONDecoder()
        XCTAssertThrowsError(try decoder.decode(BinaryInputContent.self, from: Data(json.utf8)))
    }

    // MARK: - Round-trip Tests

    func testRoundTripWithURL() throws {
        let original = BinaryInputContent(
            mimeType: "video/mp4",
            url: "https://example.com/video.mp4",
            filename: "demo.mp4"
        )

        let encoder = JSONEncoder()
        let encoded = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(BinaryInputContent.self, from: encoded)

        XCTAssertEqual(decoded.type, original.type)
        XCTAssertEqual(decoded.mimeType, original.mimeType)
        XCTAssertEqual(decoded.url, original.url)
        XCTAssertEqual(decoded.filename, original.filename)
    }

    // MARK: - Equatable Tests

    func testEquality() {
        let content1 = BinaryInputContent(mimeType: "image/png", url: "https://test.com/1.png")
        let content2 = BinaryInputContent(mimeType: "image/png", url: "https://test.com/1.png")
        let content3 = BinaryInputContent(mimeType: "image/jpeg", url: "https://test.com/1.png")
        let content4 = BinaryInputContent(mimeType: "image/png", id: "img-1")

        XCTAssertEqual(content1, content2)
        XCTAssertNotEqual(content1, content3)
        XCTAssertNotEqual(content1, content4)
    }

    // MARK: - Hashable Tests

    func testHashable() {
        let content1 = BinaryInputContent(mimeType: "image/png", id: "img-1")
        let content2 = BinaryInputContent(mimeType: "image/png", id: "img-2")

        let set: Set<BinaryInputContent> = [content1, content2]
        XCTAssertEqual(set.count, 2)
        XCTAssertTrue(set.contains(content1))
        XCTAssertTrue(set.contains(content2))
    }

    // MARK: - Sendable Tests

    func testSendableConformance() {
        let content = BinaryInputContent(mimeType: "image/png", url: "https://test.com/img.png")

        Task {
            let capturedContent = content
            XCTAssertEqual(capturedContent.mimeType, "image/png")
        }
    }

    // MARK: - Real-world Usage Tests

    func testImageFromURL() {
        let imageContent = BinaryInputContent(
            mimeType: "image/jpeg",
            url: "https://photos.example.com/sunset.jpg",
            filename: "sunset.jpg"
        )

        XCTAssertEqual(imageContent.mimeType, "image/jpeg")
        XCTAssertNotNil(imageContent.url)
        XCTAssertEqual(imageContent.filename, "sunset.jpg")
    }

    func testPDFDocument() {
        let pdfContent = BinaryInputContent(
            mimeType: "application/pdf",
            id: "doc-report-2024",
            filename: "annual-report.pdf"
        )

        XCTAssertEqual(pdfContent.mimeType, "application/pdf")
        XCTAssertEqual(pdfContent.id, "doc-report-2024")
    }

    func testBase64EmbeddedImage() {
        let smallPNG = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg=="

        let imageContent = BinaryInputContent(
            mimeType: "image/png",
            data: smallPNG,
            filename: "pixel.png"
        )

        XCTAssertEqual(imageContent.data, smallPNG)
        XCTAssertTrue(imageContent.data?.hasSuffix("==") ?? false)
    }

    func testAudioFile() {
        let audioContent = BinaryInputContent(
            mimeType: "audio/mpeg",
            url: "https://cdn.example.com/audio/track01.mp3",
            filename: "track01.mp3"
        )

        XCTAssertEqual(audioContent.mimeType, "audio/mpeg")
    }

    func testTypeAlwaysBinary() {
        let content1 = BinaryInputContent(mimeType: "image/png", url: "https://test.com/1.png")
        let content2 = BinaryInputContent(mimeType: "application/pdf", id: "doc-1")
        let content3 = BinaryInputContent(mimeType: "audio/wav", data: "base64data")

        XCTAssertEqual(content1.type, "binary")
        XCTAssertEqual(content2.type, "binary")
        XCTAssertEqual(content3.type, "binary")
    }
}
