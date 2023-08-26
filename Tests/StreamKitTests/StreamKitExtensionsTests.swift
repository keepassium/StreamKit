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

final class StreamKitExtensionsTests: XCTestCase {
    static var tmpDir: URL!
    
    override class func setUp() {
        super.setUp()
        tmpDir = try! createTmpFolder()
    }
    
    override class func tearDown() {
        super.tearDown()
        try! removeTmpFolder(tmpDir)
    }

    func testEncryptingDecryptingStringUsingSalsa20Streams() throws {
        let key = genBufferOfLen(32)
        let iv = genBufferOfLen(8)
        
        let encryptedFileURL = genTmpFileURL(Self.tmpDir)
        let originString = genRandStr(100)
        
        try encryptStrUsingSalsa20(originString, key, iv, encryptedFileURL)
        let decryptedString = try decryptFileUsingSalsa20(encryptedFileURL, key, iv)
        
        XCTAssertEqual(originString, decryptedString)
    }
}

extension StreamKitExtensionsTests {
    func encryptStrUsingSalsa20(_ str: String, _ key: [UInt8], _ iv: [UInt8], _ outURL: URL) throws {
        let outputFileStream = FileOutputStream(with: outURL)!
        try outputFileStream.open()
        
        let encryptingStream = Salsa20OutputStream(writingTo: outputFileStream,
                                                   key: key,
                                                   iv: iv)
        try encryptingStream.open()
                
        try encryptingStream.write(str, ofEncoding: .utf8)
        
        try encryptingStream.close()
        try outputFileStream.close()
    }
    
    func decryptFileUsingSalsa20(_ encryptedFileURL: URL, _ key: [UInt8], _ iv: [UInt8]) throws -> String? {
        let inputFileStream = FileInputStream(with: try! FileHandle(forReadingFrom: encryptedFileURL))
        try inputFileStream.open()
        
        let decryptingStream = Salsa20InputStream(readingFrom: inputFileStream,
                                                  key: key,
                                                  iv: iv)
        try decryptingStream.open()
        
        let data = try decryptingStream.readToEnd()
        
        decryptingStream.close()
        inputFileStream.close()
        return String(data: data, encoding: .utf8)
    }
}
