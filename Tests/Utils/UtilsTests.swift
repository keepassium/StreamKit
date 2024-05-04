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

final class UtilsTests: XCTestCase {
    func testCalculatingSHA256() {
        let inFileURL = fileURL("1MB")!
        let expectedDigest: [UInt8] = [
            0xf1, 0xb6, 0x42, 0x31, 0x71, 0x66, 0x75, 0x5a, 0xcc, 0x6f, 0x98, 0xbe, 0x86, 0xd9, 0xf8, 0x07,
            0x16, 0xd0, 0x57, 0x3c, 0x26, 0x5f, 0x63, 0x03, 0x91, 0xd4, 0x97, 0xa4, 0xe4, 0x60, 0x69, 0x2f,]
        XCTAssertEqual(sha256(fileAt: inFileURL), expectedDigest)
    }
}
