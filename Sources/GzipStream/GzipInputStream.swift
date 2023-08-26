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

public final class GzipInputStream: InputStream {
    public static let defaultDeflateChunkSize = 1<<15
    public static let defaultInflateChunkSize = 1<<15
    
    private var zstream: z_stream
    private let nestedStream: InputStream
    private let inflateBufferSize: Int
    private let deflateBufferSize: Int
    private var deflateBuffer: UnsafeMutablePointer<UInt8>
    private var inflateBuffer: UnsafeMutablePointer<UInt8>
    private var inflateUsedLen: Int
    private var inflateAvailableLen: Int
    private var eofReached = false
    private var isOpen = false
    private var status: Int32 = Z_OK
    private var windowBits: Int32

    
    /// - Parameters:
    ///   - inputStream: <#inputStream description#>
    ///   - windowBits: shall be a base 2 logarithm of the maximum window size to use, and shall be a value between 9 and 15. If the input data was compressed with a larger window size, subsequent attempts to decompress this data will fail with Z_DATA_ERROR, rather than try to allocate a larger window.
    ///   - deflateBufferSize: <#deflateBufferSize description#>
    ///   - inflateBufferSize: <#inflateBufferSize description#>
    public init(readingFrom nestedStream: InputStream,
                windowBits: Int32 = MAX_WBITS + 16,
                deflateChunkSize: Int = GzipInputStream.defaultDeflateChunkSize,
                inflateChunkSize: Int = GzipInputStream.defaultInflateChunkSize) {
        self.nestedStream = nestedStream
        self.windowBits = windowBits
        self.deflateBufferSize = deflateChunkSize
        self.inflateBufferSize = inflateChunkSize
        self.deflateBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: deflateBufferSize)
        self.inflateBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: inflateBufferSize)
        self.inflateUsedLen = 0
        self.inflateAvailableLen = inflateChunkSize

        zstream = z_stream()
    }

    deinit {
        deflateBuffer.deallocate()
        inflateBuffer.deallocate()
    }
    
    public func open() throws {
        guard !isOpen else { fatalError("The stream can be opened only once") }
        isOpen = true
        
        let streamSize = Int32(MemoryLayout<z_stream>.size)
        let zlibVersion = ZLIB_VERSION
        status = inflateInit2_(&zstream, windowBits, zlibVersion, streamSize)
        
        guard status == Z_OK else {
            throw GzipStreamError(code: status, description: zstream.msg)
        }
        zstream.avail_in = 0
        zstream.avail_out = 0
        zstream.next_in = nil
        zstream.next_out = nil
    }

    public var hasBytesAvailable: Bool {
        return !eofReached || bytesReadyToRead > 0
    }
    
    private var bytesReadyToRead: Int {
        return inflateBufferSize-inflateUsedLen-inflateAvailableLen
    }
    
    private var isInflateBufferFull: Bool {
        return inflateAvailableLen == 0
    }

    public func read(_ outBuffer: UnsafeMutablePointer<UInt8>, maxLength: Int) throws -> Int {
        guard isOpen else { fatalError("The stream is not opened") }
        
        var totalReadLen = 0
        var remainingLen = maxLength
        while remainingLen > 0 && hasBytesAvailable {
            try fillInflateBuffer()
            let copiedLen = copyReadyBytesTo(outBuffer+totalReadLen, count: remainingLen)
            totalReadLen += copiedLen
            remainingLen -= copiedLen
        }
        return totalReadLen
    }
    
    private func copyReadyBytesTo(_ outBuffer: UnsafeMutablePointer<UInt8>, count: Int) -> Int {
        let outLen = min(bytesReadyToRead, count)
        outBuffer.initialize(from: inflateBuffer+inflateUsedLen, count: outLen)
        inflateUsedLen += outLen
        if bytesReadyToRead == 0 {
            (inflateUsedLen, inflateAvailableLen) = (0, inflateBufferSize)
        }
        return outLen
    }

    private func fillInflateBuffer() throws {
        if isInflateBufferFull {
            return
        }

        zstream.next_out = (inflateBuffer+inflateBufferSize-inflateAvailableLen)
        zstream.avail_out = uInt(inflateAvailableLen)
        
        if zstream.avail_in == 0 {
            let readLen = try nestedStream.read(deflateBuffer, maxLength: deflateBufferSize)
            zstream.next_in = deflateBuffer
            zstream.avail_in = uInt(readLen)
            
            if readLen == 0 {
                eofReached = true
                try finalizeInflate()
                return
            }
        }
        
        status = inflate(&zstream, Z_NO_FLUSH)
        if status == Z_STREAM_END {
            eofReached = true
            try finalizeInflate()
        }
        guard status == Z_OK else {
            throw GzipStreamError(code: status, description: zstream.msg)
        }
        inflateAvailableLen = Int(zstream.avail_out)
    }
    
    private func finalizeInflate() throws {
        status = inflateEnd(&zstream)
        if status != Z_OK {
            throw GzipStreamError(code: status, description: zstream.msg)
        }
    }
    
    public func close() {
        guard isOpen else { fatalError("The stream is not opened") }
        _ = inflateEnd(&zstream)
        nestedStream.close()
    }
}

