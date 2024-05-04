//
// The MIT License (MIT)
//
// Copyright (c) 2023 Ihar Katkavets

// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import StreamKit
import XCTest

final class TwofishStreamTests: XCTestCase {
    func testForWrongKey() {
        let sourceBufLen = 128
        let sourceBuf = genBufferOfLen(sourceBufLen)
        let key = genBufferOfLen(33)
        let iv = genBufferOfLen(16)
        XCTAssertThrowsError(try encrypt(sourceBuf, len: sourceBufLen, key: key, iv: iv)) { error in
            guard let tfError = error as? TwofishStreamError else {
                XCTFail("Unexpected error type")
                return
            }
            XCTAssertEqual(tfError.kind, .keySizeError)
        }
    }

    func testForWrongIV() {
        let sourceBufLen = 128
        let sourceBuf = genBufferOfLen(sourceBufLen)
        let key = genBufferOfLen(32)
        let iv = genBufferOfLen(13)
        XCTAssertThrowsError(try encrypt(sourceBuf, len: sourceBufLen, key: key, iv: iv)) { error in
            guard let tfError = error as? TwofishStreamError else {
                XCTFail("Unexpected error type")
                return
            }
            XCTAssertEqual(tfError.kind, .ivSizeError)
        }
    }

    func testEncryptZeroLenBuffer() throws {
        let encryptedSize = try encryptBufferOfLen(0)
        XCTAssertEqual(16, encryptedSize)
    }

    func testEncrypt16Bytes() throws {
        let encryptedSize = try encryptBufferOfLen(16)
        XCTAssertEqual(32, encryptedSize)
    }

    func testEncrypt16BytesWithChunk16Bytes() throws {
        let encryptedSize = try encryptBufferOfLen(16, chunkSize: 16)
        XCTAssertEqual(32, encryptedSize)
    }

    func testEncrypt63Bytes() throws {
        let encryptedSize = try encryptBufferOfLen(63)
        XCTAssertEqual(64, encryptedSize)
    }

    func testEncrypt64Bytes() throws {
        let encryptedSize = try encryptBufferOfLen(64)
        XCTAssertEqual(80, encryptedSize)
    }

    func testEncrypt65Bytes() throws {
        let encryptedSize = try encryptBufferOfLen(65)
        XCTAssertEqual(80, encryptedSize)
    }

    func testEncrypt127Bytes() throws {
        let encryptedSize = try encryptBufferOfLen(127, chunkSize: 127)
        XCTAssertEqual(128, encryptedSize)
    }

    func testEncrypt128Bytes() throws {
        let encryptedSize = try encryptBufferOfLen(128, chunkSize: 128)
        XCTAssertEqual(144, encryptedSize)
    }

    func testEncrypt256Bytes() throws {
        let encryptedSize = try encryptBufferOfLen(256, chunkSize: 256)
        XCTAssertEqual(272, encryptedSize)
    }

    func testEncryptDecryptZeroLenBuffer() throws {
        try encryptDecryptBufferOfLen(0, keyLen: 32)
    }

    func testEncryptDecrypt16Bytes() throws {
        try encryptDecryptBufferOfLen(16, keyLen: 32)
    }

    func testEncryptDecrypt16BytesWithChunk16Bytes() throws {
        try encryptDecryptBufferOfLen(16, keyLen: 32, chunkSize: 16)
    }

    func testEncryptDecrypt17BytesWithChunk16Bytes() throws {
        try encryptDecryptBufferOfLen(17, keyLen: 32)
    }

    func testEncryptDecrypt32BytesWithChunk16Bytes() throws {
        try encryptDecryptBufferOfLen(32, keyLen: 32, chunkSize: 16)
    }

    func testEncryptDecrypt64Bytes() throws {
        try encryptDecryptBufferOfLen(64, keyLen: 32)
    }

    func testEncryptDecrypt65Bytes() throws {
        try encryptDecryptBufferOfLen(65, keyLen: 32)
    }

    func testEncryptDecrypt192Bytes() throws {
        try encryptDecryptBufferOfLen(192, keyLen: 32)
    }

    func testEncryptDecrypt1024Bytes_2() throws {
        try encryptDecryptBufferOfLen(127, keyLen: 32)
    }

    func testEncryptDecrypt128Bytes() throws {
        try encryptDecryptBufferOfLen(128, keyLen: 32)
    }

