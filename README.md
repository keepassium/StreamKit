# StreamKit
This open-source Swift library offers a comprehensive collection of cryptographic algorithms. These ciphers can be structured into chains, facilitating the seamless flow of output from one cipher stream to another. This architecture enables concurrent tasks, such as encrypting data while writing the encrypted result to a file. Integrate "StreamKit" into your projects to efficiently utilize these cryptographic functionalities.


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
