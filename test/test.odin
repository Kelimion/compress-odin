package tests

import "core:testing"

import "core:compress"
import "core:compress/zlib"
import "core:compress/gzip"
import "core:image"
import "core:image/png"

import "core:bytes"
import "core:hash"
import "core:fmt"

import "core:mem"
import "core:os"

WRITE_PPM_ON_FAIL :: #config(WRITE_PPM_ON_FAIL, false);

expect  :: testing.expect;
OK      :: compress.General_Error.OK;

@test
zlib_test :: proc(t: ^testing.T) {
    ODIN_DEMO := []u8{
        120, 156, 101, 144,  77, 110, 131,  48,  16, 133, 215, 204,  41, 158,  44,
         69,  73,  32, 148, 182,  75,  35,  14, 208, 125,  47,  96, 185, 195, 143,
        130,  13,  50,  38,  81,  84, 101, 213,  75, 116, 215,  43, 246,   8,  53,
         82, 126,   8, 181, 188, 152, 153, 111, 222, 147, 159, 123, 165, 247, 170,
         98,  24, 213,  88, 162, 198, 244, 157, 243,  16, 186, 115,  44,  75, 227,
          5,  77, 115,  72, 137, 222, 117, 122, 179, 197,  39,  69, 161, 170, 156,
         50, 144,   5,  68, 130,   4,  49, 126, 127, 190, 191, 144,  34,  19,  57,
         69,  74, 235, 209, 140, 173, 242, 157, 155,  54, 158, 115, 162, 168,  12,
        181, 239, 246, 108,  17, 188, 174, 242, 224,  20,  13, 199, 198, 235, 250,
        194, 166, 129,  86,   3,  99, 157, 172,  37, 230,  62,  73, 129, 151, 252,
         70, 211,   5,  77,  31, 104, 188, 160, 113, 129, 215,  59, 205,  22,  52,
        123, 160,  83, 142, 255, 242,  89, 123,  93, 149, 200,  50, 188,  85,  54,
        252,  18, 248, 192, 238, 228, 235, 198,  86, 224, 118, 224, 176, 113, 166,
        112,  67, 106, 227, 159, 122, 215,  88,  95, 110, 196, 123, 205, 183, 224,
         98,  53,   8, 104, 213, 234, 201, 147,   7, 248, 192,  14, 170,  29,  25,
        171,  15,  18,  59, 138, 112,  63,  23, 205, 110, 254, 136, 109,  78, 231,
         63, 234, 138, 133, 204,
    };

    buf: bytes.Buffer;
    defer bytes.buffer_destroy(&buf);

    err := zlib.inflate(ODIN_DEMO, &buf);

    expect(t, is_kind(err, OK), "ZLIB failed to decompress ODIN_DEMO");
    s := bytes.buffer_to_string(&buf);

    expect(t, len(s) == 438, "ZLIB result has an unexpected length.");
}

@test
gzip_test :: proc(t: ^testing.T) {
    // Small GZIP file with fextra, fname and fcomment present.
    TEST: []u8 = {
        0x1f, 0x8b, 0x08, 0x1c, 0xcb, 0x3b, 0x3a, 0x5a,
        0x02, 0x03, 0x07, 0x00, 0x61, 0x62, 0x03, 0x00,
        0x63, 0x64, 0x65, 0x66, 0x69, 0x6c, 0x65, 0x6e,
        0x61, 0x6d, 0x65, 0x00, 0x54, 0x68, 0x69, 0x73,
        0x20, 0x69, 0x73, 0x20, 0x61, 0x20, 0x63, 0x6f,
        0x6d, 0x6d, 0x65, 0x6e, 0x74, 0x00, 0x2b, 0x48,
        0xac, 0xcc, 0xc9, 0x4f, 0x4c, 0x01, 0x00, 0x15,
        0x6a, 0x2c, 0x42, 0x07, 0x00, 0x00, 0x00,
    };

    buf: bytes.Buffer;
    defer bytes.buffer_destroy(&buf);

    err := gzip.load(TEST, &buf);

    expect(t, is_kind(err, OK), "GZIP failed to decompress TEST");
    s := bytes.buffer_to_string(&buf);

    expect(t, s == "payload", "GZIP result wasn't 'payload'");
}

