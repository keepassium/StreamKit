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
import StreamKit

final class TwoFishStreamTests: XCTestCase {
    func testForWrongKey() {
        let sourceBufLen = 128
        let sourceBuf = genBufferOfLen(sourceBufLen)
        let key = genBufferOfLen(33)
        let iv = genBufferOfLen(16)
        XCTAssertThrowsError(try encrypt(sourceBuf, sourceBufLen, key, iv))
    }
    
    func testForWrongIV() {
        let sourceBufLen = 128
        let sourceBuf = genBufferOfLen(sourceBufLen)
        let key = genBufferOfLen(32)
        let iv = genBufferOfLen(13)
        XCTAssertThrowsError(try encrypt(sourceBuf, sourceBufLen, key, iv))
    }
    
    func testEncryptZeroLenBuffer() throws {
        let sourceBufLen = 0
        let sourceBuf = genBufferOfLen(sourceBufLen)
        let key = genBufferOfLen(32)
        let iv = genBufferOfLen(16)
        let encryptedBuf = try encrypt(sourceBuf, sourceBufLen, key, iv)
        XCTAssertEqual(16, encryptedBuf.count)
    }
    
    func testEncrypt16Bytes() throws {
        let sourceBufLen = 16
        let sourceBuf = genBufferOfLen(sourceBufLen)
        let key = genBufferOfLen(32)
        let iv = genBufferOfLen(16)
        let encryptedBuf = try encrypt(sourceBuf, sourceBufLen, key, iv)
        XCTAssertEqual(32, encryptedBuf.count)
    }
    
    func testEncrypt16BytesWithChunk16Bytes() throws {
        let sourceBufLen = 16
        let sourceBuf = genBufferOfLen(sourceBufLen)
        let key = genBufferOfLen(32)
        let iv = genBufferOfLen(16)
        let encryptedBuf = try encrypt(sourceBuf, sourceBufLen, key, iv, 16)
        XCTAssertEqual(32, encryptedBuf.count)
    }
    
    func testEncrypt63Bytes() throws {
        let sourceBufLen = 63
        let sourceBuf = genBufferOfLen(sourceBufLen)
        let key = genBufferOfLen(32)
        let iv = genBufferOfLen(16)
        let encryptedBuf = try encrypt(sourceBuf, sourceBufLen, key, iv)
        XCTAssertEqual(64, encryptedBuf.count)
        XCTAssertNotEqual(sourceBuf, encryptedBuf)
    }
    
    func testEncrypt64Bytes() throws {
        let sourceBufLen = 64
        let sourceBuf = genBufferOfLen(sourceBufLen)
        let key = genBufferOfLen(32)
        let iv = genBufferOfLen(16)
        let encryptedBuf = try encrypt(sourceBuf, sourceBufLen, key, iv)
        XCTAssertEqual(80, encryptedBuf.count)
        XCTAssertNotEqual(sourceBuf, encryptedBuf)
    }
    
    func testEncrypt65Bytes() throws {
        let sourceBufLen = 65
        let sourceBuf = genBufferOfLen(sourceBufLen)
        let key = genBufferOfLen(32)
        let iv = genBufferOfLen(16)
        let encryptedBuf = try encrypt(sourceBuf, sourceBufLen, key, iv)
        XCTAssertEqual(80, encryptedBuf.count)
        XCTAssertNotEqual(sourceBuf, encryptedBuf)
    }
    
    func testEncrypt127Bytes() throws {
        let sourceBufLen = 127
        let sourceBuf = genBufferOfLen(sourceBufLen)
        let key = genBufferOfLen(32)
        let iv = genBufferOfLen(16)
        let encryptedBuf = try encrypt(sourceBuf, sourceBufLen, key, iv, 127)
        XCTAssertEqual(128, encryptedBuf.count)
        XCTAssertNotEqual(sourceBuf, encryptedBuf)
    }
    
    func testEncrypt128Bytes() throws {
        let sourceBufLen = 128
        let sourceBuf = genBufferOfLen(sourceBufLen)
        let key = genBufferOfLen(32)
        let iv = genBufferOfLen(16)
        let encryptedBuf = try encrypt(sourceBuf, sourceBufLen, key, iv, 128)
        XCTAssertEqual(144, encryptedBuf.count)
        XCTAssertNotEqual(sourceBuf, encryptedBuf)
    }
    
