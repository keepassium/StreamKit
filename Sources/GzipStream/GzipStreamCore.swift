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
import zlib

public typealias GzipCompressionLevel = Int32
public extension GzipCompressionLevel {
    static let noCompression = Z_NO_COMPRESSION
    static let bestSpeed = Z_BEST_SPEED
    static let bestCompression = Z_BEST_COMPRESSION
    static let defaultCompression = Z_DEFAULT_COMPRESSION
}

public struct GzipStreamError: LocalizedError {
    public enum Kind {
        case streamError
        case dataError
        case memoryError
        case bufferError
        case versionError
        case otherError(code: Int32)
    }
    public let file: String
    public let line: Int
    public let code: Int
    public let description: String?
    public let kind: Kind
    
    internal init(file: String = #file, line: Int = #line, code: Int32, description dPtr: UnsafePointer<CChar>?) {
        self.file = String(describing: file)
        self.code = Int(code)
        self.line = line
        self.description = dPtr.flatMap { String(cString: $0, encoding: .utf8) }
        switch code {
        case Z_STREAM_ERROR:  // -2
            kind = .streamError
        case Z_DATA_ERROR:    // -3
            kind = .dataError
        case Z_MEM_ERROR:     // -4
            kind = .memoryError
        case Z_BUF_ERROR:     // -5
            kind = .bufferError
        case Z_VERSION_ERROR: // -6
            kind = .versionError
        default:
            kind = .otherError(code: code)
        }
    }
    
    public var errorDescription: String? {
        return "\(file):\(line) " + (description ?? "")
    }
}

