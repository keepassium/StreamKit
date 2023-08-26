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

final class StreamKitTests: XCTestCase {
    static var tmpDir: URL!
    
    override class func setUp() {
        super.setUp()
        tmpDir = try! createTmpFolder()
    }
    
    override class func tearDown() {
        super.tearDown()
        try! removeTmpFolder(tmpDir)
    }
    
    func testEncryptingDecrypting1MBFileUsingSalsa20Streams() throws {
        let key = genBufferOfLen(32)
        let iv = genBufferOfLen(8)
        
        let originalFileURL = fileURL("1MB")!
        let encryptedFileURL = try encryptFileUsingSalsa20(originalFileURL, key, iv)
        let decryptedFileURL = try decryptFileUsingSalsa20(encryptedFileURL, key, iv)
        
        XCTAssertNotEqual(md5(originalFileURL), md5(encryptedFileURL))
        XCTAssertEqual(md5(originalFileURL), md5(decryptedFileURL))
    }
    
    func testCompressEncryptDecryptDecompress1MBFileUsingSalsa20Stream() throws {
        let key = genBufferOfLen(32)
        let iv = genBufferOfLen(8)
        
        let originalFileURL = fileURL("1MB")!
        let encryptedFileURL = try compressAndEncryptFileUsingSalsa20(originalFileURL, key, iv)
        let decryptedFileURL = try decryptAndDecompressFileUsingSalsa20(encryptedFileURL, key, iv)
        
        XCTAssertNotEqual(md5(originalFileURL), md5(encryptedFileURL))
        XCTAssertEqual(md5(originalFileURL), md5(decryptedFileURL))
    }
    
    func testEncryptingDecrypting1MBFileUsingChaCha20Streams() throws {
        let key = genBufferOfLen(32)
        let iv = genBufferOfLen(12)
        
        let originalFileURL = fileURL("1MB")!
        let encryptedFileURL = try encryptFileUsingChaCha20(originalFileURL, key, iv)
        let decryptedFileURL = try decryptFileUsingChaCha20(encryptedFileURL, key, iv)
        
        XCTAssertNotEqual(md5(originalFileURL), md5(encryptedFileURL))
        XCTAssertEqual(md5(originalFileURL), md5(decryptedFileURL))
    }
    
    func testCompressEncryptDecryptDecompress1MBFileUsingChaCha20Stream() throws {
        let key = genBufferOfLen(32)
        let iv = genBufferOfLen(12)
        
        let originalFileURL = fileURL("1MB")!
        let encryptedFileURL = try compressAndEncryptFileUsingChaCha20(originalFileURL, key, iv)
        let decryptedFileURL = try decryptAndDecompressFileUsingChaCha20(encryptedFileURL, key, iv)
        
        XCTAssertNotEqual(md5(originalFileURL), md5(encryptedFileURL))
        XCTAssertEqual(md5(originalFileURL), md5(decryptedFileURL))
    }
    
    func testEncryptingDecrypting1MBFileUsingAesStream() throws {
        let key = genBufferOfLen(32)
        let iv = genBufferOfLen(16)
        
        let originalFileURL = fileURL("1MB")!
        let encryptedFileURL = try encryptFileUsingAes(originalFileURL, key, iv)
        let decryptedFileURL = try decryptFileUsingAes(encryptedFileURL, key, iv)
        
        XCTAssertNotEqual(md5(originalFileURL), md5(encryptedFileURL))
        XCTAssertEqual(md5(originalFileURL), md5(decryptedFileURL))
    }
    
    func testCompressEncryptDecryptDecompress1MBFileUsingAesStream() throws {
        let key = genBufferOfLen(32)
        let iv = genBufferOfLen(16)
        
        let originalFileURL = fileURL("1MB")!
        let encryptedFileURL = try compressAndEncryptFileUsingAes(originalFileURL, key, iv)
        let decryptedFileURL = try decryptAndDecompressFileUsingAes(encryptedFileURL, key, iv)
        
        XCTAssertNotEqual(md5(originalFileURL), md5(encryptedFileURL))
        XCTAssertEqual(md5(originalFileURL), md5(decryptedFileURL))
    }
    
    func testDecompressing() throws {
        let originalFileURL = fileURL("PlainText")!
        let compressedFileURL = fileURL("PlainText","gz")!
        
        let decompressedFileURL = try decompressFileUsingGzip(compressedFileURL)
        
        XCTAssertEqual(md5(originalFileURL), md5(decompressedFileURL))
    }
    