    func testEncrypt256Bytes() throws {
        let sourceBufLen = 256
        let sourceBuf = genBufferOfLen(sourceBufLen)
        let key = genBufferOfLen(32)
        let iv = genBufferOfLen(16)
        let encryptedBuf = try encrypt(sourceBuf, sourceBufLen, key, iv, 256)
        XCTAssertEqual(272, encryptedBuf.count)
        XCTAssertNotEqual(sourceBuf, encryptedBuf)
    }
    
    func testEncryptDecryptZeroLenBuffer() throws {
        try encryptDecryptBufferOfLen(0, 32)
    }
    
    func testEncryptDecrypt16Bytes() throws {
        try encryptDecryptBufferOfLen(16,32)
    }
    
    func testEncryptDecrypt16BytesWithChunk16Bytes() throws {
        try encryptDecryptBufferOfLen(16,32,16)
    }
    
    func testEncryptDecrypt17BytesWithChunk16Bytes() throws {
        try encryptDecryptBufferOfLen(17,32)
    }
    
    func testEncryptDecrypt32BytesWithChunk16Bytes() throws {
        try encryptDecryptBufferOfLen(32,32,16)
    }
    
    func testEncryptDecrypt64Bytes() throws {
        try encryptDecryptBufferOfLen(64,32)
    }
    
    func testEncryptDecrypt65Bytes() throws {
        try encryptDecryptBufferOfLen(65,32)
    }
    
    func testEncryptDecrypt192Bytes() throws {
        try encryptDecryptBufferOfLen(192,32)
    }
    
    func testEncryptDecrypt1024Bytes_2() throws {
        try encryptDecryptBufferOfLen(127,32)
    }
    
    func testEncryptDecrypt128Bytes() throws {
        try encryptDecryptBufferOfLen(128,32)
    }
    
    func testEncryptVariousLenBuffers() throws {
        for pow in 0...14 {
            let sourceBufLen = 1<<pow
            let sourceBuf = genBufferOfLen(sourceBufLen)
            let key = genBufferOfLen(32)
            let iv = genBufferOfLen(16)
            let encryptedBuf = try encrypt(sourceBuf, sourceBufLen, key, iv)
            let expected = ((sourceBufLen/16)+1)*16
            XCTAssertEqual(expected, encryptedBuf.count)
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

extension TwoFishStreamTests {
    func encrypt(_ buffer: UnsafePointer<UInt8>,
                 _ len: Int,
                 _ key: [UInt8],
                 _ iv: [UInt8],
                 _ chunkSize: Int = TwoFishOutputStream.defaultChunkSize
    ) throws -> [UInt8] {
        let dataOutputStream = BufferOutputStream()
        try dataOutputStream.open()
        
        let encryptingStream = TwoFishOutputStream(writingTo: dataOutputStream,
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
                 _ chunkSize: Int = TwoFishInputStream.defaultChunkSize
    ) throws -> [UInt8] {
        let dataInputStream = BufferInputStream(withBuffer: buffer)
        try dataInputStream.open()
        
        let decryptingStream = TwoFishInputStream(readingFrom: dataInputStream,
                                                  key: key, iv: iv,
                                                  chunkSize: chunkSize)
        try decryptingStream.open()
        
        var decryptedBytes = [UInt8]()
        let tmpBufferLen = 1<<16
        var tmpBuffer = Array<UInt8>(repeating: 0, count: tmpBufferLen)
        while decryptingStream.hasBytesAvailable {
            let readLen = try decryptingStream.read(&tmpBuffer, maxLength: tmpBufferLen)
            decryptedBytes.append(contentsOf: tmpBuffer.prefix(readLen))
        }
        return decryptedBytes
    }
    
    func encryptDecryptBufferOfLen(_ bufLen: Int) throws {
        for keyLen in 1...32 {
            for chunkSize in [64,65,127,128,129,512,1023,1024] {
                try encryptDecryptBufferOfLen(bufLen, keyLen, chunkSize)
            }
        }
    }
    
    func encryptDecryptBufferOfLen(_ bufLen: Int,
                                   _ keyLen: Int,
                                   _ chunkSize: Int = TwoFishOutputStream.defaultChunkSize
    ) throws {
        let sourceBuf = genBufferOfLen(bufLen)
        let key = genBufferOfLen(keyLen)
        let iv = genBufferOfLen(16)
        let encryptedBuf = try encrypt(sourceBuf, bufLen, key, iv, chunkSize)
        let decryptedBuf = try decrypt(encryptedBuf, key, iv, chunkSize)
        XCTAssertEqual(bufLen, decryptedBuf.count, "\(bufLen) \(chunkSize)")
        XCTAssertEqual(sourceBuf, decryptedBuf, "\(bufLen) \(chunkSize)")
    }
}
