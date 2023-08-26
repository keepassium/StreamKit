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

public final class AesOutputStream: OutputStream {
    public static let defaultChunkSize = 1<<15
    private var cryptorRef: CCCryptorRef?
    private var outBuffer: UnsafeMutablePointer<UInt8>
    private var inBuffer: UnsafeMutablePointer<UInt8>
    private let chunkSize: Int
    private let nestedStream: OutputStream
    private let iv: [UInt8]
    private let key: [UInt8]
    private var isOpen = false
    private var status: Int32 = 0
    private let options: AesOptions
    private let blockSize = 16
    
    public init(writingTo outputStream: OutputStream,
                key: [UInt8],
                iv: [UInt8],
                options: AesOptions = AesOptions.PKCS7Padding,
                chunkSize: Int = AesOutputStream.defaultChunkSize) {
        self.nestedStream = outputStream
        self.options = options
        self.outBuffer = UnsafeMutablePointer.allocate(capacity: chunkSize)
        self.inBuffer = UnsafeMutablePointer.allocate(capacity: chunkSize)
        self.chunkSize = chunkSize
        self.key = key
        self.iv = iv
    }
    
    deinit {
        outBuffer.deallocate()
    }
    
    public var hasSpaceAvailable: Bool {
        return nestedStream.hasSpaceAvailable
    }
    
    public func open() throws {
        guard !isOpen else { fatalError("The stream can be opened only once") }
        isOpen = true
        
        guard iv.count == blockSize else {
            throw AesStreamError(kind: .ivSizeError)
        }
        
        status = CCCryptorCreate(CCOperation(kCCEncrypt),
                                 CCAlgorithm(kCCAlgorithmAES),
                                 CCOptions(options),
                                 key,
                                 key.count,
                                 iv,
                                 &cryptorRef)
        guard status == kCCSuccess else {
            throw AesStreamError(code: status)
        }
    }
    
    public func write(_ buffer: UnsafePointer<UInt8>, length: Int) throws {
        guard isOpen else { fatalError("The stream is not opened") }
        
        var remainingLen = length
        var totalReadLen = 0
        while remainingLen > 0 {
            let inBufAvailable = min(chunkSize, remainingLen)
            inBuffer.initialize(from: buffer+totalReadLen, count: inBufAvailable)
            
            var outBufCount = 0
            status = CCCryptorUpdate(cryptorRef,
                                     inBuffer,
                                     inBufAvailable,
                                     outBuffer,
                                     chunkSize,
                                     &outBufCount)
            guard status == kCCSuccess else {
                throw AesStreamError(code: status)
            }
            
            if outBufCount > 0 {
                try nestedStream.write(outBuffer, length: outBufCount)
            }
            totalReadLen += inBufAvailable
            remainingLen -= inBufAvailable
        }
    }
    
    public func close() throws {
        guard isOpen else { fatalError("The stream is not opened") }
        
        var outBufCount = 0
        status = CCCryptorFinal(cryptorRef,
                                outBuffer,
                                chunkSize,
                                &outBufCount)
        guard status == kCCSuccess else {
            throw AesStreamError(code: status)
        }
        
        try nestedStream.write(outBuffer, length: outBufCount)
        
        _ = CCCryptorRelease(cryptorRef)
    }
}


