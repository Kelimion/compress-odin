package png

import "../common"
import "../zlib"
import "core:time"
import "core:strings"
import "core:bytes"
import "core:mem"

// import "core:fmt"

/*
	These are a few useful utility functions to work with PNG images.
*/

/*
	Cleanup of image-specific data. For cleanup of PNG chunk helpers, see png_helpers.odin.
	Those are named *_destroy, where * is the name of the helper.
*/

png_destroy :: proc(img: ^Image) {
	bytes.buffer_destroy(&img.pixels);

	/*
		We don't need to do anything for the individual chunks.
		They're allocated on the temp allocator, as is info.chunks

		See png_read_chunk.
	*/
	free(img);
}

/*
	Chunk helpers
*/

png_gamma :: proc(c: PNG_Chunk) -> f32 {
	assert(c.header.type == .gAMA);
	res := (^PNG_gAMA)(raw_data(c.data))^;
	when true {
		// Returns the wrong result on old backend
		// Fixed for -llvm-api
		return f32(res.gamma_100k) / 100_000.0;
	} else {
		return f32(u32(res.gamma_100k)) / 100_000.0;
	}
}

INCHES_PER_METER :: 1000.0 / 25.4;

png_phys :: proc(c: PNG_Chunk) -> PNG_pHYs {
	assert(c.header.type == .pHYs);
	res := (^PNG_pHYs)(raw_data(c.data))^;
	return res;
}

png_phys_to_dpi :: proc(p: PNG_pHYs) -> (x_dpi, y_dpi: f32) {
	return f32(p.ppu_x) / INCHES_PER_METER, f32(p.ppu_y) / INCHES_PER_METER;
}

png_time :: proc(c: PNG_Chunk) -> PNG_tIME {
	assert(c.header.type == .tIME);
	res := (^PNG_tIME)(raw_data(c.data))^;
	return res;
}

png_time_to_time :: proc(c: PNG_Chunk) -> (t: time.Time, ok: bool) {
	png_time := png_time(c);
	using png_time;

	return time.datetime_to_time(
		int(year), int(month), int(day),
		int(hour), int(minute), int(second));
}

png_text :: proc(c: PNG_Chunk) -> (res: PNG_Text, ok: bool) {
	 #partial switch c.header.type {
		case .tEXt:
			ok = true;

			fields := bytes.split(s=c.data, sep=[]u8{0}, allocator=context.temp_allocator);
			if len(fields) == 2 {
				res.keyword = strings.clone(string(fields[0]));
				res.text    = strings.clone(string(fields[1]));
			} else {
				ok = false;
			}
			return;
		case .zTXt:
			ok = true;

			fields := bytes.split_n(s=c.data, sep=[]u8{0}, n=3, allocator=context.temp_allocator);
			if len(fields) != 3 || len(fields[1]) != 0 {
				// Compression method must be 0=Deflate, which thanks to the split above turns
				// into an empty slice
				ok = false; return;
			}

			// Set up ZLIB context and decompress text payload.
			buf: bytes.Buffer;
			zlib_error := zlib.inflate_from_byte_array(&fields[2], &buf);
			defer bytes.buffer_destroy(&buf);
			if !is_kind(zlib_error, E_General, E_General.OK) {
				ok = false; return;
			}

			res.keyword = strings.clone(string(fields[0]));
			res.text = strings.clone(bytes.buffer_to_string(&buf));
			return;
		case .iTXt:
			ok = true;

			s := string(c.data);
			null := strings.index_byte(s, 0);
			if null == -1 {
				ok = false; return;
			}
			if len(c.data) < null + 4 {
				// At a minimum, including the \0 following the keyword, we require 5 more bytes.
				ok = false;	return;
			}
			res.keyword = strings.clone(string(c.data[:null]));
			rest := c.data[null+1:];

			compression_flag := rest[:1][0];
			if compression_flag > 1 {
				ok = false; return;
			}
			compression_method := rest[1:2][0];
			if compression_flag == 1 && compression_method > 0 {
				// Only Deflate is supported
				ok = false; return;
			}
			rest = rest[2:];

			// We now expect an optional language keyword and translated keyword, both followed by a \0
			null = strings.index_byte(string(rest), 0);
			if null == -1 {
				ok = false; return;
			}
			res.language = strings.clone(string(rest[:null]));
			rest = rest[null+1:];

			null = strings.index_byte(string(rest), 0);
			if null == -1 {
				ok = false; return;
			}
			res.keyword_localized = strings.clone(string(rest[:null]));
			rest = rest[null+1:];
			if compression_flag == 0 {
				res.text = strings.clone(string(rest));
			} else {
				// Set up ZLIB context and decompress text payload.
				buf: bytes.Buffer;
				zlib_error := zlib.inflate_from_byte_array(&rest, &buf);
				defer bytes.buffer_destroy(&buf);
				if !is_kind(zlib_error, E_General, E_General.OK) {
					
					ok = false; return;
				}

				res.text = strings.clone(bytes.buffer_to_string(&buf));
			}
			return;
		case:
			// PNG text helper called with an unrecognized chunk type.
			ok = false; return;

	}
}