    func testEncryptVariousLenBuffers() throws {
        for pow in 0...14 {
            let sourceBufLen = 1 << pow
            let sourceBuf = genBufferOfLen(sourceBufLen)
            let key = genBufferOfLen(32)
            let iv = genBufferOfLen(16)
            let encryptedBuf = try encrypt(sourceBuf, len: sourceBufLen, key: key, iv: iv)
            let expected = ((sourceBufLen / 16) + 1) * 16
            XCTAssertEqual(expected, encryptedBuf.count)
            XCTAssertNotEqual(sourceBuf, encryptedBuf)
        }
    }

    func testEncryptDecryptVariousLenBuffers() throws {
        for pow in 0...14 {
            try encryptDecryptBufferOfLen(1 << pow)
        }
    }

    func disabled_testPerformanceEncryptDecrypt1MBFile() throws {
        self.measure {
            try! encryptDecryptBufferOfLen(1 << 20)
        }
    }
}

extension TwofishStreamTests {
    func encrypt(
        _ buffer: UnsafePointer<UInt8>,
        len: Int,
        key: [UInt8],
        iv: [UInt8],
        chunkSize: Int = TwofishOutputStream.defaultChunkSize
    ) throws -> [UInt8] {
        let dataOutputStream = BufferOutputStream()
        try dataOutputStream.open()

        let encryptingStream = TwofishOutputStream(
            writingTo: dataOutputStream,
            key: key,
            iv: iv,
            chunkSize: chunkSize)
        try encryptingStream.open()
        try encryptingStream.write(buffer, length: len)
        try encryptingStream.close()

        let resultData = dataOutputStream.buffer
        dataOutputStream.close()
        return resultData
    }

    func decrypt(
        buffer: [UInt8],
        key: [UInt8],
        iv: [UInt8],
        chunkSize: Int = TwofishInputStream.defaultChunkSize
    ) throws -> [UInt8] {
        let dataInputStream = BufferInputStream(withBuffer: buffer)
        try dataInputStream.open()

        let decryptingStream = TwofishInputStream(
            readingFrom: dataInputStream,
            key: key, iv: iv,
            chunkSize: chunkSize)
        try decryptingStream.open()

        var decryptedBytes = [UInt8]()
        let tmpBufferLen = 1 << 16
        var tmpBuffer = Array<UInt8>(repeating: 0, count: tmpBufferLen)
        while decryptingStream.hasBytesAvailable {
            let readLen = try decryptingStream.read(&tmpBuffer, maxLength: tmpBufferLen)
            decryptedBytes.append(contentsOf: tmpBuffer.prefix(readLen))
        }
        return decryptedBytes
    }

    // Returns encrypted buffer size
    func encryptBufferOfLen(
        _ sourceBufLen: Int,
        chunkSize: Int = TwofishOutputStream.defaultChunkSize
    ) throws -> Int {
        let sourceBuf = genBufferOfLen(sourceBufLen)
        let key = genBufferOfLen(32)
        let iv = genBufferOfLen(16)
        let encryptedBuf = try encrypt(sourceBuf, len: sourceBufLen, key: key, iv: iv, chunkSize: chunkSize)
        XCTAssertNotEqual(sourceBuf, encryptedBuf)
        return encryptedBuf.count
    }

    func encryptDecryptBufferOfLen(_ bufLen: Int) throws {
        let chunkSizeOptions = [64, 65, 127, 128, 129, 512, 1023, 1024]
        for keyLen in 1...32 {
            for chunkSize in chunkSizeOptions {
                try encryptDecryptBufferOfLen(bufLen, keyLen: keyLen, chunkSize: chunkSize)
            }
        }
    }

    func encryptDecryptBufferOfLen(
        _ bufLen: Int,
        keyLen: Int,
        chunkSize: Int = TwofishOutputStream.defaultChunkSize
    ) throws {
        let sourceBuf = genBufferOfLen(bufLen)
        let key = genBufferOfLen(keyLen)
        let iv = genBufferOfLen(16)
        let encryptedBuf = try encrypt(sourceBuf, len: bufLen, key: key, iv: iv, chunkSize: chunkSize)
        let decryptedBuf = try decrypt(buffer: encryptedBuf, key: key, iv: iv, chunkSize: chunkSize)
        XCTAssertEqual(bufLen, decryptedBuf.count, "\(bufLen) \(chunkSize)")
        XCTAssertEqual(sourceBuf, decryptedBuf, "\(bufLen) \(chunkSize)")
    }
}
