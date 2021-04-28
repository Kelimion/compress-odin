package gzip

import "../zlib"
import "../common"
import "core:os"
import "core:io"
import "core:bytes"
import "core:hash"

/*

	This package implements support for the GZIP file format v4.3,
	as specified in RFC 1952.

	It is implemented in such a way that it lends itself naturally
	to be the input to a complementary TAR implementation.

*/

GZIP_Magic :: enum u16le {
	GZIP = 0x8b << 8 | 0x1f,
}

GZIP_Header :: struct #packed {
	magic: GZIP_Magic,
	compression_method: GZIP_Compression,
	flags: GZIP_Header_Flags,
	modification_time: u32le,
	xfl: GZIP_Compression_Flags,
	os: GZIP_OS,
}
#assert(size_of(GZIP_Header) == 10);

GZIP_Header_Flag :: enum u8 {
	// Order is important
	text       = 0,
	header_crc = 1,
	extra      = 2,
	name       = 3,
	comment    = 4,
	reserved_1 = 5,
	reserved_2 = 6,
	reserved_3 = 7,
}
GZIP_Header_Flags :: distinct bit_set[GZIP_Header_Flag; u8];

GZIP_OS :: enum u8 {
	FAT = 0,
	Amiga = 1,
	VMS = 2,
	Unix = 3,
	VM_CMS = 4,
	Atari_TOS = 5,
	HPFS = 6,
	Macintosh = 7,
	Z_System = 8,
	CP_M = 9,
	TOPS_20 = 10,
	NTFS = 11,
	QDOS = 12,
	Acorn_RISCOS = 13,
	_Unknown = 14,
	Unknown = 255,
}
GZIP_OS_Name :: #partial [GZIP_OS]string{
	.FAT   = "FAT",
	.Amiga = "Amiga",
	.VMS   = "VMS/OpenVMS",
	.Unix = "Unix",
	.VM_CMS = "VM/CMS",
	.Atari_TOS = "Atari TOS",
	.HPFS = "HPFS",
	.Macintosh = "Macintosh",
	.Z_System = "Z-System",
	.CP_M = "CP/M",
	.TOPS_20 = "TOPS-20",
	.NTFS = "NTFS",
	.QDOS = "QDOS",
	.Acorn_RISCOS = "Acorn RISCOS",
	.Unknown = "Unknown",
};

GZIP_Compression :: enum u8 {
	DEFLATE = 8,
}

GZIP_Compression_Flags :: enum u8 {
	Maximum_Compression = 2,
	Fastest_Compression = 4,
}

Error     :: common.Compress_Error;
E_General :: common.General_Error;
E_GZIP    :: common.GZIP_Error;
E_ZLIB    :: common.ZLIB_Error;
E_Deflate :: common.Deflate_Error;
is_kind   :: common.is_kind;


// Small GZIP file with fextra, fname and fcomment present.
@private
GZIP_TEST: []u8 = {
	0x1f, 0x8b, 0x08, 0x1c, 0xcb, 0x3b, 0x3a, 0x5a,
	0x02, 0x03, 0x07, 0x00, 0x61, 0x62, 0x03, 0x00,
	0x63, 0x64, 0x65, 0x66, 0x69, 0x6c, 0x65, 0x6e,
	0x61, 0x6d, 0x65, 0x00, 0x54, 0x68, 0x69, 0x73,
	0x20, 0x69, 0x73, 0x20, 0x61, 0x20, 0x63, 0x6f,
	0x6d, 0x6d, 0x65, 0x6e, 0x74, 0x00, 0x2b, 0x48,
	0xac, 0xcc, 0xc9, 0x4f, 0x4c, 0x01, 0x00, 0x15,
	0x6a, 0x2c, 0x42, 0x07, 0x00, 0x00, 0x00,
};

load_gzip_from_slice :: proc(slice: ^[]u8, buf: ^bytes.Buffer, allocator := context.allocator) -> (err: Error) {

	r := bytes.Reader{};
	bytes.reader_init(&r, slice^);
	stream := bytes.reader_to_stream(&r);

	err = load_gzip_from_stream(&stream, buf, allocator);

	return err;
}

load_gzip_from_file :: proc(filename: string, buf: ^bytes.Buffer, allocator := context.allocator) -> (err: Error) {
	data, ok := os.read_entire_file(filename, context.temp_allocator);
	if ok {
		err = load_gzip_from_slice(&data, buf, allocator);
		return;
	} else {
		return E_General.File_Not_Found;
	}
}

