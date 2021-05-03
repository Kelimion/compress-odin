package zip

/*
	ZIP format support.

	Will be implemented following version 6.3.9 of the APPDATA.txt specification:
		https://pkware.cachefly.net/webdocs/casestudies/APPNOTE.TXT

	Patented features added in v6.2 of the spec are not going to be implemented beyond
	defining their enums and structs, so they may be appropriately signalled to the end user,
	even if using their payloads remains outside the scope of this implementation.
*/

// import zlib "../zlib"
import "core:compress"

import "core:os"
import "core:time"
// import "core:strings"
// import "core:hash"
import "core:bytes"
import "core:io"

import "core:fmt"
// import "core:mem"

Signature :: enum u32le {
	ZIP_Local_File_Header                  = 0x04034b50, // 'P' << 24 | 'K' << 16 | 0x3 << 8 | 0x4,
	Data_Descriptor                        = 0x08074b50, // 'P' << 24 | 'K' << 16 | 0x7 << 8 | 0x8,
	Archive_Extra_Data                     = 0x08064b50, // 'P' << 24 | 'K' << 16 | 0x6 << 8 | 0x8,
	Central_File_Header                    = 0x02014b50, // 'P' << 24 | 'K' << 16 | 0x1 << 8 | 0x2,
	Digital_Signature                      = 0x05054b50, // 'P' << 24 | 'K' << 16 | 0x5 << 8 | 0x5,
	ZIP64_End_of_Central_V1                = 0x06064b50, // 'P' << 24 | 'K' << 16 | 0x6 << 8 | 0x6,
	ZIP64_End_of_Central_Directory_Locator = 0x07064b50, // 'P' << 24 | 'K' << 16 | 0x6 << 8 | 0x7,
	End_of_Central_Directory_Record        = 0x06054b50, // 'P' << 24 | 'K' << 16 | 0x5 << 8 | 0x6,
	Spanning_Marker                        = 0x08074b50, // Same as Data_Descriptor, but found at the start of a volume
	Temporary_Spanning_Marker              = 0x30304b50, // 'P' << 24 | 'K' << 16 | 0x30 << 8 | 0x30,
}

Compression_Method :: enum u16le {
	Stored  = 0,
	DEFLATE = 8,
}

Platform :: enum u8 {
	MS_DOS_FAT = 0,
	Amiga  = 1,
	OpenVMS = 2,
	UNIX = 3,
	VM_CMS = 4,
	Atari_ST = 5,
	OS_2_HPFS = 6,
	Macintosh = 7,
	Z_System = 8,
	CP_M = 9,
	Windows_NTFS = 10,
	MVS_OS_390_ZOS = 11,
	VSE = 12,
	Acorn_Risc = 13,
	VFAT = 14,
	Alternate_MVS = 15,
	BeOS = 16,
	Tandem = 17,
	OS_400 = 18,
	OS_X_Darwin = 19,
	Unused = 20,

	Unused_Max = 255,
}

Data_Descriptor :: struct #packed {
	crc32:      u32le,       // Cyclic Redunancy Check
	compressed_size:       u32le,       // Compressed size
	uncompressed_size:     u32le,       // Raw size
}
#assert(size_of(Data_Descriptor) == 12);

Data_Descriptor_64 :: struct #packed {
	crc32:      u32le,       // Cyclic Redunancy Check
	compressed_size:       u64le,       // Compressed size
	uncompressed_size:     u64le,       // Raw size
}
#assert(size_of(Data_Descriptor_64) == 20);

File_Version :: struct #packed {
	feature_level:  u8,
	platform: Platform,
}
#assert(size_of(File_Version) == 2);


ZIP_Local_File_Header :: struct #packed {
	signature:  Signature,
	version_extractor_required:  File_Version,	     // Version needed to extract
	general:    u16le,       // General purpose bit flags
	method:     Compression_Method,       // Compression method
	modification_datetime:   u32le,       // Last modification datetime
	descriptor:  Data_Descriptor, 
	filename_length: u16le,       // Filename length
	extra_field_length:    u16le,       // Extra field length

	// Filename       (variable size)
	// Extra field    (variable size)
}
#assert(size_of(ZIP_Local_File_Header) == 30);

