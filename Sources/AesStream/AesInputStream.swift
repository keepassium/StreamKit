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

public final class AesInputStream: InputStream {
    public static let defaultChunkSize = 1<<15
    private let nestedStream: InputStream
    private var cryptorRef: CCCryptorRef?
    private let bufferSize: Int
    private var encryptedBuffer: UnsafeMutablePointer<UInt8>
    private var decryptedBuffer: UnsafeMutablePointer<UInt8>
    private let key: [UInt8]
    private let iv: [UInt8]
    private var isOpen = false
    private var eofReached = false
    private var decryptedBufferUsedLen: Int
    private var decryptedBufferAvailableLen: Int
    private var status: Int32 = 0
    private let options: AesOptions
    private let blockSize = 16
    
    public init(readingFrom nestedStream: InputStream,
                key: [UInt8],
                iv: [UInt8],
                options: AesOptions = AesOptions.PKCS7Padding,
                chunkSize: Int = AesInputStream.defaultChunkSize) {
        self.nestedStream = nestedStream
        self.options = options
        self.key = key
        self.encryptedBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: chunkSize)
        self.decryptedBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: chunkSize)
        self.bufferSize = chunkSize
        self.decryptedBufferUsedLen = 0
        self.decryptedBufferAvailableLen = chunkSize
        self.iv = iv
    }
    
    deinit {
        encryptedBuffer.deallocate()
        decryptedBuffer.deallocate()
    }
    
    public var hasBytesAvailable: Bool {
        return !eofReached || decryptedBufferReadyLen > 0
    }
    
    public func open() throws {
        guard !isOpen else { fatalError("The stream can be opened only once") }
        isOpen = true
        
        guard iv.count == blockSize else {
            throw AesStreamError(kind: .ivSizeError)
        }
        
        status = CCCryptorCreate(CCOperation(kCCDecrypt),
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
    
    public func read(_ outBuffer: UnsafeMutablePointer<UInt8>, maxLength: Int) throws -> Int {
        guard isOpen else { fatalError("The stream is not opened") }
        
        var totalReadCount = 0
        while maxLength-totalReadCount > 0 && hasBytesAvailable {
            try fillDecryptedBuffer()
            let readCount = writeOutTo(outBuffer+totalReadCount, count: maxLength-totalReadCount)
            totalReadCount += readCount
        }
        return totalReadCount
    }
    
    private var decryptedBufferReadyLen: Int {
        return bufferSize-decryptedBufferUsedLen-decryptedBufferAvailableLen
    }
    
    private func fillDecryptedBuffer() throws {
        if decryptedBufferReadyLen > 0 {
            return
        }
        
        let outBuf = decryptedBuffer+(bufferSize-decryptedBufferAvailableLen)
        let outAvailable = decryptedBufferAvailableLen
        var outMoved = 0
        let readLength = try nestedStream.read(encryptedBuffer, maxLength: bufferSize)
        
        if readLength > 0 {
            status = CCCryptorUpdate(cryptorRef,
                                     encryptedBuffer,
                                     readLength,
                                     outBuf,
                                     outAvailable,
                                     &outMoved)
        }
        else if !nestedStream.hasBytesAvailable {
            eofReached = true
            status = CCCryptorFinal(cryptorRef,
                                    outBuf,
                                    outAvailable,
                                    &outMoved)
        }
        
        guard status == kCCSuccess else {
            throw AesStreamError(code: status)
        }
        decryptedBufferAvailableLen -= outMoved
    }
    
    private func writeOutTo(_ outBuffer: UnsafeMutablePointer<UInt8>, count: Int) -> Int {
        let outLen = min(decryptedBufferReadyLen, count)
        outBuffer.initialize(from: decryptedBuffer+decryptedBufferUsedLen, count: outLen)
        decryptedBufferUsedLen += outLen
        if decryptedBufferReadyLen == 0 {
            (decryptedBufferUsedLen, decryptedBufferAvailableLen) = (0, bufferSize)
        }
        return outLen
    }
    
    public func close() {
        guard isOpen else { fatalError("The stream is not opened") }
        
        _ = CCCryptorRelease(cryptorRef)
    }
}
