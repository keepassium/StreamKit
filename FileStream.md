# File Input Stream

`FileInputStream` is used for reading data from a file. It can be added to a ciphers chain
```swift
let inputFileStream = FileInputStream(with: try! FileHandle(forReadingFrom: originalFileURL))
try inputFileStream.open()
```
```swift
guard let inputFileStream = FileInputStream(with: originalFileURL) else {
  // file not exist
  return
}
try inputFileStream.open()
```
```swift
let tmpBufferLen = 1<<16 // 65KB buffer
var tmpBuffer = Array<UInt8>(repeating: 0, count: tmpBufferLen)
while inputFileStream.hasBytesAvailable {
  let readLen = inputFileStream.read(&tmpBuffer, maxLength: tmpBufferLen)
  try compressingStream.write(tmpBuffer, length: readLen)
}
```
