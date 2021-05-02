# Compress-Odin

Compress-Odin aims to implement several common compression algorithms and file formats using them in [Odin](https://github.com/odin-lang/Odin).

## Immediate goals
It aims to provide the following and more:
- deflate (compress)
- inflate (unpack)
- gzip    (gzip stream handling)
- zip     (zip archive handling)
- png     (reading and writing png files)
- zlib    (reading and writing zlib streams)

## Progress

ZLIB, DEFLATE and GZIP decompression are implemented and became Odin's `core:compress` standard packages.

PNG 1.2 support has been implemented and has become Odin's `core:image/png` standard package.

ZIP:
- [x] Structures for ZIP 6.3.9 are defined and a basic file parser has been started.

Patented features added in v6.2 of the spec will not be implemented beyond defining their enums and structs,
so their use may be appropriately signalled to the end user, even if using their payloads remains outside the scope of this implementation.

## Near future goals
- Test suite
- Profiling and optimization of the current code, starting with ZLIB.

- TAR/TAR.gz unpacker
- ZIP unpacker
   - Allow `inflate` to be read from as a stream so compressed data need not be present in memory all at once.
- DEFLATE compression
- PNG, GZIP and ZIP writers using the above
- JPEG loading and saving
- LZ4 (de)compression
- ZStd (de)compression
- LZW decompression and GIF loading


## Specifications:
ZLIB is defined in [RFC 1950](https://tools.ietf.org/html/rfc1950).

DEFLATE is defined in [RFC 1951](https://tools.ietf.org/html/rfc1951).

GZIP    is defined in [RFC 1952](https://tools.ietf.org/html/rfc1952).

PNG     is defined in [RFC 2083](https://tools.ietf.org/html/rfc2083).

ZIP     is defined in [APPNOTES.TXT](https://pkware.cachefly.net/webdocs/casestudies/APPNOTE.TXT)

## Thanks:
Sean Barrett's [stb_image.h](https://github.com/nothings/stb) was helpful and provided a known-sane codebase to test against during development.

Willem van Schaik's [PNG Suite](http://www.schaik.com/pngsuite) is an excellent test corpus.