PNG_Test :: struct {
    file:   string,
    tests:  []struct {
        options:        image.Options,
        expected_error: compress.Error,
        dims:           PNG_Dims,
        hash:           u32,
    },
}

Default     :: image.Options{};
Alpha_Add   :: image.Options{.alpha_add_if_missing};
Premul_Drop :: image.Options{.alpha_premultiply, .alpha_drop_if_present};
Blend_BG    :: image.Options{.blend_background};

PNG_Dims    :: struct{
    width:     int,
    height:    int,
    channels:  int,
    depth:     u8,
}

PNG_Tests := []PNG_Test{
    /*
        Basic format tests:
            http://www.schaik.com/pngsuite/pngsuite_bas_png.html
    */

    {
        "basn0g01", // Black and white.
        {
            {Default,     OK, {32, 32, 3,  8}, 0x_1d8b_1934},
            {Alpha_Add,   OK, {32, 32, 4,  8}, 0x_0da2_8714},
        },
    },
    {
        "basn0g02", // 2 bit (4 level) grayscale
        {
            {Default,     OK, {32, 32, 3,  8}, 0x_cce2_e274},
            {Alpha_Add,   OK, {32, 32, 4,  8}, 0x_2e3f_e285},
        },
    },
    {
        "basn0g04", // 4 bit (16 level) grayscale
        {
            {Default,     OK, {32, 32, 3,  8}, 0x_e6ed_c27d},
            {Alpha_Add,   OK, {32, 32, 4,  8}, 0x_8d0f_641b},
        },
    },
    {
        "basn0g08", // 8 bit (256 level) grayscale
        {
            {Default,     OK, {32, 32, 3,  8}, 0x_7e0a_8ab4},
            {Alpha_Add,   OK, {32, 32, 4,  8}, 0x_c395_683c},
        },
    },
    {
        "basn0g16", // 16 bit (64k level) grayscale
        {
            {Default,     OK, {32, 32, 3, 16}, 0x_d6ae_7df7},
            {Alpha_Add,   OK, {32, 32, 4, 16}, 0x_a9da_b1bf},
        },
    },
    {
        "basn2c08", // 3x8 bits rgb color
        {
            {Default,     OK, {32, 32, 3,  8}, 0x_7855_b9bf},
            {Alpha_Add,   OK, {32, 32, 4,  8}, 0x_2fb5_4036},
        },
    },
    {
        "basn2c16", // 3x16 bits rgb color
        {
            {Default,     OK, {32, 32, 3, 16}, 0x_8ec6_de79},
            {Alpha_Add,   OK, {32, 32, 4, 16}, 0x_0a7e_bae6},
        },
    },
    {
        "basn3p01", // 1 bit (2 color) paletted
        {
            {Default,     OK, {32, 32, 3,  8}, 0x_31ec_284b},
            {Alpha_Add,   OK, {32, 32, 4,  8}, 0x_4d84_31a4},
        },
    },
    {
        "basn3p02", // 2 bit (4 color) paletted
        {
            {Default,     OK, {32, 32, 3,  8}, 0x_279a_463a},
            {Alpha_Add,   OK, {32, 32, 4,  8}, 0x_e4db_b6bc},
        },
    },
    {
        "basn3p04", // 4 bit (16 color) paletted
        {
            {Default,     OK, {32, 32, 3,  8}, 0x_3a9e_038e},
            {Alpha_Add,   OK, {32, 32, 4,  8}, 0x_671f_880f},
        },
    },
    {
        "basn3p08", // 8 bit (256 color) paletted
        {
            {Default,     OK, {32, 32, 3,  8}, 0x_ff6e_2940},
            {Alpha_Add,   OK, {32, 32, 4,  8}, 0x_3952_8682},
        },
    },
    {
        "basn4a08", // 8 bit grayscale + 8 bit alpha-channel
        {
            {Default,     OK, {32, 32, 4,  8}, 0x_905d_5b60},
            {Premul_Drop, OK, {32, 32, 3,  8}, 0x_8c36_b12c},
        },
    },
    {
        "basn4a16", // 16 bit grayscale + 16 bit alpha-channel
        {
            {Default,     OK, {32, 32, 4, 16}, 0x_224f_48b2},
            {Premul_Drop, OK, {32, 32, 3, 16}, 0x_0276_254b},
        },
    },
    {
        "basn6a08", // 3x8 bits rgb color + 8 bit alpha-channel
        {
            {Default,     OK, {32, 32, 4,  8}, 0x_a74d_f32c},
            {Premul_Drop, OK, {32, 32, 3,  8}, 0x_3a5b_8b1c},
        },
    },
    {
        "basn6a16", // 3x16 bits rgb color + 16 bit alpha-channel
        {
            {Default,     OK, {32, 32, 4, 16}, 0x_087b_e531},
            {Premul_Drop, OK, {32, 32, 3, 16}, 0x_de9d_19fd},
        },
    },

    /*
        Interlaced format tests:
            http://www.schaik.com/pngsuite/pngsuite_int_png.html

        Note that these have the same hash values as the
        non-interlaced versionss above. It would be a failure if
        they didn't, but we need these tests to exercise Adam-7.

    */

    {
        "basi0g01", // Black and white.
        {
            {Default,     OK, {32, 32, 3,  8}, 0x_1d8b_1934},
            {Alpha_Add,   OK, {32, 32, 4,  8}, 0x_0da2_8714},
        },
    },
    {
        "basi0g02", // 2 bit (4 level) grayscale
        {
            {Default,     OK, {32, 32, 3,  8}, 0x_cce2_e274},
            {Alpha_Add,   OK, {32, 32, 4,  8}, 0x_2e3f_e285},
        },
    },
    {
        "basi0g04", // 4 bit (16 level) grayscale
        {
            {Default,     OK, {32, 32, 3,  8}, 0x_e6ed_c27d},
            {Alpha_Add,   OK, {32, 32, 4,  8}, 0x_8d0f_641b},
        },
    },
    {
        "basi0g08", // 8 bit (256 level) grayscale
        {
            {Default,     OK, {32, 32, 3,  8}, 0x_7e0a_8ab4},
            {Alpha_Add,   OK, {32, 32, 4,  8}, 0x_c395_683c},
        },
    },
    {
        "basi0g16", // 16 bit (64k level) grayscale
        {
            {Default,     OK, {32, 32, 3, 16}, 0x_d6ae_7df7},
            {Alpha_Add,   OK, {32, 32, 4, 16}, 0x_a9da_b1bf},
        },
    },
    {
        "basi2c08", // 3x8 bits rgb color
        {
            {Default,     OK, {32, 32, 3,  8}, 0x_7855_b9bf},
            {Alpha_Add,   OK, {32, 32, 4,  8}, 0x_2fb5_4036},
        },
    },
    {
        "basi2c16", // 3x16 bits rgb color
        {
            {Default,     OK, {32, 32, 3, 16}, 0x_8ec6_de79},
            {Alpha_Add,   OK, {32, 32, 4, 16}, 0x_0a7e_bae6},
        },
    },
    {
        "basi3p01", // 1 bit (2 color) paletted
        {
            {Default,     OK, {32, 32, 3,  8}, 0x_31ec_284b},
            {Alpha_Add,   OK, {32, 32, 4,  8}, 0x_4d84_31a4},
        },
    },
    {
        "basi3p02", // 2 bit (4 color) paletted
        {
            {Default,     OK, {32, 32, 3,  8}, 0x_279a_463a},
            {Alpha_Add,   OK, {32, 32, 4,  8}, 0x_e4db_b6bc},
        },
    },
    {
        "basi3p04", // 4 bit (16 color) paletted
        {
            {Default,     OK, {32, 32, 3,  8}, 0x_3a9e_038e},
            {Alpha_Add,   OK, {32, 32, 4,  8}, 0x_671f_880f},
        },
    },
    {
        "basi3p08", // 8 bit (256 color) paletted
        {
            {Default,     OK, {32, 32, 3,  8}, 0x_ff6e_2940},
            {Alpha_Add,   OK, {32, 32, 4,  8}, 0x_3952_8682},
        },
    },
    {
        "basi4a08", // 8 bit grayscale + 8 bit alpha-channel
        {
            {Default,     OK, {32, 32, 4,  8}, 0x_905d_5b60},
            {Premul_Drop, OK, {32, 32, 3,  8}, 0x_8c36_b12c},
        },
    },
    {
        "basi4a16", // 16 bit grayscale + 16 bit alpha-channel
        {
            {Default,     OK, {32, 32, 4, 16}, 0x_224f_48b2},
            {Premul_Drop, OK, {32, 32, 3, 16}, 0x_0276_254b},
        },
    },
    {
        "basi6a08", // 3x8 bits rgb color + 8 bit alpha-channel
        {
            {Default,     OK, {32, 32, 4,  8}, 0x_a74d_f32c},
            {Premul_Drop, OK, {32, 32, 3,  8}, 0x_3a5b_8b1c},
        },
    },
    {
        "basi6a16", // 3x16 bits rgb color + 16 bit alpha-channel
        {
            {Default,     OK, {32, 32, 4, 16}, 0x_087b_e531},
            {Premul_Drop, OK, {32, 32, 3, 16}, 0x_de9d_19fd},
        },
    },

    /*
        PngSuite - Odd sizes / PNG-files:
            http://www.schaik.com/pngsuite/pngsuite_siz_png.html

        This tests curious sizes with and without interlacing.
    */

    {
        "s01i3p01", // 1x1 paletted file, interlaced
        {
            {Default,     OK, { 1,  1, 3,  8}, 0x_d243_369f},
        },
    },
    {
        "s01n3p01", // 1x1 paletted file, no interlacing
        {
            {Default,     OK, { 1,  1, 3,  8}, 0x_d243_369f},
        },
    },

// "s02i3p01", // 2x2 paletted file, interlaced
// "s02n3p01", // 2x2 paletted file, no interlacing
// "s03i3p01", // 3x3 paletted file, interlaced
// "s03n3p01", // 3x3 paletted file, no interlacing
// "s04i3p01", // 4x4 paletted file, interlaced
// "s04n3p01", // 4x4 paletted file, no interlacing
// "s05i3p02", // 5x5 paletted file, interlaced
// "s05n3p02", // 5x5 paletted file, no interlacing
// "s06i3p02", // 6x6 paletted file, interlaced
// "s06n3p02", // 6x6 paletted file, no interlacing
// "s07i3p02", // 7x7 paletted file, interlaced
// "s07n3p02", // 7x7 paletted file, no interlacing
// "s08i3p02", // 8x8 paletted file, interlaced
// "s08n3p02", // 8x8 paletted file, no interlacing
// "s09i3p02", // 9x9 paletted file, interlaced
// "s09n3p02", // 9x9 paletted file, no interlacing
// "s32i3p04", // 32x32 paletted file, interlaced
// "s32n3p04", // 32x32 paletted file, no interlacing
// "s33i3p04", // 33x33 paletted file, interlaced
// "s33n3p04", // 33x33 paletted file, no interlacing
// "s34i3p04", // 34x34 paletted file, interlaced
// "s34n3p04", // 34x34 paletted file, no interlacing
// "s35i3p04", // 35x35 paletted file, interlaced
// "s35n3p04", // 35x35 paletted file, no interlacing
// "s36i3p04", // 36x36 paletted file, interlaced
// "s36n3p04", // 36x36 paletted file, no interlacing
// "s37i3p04", // 37x37 paletted file, interlaced
// "s37n3p04", // 37x37 paletted file, no interlacing
// "s38i3p04", // 38x38 paletted file, interlaced
// "s38n3p04", // 38x38 paletted file, no interlacing
// "s39i3p04", // 39x39 paletted file, interlaced
// "s39n3p04", // 39x39 paletted file, no interlacing
// "s40i3p04", // 40x40 paletted file, interlaced
// "s40n3p04", // 40x40 paletted file, no interlacing



};

