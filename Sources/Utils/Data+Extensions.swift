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

import Foundation

// For package debug only
internal extension Data {
    init(fromHex str: String) {
        let stippedSpaces = str
            .filter { $0 != " " }
            .map { $0 }

        let pairs = stride(from: 0, to: stippedSpaces.endIndex, by: 2).map {
            (
                stippedSpaces[$0],
                $0 < stippedSpaces.index(before: stippedSpaces.endIndex)
                    ? stippedSpaces[$0.advanced(by: 1)]
                    : nil
            )
        }
        let array: [UInt8] = pairs.compactMap { pair in
            let string = String(format: "%@%@", "\(pair.0)", pair.1 != nil ? "\(pair.1!)" : "")
            let byte = UInt8(string, radix: 16)
            return byte
        }
        self = Data(array)
    }
}
