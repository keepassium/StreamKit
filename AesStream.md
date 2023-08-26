# AES Streams

AES is a 128-bit block cipher. It supports key of lenght `128` bits, `192` bits or `256` bits.</br>
Initialization vector(`iv`), if present, must be `16` bytes (`128` bits) length.





## Create output(encrypting) stream
```swift
let encryptingStream = AesOutputStream(writingTo: anotherOuputStream,
                                        key: key,
                                        iv: iv)
try encryptingStream.open()
try encryptingStream.write(buffer, length: len)
try encryptingStream.close()
```

## Create input(decrypting) stream
```swift
let decryptingStream = AesInputStream(readingFrom: anotherInputStream,
                                        key: key,
                                        iv: iv)
try decryptingStream.open()
        
var decryptedBytes = Array<UInt8>()
while decryptingStream.hasBytesAvailable {
    let tmpBufferLen = 1<<16
    var tmpBuffer = Array<UInt8>(repeating: 0, count: tmpBufferLen)
    let readLen = try decryptingStream.read(&tmpBuffer, maxLength: tmpBufferLen)
    decryptedBytes.append(contentsOf: readBuffer.prefix(readLen))
}

let decryptedData = Data(decryptedBytes)
```

## Constructor accepts additional parameters
```swift
let aesOptions = AesOptions.PKCS7Padding // default
// let aesOptions = AesOptions.ECBMode
// let aesOptions = AesOptions.CBCMode

let encryptingStream = AesOutputStream(writingTo: anotherOuputStream,
                                        key: key,
                                        iv: iv,
                                        options: aesOptions,
                                        chunk: AesOutputStream.defaultChunkSize)

let decryptingStream = AesInputStream(readingFrom: anotherInputStream,
                                        key: key,
                                        iv: iv,
                                        options: aesOptions,
                                        chunk: AesInputStream.defaultChunkSize)
```

where:</br>
`AesOptions.ECBMode` - doesn't use `iv`. Due to obvious weaknesses, it is generally not recommended. The source data is 
divided into blocks as the length of the block of AES, 128. So the ECB mode 
needs to pad data until it is same as the length of the block. Then every block 
will be encrypted with the same key and same algorithm. So if we encrypt the 
same plaintext, we will get the same ciphertext. So there is a high risk in this 
mode. And the plaintext and ciphertext blocks are a one-to-one correspondence. 
Because the encryption/ decryption is independent, so we can encrypt/decrypt the 
data in parallel. And if a block of plaintext or ciphertext is broken, it won’t 
affect other blocks.</br>
`AesOptions.CBCMode` - uses `iv` and it must be the same length as the algorithm's block size. The total number of bytes does have to be aligned to the block size (`128` bit), 
otherwise `open()` will return `alignmentError`. If `iv` is not present, a NULL (all zeroes) `iv` will be used </br>
`AesOptions.PKCS7Padding` - the total number of bytes provided by all the calls to this function when 
 encrypting can be arbitrary (i.e., the total number of bytes does not have to 
 be block aligned). 

    
