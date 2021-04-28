//+ignore
package compress_example_png

import "../../common"
import "../../png"
import "core:bytes"

import "core:fmt"

// For PPM writer
import "core:mem"
import "core:os"

Image_Option  :: common.Image_Option;
Image_Options :: common.Image_Options;
Image         :: common.Image;

Error     :: common.Compress_Error;
E_General :: common.General_Error;
E_PNG     :: common.PNG_Error;
E_Deflate :: common.Deflate_Error;
is_kind   :: common.is_kind;

main :: proc() {
	file: string;

	options: Image_Options;
	err:     Error;
	img:     ^Image;

	file = "logo-slim";

	// Filter tests
		// Filter: None
	// file = "f00n0g08";
	// file = "f00n2c08";
	// // Filter: Sub
	// file = "f01n0g08";
	// file = "f01n2c08";
	// // Filter: Up
	// file = "f02n0g08";
	// file = "f02n2c08";
	// // Filter: Average
	// file = "f03n0g08";
	// file = "f03n2c08";
	// // Filter: Paeth
	// file = "f04n0g08";
	// file = "f04n2c08";

	// // 1, 2 and 4 bit grayscale
	// file = "basn0g01";
	// file = "basn0g02";
	// file = "basn0g04";

	// // 1, 2 and 4 bit paletted
	// file = "basn3p01";
	// file = "basn3p02";
	// file = "basn3p04";

	// // 8 + 16 bit + alpha
	// file = "basn4a08"; // Grayscale + Alpha 8-bit
	// file = "basn6a08"; // Color + Alpha 8-bit

	// file = "basn4a16"; // Grayscale + Alpha 16-bit
	// file = "basn6a16"; // Color + Alpha 16-bit

	// // Interlace tests

	// file = "basi0g01";
	// file = "basi0g02";
	// file = "basi0g04";
	// file = "basi0g08";
	// file = "basi0g16";
	// file = "basi2c08";
	// file = "basn2c16";

	// file = "basi3p01";
	// file = "basi3p02";
	// file = "basi3p04";
	// file = "basi3p08";
	// file = "basi4a08";
	// file = "basi4a16";
	// file = "basi6a08";
	// file = "basi6a16";

	// Background tests
	// file = "bgai4a08";
	// file = "bgai4a16";
	// file = "bgan6a08";
	// file = "bgan6a16";
	// file = "bgbn4a08";
	// file = "bggn4a16";
	// file = "bgwn6a08";
	// file = "bgyn6a16";

	// Transparency chunk
	// file = "tbbn0g04";
	// file = "tbbn2c16";
	// file = "tbbn3p08";
	// file = "tbgn2c16";
	// file = "tbgn3p08";
	// file = "tbrn2c08";
	// file = "tbwn0g16";
	// file = "tbwn3p08";
	// file = "tbyn3p08";
	// file = "tp0n0g08";
	// file = "tp0n2c08";
	// file = "tp0n3p08";
	// file = "tp1n3p08";
	// file = "tm3n3p02";

	// Curious dimensions
	// file = "s01i3p01"; // 1x1 paletted file, interlaced
	// file = "s01n3p01"; // 1x1 paletted file, no interlacing
	// file = "s02i3p01"; // 2x2 paletted file, interlaced
	// file = "s02n3p01"; // 2x2 paletted file, no interlacing
	// file = "s03i3p01"; // 3x3 paletted file, interlaced
	// file = "s03n3p01"; // 3x3 paletted file, no interlacing
	// file = "s04i3p01"; // 4x4 paletted file, interlaced
	// file = "s04n3p01"; // 4x4 paletted file, no interlacing
	// file = "s05i3p02"; // 5x5 paletted file, interlaced
	// file = "s05n3p02"; // 5x5 paletted file, no interlacing
	// file = "s06i3p02"; // 6x6 paletted file, interlaced
	// file = "s06n3p02"; // 6x6 paletted file, no interlacing
	// file = "s07i3p02"; // 7x7 paletted file, interlaced
	// file = "s07n3p02"; // 7x7 paletted file, no interlacing
	// file = "s08i3p02"; // 8x8 paletted file, interlaced
	// file = "s08n3p02"; // 8x8 paletted file, no interlacing
	// file = "s09i3p02"; // 9x9 paletted file, interlaced
	// file = "s09n3p02"; // 9x9 paletted file, no interlacing
	// file = "s32i3p04"; // 32x32 paletted file, interlaced
	// file = "s32n3p04"; // 32x32 paletted file, no interlacing
	// file = "s33i3p04"; // 33x33 paletted file, interlaced
	// file = "s33n3p04"; // 33x33 paletted file, no interlacing
	// file = "s34i3p04"; // 34x34 paletted file, interlaced
	// file = "s34n3p04"; // 34x34 paletted file, no interlacing
	// file = "s35i3p04"; // 35x35 paletted file, interlaced
	// file = "s35n3p04"; // 35x35 paletted file, no interlacing
	// file = "s36i3p04"; // 36x36 paletted file, interlaced
	// file = "s36n3p04"; // 36x36 paletted file, no interlacing
	// file = "s37i3p04"; // 37x37 paletted file, interlaced
	// file = "s37n3p04"; // 37x37 paletted file, no interlacing
	// file = "s38i3p04"; // 38x38 paletted file, interlaced
	// file = "s38n3p04"; // 38x38 paletted file, no interlacing
	// file = "s39i3p04"; // 39x39 paletted file, interlaced
	// file = "s39n3p04"; // 39x39 paletted file, no interlacing
	// file = "s40i3p04"; // 40x40 paletted file, interlaced
	// file = "s40n3p04"; // 40x40 paletted file, no interlacing


	// Ancillary chunks:
	// file = "ccwn2c08"; // Chroma
	// file = "ch1n3p04"; // Histogram
	// file = "ch2n3p08"; // Histogram
	// file = "ct1n0g04"; // tEXt
	// file = "ctzn0g04"; // zTXt
	// file = "ctjn0g04"; // iTXt
	// file = "cm0n0g04"; // Time
	// file = "cm7n0g04"; // Time
	// file = "cm9n0g04"; // Time
	// file = "exif2c08"; // EXIF

	// Suggested palette:
	// file = "pp0n2c16"; // six-cube palette-chunk in true-color image
	// file = "pp0n6a08"; // six-cube palette-chunk in true-color+alpha image
	// file = "ps1n0g08"; // six-cube suggested palette (1 byte) in grayscale image
	// file = "ps1n2c16"; // six-cube suggested palette (1 byte) in true-color image
	// file = "ps2n0g08"; // six-cube suggested palette (2 bytes) in grayscale image
	// file = "ps2n2c16"; // six-cube suggested palette (2 bytes) in true-color image

	// sBIT
	file = "cs3n2c16"; // color, 13 significant bits
	// file = "cs3n3p08"; // paletted, 3 significant bits
	// file = "cs5n2c08"; // color, 5 significant bits
	// file = "cs5n3p08"; // paletted, 5 significant bits
	// file = "cs8n2c08"; // color, 8 significant bits (reference)
	// file = "cs8n3p08"; // paletted, 8 significant bits (reference)

	options = png.Image_Options{.return_metadata, .alpha_drop_if_present, .alpha_premultiply};

	file = fmt.tprintf("../../test/%v.png", file);

	img, err = png.load_png(file, options);
	defer {
		// Make a utility function to free an image, including chunks and pixels.
		if png.is_kind(err, png.E_General, png.E_General.OK) {
			bytes.buffer_destroy(&img.pixels);
			free(img);
		}
	}

	if !png.is_kind(err, png.E_General, png.E_General.OK) {
		fmt.printf("Trying to read PNG file %v returned %v\n", file, err);
	} else {
		v:  png.PNG_Info;
		ok: bool;

		fmt.printf("Image: %vx%vx%v, %v-bit.\n", img.width, img.height, img.channels, img.depth);

		if v, ok = img.sidecar.(png.PNG_Info); ok {
			// We don't need to free the contents of [dynamic]PNG_Chunk itself.
			// Unlike the image data, they're allocated using the temp allocator.
			defer delete(v.chunks);
			// Handle ancillary chunks as you wish.
			// We provide helper functions for a few types.
			for c in v.chunks {
				#partial switch (c.header.type) {
					case .tIME:
						t, _ := png.png_time_to_time(c);
						fmt.printf("[tIME]: %v\n", t);
					case .gAMA:
						fmt.printf("[gAMA]: %v\n", png.png_gamma(c));
					case .pHYs:
						phys := png.png_phys(c);
						if phys.unit == .Meter {
							xm    := f32(img.width)  / f32(phys.ppu_x);
							ym    := f32(img.height) / f32(phys.ppu_y);
							dpi_x, dpi_y := png.png_phys_to_dpi(phys);
							fmt.printf("[pHYs] Image resolution is %v x %v pixels per meter.\n", phys.ppu_x, phys.ppu_y);
							fmt.printf("[pHYs] Image resolution is %v x %v DPI.\n", dpi_x, dpi_y);
							fmt.printf("[pHYs] Image dimensions are %v x %v meters.\n", xm, ym);
						} else {
							fmt.printf("[pHYs] x: %v, y: %v pixels per unknown unit.\n", phys.ppu_x, phys.ppu_y);
						}
					case .iTXt, .zTXt, .tEXt:
						res, ok_text := png.png_text(c);
						if ok_text {
							if c.header.type == .iTXt {
								fmt.printf("[iTXt] %v (%v:%v): %v\n", res.keyword, res.language, res.keyword_localized, res.text);
							} else {
								fmt.printf("[tEXt/zTXt] %v: %v\n", res.keyword, res.text);
							}
						}
						defer png.png_text_destroy(res);
					case .bKGD:
						fmt.printf("[bKGD] %v\n", img.background);
					case .eXIf:
						res, ok_exif := png.png_exif(c);
						if ok_exif {
							/*
								Other than checking the signature and byte order, we don't handle Exif data.
								If you wish to interpret it, pass it to an Exif parser.
							*/
							fmt.printf("[eXIf] %v\n", res);
						}
					case .PLTE:
						plte, plte_ok := png.png_plte(c);
						if plte_ok {
							fmt.printf("[PLTE] %v\n", plte);
						} else {
							fmt.printf("[PLTE] Error\n");
						}
					case .hIST:
						res, ok_hist := png.png_hist(c);
						if ok_hist {
							fmt.printf("[hIST] %v\n", res);
						}
					case .cHRM:
						res, ok_chrm := png.png_chrm(c);
						if ok_chrm {
							fmt.printf("[cHRM] %v\n", res);
						}
					case .sPLT:
						res, ok_splt := png.png_splt(c);
						if ok_splt {
							fmt.printf("[sPLT] %v\n", res);
						}
						png.png_splt_destroy(res);
					case .sBIT:
						if res, ok_sbit := png.png_sbit(c); ok_sbit {
							fmt.printf("[sBIT] %v\n", res);
						}
					case:
						type := c.header.type;
						name := png.chunk_type_to_name(&type);
						fmt.printf("[%v]: %v\n", name, c.data);
				}
			}
		}
	}

	if is_kind(err, E_General, E_General.OK) && .do_not_decompress_image not_in options && .info not_in options {
		if ok := write_image_as_ppm("out.ppm", img); ok {
			fmt.println("Saved decoded image.");
		} else {
			fmt.println("Error saving out.ppm.");
			fmt.println(img);
		}
	}
}

// Crappy PPM writer used during testing. Don't use in production.
write_image_as_ppm :: proc(filename: string, image: ^Image) -> (success: bool) {

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