Central_File_Header :: struct #packed {
	signature:  Signature,
	version_created_by:  File_Version,	     // Version created by
	version_extractor_required:  File_Version,	     // Version needed to extract
	general:    u16le,       // General purpose bit flags
	method:     Compression_Method,       // Compression method
	modification_datetime:   u32le,       // Last modification datetime
	desriptor:  Data_Descriptor, 
	filename_length: u16le,       // Filename length
	extra_field_length:    u16le,       // Extra field length
	comment_length:  u16le,       // File comment length
	start_volume: u16le,     // File starts in volume #
	internal_file_attributes: u16le,       // Internal file attributes
	external_file_attributes: u32le,       // External file attributes
	local_header_relative_offset: i32le, // Local header relative offset

    // Filename       (variable size)
    // Extra field    (variable size)
    // File comment   (variable size)	
}
#assert(size_of(Central_File_Header) == 46);

// For ZIP64 versions without central directory encryption, defined prior to APPDATA v6.2.
ZIP64_End_of_Central_Directory_Record_V1 :: struct #packed {
	signature: Signature,
	record_size: u64le,      // Remaining bytes in EoC DIR record, including variable data but excluding these 12 bytes
	version_created_by:   u16le,      // Version created by
	version_extractor_required:   u16le,      // Version needed to extract
	volume_number:   u16le,      // # of this 'disk'
	central_directory_start_volume: u16le, // # of disk containing start of the central directory
	entry_count_this_volume:        u64le, // # of entries in the central directory in this volume
	entry_count_total:              u64le, // # of entries total across all volumes
	central_directory_size:         u64le, // Size of central directory, possibly spanning several volumes
	central_directory_offset_start:  u64le, // Offset of CD start relative to CD start volume

	// Extensible data sector (variable size)
}
#assert(size_of(ZIP64_End_of_Central_Directory_Record_V1) == 52);

// Starting with version 6.2, ZIP64 End of Central Directory records are V2
// See 7.3.3 of APPDATA v6.3.9
ZIP64_End_of_Central_Directory_Record_V2 :: struct #packed {
	V1: ZIP64_End_of_Central_Directory_Record_V1,

/*
    The layout of the Zip64 End of Central Directory record for all
    versions starting with 6.2 of this specification will follow the
    Version 2 format.  The Version 2 format is as follows:

    The leading fixed size fields within the Version 1 format for this
    record remain unchanged.  The record signature for both Version 1 
    and Version 2 will be 0x06064b50.  Immediately following the last
    byte of the field known as the Offset of Start of Central 
    Directory With Respect to the Starting Disk Number will begin the 
    new fields defining Version 2 of this record.  

    7.3.4 New fields for Version 2

    Note: all fields stored in Intel low-byte/high-byte order.

              Value                 Size       Description
              -----                 ----       -----------
              Compression Method    2 bytes    Method used to compress the
                                               Central Directory
              Compressed Size       8 bytes    Size of the compressed data
              Original   Size       8 bytes    Original uncompressed size
              AlgId                 2 bytes    Encryption algorithm ID
              BitLen                2 bytes    Encryption key length
              Flags                 2 bytes    Encryption flags
              HashID                2 bytes    Hash algorithm identifier
              Hash Length           2 bytes    Length of hash data
              Hash Data             (variable) Hash data
*/
}

ZIP64_Data_Sector_Record_Header :: struct #packed {
	header_id: u16le, // See APPDATA.txt Appendix C for currently defined mappings
	data_size: u32le,
}
#assert(size_of(ZIP64_Data_Sector_Record_Header) == 6);

ZIP64_End_of_Central_Directory_Locator :: struct #packed {
	signature: Signature,
	end_of_central_directory_start_volume:    u32le, // # of disk containing the start of the ZIP64 End of Central Directory Record
	end_of_central_directory_relative_offset: i64le, //
	total_number_of_volumes:                  u32le, //
}
#assert(size_of(ZIP64_End_of_Central_Directory_Locator) == 20);

