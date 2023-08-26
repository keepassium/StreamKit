# Salsa20 Stream

Salsa20 is a stream cipher with symmetric secret key. It works on data blocks of size 64 bytes. Key length can be 16 or 32(recommended) bytes.</br>
Initialization vector(`iv`) is required of 8 bytes length.

## Create output(encrypting) stream
```swift
let encryptingStream = Salsa20OutputStream(writingTo: anotherOutputStream,
                                             key: key,
                                             iv: iv)
try encryptingStream.open()
try encryptingStream.write(buffer, length: len)
try encryptingStream.close()
```

## Create input(decrypting) stream
```swift
let decryptingStream = Salsa20InputStream(readingFrom: anotherInputStream,
                                                  key: key,
                                                  iv: iv)
try decryptingStream.open()
        
var decryptedBytes = [UInt8]()
while decryptingStream.hasBytesAvailable {
  let tmpBufferLen = 1<<16 // 65KB buffer
  var tmpBuffer = Array<UInt8>(repeating: 0, count: tmpBufferLen)
  let readLen = try decryptingStream.read(&tmpBuffer, maxLength: tmpBufferLen)
  decryptedBytes.append(contentsOf: tmpBuffer.prefix(readLen))
}

let decryptedData = Data(decryptedBytes)
```