png_text_destroy :: proc(text: PNG_Text) {
	delete(text.keyword);
	delete(text.keyword_localized);
	delete(text.language);
	delete(text.text);
}

png_iccp :: proc(c: PNG_Chunk) -> (res: PNG_iCCP, ok: bool) {
	ok = true;

	fields := bytes.split_n(s=c.data, sep=[]u8{0}, n=3, allocator=context.temp_allocator);

	if len(fields[0]) < 1 || len(fields[0]) > 79 {
		// Invalid profile name
		ok = false; return;
	}

	if len(fields[1]) != 0 {
		// Compression method should be a zero, which the split turned into an empty slice.
		ok = false; return;
	}

	// Set up ZLIB context and decompress iCCP payload
	buf: bytes.Buffer;
	zlib_error := zlib.inflate_from_byte_array(&fields[2], &buf);
	if !is_kind(zlib_error, E_General, E_General.OK) {
		bytes.buffer_destroy(&buf);
		ok = false; return;
	}

	res.name = strings.clone(string(fields[0]));
	res.profile = bytes.buffer_to_bytes(&buf);

	return;
}

png_iccp_destroy :: proc(i: PNG_iCCP) {
	delete(i.name);

	delete(i.profile);

}

png_srgb :: proc(c: PNG_Chunk) -> (res: PNG_sRGB, ok: bool) {
	ok = true;

	if c.header.type != .sRGB || len(c.data) != 1 {
		return {}, false;
	}

	res.intent = PNG_sRGB_Rendering_Intent(c.data[0]);
	if res.intent > max(PNG_sRGB_Rendering_Intent) {
		ok = false; return;
	}
	return;
}

png_plte :: proc(c: PNG_Chunk) -> (res: PNG_PLTE, ok: bool) {
	if c.header.type != .PLTE {
		return {}, false;
	}

	i := 0; j := 0; ok = true;
	for j < int(c.header.length) {
		res.entries[i] = {c.data[j], c.data[j+1], c.data[j+2]};
		i += 1; j += 3;
	}
	res.used = u16(i);
	return;
}

png_splt :: proc(c: PNG_Chunk) -> (res: PNG_sPLT, ok: bool) {
	if c.header.type != .sPLT {
		return {}, false;
	}
	ok = true;

	fields := bytes.split_n(s=c.data, sep=[]u8{0}, n=2, allocator=context.temp_allocator);
	if len(fields) != 2 {
		return {}, false;
	}

	res.depth = fields[1][0];
	if res.depth != 8 && res.depth != 16 {
		return {}, false;
	}

	data := fields[1][1:];
	count: int;

	if res.depth == 8 {
		if len(data) % 6 != 0 {
			return {}, false;
		}
		count = len(data) / 6;
		if count > 256 {
			return {}, false;
		}

		res.entries = mem.slice_data_cast([][4]u8, data);
	} else { // res.depth == 16
		if len(data) % 10 != 0 {
			return {}, false;
		}
		count = len(data) / 10;
		if count > 256 {
			return {}, false;
		}

		res.entries = mem.slice_data_cast([][4]u16, data);
	}

	res.name = strings.clone(string(fields[0]));
	res.used = u16(count);

	return;
}

png_splt_destroy :: proc(s: PNG_sPLT) {
	delete(s.name);
}

png_sbit :: proc(c: PNG_Chunk) -> (res: [4]u8, ok: bool) {
	/*
		Returns [4]u8 with the significant bits in each channel.
		A channel will contain zero if not applicable to the PNG color type.
	*/

	if len(c.data) < 1 || len(c.data) > 4 {
		ok = false; return;
	}
	ok = true;

	for i := 0; i < len(c.data); i += 1 {
		res[i] = c.data[i];
	}
	return;

}

png_hist :: proc(c: PNG_Chunk) -> (res: PNG_hIST, ok: bool) {
	if c.header.type != .hIST {
		return {}, false;
	}
	if c.header.length & 1 == 1 || c.header.length > 512 {
		// The entries are u16be, so the length must be even.
		// At most 256 entries must be present
		return {}, false;
	}

	ok = true;
	data := mem.slice_data_cast([]u16be, c.data);
	i := 0;
	for len(data) > 0 {
		// HIST entries are u16be, we unpack them to machine format
		res.entries[i] = u16(data[0]);
		i += 1; data = data[1:];
	}
	res.used = u16(i);
	return;
}

png_chrm :: proc(c: PNG_Chunk) -> (res: PNG_cHRM, ok: bool) {
	ok = true;
	if c.header.length != size_of(PNG_cHRM_Raw) {
		return {}, false;
	}
	chrm := (^PNG_cHRM_Raw)(raw_data(c.data))^;

	res.w.x = f32(chrm.w.x) / 100_000.0;
	res.w.y = f32(chrm.w.y) / 100_000.0;
	res.r.x = f32(chrm.r.x) / 100_000.0;
	res.r.y = f32(chrm.r.y) / 100_000.0;
	res.g.x = f32(chrm.g.x) / 100_000.0;
	res.g.y = f32(chrm.g.y) / 100_000.0;
	res.b.x = f32(chrm.b.x) / 100_000.0;
	res.b.y = f32(chrm.b.y) / 100_000.0;
	return;
}

