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

import XCTest
import Foundation

extension XCTestCase {
    func genBufferOfLen(_ len: Int) -> [UInt8] {
        if len == 0 { return [] }
        return (0..<len).map { _ in UInt8.random(in: 0...UInt8.max) }
    }
    
    class private var tmpFolderURL: URL {
        let url = FileManager.default.temporaryDirectory
        return url
    }
    
    class private var tmpFolderStr: String {
        return tmpFolderURL.path
    }
    
    class func genRandStr(_ length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    func genRandStr(_ length: Int) -> String {
        return Self.genRandStr(length)
    }
    
    class func createTmpFolder() throws -> URL {
        let randStr = genRandStr(32)
        let pathURL = tmpFolderURL.appendingPathComponent(randStr)
        let fm = FileManager.default
        let path = pathURL.path
        try fm.createDirectory(atPath: path, withIntermediateDirectories: true)
        return pathURL
    }
    
    class func removeTmpFolder(_ url: URL) throws {
        let fm = FileManager.default
        try fm.removeItem(at: url)
    }
    
    func genTmpFileURL(_ folder: URL) -> URL {
        let fileName = genRandStr(32)
        let filePath = folder.appendingPathComponent(fileName)
        FileManager.default.createFile(atPath: filePath.path, contents: nil)
        return filePath
    }
    
    func createTmpFileURL(_ folder: URL) -> URL {
        let filePath = genTmpFileURL(folder)
        FileManager.default.createFile(atPath: filePath.path, contents: nil)
        return filePath
    }
    
    func fileURL(_ file: String, _ ext: String? = nil) -> URL? {
        let url = Bundle.module.url(forResource: file, withExtension: ext)!
        return url
    }
    
    
}
