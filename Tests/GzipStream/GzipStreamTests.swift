//
// MIT License
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

final class GzipStreamTests: XCTestCase {
    func testCompressZeroLenBuffer() throws {
        let len = 0
        let sourceBuf = genBufferOfLen(len)
        let compressedBuf = try compress(sourceBuf, len)
        XCTAssertTrue(compressedBuf.count > 0)
    }
    
    func testComressVariousLenBuffers() throws {
        for i in 0...14 {
            let len = 1<<i
            let sourceBuf = genBufferOfLen(len)
            let compressedBuf = try compress(sourceBuf, len)
            XCTAssertTrue(compressedBuf.count > 0)
        }
    }
    
    func testCompressDecompressZeroLenBuffer() throws {
        try compressDecompressBufferOfLen(0)
    }
    
    func testCompressDecompressVariousLenBuffers() throws {
        for i in 0...14 {
            try compressDecompressBufferOfLen(1<<i)
        }
    }
    
    func testCompressDecompressOddLenBuffers() throws {
        for len in [1,15,17,31,33,63,65,127,129] {
            try compressDecompressBufferOfLen(len)
        }
    }
    
    func testCompressDecompressEmptyBufferWithVariousWindowSizes() throws {
        for windowSize in stride(from: Int32(9), to: 15, by: 1) {
            try compressDecompressBufferOfLen(0, windowSize, 8, .defaultCompression, 8, 8)
        }
    }
    
    func disabled_testPerformanceCompressDecompress1MBFile() throws {
        self.measure {
            try! compressDecompressBufferOfLen(1<<20, 15, 1<<15, .defaultCompression, 1<<15, 1<<15)
        }
    }
}

extension GzipStreamTests {
    func compress(_ buffer: UnsafePointer<UInt8>,
                  _ len: Int,
                  _ windowBits: Int32 = 15,
                  _ compressedBufferSize: Int = GzipOutputStream.defaultDeflateChunkSize
    ) throws -> [UInt8] {
        let dataOutputStream = BufferOutputStream()
        try dataOutputStream.open()
        
        let compressStream = GzipOutputStream(writingTo: dataOutputStream,
                                              windowBits: windowBits,
                                              deflateChunkSize: compressedBufferSize)
        try compressStream.open()
        try compressStream.write(buffer, length: len)
        try! compressStream.close()
        
        let resultData = dataOutputStream.buffer
        try dataOutputStream.close()
        return resultData
    }
    
    func decompress(_ buffer: [UInt8],
                    _ windowBits: Int32 = 15,
                    _ inChunkSize: Int = GzipInputStream.defaultDeflateChunkSize,
                    _ outChunkSize: Int = GzipInputStream.defaultInflateChunkSize
    ) throws -> [UInt8] {
        let dataInputStream = BufferInputStream(withBuffer: buffer)
        try dataInputStream.open()
        
        let decompressStream = GzipInputStream(readingFrom: dataInputStream,
                                               windowBits: windowBits,
                                               deflateChunkSize: inChunkSize,
                                               inflateChunkSize: outChunkSize)
        try decompressStream.open()
        
        var result = Array<UInt8>()
        let bufLen = 1<<16
        var readBuffer = Array<UInt8>(repeating: 0, count: bufLen)
        while decompressStream.hasBytesAvailable {
            let readLen = try decompressStream.read(&readBuffer, maxLength: bufLen)
            result.append(contentsOf: readBuffer.prefix(readLen))
        }
        return result
    }
    
    func compressDecompressBufferOfLen(_ len: Int) throws {
        let chunkSizes = [8, 32, 256, 1024]
        for chunkSize in chunkSizes {
            for inChunkSize in chunkSizes {
                for outChunkSize in chunkSizes {
                    try compressDecompressBufferOfLen(len,
                                                      15,
                                                      chunkSize,
                                                      GzipCompressionLevel.defaultCompression,
                                                      inChunkSize,
                                                      outChunkSize)
                }
            }
        }
        
    }
    
    func compressDecompressBufferOfLen(_ len: Int,
                                       _ windowBits: Int32 = 15,
                                       _ compressChunk: Int,
                                       _ compressionLevel: GzipCompressionLevel = .defaultCompression,
                                       _ decompressInChunk: Int,
                                       _ decompressOutChunk: Int
    ) throws {
        let sourceBuf: [UInt8] = genBufferOfLen(len)
        let compressedBuf = try compress(sourceBuf, len, windowBits, compressChunk)
        var decompressedBuf = try decompress(compressedBuf,
                                             windowBits,
                                             decompressInChunk,
                                             decompressOutChunk)
        XCTAssertEqual(len, decompressedBuf.count)
        XCTAssertEqual(memcmp(sourceBuf, &decompressedBuf, len), 0)
    }
    
}
