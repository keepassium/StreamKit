# StreamKit
This open-source Swift library offers a comprehensive collection of cryptographic algorithms. These ciphers can be structured into chains, facilitating the seamless flow of output from one cipher stream to another. This architecture enables concurrent tasks, such as encrypting data while writing the encrypted result to a file. Integrate "StreamKit" into your projects to efficiently utilize these cryptographic functionalities.

# The available streams
- [FileStream](FileStream.md)
- [GzipStream](GzipStream.md)
- [AesStream](AesStream.md)
- [Salsa20Stream](Salsa20Stream.md)
- [ChaCha20Stream](ChaCha20Stream.md)
- [TwoFishStream](TwoFishStream.md)

# How to add the library to a project
In the Xcode press `File` -> `Add Packages` -> In the search field insert `https://github.com/iharkatkavets/StreamKit.git`.
It might require to setup `GitHub Account` in the Xcode

# How to use the library in the project
First import the library
```swift
import StreamKit
```

## How to read a file using `FileInputStream`
```swift
let fileURL: URL = ...
guard let fileInputStream = FileInputStream(with: fileURL) else {
        return
}
try fileInputStream.open()

let fileContent: Data = try fileInputStream.readToEnd()

// or read chunk by chunk
let tmpBufferLen = 1<<16 // 65KB buffer
var tmpBuffer = Array<UInt8>(repeating: 0, count: tmpBufferLen)
while fileInputStream.hasBytesAvailable {
        let readLen = fileInputStream.read(&tmpBuffer, maxLength: tmpBufferLen)
        // process tmpBuffer
}
        
inputFileStream.close()
```

## How to write to a file using `FileOutputStream`
```swift
let fileURL: URL = ...
guard let fileOutputStream = FileOutputStream(with: fileURL) else {
        return
}
try fileOutputStream.open()

// write string to a file      
try fileOutputStream.write("Hello world", ofEncoding: .utf8)

// or write data to a file
try fileOutputStream.write(Data([0,1,2,3]))

// or write some buffer to a file
let tmpBufferLen = 1<<16 // 65KB buffer
var tmpBuffer = Array<UInt8>(repeating: 0, count: tmpBufferLen)
try compressingStream.write(tmpBuffer, length: readLen)

try fileOutputStream.close()
```

## How to perform encrypting using `AesOutputStream`
```swift
...
let encryptingStream = AesOutputStream(writingTo: fileOutputStream,
                                                   key: key,
                                                   iv: iv)
try encryptingStream.open()
                    
try encryptingStream.write("Hello world", ofEncoding: .utf8)
try encryptingStream.close()
...
```

## How to perform decrypting using `AesInputStream`
```swift
...
let decryptingStream = AesInputStream(readingFrom: inputFileStream,
                                              key: key,
                                              iv: iv)
try decryptingStream.open()
        
let tmpBufferLen = 1<<16 // 65KB buffer
var tmpBuffer = Array<UInt8>(repeating: 0, count: tmpBufferLen)
while decryptingStream.hasBytesAvailable {
        let readLen = try decryptingStream.read(&tmpBuffer, maxLength: tmpBufferLen)
        // process buffer
}
        
decryptingStream.close()
...
```

## How to perform encrypting using `Salsa20OutputStream`
```swift
...
let encryptingStream = Salsa20OutputStream(writingTo: fileOutputStream,
                                                   key: key,
                                                   iv: iv)
try encryptingStream.open()
                    
try encryptingStream.write("Hello world", ofEncoding: .utf8)
try encryptingStream.close()
...
```

## How to perform decrypting using `Salsa20InputStream`
```swift
...
let decryptingStream = Salsa20InputStream(readingFrom: inputFileStream,
                                              key: key,
                                              iv: iv)
try decryptingStream.open()
        
let decryptedData = try decryptingStream.readToEnd()
        
decryptingStream.close()
...
```

## How to perform encrypting using `ChaCha20OutputStream`
```swift
...
let encryptingStream = ChaCha20OutputStream(writingTo: fileOutputStream,
                                                   key: key,
                                                   iv: iv)
try encryptingStream.open()
                    
try encryptingStream.write("Hello world", ofEncoding: .utf8)
try encryptingStream.close()
...
```

## How to perform decrypting using `ChaCha20InputStream`
```swift
...
let decryptingStream = ChaCha20InputStream(readingFrom: inputFileStream,
                                              key: key,
                                              iv: iv)
try decryptingStream.open()
        
let decryptedData = try decryptingStream.readToEnd()
        
decryptingStream.close()
...
```


## How to perform encrypting using `TwoFishOutputStream`
```swift
...
let encryptingStream = TwoFishOutputStream(writingTo: fileOutputStream,
                                                   key: key,
                                                   iv: iv)
try encryptingStream.open()
                    
try encryptingStream.write("Hello world", ofEncoding: .utf8)
try encryptingStream.close()
...
```

## How to perform decrypting using `TwoFishInputStream`
```swift
...
let decryptingStream = TwoFishInputStream(readingFrom: inputFileStream,
                                              key: key,
                                              iv: iv)
try decryptingStream.open()
        
let tmpBufferLen = 1<<16 // 65KB buffer
var tmpBuffer = Array<UInt8>(repeating: 0, count: tmpBufferLen)
while decryptingStream.hasBytesAvailable {
        let readLen = try decompressingStream.read(&tmpBuffer, maxLength: tmpBufferLen)
        // process or store bytes in `tmpBuffer`
}
        
decryptingStream.close()
...
```

# How to use it
For example it's possible to encrypt some data and simulteniously write the encrypted result to a file. 
```swift
let secureFileURL: URL = ...
let fileHandle = try! FileHandle(forWritingTo: secureFileURL)
let outputFileStream = FileOutputStream(with: fileHandle)
try outputFileStream.open()
        
let encryptingStream = Salsa20OutputStream(writingTo: outputFileStream,
                                            key: key,
                                            iv: iv)
try encryptingStream.open()
                
let tmpBufferLen = 1<<16 
var tmpBuffer = Array<UInt8>(repeating: 0, count: tmpBufferLen)
while inputFileStream.hasBytesAvailable {
  let readLen = inputFileStream.read(&tmpBuffer, maxLength: tmpBufferLen)
  try encryptingStream.write(tmpBuffer, length: readLen)
}
        
try encryptingStream.close()
try outputFileStream.close()
```

Another example demonstrate reading the encrypted file 
```swift
let inputFileStream = FileInputStream(withFileHandle: try! FileHandle(forReadingFrom: secureFileURL))
try inputFileStream.open()
        
let bufferingStream = BufferOutputStream()
try bufferingStream.open()
        
let decryptingStream = Salsa20InputStream(readingFrom: inputFileStream,
                                                  key: key,
                                                  iv: iv)
try decryptingStream.open()
        
let tmpBufferLen = 1<<16 // 65KB buffer
var tmpBuffer = Array<UInt8>(repeating: 0, count: tmpBufferLen)
while decryptingStream.hasBytesAvailable {
  let readLen = try decryptingStream.read(&tmpBuffer, maxLength: tmpBufferLen)
  try bufferingStream.write(tmpBuffer, length: readLen)
}
        
decryptingStream.close()
try bufferingStream.close()
inputFileStream.close()

```


### Sponsored by [KeePassium](https://github.com/keepassium)