is_kind :: proc(u: $U, x: $V) -> bool where U == compress.Error {
    v, ok := u.(V);
    return ok && v == x;
}

@test
png_test :: proc(t: ^testing.T) {

    for file in PNG_Tests {
        test_suite_path := "PNG test suite";

        img:      ^image.Image;
        err:       compress.Error;

        test_file := fmt.tprintf("%v/%v.png", test_suite_path, file.file);

        count := 0;
        for test in file.tests {
            img, err := png.load(test_file, test.options);

            error  := fmt.tprintf("%v failed with %v.", file.file, err);
            passed := is_kind(err, OK);

            if passed {
                // No point in running the other tests if it didn't load.
                pixels := bytes.buffer_to_bytes(&img.pixels);

                dims   := PNG_Dims{img.width, img.height, img.channels, img.depth};
                error  = fmt.tprintf("%v has %v, expected: %v.", file.file, dims, test.dims);
                expect(t, test.dims == dims, error);

                passed &= test.dims == dims;

                hash   := hash.crc32(pixels);
                error  = fmt.tprintf("%v hash is %08x, expected %08x.", file.file, hash, test.hash);
                expect(t, test.hash == hash, error);

                passed &= test.hash == hash;
            }

            count += 1;
            if WRITE_PPM_ON_FAIL && !passed {
                testing.logf(t, "Test failed, writing ppm/%v-%v.ppm to help debug.\n", file.file, count);
                output := fmt.tprintf("ppm/%v-%v.ppm", file.file, count);
                write_image_as_ppm(output, img);
            }

            png.destroy(img);
        }
    }
}


