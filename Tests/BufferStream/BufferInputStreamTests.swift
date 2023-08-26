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

final class BufferInputStreamTests: XCTestCase {
    private func checkRead(_ array: inout [UInt8], _ chunkBufLen: Int) throws {
        let inStream = BufferInputStream(withBuffer: array)
        try inStream.open()
        defer {
            inStream.close()
        }
        
        var result = [UInt8]()
        var chunkBuf: [UInt8] = Array(repeating: 0, count: chunkBufLen)
        while inStream.hasBytesAvailable {
            let readLen = try inStream.read(&chunkBuf, maxLength: chunkBuf.count)
            result.append(contentsOf: chunkBuf.prefix(readLen))
        }
        XCTAssertEqual(array, result)
    }
    
    func testRead_1KB() throws {
        let len = 1<<10
        var array = genBufferOfLen(len)
        for i in stride(from: 100, to: len, by: 100) {
            try checkRead(&array, i)
        }
    }
}