    func testCompressDecompress1MBFileUsingGzipStream() throws {
        let originalFileURL = fileURL("1MB")!
        let compressedFileURL = try compressFileUsingGzip(originalFileURL)
        let decompressedFileURL = try decompressFileUsingGzip(compressedFileURL)
        
        XCTAssertNotEqual(md5(originalFileURL), md5(compressedFileURL))
        XCTAssertEqual(md5(originalFileURL), md5(decompressedFileURL))
    }
}

extension StreamKitTests {
    func encryptFileUsingSalsa20(_ originalFileURL: URL, _ key: [UInt8], _ iv: [UInt8]) throws -> URL {
        let inputFileStream = FileInputStream(with: try! FileHandle(forReadingFrom: originalFileURL))
        try inputFileStream.open()
        
        let encryptedFileURL = createTmpFileURL(Self.tmpDir)
        let outputFileStream = FileOutputStream(with: try! FileHandle(forWritingTo: encryptedFileURL))
        try outputFileStream.open()
        
        let encryptingStream = Salsa20OutputStream(writingTo: outputFileStream,
                                                   key: key,
                                                   iv: iv)
        try encryptingStream.open()
                
        let tmpBufferLen = 1<<16 // 65KB buffer
        var tmpBuffer = Array<UInt8>(repeating: 0, count: tmpBufferLen)
        while inputFileStream.hasBytesAvailable {
            let readLen = inputFileStream.read(&tmpBuffer, maxLength: tmpBufferLen)
            try encryptingStream.write(tmpBuffer, length: readLen)
        }
        
        try encryptingStream.close()
        try outputFileStream.close()
        inputFileStream.close()
        
        return encryptedFileURL
    }
    
    func decryptAndDecompressFileUsingSalsa20(_ encryptedFileURL: URL, _ key: [UInt8], _ iv: [UInt8]) throws -> URL {
        let inputFileStream = FileInputStream(with: try! FileHandle(forReadingFrom: encryptedFileURL))
        try inputFileStream.open()
        
        let decryptedFileURL = createTmpFileURL(Self.tmpDir)
        let outputFileStream = FileOutputStream(with: try! FileHandle(forWritingTo: decryptedFileURL))
        try outputFileStream.open()
        
        let decryptingStream = Salsa20InputStream(readingFrom: inputFileStream,
                                                  key: key,
                                                  iv: iv)
        try decryptingStream.open()
        
        let decompressingStream = GzipInputStream(readingFrom: decryptingStream)
        try decompressingStream.open()
        
        let tmpBufferLen = 1<<16 // 65KB buffer
        var tmpBuffer = Array<UInt8>(repeating: 0, count: tmpBufferLen)
        while decryptingStream.hasBytesAvailable {
            let readLen = try decompressingStream.read(&tmpBuffer, maxLength: tmpBufferLen)
            try outputFileStream.write(tmpBuffer, length: readLen)
        }
        
        decompressingStream.close()
        decryptingStream.close()
        try outputFileStream.close()
        inputFileStream.close()
        return decryptedFileURL
    }
    
    func compressAndEncryptFileUsingSalsa20(_ originalFileURL: URL, _ key: [UInt8], _ iv: [UInt8]) throws -> URL {
        let inputFileStream = FileInputStream(with: try! FileHandle(forReadingFrom: originalFileURL))
        try inputFileStream.open()
        inputFileStream.close()
        
        let encryptedFileURL = createTmpFileURL(Self.tmpDir)
        let outputFileStream = FileOutputStream(with: try! FileHandle(forWritingTo: encryptedFileURL))
        try outputFileStream.open()
        
        let encryptingStream = Salsa20OutputStream(writingTo: outputFileStream,
                                                   key: key,
                                                   iv: iv)
        try encryptingStream.open()
        
        let compressingStream = GzipOutputStream(writingTo: encryptingStream)
        try compressingStream.open()
                
        let tmpBufferLen = 1<<16 // 65KB buffer
        var tmpBuffer = Array<UInt8>(repeating: 0, count: tmpBufferLen)
        while inputFileStream.hasBytesAvailable {
            let readLen = inputFileStream.read(&tmpBuffer, maxLength: tmpBufferLen)
            try compressingStream.write(tmpBuffer, length: readLen)
        }
        
        try compressingStream.close()
        try encryptingStream.close()
        try outputFileStream.close()
        inputFileStream.close()
        
        return encryptedFileURL
    }
    
