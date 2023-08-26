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

public final class ChaCha20OutputStream: OutputStream {
    public static let defaultChunkSize = 1<<15
    private var inChunkBuffer: UnsafeMutablePointer<UInt8>
    private var outChunkBuffer: UnsafeMutablePointer<UInt8>
    private let chunkBufferLen: Int
    private let nestedStream: OutputStream
    private let iv: [UInt8]
    private let key: [UInt8]
    private var isOpen = false
    private var context = CHACHA20_ctx()
    private var inChunkBufferDirtyLen: Int = 0
    private var inChunkBufferAvailableLen: Int
    private let blockLen: Int = Int(CHACHA20_BLOCKLENGTH)
    
    public init(writingTo outputStream: OutputStream,
                key: [UInt8],
                iv: [UInt8],
                chunkSize: Int = ChaCha20OutputStream.defaultChunkSize) {
        self.nestedStream = outputStream
        self.inChunkBuffer = UnsafeMutablePointer.allocate(capacity: chunkSize)
        self.outChunkBuffer = UnsafeMutablePointer.allocate(capacity: chunkSize)
        self.chunkBufferLen = chunkSize
        self.key = key
        self.iv = iv
        self.inChunkBufferAvailableLen = chunkSize
    }
    
    deinit {
        inChunkBuffer.deallocate()
        outChunkBuffer.deallocate()
    }
    
    public var hasSpaceAvailable: Bool {
        return nestedStream.hasSpaceAvailable
    }
    
    public func open() throws {
        guard !isOpen else { fatalError("The stream can be opened only once") }
        isOpen = true
        
        guard key.count == ChaCha20KeySize else {
            throw ChaCha20StreamError(kind: .keySizeError)
        }
        
        guard iv.count == ChaCha20IVSize else {
            throw ChaCha20StreamError(kind: .ivSizeError)
        }
        
        CHACHA20_init();
        
        let keySize = key.count
        let ivSize = iv.count
        key.withUnsafeBufferPointer { keyubp in
            CHACHA20_keysetup(&context, keyubp.baseAddress!, u32(keySize*8), u32(ivSize*8))
        }
        iv.withUnsafeBufferPointer { ivubp in
            CHACHA20_ivsetup(&context, ivubp.baseAddress!)
        }
    }
    
    public func write(_ buffer: UnsafePointer<UInt8>, length: Int) throws {
        guard isOpen else { fatalError("The stream is not opened") }
        
        var remainingLen = length
        var totalReadLen = 0
        while remainingLen > 0 {
            let tookLen = fillChunkBuffer(buffer+totalReadLen, remainingLen)
            remainingLen -= tookLen
            totalReadLen += tookLen
            if try encryptChunkBuffer() == 0 { break }
        }
    }
    
    private var isInChunkBufferFull: Bool {
        return inChunkBufferAvailableLen == 0
    }
    
    private var inChunkBufferFilledLen: Int {
        return chunkBufferLen-inChunkBufferAvailableLen
    }
    
    private var inChunkBufferReadyLen: Int {
        return chunkBufferLen-inChunkBufferDirtyLen-inChunkBufferAvailableLen
    }
    
    private func fillChunkBuffer(_ buffer: UnsafePointer<UInt8>, _ length: Int) -> Int  {
        if isInChunkBufferFull {
            return 0
        }
        
        let numOfBlocks = min(length, inChunkBufferAvailableLen)/blockLen
        if numOfBlocks > 0 {
            let tookLen = numOfBlocks*blockLen
            let inBuf = inChunkBuffer+inChunkBufferFilledLen
            inBuf.initialize(from: buffer, count: tookLen)
            inChunkBufferAvailableLen -= tookLen
            return tookLen
        }
        else {
            let tookLen = min(length, inChunkBufferAvailableLen)
            let inBuf = inChunkBuffer+inChunkBufferFilledLen
            inBuf.initialize(from: buffer, count: tookLen)
            inChunkBufferAvailableLen -= tookLen
            return tookLen
        }
    }
    
    private func encryptChunkBuffer() throws -> Int {
        let numOfBlocks = inChunkBufferReadyLen/blockLen
        let processBytesLen = numOfBlocks*blockLen
        if numOfBlocks > 0 {
            let inBuffer = inChunkBuffer+inChunkBufferDirtyLen
            CHACHA20_encrypt_blocks(&context, inBuffer, outChunkBuffer, u32(numOfBlocks))
            try nestedStream.write(outChunkBuffer, length: processBytesLen)
            inChunkBufferDirtyLen += processBytesLen
            if inChunkBufferDirtyLen == inChunkBufferFilledLen {
                (inChunkBufferDirtyLen, inChunkBufferAvailableLen) = (0, chunkBufferLen)
            }
        }
        return processBytesLen
    }
    
    public func close() throws {
        guard isOpen else { fatalError("The stream is not opened") }
        if inChunkBufferReadyLen > 0 {
            let inBuffer = inChunkBuffer+inChunkBufferDirtyLen
            CHACHA20_encrypt_bytes(&context, inBuffer, outChunkBuffer, u32(inChunkBufferReadyLen))
            try nestedStream.write(outChunkBuffer, length: inChunkBufferReadyLen)
        }
    }
}


