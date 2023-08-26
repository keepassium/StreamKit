    The `windowBits` parameter is the base two logarithm of the window size
(the size of the history buffer).  It should be in the range 8..15 for this
version of the library.  Larger values of this parameter result in better
compression at the expense of memory usage.

`windowBits` is used to control the compression level and the format of the 
    compressed data. According to the zlib manual, the windowBits parameter can 
    have the following values:
- negative value means that the compressed data will have no zlib header or 
    trailer, and will use the deflate format instead. windowBits can also 
    be -8..-15 for raw deflate.  In this case, -windowBits determines the window
    size.  deflate() will then generate raw deflate data with no zlib header or 
    trailer, and will not compute a check value. This is useful for some 
    applications that already have their own headers, such as PNG images.

- value between 8 and 15 means that the compressed data will have a zlib header 
    and trailer, and will use a fixed window size of 2^windowBits bytes. The 
    default value is 15, which corresponds to a window size of 32 KB.
    2^15 = 32KB
    2^14 = 16KB
    2^13 = 8KB
    2^12 = 4KB
    2^11 = 2KB
    2^10 = 1KB
    2^9 = 512B
    2^8 = 256B
    
     For the current implementation of deflate(), a windowBits value of 8 (a
   window size of 256 bytes) is not supported.  As a result, a request for 8
   will result in 9 (a 512-byte window).  In that case, providing 8 to
   inflateInit2() will result in an error when the zlib header with 9 is
   checked against the initialization of inflate().  The remedy is to not use 8
   with deflateInit2() with this initialization, or at least in that case use 9
   with inflateInit2().

- value between 16 and 31 means that the compressed data will have a gzip header 
    and trailer, and will use a variable window size of 2^(windowBits-16) bytes. 
    The maximum value is 31, which corresponds to a window size of 128 KB.

     windowBits can also be greater than 15 for optional gzip encoding.  Add
   16 to windowBits to write a simple gzip header and trailer around the
   compressed data instead of a zlib wrapper.  The gzip header will have no
   file name, no extra data, no comment, no modification time (set to zero), no
   header crc, and the operating system will be set to the appropriate value,
   if the operating system was determined at compile time.

     