    func decryptFileUsingSalsa20(_ encryptedFileURL: URL, _ key: [UInt8], _ iv: [UInt8]) throws -> URL {
        let inputFileStream = FileInputStream(with: try! FileHandle(forReadingFrom: encryptedFileURL))
        try inputFileStream.open()
        
        let decryptedFileURL = createTmpFileURL(Self.tmpDir)
        let outputFileStream = FileOutputStream(with: try! FileHandle(forWritingTo: decryptedFileURL))
        try outputFileStream.open()
        
        let decryptingStream = Salsa20InputStream(readingFrom: inputFileStream,
                                                  key: key,
                                                  iv: iv)
        try decryptingStream.open()
        
        let tmpBufferLen = 1<<16 // 65KB buffer
        var tmpBuffer = Array<UInt8>(repeating: 0, count: tmpBufferLen)
        while decryptingStream.hasBytesAvailable {
            let readLen = try decryptingStream.read(&tmpBuffer, maxLength: tmpBufferLen)
            try outputFileStream.write(tmpBuffer, length: readLen)
        }
        
        decryptingStream.close()
        try outputFileStream.close()
        inputFileStream.close()
        return decryptedFileURL
    }
    
    func encryptFileUsingChaCha20(_ originalFileURL: URL, _ key: [UInt8], _ iv: [UInt8]) throws -> URL {
        let inputFileStream = FileInputStream(with: try! FileHandle(forReadingFrom: originalFileURL))
        try inputFileStream.open()
        
        let encryptedFileURL = createTmpFileURL(Self.tmpDir)
        let outputFileStream = FileOutputStream(with: try! FileHandle(forWritingTo: encryptedFileURL))
        try outputFileStream.open()
        
        let encryptingStream = ChaCha20OutputStream(writingTo: outputFileStream,
                                                    key: key,
                                                    iv: iv)
        try encryptingStream.open()
                
        let tmpBufferLen = 1<<16 // 65KB buffer
        var tmpBuffer = Array<UInt8>(repeating: 0, count: tmpBufferLen)
        while inputFileStream.hasBytesAvailable {
            let readLen = inputFileStream.read(&tmpBuffer, maxLength: tmpBufferLen)
            try encryptingStream.write(tmpBuffer, length: readLen)
        }
        
        try encryptingStream.close()
        try outputFileStream.close()
        inputFileStream.close()
        
        return encryptedFileURL
    }
    
    func decryptFileUsingChaCha20(_ encryptedFileURL: URL, _ key: [UInt8], _ iv: [UInt8]) throws -> URL {
        let inputFileStream = FileInputStream(with: try! FileHandle(forReadingFrom: encryptedFileURL))
        try inputFileStream.open()
        
        let decryptedFileURL = createTmpFileURL(Self.tmpDir)
        let outputFileStream = FileOutputStream(with: try! FileHandle(forWritingTo: decryptedFileURL))
        try outputFileStream.open()
        
        let decryptingStream = ChaCha20InputStream(readingFrom: inputFileStream,
                                                   key: key,
                                                   iv: iv)
        try decryptingStream.open()
        
        let tmpBufferLen = 1<<16 // 65KB buffer
        var tmpBuffer = Array<UInt8>(repeating: 0, count: tmpBufferLen)
        while decryptingStream.hasBytesAvailable {
            let readLen = try decryptingStream.read(&tmpBuffer, maxLength: tmpBufferLen)
            try outputFileStream.write(tmpBuffer, length: readLen)
        }
        
        decryptingStream.close()
        try outputFileStream.close()
        inputFileStream.close()
        return decryptedFileURL
    }
    
    func compressAndEncryptFileUsingChaCha20(_ originalFileURL: URL, _ key: [UInt8], _ iv: [UInt8]) throws -> URL {
        let inputFileStream = FileInputStream(with: try! FileHandle(forReadingFrom: originalFileURL))
        try inputFileStream.open()
        inputFileStream.close()
        
        let encryptedFileURL = createTmpFileURL(Self.tmpDir)
        let outputFileStream = FileOutputStream(with: try! FileHandle(forWritingTo: encryptedFileURL))
        try outputFileStream.open()
        
        let encryptingStream = ChaCha20OutputStream(writingTo: outputFileStream,
                                                    key: key,
                                                    iv: iv)
        try encryptingStream.open()
        
        let compressingStream = GzipOutputStream(writingTo: encryptingStream)
        try compressingStream.open()
                
        let tmpBufferLen = 1<<16 // 65KB buffer
        var tmpBuffer = Array<UInt8>(repeating: 0, count: tmpBufferLen)
        while inputFileStream.hasBytesAvailable {
            let readLen = inputFileStream.read(&tmpBuffer, maxLength: tmpBufferLen)
            try compressingStream.write(tmpBuffer, length: readLen)
        }
        
        try compressingStream.close()
        try encryptingStream.close()
        try outputFileStream.close()
        inputFileStream.close()
        
        return encryptedFileURL
    }
    
