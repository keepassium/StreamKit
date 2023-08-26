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
import Core

public final class TwoFishInputStream: InputStream {
    public static let defaultChunkSize = 1<<15
    private let nestedStream: InputStream
    private let bufferSize: Int
    private var encryptedBuffer: UnsafeMutablePointer<UInt8>
    private var decryptedBuffer: UnsafeMutablePointer<UInt8>
    private let key: [UInt8]
    private var iv: [UInt8]
    private var isOpen = false
    private var eofReached = false
    private var encryptedBufferDirtyLen: Int = 0
    private var encryptedBufferAvailableLen: Int
    private var decryptedBufferDirtyLen: Int = 0
    private var decryptedBufferAvailableLen: Int
    private var context: Twofish_key
    private let blockLen = 16
    private var status: Int32 = 0
    
    public init(readingFrom nestedStream: InputStream,
                key: [UInt8],
                iv: [UInt8],
                chunkSize: Int = TwoFishInputStream.defaultChunkSize) {
        self.nestedStream = nestedStream
        self.key = key
        self.encryptedBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: chunkSize)
        self.decryptedBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: chunkSize)
        self.bufferSize = chunkSize
        self.decryptedBufferAvailableLen = chunkSize
        self.encryptedBufferAvailableLen = chunkSize
        self.iv = iv
        self.context = Twofish_key()
    }
    
    deinit {
        encryptedBuffer.deallocate()
        decryptedBuffer.deallocate()
    }
    
    public var hasBytesAvailable: Bool {
        return !eofReached || encryptedBufferReadyLen > 0 || decryptedBufferReadyLen > 0
    }
    
    public func open() throws {
        guard !isOpen else { fatalError("The stream can be opened only once") }
        isOpen = true
        
        guard iv.count == TwoFishIVSize else {
            throw TwoFishStreamError(kind: .ivSizeError)
        }
        
        status = Twofish_initialise();
        guard status == TWOFISH_SUCCESS.rawValue else {
            throw TwoFishStreamError(code: status)
        }
        
        var key = key
        status = Twofish_prepare_key(&key, Int32(key.count), &context)
        guard status == TWOFISH_SUCCESS.rawValue else {
            throw TwoFishStreamError(code: status)
        }
    }
    
    public func read(_ outBuffer: UnsafeMutablePointer<UInt8>, maxLength: Int) throws -> Int {
        guard isOpen else { fatalError("The stream is not opened") }
        
        var totalReadCount = 0
        var remainingLen = maxLength
        while remainingLen > 0 && hasBytesAvailable {
            try fillEncryptedBuffer()
            if nestedStream.hasBytesAvailable {
                try decryptBlocks()
            }
            else {
                try decryptRemaining()
            }
            let readCount = writeOutTo(outBuffer+totalReadCount, count: remainingLen)
            if readCount == 0 { break }
            remainingLen -= readCount
            totalReadCount += readCount
        }
        return totalReadCount
    }
    
    private var encryptedBufferReadyLen: Int {
        return bufferSize-encryptedBufferDirtyLen-encryptedBufferAvailableLen
    }
    
    private var encryptedBufferFilledLen: Int {
        return bufferSize-encryptedBufferAvailableLen
    }
    
    private var isEncryptedBufferFull: Bool {
        return encryptedBufferAvailableLen == 0
    }
    
    private func fillEncryptedBuffer() throws {
        if eofReached || isEncryptedBufferFull {
            return
        }
        
        let canTake = encryptedBufferAvailableLen/blockLen*blockLen
        let inBuf = encryptedBuffer+encryptedBufferFilledLen
        let readLen = try nestedStream.read(inBuf, maxLength: canTake)
        if !nestedStream.hasBytesAvailable {
            eofReached = true
        }
        encryptedBufferAvailableLen -= readLen
    }
    
    
    private var decryptedBufferReadyLen: Int {
        return bufferSize-decryptedBufferDirtyLen-decryptedBufferAvailableLen
    }
    
    private var decryptedBufferFilledLen: Int {
        return bufferSize-decryptedBufferAvailableLen
    }
    
    private func decryptBlocks() throws {
        if decryptedBufferReadyLen > blockLen {
            return
        }
        
        let inBufAvailable = encryptedBufferReadyLen
        let outBufAvailable = decryptedBufferAvailableLen
        let numOfBlocks = min(inBufAvailable,outBufAvailable)/blockLen
        if numOfBlocks > 0 {
            let processBytesLen = numOfBlocks*blockLen
            let inBuffer = encryptedBuffer+encryptedBufferDirtyLen
            let outBuffer = decryptedBuffer+decryptedBufferFilledLen
            for n in 0..<numOfBlocks {
                let blockStartPos = n*blockLen
                Twofish_decrypt(&context, inBuffer+blockStartPos, outBuffer+blockStartPos)
                for i in 0..<blockLen {
                    (outBuffer+blockStartPos)[i] ^= iv[i]
                }
                memcpy(&iv, inBuffer+blockStartPos, blockLen)
            }
            encryptedBufferDirtyLen += processBytesLen
            if encryptedBufferReadyLen == 0 {
                (encryptedBufferDirtyLen, encryptedBufferAvailableLen) = (0, bufferSize)
            }
            decryptedBufferAvailableLen -= processBytesLen
        }
    }
    
    private func decryptRemaining() throws {
        if encryptedBufferReadyLen > 0 && decryptedBufferAvailableLen >= encryptedBufferReadyLen {
            let numOfBlocks = min(encryptedBufferReadyLen,decryptedBufferAvailableLen)/blockLen
            if numOfBlocks > 0 {
                for _ in 0..<numOfBlocks {
                    let inBuffer = encryptedBuffer+encryptedBufferDirtyLen
                    let outBuffer = decryptedBuffer+decryptedBufferFilledLen
                    Twofish_decrypt(&context, inBuffer, outBuffer)
                    for i in 0..<blockLen {
                        (outBuffer)[i] ^= iv[i]
                    }
                    memcpy(&iv, inBuffer, blockLen)
                    encryptedBufferDirtyLen += blockLen
                    if encryptedBufferReadyLen == 0 {
                        (encryptedBufferDirtyLen, encryptedBufferAvailableLen) = (0, bufferSize)
                    }
                    decryptedBufferAvailableLen -= blockLen
                }
            }

            guard encryptedBufferReadyLen%blockLen == 0 else {
                throw TwoFishStreamError(kind: .dataNotAligned)
            }
            
            if !nestedStream.hasBytesAvailable && encryptedBufferReadyLen == 0 {
                removePaddinDataFromDecryptedBuffer()
            }
        }
    }
    
    private func removePaddinDataFromDecryptedBuffer() {
        if decryptedBufferReadyLen > 0 {
            let lastByte = (decryptedBuffer+decryptedBufferFilledLen-1).pointee
            decryptedBufferAvailableLen += Int(lastByte)
        }
    }
    
    private func writeOutTo(_ outBuffer: UnsafeMutablePointer<UInt8>, count: Int) -> Int {
        let outLen = min(decryptedBufferReadyLen, count)
        if outLen > 0 {
            outBuffer.initialize(from: decryptedBuffer+decryptedBufferDirtyLen, count: outLen)
            decryptedBufferDirtyLen += outLen
            if decryptedBufferReadyLen == 0 {
                (decryptedBufferDirtyLen, decryptedBufferAvailableLen) = (0, bufferSize)
            }
        }
        return outLen
    }
    
    public func close() {
        guard isOpen else { fatalError("The stream is not opened") }
    }
}