// Crappy PPM writer used during testing. Don't use in production.
write_image_as_ppm :: proc(filename: string, image: ^image.Image) -> (success: bool) {

    _bg :: proc(bg: Maybe([3]u16), x, y: int, high := true) -> (res: [3]u16) {
        if v, ok := bg.?; ok {
            res = v;
        } else {
            if high {
                l := u16(30 * 256 + 30);

                if (x & 4 == 0) ~ (y & 4 == 0) {
                    res = [3]u16{l, 0, l};
                } else {
                    res = [3]u16{l >> 1, 0, l >> 1};
                }
            } else {
                if (x & 4 == 0) ~ (y & 4 == 0) {
                    res = [3]u16{30, 30, 30};
                } else {
                    res = [3]u16{15, 15, 15};
                }
            }
        }
        return;
    }

    // profiler.timed_proc();
    using image;
    using os;

    flags: int = O_WRONLY|O_CREATE|O_TRUNC;

    img := image;

    // PBM 16-bit images are big endian
    when ODIN_ENDIAN == "little" {
        if img.depth == 16 {
            // The pixel components are in Big Endian. Let's byteswap back.
            input  := mem.slice_data_cast([]u16,   img.pixels.buf[:]);
            output := mem.slice_data_cast([]u16be, img.pixels.buf[:]);
            #no_bounds_check for v, i in input {
                output[i] = u16be(v);
            }
        }
    }

    pix := bytes.buffer_to_bytes(&img.pixels);

    if len(pix) == 0 || len(pix) < image.width * image.height * int(image.channels) {
        return false;
    }

    mode: int = 0;
    when ODIN_OS == "linux" || ODIN_OS == "darwin" {
        // NOTE(justasd): 644 (owner read, write; group read; others read)
        mode = S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH;
    }

    fd, err := open(filename, flags, mode);
    if err != 0 {
        return false;
    }
    defer close(fd);

    write_string(fd,
        fmt.tprintf("P6\n%v %v\n%v\n", width, height, (1 << depth -1)),
    );

    if channels == 3 {
        // We don't handle transparency here...
        write_ptr(fd, raw_data(pix), len(pix));
    } else {
        bpp := depth == 16 ? 2 : 1;
        bytes_needed := width * height * 3 * bpp;

        op := bytes.Buffer{};
        bytes.buffer_init_allocator(&op, bytes_needed, bytes_needed);
        defer bytes.buffer_destroy(&op);

        if channels == 1 {
            if depth == 16 {
                assert(len(pix) == width * height * 2);
                p16 := mem.slice_data_cast([]u16, pix);
                o16 := mem.slice_data_cast([]u16, op.buf[:]);
                #no_bounds_check for len(p16) != 0 {
                    r := u16(p16[0]);
                    o16[0] = r;
                    o16[1] = r;
                    o16[2] = r;
                    p16 = p16[1:];
                    o16 = o16[3:];
                }
            } else {
                o := 0;
                for i := 0; i < len(pix); i += 1 {
                    r := pix[i];
                    op.buf[o  ] = r;
                    op.buf[o+1] = r;
                    op.buf[o+2] = r;
                    o += 3;
                }
            }
            write_ptr(fd, raw_data(op.buf), len(op.buf));
        } else if channels == 2 {
            if depth == 16 {
                p16 := mem.slice_data_cast([]u16, pix);
                o16 := mem.slice_data_cast([]u16, op.buf[:]);

                bgcol := img.background;

                #no_bounds_check for len(p16) != 0 {
                    r  := f64(u16(p16[0]));
                    bg:   f64;
                    if bgcol != nil {
                        v := bgcol.([3]u16)[0];
                        bg = f64(v);
                    }
                    a  := f64(u16(p16[1])) / 65535.0;
                    l  := (a * r) + (1 - a) * bg;

                    o16[0] = u16(l);
                    o16[1] = u16(l);
                    o16[2] = u16(l);

                    p16 = p16[2:];
                    o16 = o16[3:];
                }
            } else {
                o := 0;
                for i := 0; i < len(pix); i += 2 {
                    r := pix[i]; a := pix[i+1]; a1 := f32(a) / 255.0;
                    c := u8(f32(r) * a1);
                    op.buf[o  ] = c;
                    op.buf[o+1] = c;
                    op.buf[o+2] = c;
                    o += 3;
                }
            }
            write_ptr(fd, raw_data(op.buf), len(op.buf));
        } else if channels == 4 {
            if depth == 16 {
                p16 := mem.slice_data_cast([]u16be, pix);
                o16 := mem.slice_data_cast([]u16be, op.buf[:]);

                #no_bounds_check for len(p16) != 0 {

                    bg := _bg(img.background, 0, 0);
                    r     := f32(p16[0]);
                    g     := f32(p16[1]);
                    b     := f32(p16[2]);
                    a     := f32(p16[3]) / 65535.0;

                    lr  := (a * r) + (1 - a) * f32(bg[0]);
                    lg  := (a * g) + (1 - a) * f32(bg[1]);
                    lb  := (a * b) + (1 - a) * f32(bg[2]);

                    o16[0] = u16be(lr);
                    o16[1] = u16be(lg);
                    o16[2] = u16be(lb);

                    p16 = p16[4:];
                    o16 = o16[3:];
                }
            } else {
                o := 0;

                for i := 0; i < len(pix); i += 4 {

                    x := (i / 4)  % width;
                    y := i / width / 4;

                    _b := _bg(img.background, x, y, false);
                    bgcol := [3]u8{u8(_b[0]), u8(_b[1]), u8(_b[2])};

                    r := f32(pix[i]);
                    g := f32(pix[i+1]);
                    b := f32(pix[i+2]);
                    a := f32(pix[i+3]) / 255.0;

                    lr := u8(f32(r) * a + (1 - a) * f32(bgcol[0]));
                    lg := u8(f32(g) * a + (1 - a) * f32(bgcol[1]));
                    lb := u8(f32(b) * a + (1 - a) * f32(bgcol[2]));
                    op.buf[o  ] = lr;
                    op.buf[o+1] = lg;
                    op.buf[o+2] = lb;
                    o += 3;
                }
            }
            write_ptr(fd, raw_data(op.buf), len(op.buf));
        } else {
            return false;
        }
    }
    return true;
}