    func decryptAndDecompressFileUsingChaCha20(_ encryptedFileURL: URL, _ key: [UInt8], _ iv: [UInt8]) throws -> URL {
        let inputFileStream = FileInputStream(with: try! FileHandle(forReadingFrom: encryptedFileURL))
        try inputFileStream.open()
        
        let decryptedFileURL = createTmpFileURL(Self.tmpDir)
        let outputFileStream = FileOutputStream(with: try! FileHandle(forWritingTo: decryptedFileURL))
        try outputFileStream.open()
        
        let decryptingStream = ChaCha20InputStream(readingFrom: inputFileStream,
                                                   key: key,
                                                   iv: iv)
        try decryptingStream.open()
        
        let decompressingStream = GzipInputStream(readingFrom: decryptingStream)
        try decompressingStream.open()
        
        let tmpBufferLen = 1<<16 // 65KB buffer
        var tmpBuffer = Array<UInt8>(repeating: 0, count: tmpBufferLen)
        while decryptingStream.hasBytesAvailable {
            let readLen = try decompressingStream.read(&tmpBuffer, maxLength: tmpBufferLen)
            try outputFileStream.write(tmpBuffer, length: readLen)
        }
        
        decompressingStream.close()
        decryptingStream.close()
        try outputFileStream.close()
        inputFileStream.close()
        return decryptedFileURL
    }
    
    func encryptFileUsingAes(_ originalFileURL: URL, _ key: [UInt8], _ iv: [UInt8]) throws -> URL {
        let inputFileStream = FileInputStream(with: try! FileHandle(forReadingFrom: originalFileURL))
        try inputFileStream.open()
        
        let encryptedFileURL = createTmpFileURL(Self.tmpDir)
        let outputFileStream = FileOutputStream(with: try! FileHandle(forWritingTo: encryptedFileURL))
        try outputFileStream.open()
        
        let encryptingStream = AesOutputStream(writingTo: outputFileStream,
                                               key: key,
                                               iv: iv)
        try encryptingStream.open()
                
        let tmpBufferLen = 1<<16 // 65KB buffer
        var tmpBuffer = Array<UInt8>(repeating: 0, count: tmpBufferLen)
        while inputFileStream.hasBytesAvailable {
            let readLen = inputFileStream.read(&tmpBuffer, maxLength: tmpBufferLen)
            try encryptingStream.write(tmpBuffer, length: readLen)
        }
        
        try encryptingStream.close()
        try outputFileStream.close()
        inputFileStream.close()
        
        return encryptedFileURL
    }
    
    func compressAndEncryptFileUsingAes(_ originalFileURL: URL, _ key: [UInt8], _ iv: [UInt8]) throws -> URL {
        let inputFileStream = FileInputStream(with: try! FileHandle(forReadingFrom: originalFileURL))
        try inputFileStream.open()
        inputFileStream.close()
        
        let encryptedFileURL = createTmpFileURL(Self.tmpDir)
        let outputFileStream = FileOutputStream(with: try! FileHandle(forWritingTo: encryptedFileURL))
        try outputFileStream.open()
        
        let encryptingStream = AesOutputStream(writingTo: outputFileStream,
                                               key: key,
                                               iv: iv)
        try encryptingStream.open()
        
        let compressingStream = GzipOutputStream(writingTo: encryptingStream)
        try compressingStream.open()
                
        let tmpBufferLen = 1<<16 // 65KB buffer
        var tmpBuffer = Array<UInt8>(repeating: 0, count: tmpBufferLen)
        while inputFileStream.hasBytesAvailable {
            let readLen = inputFileStream.read(&tmpBuffer, maxLength: tmpBufferLen)
            try compressingStream.write(tmpBuffer, length: readLen)
        }
        
        try compressingStream.close()
        try encryptingStream.close()
        try outputFileStream.close()
        inputFileStream.close()
        
        return encryptedFileURL
    }
    