load_gzip_from_stream :: proc(stream: ^io.Stream, buf: ^bytes.Buffer, allocator := context.allocator) -> (err: Error) {

	ctx := common.Context{
		input  = stream^,
	};
	buf := buf;
	ws := bytes.buffer_to_stream(buf);
	ctx.output = ws;

	header, e := common.read_data(&ctx, GZIP_Header);
	if e != .None {
		return E_General.File_Too_Short;
	}

	if header.magic != .GZIP {
		return E_GZIP.Invalid_GZIP_Signature;
	}
	if header.compression_method != .DEFLATE {
		return E_General.Unknown_Compression_Method;
	}

	if header.os >= ._Unknown {
		header.os = .Unknown;
	}

	if .reserved_1 in header.flags || .reserved_2 in header.flags || .reserved_3 in header.flags {
		return E_GZIP.Reserved_Flag_Set;
	}

	// printf("signature: %v\n", header.magic);
	// printf("compression: %v\n", header.compression_method);
	// printf("flags: %v\n", header.flags);
	// printf("modification time: %v\n", time.unix(i64(header.modification_time), 0));
	// printf("xfl: %v (%v)\n", header.xfl, int(header.xfl));
	// printf("os: %v\n", GZIP_OS_Name[header.os]);

	if .extra in header.flags {
		xlen, e_extra := common.read_data(&ctx, u16le);
		if e_extra != .None {
			return E_General.Stream_Too_Short;
		}
		// printf("Extra data present (%v bytes)\n", xlen);
		if xlen < 4 {
			// Minimum length is 2 for ID + 2 for a field length, if set to zero.
			return E_GZIP.Invalid_Extra_Data;
		}

		field_id:     [2]u8;
		field_length: u16le;
		field_error: io.Error;

		for xlen >= 4 {
			// println("Parsing Extra field(s).");
			field_id, field_error = common.read_data(&ctx, [2]u8);
			if field_error != .None {
				// printf("Parsing Extra returned: %v\n", field_error);
				return E_General.Stream_Too_Short;
			}
			xlen -= 2;

			field_length, field_error = common.read_data(&ctx, u16le);
			if field_error != .None {
				// printf("Parsing Extra returned: %v\n", field_error);
				return E_General.Stream_Too_Short;
			}
			xlen -= 2;

			if xlen <= 0 {
				// We're not going to try and recover by scanning for a ZLIB header.
				// Who knows what else is wrong with this file.
				return E_GZIP.Invalid_Extra_Data;
			}

			// printf("    Field \"%v\" of length %v found: ", string(field_id[:]), field_length);
			if field_length > 0 {
				field_data := make([]u8, field_length, context.temp_allocator);
				_, field_error = ctx.input->impl_read(field_data);
				if field_error != .None {
					// printf("Parsing Extra returned: %v\n", field_error);
					return E_General.Stream_Too_Short;
				}
				xlen -= field_length;

				// printf("%v\n", string(field_data));
	 		}

			if xlen != 0 {
				return E_GZIP.Invalid_Extra_Data;
			}
		}
	}

	if .name in header.flags {
		// Should be enough.
		name: [1024]u8;
		b: [1]u8;
		i := 0;
		name_error: io.Error;

		for i < len(name) {
			_, name_error = ctx.input->impl_read(b[:]);
			if name_error != .None {
				return E_General.Stream_Too_Short;
			}
			if b == 0 {
				break;
			}
			name[i] = b[0];
			i += 1;
			if i >= len(name) {
				return E_GZIP.Original_Name_Too_Long;
			}
		}
		// printf("Original filename: %v\n", string(name[:i]));
	}

	if .comment in header.flags {
		// Should be enough.
		comment: [1024]u8;
		b: [1]u8;
		i := 0;
		comment_error: io.Error;

		for i < len(comment) {
			_, comment_error = ctx.input->impl_read(b[:]);
			if comment_error != .None {
				return E_General.Stream_Too_Short;
			}
			if b == 0 {
				break;
			}
			comment[i] = b[0];
			i += 1;
			if i >= len(comment) {
				return E_GZIP.Comment_Too_Long;
			}
		}
		// printf("Comment: %v\n", string(comment[:i]));
	}

	if .header_crc in header.flags {
		crc16: [2]u8;
		crc_error: io.Error;
		_, crc_error = ctx.input->impl_read(crc16[:]);
		if crc_error != .None {
			return E_General.Stream_Too_Short;
		}
		/*
			We don't actually check the CRC16 (lower 2 bytes of CRC32 of header data until the CRC field).
			If we find a gzip file in the wild that sets this field, we can add proper support for it.
		*/
	}

	/*
		We should have arrived at the ZLIB payload.
	*/

	zlib_error := zlib.inflate_raw(&ctx);

	// fmt.printf("ZLIB returned: %v\n", zlib_error);

	if !is_kind(zlib_error, E_General, E_General.OK) || zlib_error == nil {
		return zlib_error;
	}

	/*
		Read CRC32 using the ctx bit reader because zlib may leave bytes in there.
	*/
	common.discard_to_next_byte_lsb(&ctx);

	payload_crc_b: [4]u8;
	payload_len_b: [4]u8;
	for i in 0..3 {
		payload_crc_b[i] = u8(common.read_bits_lsb(&ctx, 8));
	}
	payload_crc := transmute(u32le)payload_crc_b;
	for i in 0..3 {
		payload_len_b[i] = u8(common.read_bits_lsb(&ctx, 8));
	}
	payload_len := int(transmute(u32le)payload_len_b);

	payload := bytes.buffer_to_bytes(buf);
	crc32 := u32le(hash.crc32(payload));

	if crc32 != payload_crc {
		return E_GZIP.Payload_CRC_Invalid;
	}

	if len(payload) != payload_len {
		return E_GZIP.Payload_Length_Invalid;
	}
	return E_General.OK;
}