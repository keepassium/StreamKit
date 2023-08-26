# TwoFish Streams

Twofish is a 128-bit block cipher that accepts a variable-length `key` up to 256 bits.</br>
`key` can be any length up to 256 bits</br>
`iv` must be 128 bits length
```swift
//let key: [UInt8] = Array(repeating: 0, count: 9) // for 72 bits length key
//let key: [UInt8] = Array(repeating: 0, count: 24) // for 192 bits length key
//let key: [UInt8] = Array(repeating: 0, count: 31) // for 248 bits length key
let key: [UInt8] = Array(repeating: 0, count: 32) // 256 bits length key
let iv: [UInt8] = Array(repeating: 0, count: 16) // 128 bits length initilization vector
```


## Create output(encrypting) stream
```swift
let encryptingStream = TwoFishOutputStream(writingTo: anotherOutputStream,
                                            key: key,
                                            iv: iv,
                                            chunkSize: chunkSize)
try encryptingStream.open()
try encryptingStream.write(buffer, length: len)
try encryptingStream.close()
```

## Create input(decrypting) stream
```swift
let decryptingStream = TwoFishInputStream(readingFrom: anotherInputStream,
                                          key: key,
                                          iv: iv,
                                          chunkSize: chunkSize)
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

# The information taken from
https://www.schneier.com/wp-content/uploads/2016/02/paper-twofish-paper.pdf