png_exif :: proc(c: PNG_Chunk) -> (res: PNG_Exif, ok: bool) {

	ok = true;

	if len(c.data) < 4 {
		ok = false; return;
	}

	if c.data[0] == 'M' && c.data[1] == 'M' {
		res.byte_order = .big_endian;
		if c.data[2] != 0 || c.data[3] != 42 {
			ok = false; return;
		}
	} else if c.data[0] == 'I' && c.data[1] == 'I' {
		res.byte_order = .little_endian;
		if c.data[2] != 42 || c.data[3] != 0 {
			ok = false; return;
		}
	} else {
		ok = false; return;
	}

	res.data = c.data;
	return;
}

/*
	General helper functions
*/

compute_buffer_size :: common.compute_buffer_size;

/*
	PNG save helpers
*/

when false {

	make_png_chunk :: proc(c: any, t: PNG_Chunk_Type) -> (res: PNG_Chunk) {

		data: []u8;
		if v, ok := c.([]u8); ok {
			data = v;
		} else {
			data = mem.any_to_bytes(c);
		}

		res.header.length = u32be(len(data));
		res.header.type   = t;
		res.data   = data;

		// CRC the type
		crc    := hash.crc32(mem.any_to_bytes(res.header.type));
		// Extend the CRC with the data
		res.crc = u32be(hash.crc32(data, crc));
		return;
	}

	write_png_chunk :: proc(fd: os.Handle, chunk: PNG_Chunk) {
		c := chunk;
		// Write length + type
		os.write_ptr(fd, &c.header, 8);
		// Write data
		os.write_ptr(fd, mem.raw_data(c.data), int(c.header.length));
		// Write CRC32
		os.write_ptr(fd, &c.crc, 4);
	}

	write_image_as_png :: proc(filename: string, image: Image) -> (err: Error) {
		profiler.timed_proc();
		using image;
		using os;
		flags: int = O_WRONLY|O_CREATE|O_TRUNC;

		if len(image.pixels) == 0 || len(image.pixels) < image.width * image.height * int(image.channels) {
			return E_PNG.Invalid_Image_Dimensions;
		}

		mode: int = 0;
		when ODIN_OS == "linux" || ODIN_OS == "darwin" {
			// NOTE(justasd): 644 (owner read, write; group read; others read)
			mode = S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH;
		}

		fd, fderr := open(filename, flags, mode);
		if fderr != 0 {
			return E_General.Cannot_Open_File;
		}
		defer close(fd);

		png_magic := PNG_Signature;

		write_ptr(fd, &png_magic, 8);

		ihdr := PNG_IHDR{
			width              = u32be(width),
			height             = u32be(height),
			bit_depth          = depth,
			compression_method = 0,
			filter_method      = 0,
			interlace_method   = .None,
		};

		if channels == 1 {
			ihdr.color_type = PNG_Color_Type{};
		} else if channels == 2 {
			ihdr.color_type = PNG_Color_Type{.Alpha};
		} else if channels == 3 {
			ihdr.color_type = PNG_Color_Type{.Color};
		} else if channels == 4 {
			ihdr.color_type = PNG_Color_Type{.Color, .Alpha};
		} else {
			// Unhandled
			return E_PNG.Unknown_Color_Type;
		}

		h := make_png_chunk(ihdr, .IHDR);
		write_png_chunk(fd, h);

		bytes_needed := width * height * int(channels) + height;
		filter_bytes := mem.make_dynamic_array_len_cap([dynamic]u8, bytes_needed, bytes_needed, context.allocator);
		defer delete(filter_bytes);

		i := 0; j := 0;
		// Add a filter byte 0 per pixel row
		for y := 0; y < height; y += 1 {
			filter_bytes[j] = 0; j += 1;
			for x := 0; x < width; x += 1 {
				for z := 0; z < channels; z += 1 {
					filter_bytes[j+z] = image.pixels[i+z];
				}
				i += channels; j += channels;
			}
		}
		assert(j == bytes_needed);

		a: []u8 = filter_bytes[:];

		out_buf: ^[dynamic]u8;
		defer free(out_buf);

		ctx := zlib.ZLIB_Context{
			in_buf  = &a,
			out_buf = out_buf,
		};
		err = zlib.write_zlib_stream_from_memory(&ctx);

		b: []u8;
		if is_kind(err, E_General, E_General.OK) {
			b = ctx.out_buf[:];
		} else {
			return err;
		}

		idat := make_png_chunk(b, .IDAT);

		write_png_chunk(fd, idat);

		iend := make_png_chunk([]u8{}, .IEND);
		write_png_chunk(fd, iend);

		return E_General.OK;
	}
}

