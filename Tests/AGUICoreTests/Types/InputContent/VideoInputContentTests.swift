/*
 * MIT License
 *
 * Copyright (c) 2025 Perfect Aduh
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import XCTest
@testable import AGUICore

final class VideoInputContentTests: XCTestCase {

    // MARK: - Initialization

    func test_initWithURL_setsFields() {
        let content = VideoInputContent(url: "https://example.com/video.mp4")
        XCTAssertEqual(content.type, "video")
        XCTAssertEqual(content.url, "https://example.com/video.mp4")
        XCTAssertNil(content.data)
    }

    func test_initWithData_setsFields() {
        let content = VideoInputContent(data: "base64video")
        XCTAssertEqual(content.type, "video")
        XCTAssertEqual(content.data, "base64video")
        XCTAssertNil(content.url)
    }

    // MARK: - Protocol conformance

    func test_conformsToInputContent() {
        let content: any InputContent = VideoInputContent(url: "https://example.com/video.mp4")
        XCTAssertEqual(content.type, "video")
    }

    // MARK: - DTO decoding

    func test_dtoDecodeWithURL_succeeds() throws {
        let json = Data("""
        {"type":"video","url":"https://example.com/clip.mp4"}
        """.utf8)
        let dto = try VideoInputContentDTO.decode(from: json)
        let content = dto.toDomain()
        XCTAssertEqual(content.url, "https://example.com/clip.mp4")
        XCTAssertEqual(content.type, "video")
    }

    func test_dtoDecodeWithData_succeeds() throws {
        let json = Data("""
        {"type":"video","data":"base64videodata"}
        """.utf8)
        let dto = try VideoInputContentDTO.decode(from: json)
        XCTAssertEqual(dto.toDomain().data, "base64videodata")
    }

    func test_dtoDecodeWithNoSource_throws() {
        let json = Data("""
        {"type":"video"}
        """.utf8)
        XCTAssertThrowsError(try VideoInputContentDTO.decode(from: json))
    }

    func test_dtoDecodeWithWrongType_throws() {
        let json = Data("""
        {"type":"audio","url":"https://example.com/audio.mp3"}
        """.utf8)
        XCTAssertThrowsError(try VideoInputContentDTO.decode(from: json))
    }

    // MARK: - Integration: decode via UserMessage

    func test_userMessage_withVideoContent_decodesFromJSON() throws {
        let json = """
        {
          "id": "msg-3",
          "role": "user",
          "content": [
            {"type": "video", "url": "https://example.com/clip.mp4"}
          ]
        }
        """
        let decoder = MessageDecoder()
        let message = try decoder.decode(Data(json.utf8))
        guard let userMsg = message as? UserMessage,
              let parts = userMsg.contentParts else {
            return XCTFail("Expected multimodal UserMessage")
        }
        guard let videoPart = parts[0] as? VideoInputContent else {
            return XCTFail("Expected VideoInputContent")
        }
        XCTAssertEqual(videoPart.url, "https://example.com/clip.mp4")
    }

    func test_userMessage_withVideoContent_encodesCorrectly() throws {
        let video = VideoInputContent(url: "https://example.com/clip.mp4")
        let userMsg = UserMessage.multimodal(id: "msg-3", parts: [video])

        let encoder = MessageEncoder()
        let data = try encoder.encode(userMsg)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let contentArray = json?["content"] as? [[String: Any]]

        XCTAssertEqual(contentArray?[0]["type"] as? String, "video")
        XCTAssertEqual(contentArray?[0]["url"] as? String, "https://example.com/clip.mp4")
    }

    // MARK: - Equatable / Hashable / Sendable

    func test_equalContentAreEqual() {
        XCTAssertEqual(
            VideoInputContent(url: "https://example.com/v.mp4"),
            VideoInputContent(url: "https://example.com/v.mp4")
        )
    }

    func test_differentURLNotEqual() {
        XCTAssertNotEqual(
            VideoInputContent(url: "https://example.com/a.mp4"),
            VideoInputContent(url: "https://example.com/b.mp4")
        )
    }

    func test_hashable() {
        let set: Set<VideoInputContent> = [
            VideoInputContent(url: "https://example.com/a.mp4"),
            VideoInputContent(url: "https://example.com/b.mp4")
        ]
        XCTAssertEqual(set.count, 2)
    }

    func test_sendable() {
        let content = VideoInputContent(url: "https://example.com/video.mp4")
        Task { XCTAssertEqual(content.type, "video") }
    }
}