    func decryptFileUsingAes(_ encryptedFileURL: URL, _ key: [UInt8], _ iv: [UInt8]) throws -> URL {
        let inputFileStream = FileInputStream(with: try! FileHandle(forReadingFrom: encryptedFileURL))
        try inputFileStream.open()
        
        let decryptedFileURL = createTmpFileURL(Self.tmpDir)
        let outputFileStream = FileOutputStream(with: try! FileHandle(forWritingTo: decryptedFileURL))
        try outputFileStream.open()
        
        let decryptingStream = AesInputStream(readingFrom: inputFileStream,
                                              key: key,
                                              iv: iv)
        try decryptingStream.open()
        
        let tmpBufferLen = 1<<16 // 65KB buffer
        var tmpBuffer = Array<UInt8>(repeating: 0, count: tmpBufferLen)
        while decryptingStream.hasBytesAvailable {
            let readLen = try decryptingStream.read(&tmpBuffer, maxLength: tmpBufferLen)
            try outputFileStream.write(tmpBuffer, length: readLen)
        }
        
        decryptingStream.close()
        try outputFileStream.close()
        inputFileStream.close()
        return decryptedFileURL
    }
    
    func decryptAndDecompressFileUsingAes(_ encryptedFileURL: URL, _ key: [UInt8], _ iv: [UInt8]) throws -> URL {
        let inputFileStream = FileInputStream(with: try! FileHandle(forReadingFrom: encryptedFileURL))
        try inputFileStream.open()
        
        let decryptedFileURL = createTmpFileURL(Self.tmpDir)
        let outputFileStream = FileOutputStream(with: try! FileHandle(forWritingTo: decryptedFileURL))
        try outputFileStream.open()
        
        let decryptingStream = AesInputStream(readingFrom: inputFileStream,
                                              key: key,
                                              iv: iv)
        try decryptingStream.open()
        
        let decompressingStream = GzipInputStream(readingFrom: decryptingStream)
        try decompressingStream.open()
        
        let tmpBufferLen = 1<<16 // 65KB buffer
        var tmpBuffer = Array<UInt8>(repeating: 0, count: tmpBufferLen)
        while decryptingStream.hasBytesAvailable {
            let readLen = try decompressingStream.read(&tmpBuffer, maxLength: tmpBufferLen)
            try outputFileStream.write(tmpBuffer, length: readLen)
        }
        
        decryptingStream.close()
        try outputFileStream.close()
        inputFileStream.close()
        return decryptedFileURL
    }
    
    func compressFileUsingGzip(_ originalFileURL: URL) throws -> URL {
        let inputFileStream = FileInputStream(with: try! FileHandle(forReadingFrom: originalFileURL))
        try inputFileStream.open()
        
        let compressedFileURL = createTmpFileURL(Self.tmpDir)
        let outputFileStream = FileOutputStream(with: try! FileHandle(forWritingTo: compressedFileURL))
        try outputFileStream.open()
        
        let compressingStream = GzipOutputStream(writingTo: outputFileStream)
        try compressingStream.open()
                
        let tmpBufferLen = 1<<16 // 65KB buffer
        var tmpBuffer = Array<UInt8>(repeating: 0, count: tmpBufferLen)
        while inputFileStream.hasBytesAvailable {
            let readLen = inputFileStream.read(&tmpBuffer, maxLength: tmpBufferLen)
            try compressingStream.write(tmpBuffer, length: readLen)
        }
        
        try compressingStream.close()
        try outputFileStream.close()
        inputFileStream.close()
        
        return compressedFileURL
    }
    
    func decompressFileUsingGzip(_ compressedFileURL: URL) throws -> URL {
        let inputFileStream = FileInputStream(with: try! FileHandle(forReadingFrom: compressedFileURL))
        try inputFileStream.open()
        
        let decompressedFileURL = createTmpFileURL(Self.tmpDir)
        let outputFileStream = FileOutputStream(with: try! FileHandle(forWritingTo: decompressedFileURL))
        try outputFileStream.open()
        
        let decompressingStream = GzipInputStream(readingFrom: inputFileStream)
        try decompressingStream.open()
        
        let tmpBufferLen = 1<<16 // 65KB buffer
        var tmpBuffer = Array<UInt8>(repeating: 0, count: tmpBufferLen)
        while decompressingStream.hasBytesAvailable {
            let readLen = try decompressingStream.read(&tmpBuffer, maxLength: tmpBufferLen)
            try outputFileStream.write(tmpBuffer, length: readLen)
        }
        
        decompressingStream.close()
        try outputFileStream.close()
        inputFileStream.close()
        return decompressedFileURL
    }
}
