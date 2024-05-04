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

final class ChaCha20StreamTests: XCTestCase {
    func testForWrongKey() {
        let sourceBufLen = 128
        let sourceBuf = genBufferOfLen(sourceBufLen)
        let key = genBufferOfLen(16)
        let iv = genBufferOfLen(12)
        XCTAssertThrowsError(try encrypt(sourceBuf, len: sourceBufLen, key: key, iv: iv)) { error in
            guard let chaError = error as? ChaCha20StreamError else {
                XCTFail("Unexpected error type")
                return
            }
            XCTAssertEqual(chaError.kind, .keySizeError)
        }
    }

    func testForWrongIV() {
        let sourceBufLen = 128
        let sourceBuf = genBufferOfLen(sourceBufLen)
        let key = genBufferOfLen(32)
        let iv = genBufferOfLen(13)
        XCTAssertThrowsError(try encrypt(sourceBuf, len: sourceBufLen, key: key, iv: iv)) { error in
            guard let chaError = error as? ChaCha20StreamError else {
                XCTFail("Unexpected error type")
                return
            }
            XCTAssertEqual(chaError.kind, .ivSizeError)
        }
    }

    func testEncryptZeroLenBuffer() throws {
        let sourceBufLen = 0
        let sourceBuf = genBufferOfLen(sourceBufLen)
        let key = genBufferOfLen(32)
        let iv = genBufferOfLen(12)
        let encryptedBuf = try encrypt(sourceBuf, len: sourceBufLen, key: key, iv: iv)
        XCTAssertTrue(encryptedBuf.count == 0)
    }

    func testEncrypt63Bytes() throws {
        let sourceBufLen = 63
        let sourceBuf = genBufferOfLen(sourceBufLen)
        let key = genBufferOfLen(32)
        let iv = genBufferOfLen(12)
        let encryptedBuf = try encrypt(sourceBuf, len: sourceBufLen, key: key, iv: iv)
        XCTAssertTrue(encryptedBuf.count == 63)
        XCTAssertNotEqual(sourceBuf, encryptedBuf)
    }

    func testEncrypt64Bytes() throws {
        let sourceBufLen = 64
        let sourceBuf = genBufferOfLen(sourceBufLen)
        let key = genBufferOfLen(32)
        let iv = genBufferOfLen(12)
        let encryptedBuf = try encrypt(sourceBuf, len: sourceBufLen, key: key, iv: iv)
        XCTAssertTrue(encryptedBuf.count == 64)
        XCTAssertNotEqual(sourceBuf, encryptedBuf)
    }

    func testEncrypt65Bytes() throws {
        let sourceBufLen = 65
        let sourceBuf = genBufferOfLen(sourceBufLen)
        let key = genBufferOfLen(32)
        let iv = genBufferOfLen(12)
        let encryptedBuf = try encrypt(sourceBuf, len: sourceBufLen, key: key, iv: iv)
        XCTAssertTrue(encryptedBuf.count == 65)
        XCTAssertNotEqual(sourceBuf, encryptedBuf)
    }

    func testEncrypt127Bytes() throws {
        let sourceBufLen = 127
        let sourceBuf = genBufferOfLen(sourceBufLen)
        let key = genBufferOfLen(32)
        let iv = genBufferOfLen(12)
        let encryptedBuf = try encrypt(sourceBuf, len: sourceBufLen, key: key, iv: iv, chunkSize: 127)
        XCTAssertTrue(encryptedBuf.count == 127)
        XCTAssertNotEqual(sourceBuf, encryptedBuf)
    }

    func testEncrypt128Bytes() throws {
        let sourceBufLen = 128
        let sourceBuf = genBufferOfLen(sourceBufLen)
        let key = genBufferOfLen(32)
        let iv = genBufferOfLen(12)
        let encryptedBuf = try encrypt(sourceBuf, len: sourceBufLen, key: key, iv: iv, chunkSize: 127)
        XCTAssertTrue(encryptedBuf.count == 128)
        XCTAssertNotEqual(sourceBuf, encryptedBuf)
    }

