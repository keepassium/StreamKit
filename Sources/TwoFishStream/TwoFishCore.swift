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

let TwoFishIVSize = 16

public struct TwoFishStreamError: LocalizedError {
    public enum Kind {
        case fillKeyedSBoxes
        case notInitialized
        case illegalKeyLength
        case platformUnsuitableUInt32
        case platformUnsuitableByte
        case platformGet32ImplementedImproperly
        case platformPut32ImplementedImproperly
        case platformRolRoRImplementedImproperly
        case platformBSwapUndefined
        case platformSelectByteTestImplementedImproperly
        case testEncryptionFail
        case testDecryptionFail
        case testSequenceEncryptionFail
        case testSequenceDecryptionFail
        case testOddSizedKeysFail
        case keySizeError
        case ivSizeError
        case dataNotAligned
        case otherError(code: Int32)
    }
    public let file: String
    public let line: Int
    public let kind: Kind
    
    internal init(file: String = #file, line: Int = #line, kind: Kind) {
        self.file = String(describing: file)
        self.line = line
        self.kind = kind
    }
    
    internal init(file: String = #file, line: Int = #line, code: Int32) {
        self.file = String(describing: file)
        self.line = line
        let mapper: [Int32: Kind] = [
            1: .fillKeyedSBoxes,
            2: .notInitialized,
            3: .illegalKeyLength,
            101: .platformUnsuitableUInt32,
            102: .platformUnsuitableByte,
            103: .platformGet32ImplementedImproperly,
            104: .platformPut32ImplementedImproperly,
            105: .platformRolRoRImplementedImproperly,
            106: .platformBSwapUndefined,
            107: .platformSelectByteTestImplementedImproperly,
            108: .testEncryptionFail,
            109: .testDecryptionFail,
            110: .testSequenceEncryptionFail,
            111: .testSequenceDecryptionFail,
            112: .testOddSizedKeysFail
        ]
        self.kind = mapper[code] ?? .otherError(code: code)
    }
}

