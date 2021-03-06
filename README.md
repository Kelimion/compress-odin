# Compress-Odin

Compress-Odin aims to implement several common compression algorithms and file formats using them in [Odin](https://github.com/odin-lang/Odin).

## Roadmap
Stage 1:
- OpenEXR reader, minus the patented Dreamworks compression method introduced in 3.0.
- Deflate compressor
- ZLIB 'writer', PNG writer
- Tar / Tar.gz packer and unpacker
- Quick optimization pass on stream handling and bit readers/writers
- ZIP unpacker for ZIP 2.0, covering 99.99% of all ZIP files
- ZIP writer
- Proper optimization pass on stage 1

Stage 2:
- Jpeg loader
- Jpeg writer
- TIFF reader and writer
- EXIF reader and writer
- LZ4 packer and unpacker
- BZIP2 / Tar.bz2 packer and unpacker
- Deflate64 packer and unpacker / ZIP 2.5+ format support.
- Optimization pass on stage 2

Stage 3:
- LWZ/GIF reader
- APNG... maybe?
- ZStd + Optimization pass

## Progress

ZLIB, DEFLATE and GZIP decompression are implemented and became Odin's `core:compress` standard packages.

PNG 1.2 support has been implemented and has become Odin's `core:image/png` standard package.

A test suite lives under `tests`. It tests `zlib`, `gzip` and runs the `png` implementation through 200+ tests against Willem van Schaik's PNG Suite.

ZIP:
- [x] Structures for ZIP 6.3.9 are defined and a basic file parser has been started.

OpenEXR:
- [x] OpenEXR can load uncompressed, ZIP and ZIPS compressed images.

Patented features added in v6.2 of the spec will not be implemented beyond defining their enums and structs,
so their use may be appropriately signalled to the end user, even if using their payloads remains outside the scope of this implementation.

## Specifications:
ZLIB is defined in [RFC 1950](https://tools.ietf.org/html/rfc1950).

DEFLATE is defined in [RFC 1951](https://tools.ietf.org/html/rfc1951).

GZIP    is defined in [RFC 1952](https://tools.ietf.org/html/rfc1952).

PNG     is defined in [RFC 2083](https://tools.ietf.org/html/rfc2083).

ZIP     is defined in [APPNOTES.TXT](https://pkware.cachefly.net/webdocs/casestudies/APPNOTE.TXT)

## Thanks:
Sean Barrett's [stb_image.h](https://github.com/nothings/stb) was helpful and provided a known-sane codebase to test against during development.

Willem van Schaik's [PNG Suite](http://www.schaik.com/pngsuite) is an excellent test corpus.
