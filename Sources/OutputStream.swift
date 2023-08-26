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

import Foundation

public protocol OutputStream {
    var hasSpaceAvailable: Bool { get }
    
    func open() throws
    func write(_ buffer: UnsafePointer<UInt8>, length: Int) throws
    func close() throws
}

public extension OutputStream {
    func write(_ data: Data) throws {
        try data.withUnsafeBytes { urbp in
            try urbp.withMemoryRebound(to: UInt8.self) { buffer in
                try buffer.baseAddress.map { try write($0, length: data.count) }
            }
        }
    }
    
    func write(_ string: String, ofEncoding encoding: String.Encoding) throws {
        try string.data(using: encoding).map { try write($0) }
    }
}
