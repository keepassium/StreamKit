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

import XCTest
@testable import StreamKit

final class Salsa20CryptorTests: XCTestCase {
    func testForWrongKey() {
        let sourceBufLen = 128
        let sourceBuf = genBufferOfLen(sourceBufLen)
        let key = genBufferOfLen(16)
        let iv = genBufferOfLen(16)
        XCTAssertThrowsError(try encrypt(sourceBuf, sourceBufLen, key, iv))
    }
    
    func testEncryptZeroLenBuffer() throws {
        let sourceBufLen = 0
        let sourceBuf = genBufferOfLen(sourceBufLen)
        let key = genBufferOfLen(32)
        let iv = genBufferOfLen(8)
        let encryptedBuf = try encrypt(sourceBuf, sourceBufLen, key, iv)
        XCTAssertTrue(encryptedBuf.count == 0)
    }
    
    func testEncrypt64Bytes() throws {
        let sourceBufLen = 64
        let sourceBuf = genBufferOfLen(sourceBufLen)
        let key = genBufferOfLen(32)
        let iv = genBufferOfLen(8)
        let encryptedBuf = try encrypt(sourceBuf, sourceBufLen, key, iv)
        XCTAssertTrue(encryptedBuf.count == 64)
        XCTAssertNotEqual(sourceBuf, encryptedBuf)
    }
    
    func testEncrypt65Bytes() throws {
        let sourceBufLen = 65
        let sourceBuf = genBufferOfLen(sourceBufLen)
        let key = genBufferOfLen(32)
        let iv = genBufferOfLen(8)
        let encryptedBuf = try encrypt(sourceBuf, sourceBufLen, key, iv)
        XCTAssertEqual(65, encryptedBuf.count)
        XCTAssertNotEqual(sourceBuf, encryptedBuf)
    }
    
    func testEncrypt128Bytes() throws {
        let sourceBufLen = 128
        let sourceBuf = genBufferOfLen(sourceBufLen)
        let key = genBufferOfLen(32)
        let iv = genBufferOfLen(8)
        let encryptedBuf = try encrypt(sourceBuf, sourceBufLen, key, iv)
        XCTAssertTrue(encryptedBuf.count == 128)
        XCTAssertNotEqual(sourceBuf, encryptedBuf)
    }
    
    func testEncryptDecryptZeroLenBuffer() throws {
        try encryptDecryptBufferOfLen(0, 32, 64, 64)
    }
    
    func testEncryptVariousLenBuffers() throws {
        for pow in 0...14 {
            let sourceBufLen = 1<<pow
            let sourceBuf = genBufferOfLen(sourceBufLen)
            let key = genBufferOfLen(16)
            let iv = genBufferOfLen(8)
            let encryptedBuf = try encrypt(sourceBuf, sourceBufLen, key, iv)
            XCTAssertTrue(encryptedBuf.count == sourceBuf.count)
            XCTAssertNotEqual(sourceBuf, encryptedBuf)
        }
    }
    
    func testEncryptDecryptVariousLenBuffers() throws {
        for pow in 0...14 {
            try encryptDecryptBufferOfLen(1<<pow)
        }
    }
    
    func disabled_testPerformanceEncryptDecrypt1MBFile() throws {
        self.measure {
            try! encryptDecryptBufferOfLen(1<<20)
        }
    }
}

extension Salsa20CryptorTests {
    func encrypt(_ buffer: UnsafePointer<UInt8>,
                 _ len: Int,
                 _ key: [UInt8],
                 _ iv: [UInt8],
                 _ chunkSize: Int = Salsa20OutputStream.defaultChunkSize
    ) throws -> [UInt8] {
        let dataOutputStream = BufferOutputStream()
        try dataOutputStream.open()
        
        let encryptingStream = Salsa20OutputStream(writingTo: dataOutputStream,
                                                   key: key,
                                                   iv: iv,
                                                   chunkSize: chunkSize)
        try encryptingStream.open()
        try encryptingStream.write(buffer, length: len)
        try encryptingStream.close()
        
        let resultData = dataOutputStream.buffer
        try dataOutputStream.close()
        return resultData
    }
    
    func decrypt(_ buffer: [UInt8],
                 _ key: [UInt8],
                 _ iv: [UInt8],
                 _ chunkSize: Int = Salsa20InputStream.defaultChunkSize,
                 _ iterBufSize: Int
    ) throws -> [UInt8] {
        let dataInputStream = BufferInputStream(withBuffer: buffer)
        try dataInputStream.open()
        
        let decryptingStream = Salsa20InputStream(readingFrom: dataInputStream,
                                                  key: key,
                                                  iv: iv,
                                                  chunkSize: chunkSize)
        try decryptingStream.open()
        
        var result = Array<UInt8>()
        while decryptingStream.hasBytesAvailable {
            var readBuffer = Array<UInt8>(repeating: 0, count: iterBufSize)
            let readLen = try decryptingStream.read(&readBuffer, maxLength: iterBufSize)
            result.append(contentsOf: readBuffer.prefix(readLen))
        }
        return result
    }
    
    func encryptDecryptBufferOfLen(_ bufLen: Int) throws {
        for iterBufSize in [64,65,127,128,129,256] {
            for chunkSize in [64,65,127,128,129,256] {
                for keySize in [16,32] {
                    print("\(bufLen) \(keySize) \(chunkSize) \(iterBufSize)  ")
                    try encryptDecryptBufferOfLen(bufLen, keySize, chunkSize, iterBufSize)
                }
            }
        }
    }
    
    func encryptDecryptBufferOfLen(_ bufLen: Int,
                                   _ keyLen: Int,
                                   _ chunkSize: Int = Salsa20OutputStream.defaultChunkSize,
                                   _ iterBufSize: Int
    ) throws {
        let sourceBuf = genBufferOfLen(bufLen)
        let key = genBufferOfLen(keyLen)
        let iv = genBufferOfLen(8)
        let encryptedBuf = try encrypt(sourceBuf, bufLen, key, iv, chunkSize)
        let decryptedBuf = try decrypt(encryptedBuf, key, iv, chunkSize, iterBufSize)
        XCTAssertEqual(bufLen, decryptedBuf.count, "\(bufLen) \(keyLen) \(chunkSize)")
        XCTAssertEqual(sourceBuf, decryptedBuf, "\(bufLen) \(keyLen) \(chunkSize)")
    }
}
