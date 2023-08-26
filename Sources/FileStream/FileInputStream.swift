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

public final class FileInputStream: InputStream {
    private let fileHandle: FileHandle
    private var eofReached = false

    public init(with fileHandle: FileHandle) {
        self.fileHandle = fileHandle
    }
    
    public init?(with localFileURL: URL) {
        guard let fileHandle = try? FileHandle(forReadingFrom: localFileURL) else {
            return nil
        }
        self.fileHandle = fileHandle
    }

    public var hasBytesAvailable: Bool {
        return !eofReached
    }
    
    public func open() throws {
    }
    
    public func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        let readData = fileHandle.readData(ofLength: len)
        eofReached = (readData.count != len)
        readData.withUnsafeBytes {
            if let baseAddress = $0.baseAddress {
                let t = baseAddress.assumingMemoryBound(to: UInt8.self)
                buffer.initialize(from: t, count: readData.count)
            }
        }
        return readData.count
    }
    
    public func close() {
    }
}