End_of_Central_Directory_Record :: struct #packed {
	signature: Signature,
	volume_number: u16le,
	central_directory_start_volume: u16le,
	entry_count_this_volume: u16le,
	entry_count_total:       u16le,
	central_directory_size:  u32le,
	central_directory_offset_start: u32le,
	zip_file_comment_length: u16le,

    //  .ZIP file comment       (variable size)
}
#assert(size_of(End_of_Central_Directory_Record) == 22);

Local_Record :: struct #packed {
	header:   ZIP_Local_File_Header,
	filename: string,
	extra:    bytes.Buffer,
}

Digital_Signature :: struct #packed {
	signature: Signature,
	data_size: u32le,

	// Signature data (variable size)
}

Error     :: compress.Error;
E_General :: compress.General_Error;
E_Deflate :: compress.Deflate_Error;
E_ZIP     :: compress.ZIP_Error;

parse_zip_file :: proc(buf: []u8) -> (err: Error) {

	r := bytes.Reader{};
	bytes.reader_init(&r, buf);
	stream := bytes.reader_to_stream(&r);
	c := compress.Context{
		input = stream,
	};

	sig: Signature;
	io_err: io.Error;
	file_header: ZIP_Local_File_Header;
	n: int;
	size: i64;

	first := true;

	temp_buffer := make([]u8, 65536, context.temp_allocator);

	size, io_err = c.input->impl_seek(0, .End);
	_, io_err = c.input->impl_seek(0, .Start);

	for {
		sig, io_err = compress.peek_data(&c, Signature);
		if io_err != .None {
			fmt.println("Read ran short trying to read the next section signature.");
			return E_General.Stream_Too_Short;
		}

		// First signature in file must be a ZIP_Local_File_Header
		if first && !(sig == .ZIP_Local_File_Header || sig == .Spanning_Marker || sig == .Temporary_Spanning_Marker) {
			return E_ZIP.Invalid_ZIP_File_Signature;
		} else {
			first = false;
			// TODO: Handle .Spanning_Marker & .Temporary_Spanning_Marker
			if sig != .ZIP_Local_File_Header {
				fmt.printf("Start of ZIP volume contained unexpected signature: %v\n", sig);
				return E_ZIP.Unexpected_Signature;
			}
		}
	
		file_header, io_err = compress.read_data(&c, ZIP_Local_File_Header);
		if io_err != .None {
			return E_ZIP.Invalid_ZIP_File_Signature;	
		}

		{
			using file_header;
			using descriptor;

			// fmt.println(file_header);

			filename := temp_buffer[:filename_length];
			n, io_err = c.input->impl_read(filename);
			if io_err != .None || n != int(filename_length) {
				fmt.println("Read ran short trying to read the filename.");
				return E_General.Stream_Too_Short;
			}

			ratio := f64(compressed_size) / f64(uncompressed_size) * 100.0;
			fmt.printf("%v (%v/%v = %v%%, method: %v, CRC32: %x)\n", string(filename), compressed_size, uncompressed_size, ratio, method, crc32);

			when false {
				extra_data := temp_buffer[:extra_field_length];
				n, io_err = c.input->impl_read(extra_data);
				if io_err != .None || n != int(extra_field_length) {
					fmt.println("Read ran short trying to read extra_data.");
					return E_General.Stream_Too_Short;
				}
				fmt.printf("extra data: %v\n", extra_data);
			} else {
				_, io_err = c.input->impl_seek(i64(extra_field_length), .Current);
				if io_err != .None {
					fmt.println("Read ran short trying to seek past extra_data.");
					return E_General.Stream_Too_Short;
				}
			}

			sook: i64;
			// File data should follow. Let's seek past it for now.
			sook, io_err = c.input->impl_seek(i64(compressed_size), .Current);
			if io_err != .None {
				fmt.println("Read ran short trying to seek past the data.");
				return E_General.Stream_Too_Short;
			}

			sig, io_err = compress.peek_data(&c, Signature);
			if io_err != .None {
				fmt.println("Read ran short trying to peek at the next section signature.");
				fmt.printf("Last seek wanted to take us to offset %v\n", sook);
				fmt.printf("Volume size is %v\n", size);
				vol    := (sook / size) + 1;
				offset := sook % size;
				fmt.printf("It should be in split volume %v at offset %v (0x%x)\n", vol, offset, offset);

				return E_ZIP.Insert_Next_Disk;
			}
			if sig == .Central_File_Header {
				break;
			}
		}
	}

	// If seek is supported for this Stream, we can just seek to the end and look for the EoCD.
	// Provided it's not a split archive, that is.

	central_header: Central_File_Header;

	for {
		sig, io_err = compress.peek_data(&c, Signature);
		if io_err != .None {
			fmt.println("Read ran short trying to read the next section signature.");
			return E_General.Stream_Too_Short;
		}
		if sig != .Central_File_Header {
			break;
		}

		central_header, io_err = compress.read_data(&c, Central_File_Header);
		if io_err != .None {
			return E_General.Stream_Too_Short;
		}


		{
			filename, extra, comment: []u8;

			if central_header.filename_length > 0 {
				filename = temp_buffer[:central_header.filename_length];
				n, io_err = c.input->impl_read(filename);
				if io_err != .None || n != int(central_header.filename_length) {
					fmt.println("Read ran short trying to read the filename.");
					return E_General.Stream_Too_Short;
				}
			} else {
				filename = {};
			}

			if central_header.extra_field_length > 0 {
				extra = temp_buffer[central_header.filename_length:central_header.filename_length+central_header.extra_field_length];
				n, io_err = c.input->impl_read(extra);
				if io_err != .None || n != int(central_header.extra_field_length) {
					fmt.println("Read ran short trying to read extra field.");
					return E_General.Stream_Too_Short;
				}
			} else {
				extra = {};
			}

			if central_header.comment_length > 0 {
				comment = temp_buffer[:central_header.comment_length];
				n, io_err = c.input->impl_read(comment);
				if io_err != .None || n != int(central_header.comment_length) {
					fmt.println("Read ran short trying to read the file comment.");
					return E_General.Stream_Too_Short;
				}
			} else {
				comment = {};
			}

			// fmt.println(string(filename));
			// fmt.println(dos_datetime_to_time(central_header.modification_datetime));
		}
	}

	if sig != .End_of_Central_Directory_Record {
		return E_ZIP.Expected_End_of_Central_Directory_Record;
	}
	end_of_central: End_of_Central_Directory_Record;

	end_of_central, io_err = compress.read_data(&c, End_of_Central_Directory_Record);
	if io_err != .None {
		return E_General.Stream_Too_Short;
	}

	fmt.println(end_of_central);

	return nil;
}

dos_datetime_to_time :: proc(datetime: u32le) -> (t: time.Time) {
	/*
		Top 16 bits:    date.
		7 bits: year, epoch 1980
		4 bits: month
		5 bits: day

		Bottom 16 bits: time.
		5 bits: hour
		6 bits: minute
		5 bits: seconds / 2
	*/

	year   := int((datetime >> 25) & 0x7f) + 1980;
	month  := int((datetime >> 21) & 0x0f);
	day    := int((datetime >> 16) & 0x1f);
	hour   := int((datetime >> 11) & 0x1f);
    minute := int((datetime >>  5) & 0x3f);
    second := int((datetime <<  1) & 0x3e);

    t, _ = time.datetime_to_time(year, month, day, hour, minute, second);
    return;
}


main :: proc() {

	using fmt;

	file: string;
	file = "../test/PngSuite-2017jul19.zip";
	// file = "../test/split.zip.001";

	buf, ok := os.read_entire_file(file);
	if !ok {
		printf("Couldn't open %v to read.\n", file);
		os.exit(1);
	}

	err := parse_zip_file(buf);
	fmt.printf("ZIP returned: %v\n", err);
}