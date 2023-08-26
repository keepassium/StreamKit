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

final class AesStreamTests: XCTestCase {
    func testForWrongKey() {
        let sourceBufLen = 128
        let sourceBuf = genBufferOfLen(sourceBufLen)
        let key = genBufferOfLen(31)
        let iv = genBufferOfLen(8)
        XCTAssertThrowsError(try encrypt(sourceBuf, sourceBufLen, key, iv))
    }
    
    func testForWrongIV() {
        let sourceBufLen = 128
        let sourceBuf = genBufferOfLen(sourceBufLen)
        let key = genBufferOfLen(32)
        let iv = genBufferOfLen(7)
        XCTAssertThrowsError(try encrypt(sourceBuf, sourceBufLen, key, iv))
    }
    
    func testEncryptZeroLenBuffer() throws {
        let len = 0
        let sourceBuf = genBufferOfLen(len)
        let key = genBufferOfLen(16)
        let iv = genBufferOfLen(16)
        let compressedBuf = try encrypt(sourceBuf, len, key, iv)
        XCTAssertEqual(16, compressedBuf.count)
    }
    
    func testEncryptZeroLenBufferWithVariousKeys() throws {
        let len = 0
        let sourceBuf = genBufferOfLen(len)
        let iv = genBufferOfLen(16)
        for keySize in [16,24,32] {
            let key = genBufferOfLen(keySize)
            let compressedBuf = try encrypt(sourceBuf, len, key, iv)
            XCTAssertEqual(16, compressedBuf.count)
        }
    }
    
    func testThatEncryptWithWrongKeySizesThrowsError() throws {
        let sourceBufLen = 512
        let sourceBuf = genBufferOfLen(sourceBufLen)
        let iv = genBufferOfLen(16)
        for keyLen in (0...15).map({$0}) {
            let key = genBufferOfLen(keyLen)
            XCTAssertThrowsError(try encrypt(sourceBuf, sourceBufLen, key, iv))
        }
    }
    
    func testEncryptVariousLenBuffers() throws {
        for pow in 0...14 {
            let len = 1<<pow
            let sourceBuf = genBufferOfLen(len)
            let key = genBufferOfLen(16)
            let iv = genBufferOfLen(16)
            let compressedBuf = try encrypt(sourceBuf, len, key, iv)
            XCTAssertTrue(compressedBuf.count > 0)
        }
    }
    
    func testEncryptDecryptZeroLenBuffer() throws {
        try encryptDecryptBufferOfLen(0)
    }
    
    func testEncryptOddLenBuffers() throws {
        for len in [1,15,17,31,33,63,65,127,129] {
            try encryptDecryptBufferOfLen(len)
        }
    }
    
    func testEncryptDecryptVariousLenBuffers() throws {
        for pow in 0...14 {
            try encryptDecryptBufferOfLen(1<<pow)
        }
    }
    
    func disabled_testPerformanceEncryptDecrypt1MBFile() throws {
        self.measure {
            try! encryptDecryptBufferOfLen(1<<20, 32, 1<<15)
        }
    }
}

extension AesStreamTests {
    func encrypt(_ buffer: UnsafePointer<UInt8>,
                 _ len: Int,
                 _ key: [UInt8],
                 _ iv: [UInt8],
                 _ chunkSize: Int = AesOutputStream.defaultChunkSize
    ) throws -> [UInt8] {
        let dataOutputStream = BufferOutputStream()
        try dataOutputStream.open()
        
        let encryptingStream = AesOutputStream(writingTo: dataOutputStream,
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
                 _ chunkSize: Int = AesInputStream.defaultChunkSize
    ) throws -> [UInt8] {
        let dataInputStream = BufferInputStream(withBuffer: buffer)
        try dataInputStream.open()
        
        let decryptingStream = AesInputStream(readingFrom: dataInputStream, key: key, iv: iv, chunkSize: chunkSize)
        try decryptingStream.open()
        
        var result = Array<UInt8>()
        let bufLen = 1<<16
        var readBuffer = Array<UInt8>(repeating: 0, count: bufLen)
        while decryptingStream.hasBytesAvailable {
            let readLen = try decryptingStream.read(&readBuffer, maxLength: bufLen)
            result.append(contentsOf: readBuffer.prefix(readLen))
        }
        return result
    }
    
    func encryptDecryptBufferOfLen(_ bufLen: Int) throws {
        for chunkLen in [128,256,512,1024,2048,4096]{
            for keySize in [16,24,32] {
                try encryptDecryptBufferOfLen(bufLen, keySize, chunkLen)
            }
        }
    }
    
    func encryptDecryptBufferOfLen(_ bufLen: Int,
                                   _ keyLen: Int,
                                   _ chunkSize: Int
    ) throws {
        let sourceBuf = genBufferOfLen(bufLen)
        let key = genBufferOfLen(keyLen)
        let iv = genBufferOfLen(16)
        let encryptedBuf = try encrypt(sourceBuf, bufLen, key, iv, chunkSize)
        let decryptedBuf = try decrypt(encryptedBuf, key, iv, chunkSize)
        XCTAssertNotEqual(sourceBuf, encryptedBuf, "\(bufLen) \(keyLen) \(chunkSize)")
        XCTAssertEqual(sourceBuf, decryptedBuf, "\(bufLen) \(keyLen) \(chunkSize)")
    }
}
