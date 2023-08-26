# ChaCha20 Stream

ChaCha20 is a stream cipher with symmetric secret key. It works on data blocks of size 64 bytes. Key length is 32 bytes.</br>
Initialization vector(`iv`) is required of 12 bytes length.</br>
The stream cipher algorithm performs 20 rounds of computations in its hash function.

## Enrypt data using ChaCha20 cipher and store to a file
```swift
let encryptingStream = ChaCha20OutputStream(writingTo: fileOutputStream,
                                            key: key,
                                            iv: iv)
try encryptingStream.open()
try encryptingStream.write(buffer, length: len)
try encryptingStream.close()
```

## Read a file chunk by chunk that is encrypted using ChaCha20 cipher 
```swift
let decryptionStream = ChaCha20InputStream(readingFrom: fileInputStream,
                                                   key: key,
                                                   iv: iv)
try decryptingStream.open()
        
var decryptedBytes = [UInt8]()
let tmpBufferLen = 1<<16 // 65KB buffer
var tmpBuffer = Array<UInt8>(repeating: 0, count: tmpBufferLen)
while decryptingStream.hasBytesAvailable {
  let readLen = try decryptingStream.read(&tmpBuffer, maxLength: tmpBufferLen)
  decryptedBytes.append(contentsOf: tmpBuffer.prefix(readLen))
}

let decryptedData = Data(decryptedBytes)
```
## Read entire file that is encrypted using ChaCha20 cipher
```swift
let decryptionStream = ChaCha20InputStream(readingFrom: fileInputStream,
                                                   key: key,
                                                   iv: iv)
try decryptingStream.open()
let decryptedData = decryptingStream.readToEnd()
```