    func testEncrypt256Bytes() throws {
        let sourceBufLen = 256
        let sourceBuf = genBufferOfLen(sourceBufLen)
        let key = genBufferOfLen(32)
        let iv = genBufferOfLen(12)
        let encryptedBuf = try encrypt(sourceBuf, len: sourceBufLen, key: key, iv: iv, chunkSize: 127)
        XCTAssertTrue(encryptedBuf.count == 256)
        XCTAssertNotEqual(sourceBuf, encryptedBuf)
    }

    func testEncryptDecryptZeroLenBuffer() throws {
        try encryptDecryptBufferOfLen(0)
    }

    func testEncryptDecrypt16Bytes() throws {
        try encryptDecryptBufferOfLen(16)
    }

    func testEncryptDecrypt64Bytes() throws {
        try encryptDecryptBufferOfLen(64)
    }

    func testEncryptDecrypt65Bytes() throws {
        try encryptDecryptBufferOfLen(65, chunkSize: 64)
    }

    func testEncryptDecrypt192Bytes() throws {
        try encryptDecryptBufferOfLen(192, chunkSize: 65)
    }

    func testEncryptDecrypt1024Bytes_2() throws {
        try encryptDecryptBufferOfLen(127)
    }

    func testEncryptDecrypt128Bytes() throws {
        try encryptDecryptBufferOfLen(128)
    }

    func testEncryptVariousLenBuffers() throws {
        for pow in 0...14 {
            let sourceBufLen = 1 << pow
            let sourceBuf = genBufferOfLen(sourceBufLen)
            let key = genBufferOfLen(32)
            let iv = genBufferOfLen(12)
            let encryptedBuf = try encrypt(sourceBuf, len: sourceBufLen, key: key, iv: iv)
            XCTAssertTrue(encryptedBuf.count == sourceBuf.count)
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

extension ChaCha20StreamTests {
    func encrypt(
        _ buffer: UnsafePointer<UInt8>,
        len: Int,
        key: [UInt8],
        iv: [UInt8],
        chunkSize: Int = ChaCha20OutputStream.defaultChunkSize
    ) throws -> [UInt8] {
        let dataOutputStream = BufferOutputStream()
        try dataOutputStream.open()

        let encryptingStream = ChaCha20OutputStream(
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
        _ buffer: [UInt8],
        key: [UInt8],
        iv: [UInt8],
        chunkSize: Int = ChaCha20InputStream.defaultChunkSize
    ) throws -> [UInt8] {
        let dataInputStream = BufferInputStream(withBuffer: buffer)
        try dataInputStream.open()

        let decryptionStream = ChaCha20InputStream(
            readingFrom: dataInputStream,
            key: key,
            iv: iv,
            chunkSize: chunkSize)
        try decryptionStream.open()

        var result = Array<UInt8>()
        let bufLen = 1 << 16
        var readBuffer = Array<UInt8>(repeating: 0, count: bufLen)
        while decryptionStream.hasBytesAvailable {
            let readLen = try decryptionStream.read(&readBuffer, maxLength: bufLen)
            result.append(contentsOf: readBuffer.prefix(readLen))
        }
        return result
    }

    func encryptDecryptBufferOfLen(_ bufLen: Int) throws {
        let chunkSizeOptions = [64, 65, 127, 128, 129, 512, 1023, 1024]
        for chunkSize in chunkSizeOptions {
            try encryptDecryptBufferOfLen(bufLen, chunkSize: chunkSize)
        }
    }

    func encryptDecryptBufferOfLen(
        _ bufLen: Int,
        chunkSize: Int = ChaCha20OutputStream.defaultChunkSize
    ) throws {
        let sourceBuf = genBufferOfLen(bufLen)
        let key = genBufferOfLen(32)
        let iv = genBufferOfLen(12)
        let encryptedBuf = try encrypt(sourceBuf, len: bufLen, key: key, iv: iv, chunkSize: chunkSize)
        let decryptedBuf = try decrypt(encryptedBuf, key: key, iv: iv, chunkSize: chunkSize)
        XCTAssertEqual(bufLen, decryptedBuf.count, "\(bufLen) \(chunkSize)")
        XCTAssertEqual(sourceBuf, decryptedBuf, "\(bufLen) \(chunkSize)")
    }
}
