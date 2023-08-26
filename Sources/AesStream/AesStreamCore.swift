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
import CommonCrypto

public typealias AesOptions = Int
public extension AesOptions {
    static let CBCMode = 0
    static let PKCS7Padding = kCCOptionPKCS7Padding
    static let ECBMode = kCCOptionECBMode
}

public struct AesStreamError: LocalizedError {
    public enum Kind {
        case paramError
        case bufferTooSmall
        case memoryFailure
        case alignmentError
        case decodeError
        case unimplemented
        case overflow
        case rngFailure
        case unspecifiedError
        case callSequenceError
        case keySizeError
        case ivSizeError
        case otherError(code: Int32)
    }
    public let file: String
    public let line: Int
    public let kind: Kind
    
    internal init(file: String = #file, line: Int = #line, code: Int32) {
        self.file = String(describing: file)
        self.line = line
        switch Int(code) {
        case kCCParamError:
            kind = .paramError
        case kCCBufferTooSmall:
            kind = .bufferTooSmall
        case kCCMemoryFailure:
            kind = .memoryFailure
        case kCCAlignmentError:
            kind = .alignmentError
        case kCCDecodeError:
            kind = .decodeError
        case kCCUnimplemented:
            kind = .unimplemented
        case kCCOverflow:
            kind = .overflow
        case kCCRNGFailure:
            kind = .rngFailure
        case kCCUnspecifiedError:
            kind = .unspecifiedError
        case kCCCallSequenceError:
            kind = .callSequenceError
        case kCCKeySizeError:
            kind = .keySizeError
        case kCCAlignmentError:
            kind = .alignmentError
        default:
            kind = .otherError(code: code)
        }
    }
    
    internal init(file: String = #file, line: Int = #line, kind: Kind) {
        self.file = String(describing: file)
        self.line = line
        self.kind = kind
    }
}

