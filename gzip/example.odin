//+ignore
package gzip_example

import "core:compress"
import "core:compress/gzip"
import "core:bytes"
import "core:os"

// Small GZIP file with fextra, fname and fcomment present.
@private
TEST: []u8 = {
	0x1f, 0x8b, 0x08, 0x1c, 0xcb, 0x3b, 0x3a, 0x5a,
	0x02, 0x03, 0x07, 0x00, 0x61, 0x62, 0x03, 0x00,
	0x63, 0x64, 0x65, 0x66, 0x69, 0x6c, 0x65, 0x6e,
	0x61, 0x6d, 0x65, 0x00, 0x54, 0x68, 0x69, 0x73,
	0x20, 0x69, 0x73, 0x20, 0x61, 0x20, 0x63, 0x6f,
	0x6d, 0x6d, 0x65, 0x6e, 0x74, 0x00, 0x2b, 0x48,
	0xac, 0xcc, 0xc9, 0x4f, 0x4c, 0x01, 0x00, 0x15,
	0x6a, 0x2c, 0x42, 0x07, 0x00, 0x00, 0x00,
}

main :: proc() {
	// Set up output buffer.
	buf: bytes.Buffer

	stdout :: proc(s: string) {
		os.write_string(os.stdout, s)
	}
	stderr :: proc(s: string) {
		os.write_string(os.stderr, s)
	}

	args := os.args

	if len(args) < 2 {
		stderr("No input file specified.\n")
		err := gzip.load(TEST, &buf)
		if err == nil {
			stdout("Displaying test vector: ")
			stdout(bytes.buffer_to_string(&buf))
			stdout("\n")
		}
		bytes.buffer_destroy(&buf)
	}

	// The rest are all files.
	args = args[1:]
	err: gzip.Error

	for file in args {
		if file == "-" {
			// Read from stdin
			s := os.stream_from_handle(os.stdin)
			c := compress.Context_Stream_Input{
				input  = s,
				output = &buf,
			}
			err = gzip.load_from_context(z = &c, buf = &buf)
		} else {
			err = gzip.load(file, &buf)
		}
		if err != nil {
			if err == gzip.E_General.File_Not_Found {
				stderr("File not found: ")
				stderr(file)
				stderr("\n")
				os.exit(1)
			}
			stderr("GZIP returned an error.\n")
			bytes.buffer_destroy(&buf)
			os.exit(2)
		}
		stdout(bytes.buffer_to_string(&buf))
		bytes.buffer_destroy(&buf)
	}
	os.exit(0)
}
