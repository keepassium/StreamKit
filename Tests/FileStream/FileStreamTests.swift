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

final class FileStreamTests: XCTestCase {
    static var tmpDir: URL!
    
    override class func setUp() {
        super.setUp()
        tmpDir = try! createTmpFolder()
    }
    
    func testCopyFile() throws {
        let inFileURL = fileURL("1MB")!
        let inFileHandle = try! FileHandle(forReadingFrom: inFileURL)
        let inputFileStream = FileInputStream(with: inFileHandle)
        try inputFileStream.open()
        
        let outputFileURL = createTmpFileURL(Self.tmpDir)
        let fileHandle = try! FileHandle(forWritingTo: outputFileURL)
        let outputFileStream = FileOutputStream(with: fileHandle)
        try outputFileStream.open()
                
        let tmpBufferLen = 1<<16 // 65KB buffer
        var tmpBuffer = Array<UInt8>(repeating: 0, count: tmpBufferLen)
        while inputFileStream.hasBytesAvailable {
            let readLen = inputFileStream.read(&tmpBuffer, maxLength: tmpBufferLen)
            try outputFileStream.write(tmpBuffer, length: readLen)
        }
        
        inputFileStream.close()
        try outputFileStream.close()
        XCTAssertEqual(md5(inFileURL), md5(outputFileURL))
    }
    
    func testRead16BFile() throws {
        let inFileURL = fileURL("16B")!
        let inFileHandle = try! FileHandle(forReadingFrom: inFileURL)
        let inputFileStream = FileInputStream(with: inFileHandle)
        try inputFileStream.open()
        defer {
            inputFileStream.close()
        }
        
        let tmpBufferLen = 1<<16 // 65KB buffer
        var tmpBuffer = Array<UInt8>(repeating: 0, count: tmpBufferLen)
        
        XCTAssertEqual(16, inputFileStream.read(&tmpBuffer, maxLength: 16))
        XCTAssertTrue(inputFileStream.hasBytesAvailable)
        XCTAssertEqual(0, inputFileStream.read(&tmpBuffer, maxLength: 16))
        XCTAssertFalse(inputFileStream.hasBytesAvailable)
    }
    
    override class func tearDown() {
        super.tearDown()
        try! removeTmpFolder(tmpDir)
    }

}
