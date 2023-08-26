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

public final class GzipOutputStream: OutputStream {
    public static let defaultDeflateChunkSize = 1 << 14
    private let nestedStream: OutputStream
    private var zstream: z_stream
    private var deflateBuffer: UnsafeMutablePointer<UInt8>
    private let deflateBufferSize: Int
    private var isOpen = false
    private let windowBits: Int32
    private let compressionLevel: Int32
    private var status: Int32 = Z_OK

    public var hasSpaceAvailable: Bool {
        return true
    }
    
    /// returns  Z_STREAM_ERROR if level is not a valid compression level
    /// - Parameters:
    ///   - windowBits: shall be a base 2 logarithm of the maximum window size to use, and shall be a value between 9 and 15.
    ///
    public init(writingTo nestedStream: OutputStream,
                windowBits: Int32 = MAX_WBITS + 16,
                deflateChunkSize: Int = defaultDeflateChunkSize,
                compressionLevel: GzipCompressionLevel = .defaultCompression) {
        self.nestedStream = nestedStream
        self.windowBits = windowBits
        self.deflateBufferSize = deflateChunkSize
        self.compressionLevel = compressionLevel
        self.deflateBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: deflateBufferSize)
        zstream = z_stream()
    }

    deinit {
        deflateBuffer.deallocate()
    }
    
    public func open() throws {
        guard !isOpen else { fatalError("The stream can be opened only once") }
        isOpen = true
        
        let zlibVersion = ZLIB_VERSION
        let streamSize = MemoryLayout<z_stream>.size
        status = deflateInit2_(&zstream,
                               compressionLevel,
                               Z_DEFLATED,
                               windowBits,
                               MAX_MEM_LEVEL,
                               Z_DEFAULT_STRATEGY,
                               zlibVersion,
                               Int32(streamSize))
        guard status == Z_OK else {
            throw GzipStreamError(code: status, description: zstream.msg)
        }
    }

    public func write(_ buffer: UnsafePointer<UInt8>, length: Int) throws {
        guard isOpen else { fatalError("The stream is not opened") }
        
        zstream.next_in = UnsafeMutablePointer(mutating: buffer)
        zstream.avail_in = UInt32(length)

        do {
            while zstream.avail_in > 0 {
                repeat {
                    zstream.avail_out = UInt32(deflateBufferSize)
                    zstream.next_out = deflateBuffer
                    
                    status = deflate(&zstream, Z_NO_FLUSH)
                    guard status != Z_STREAM_ERROR else {
                        throw GzipStreamError(code: status, description: zstream.msg)
                    }
                    
                    let outBytesLength = deflateBufferSize-Int(zstream.avail_out)
                    try nestedStream.write(deflateBuffer, length: outBytesLength)
                } while zstream.avail_out == 0
            }
        }
        catch {
            deflateEnd(&zstream)
            throw error
        }
    }

    public func close() throws {
        guard isOpen else { fatalError("The stream is not opened") }
        
        zstream.avail_in = 0
        zstream.next_in = nil
        do {
            repeat {
                zstream.avail_out = UInt32(deflateBufferSize)
                zstream.next_out = deflateBuffer
                status = deflate(&zstream, Z_FINISH)
                guard status != Z_STREAM_ERROR else {
                    throw GzipStreamError(code: status, description: zstream.msg)
                }
                let outBytesCount = deflateBufferSize-Int(zstream.avail_out)
                try nestedStream.write(deflateBuffer, length: outBytesCount)
                
            } while status != Z_STREAM_END
            
            deflateEnd(&zstream)
        }
        catch {
            deflateEnd(&zstream)
            throw error
        }

    }
}
