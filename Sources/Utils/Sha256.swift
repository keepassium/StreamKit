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

import CommonCrypto
import Foundation

public func sha256(fileAt url: URL) -> [UInt8]? {
    let bufferSize = 1 << 11
    do {
        let file = try FileHandle(forReadingFrom: url)
        defer {
            file.closeFile()
        }

        var context = CC_SHA256_CTX()
        CC_SHA256_Init(&context)

        while autoreleasepool(invoking: {
            let data = file.readData(ofLength: bufferSize)
            if data.count > 0 {
                data.withUnsafeBytes {
                    _ = CC_SHA256_Update(&context, $0.baseAddress, numericCast(data.count))
                }
                return true
            } else {
                return false
            }
        }) { }

        var digest: [UInt8] = Array(repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        _ = CC_SHA256_Final(&digest, &context)
        return digest
    } catch {
        return nil
    }
}
