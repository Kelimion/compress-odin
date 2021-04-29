//+ignore
package compress_example

import "../../gzip"
import "core:bytes"
import "core:os"

main :: proc() {
	// Set up output buffer.
	buf: bytes.Buffer;
	defer bytes.buffer_destroy(&buf);

	stdout :: proc(s: string) {
		os.write_string(os.stdout, s);
	}
	stderr :: proc(s: string) {
		os.write_string(os.stderr, s);
	}

	args := os.args;

	if len(args) < 2 {
		stderr("No input file specified.\n");
		os.exit(1);
	}

	// The rest are all files.
	args = args[1:];
	err: gzip.Error;

	for file in args {
		if file == "-" {
			// Read from stdin
			s := os.stream_from_handle(os.stdin);
			err = gzip.load(&s, &buf);
		} else {
			err = gzip.load(file, &buf);
		}
		if !gzip.is_kind(err, gzip.E_General.OK) {
			if gzip.is_kind(err, gzip.E_General.File_Not_Found) {
				stderr("File not found: ");
				stderr(file);
				stderr("\n");
				os.exit(1);
			}
			stderr("GZIP returned an error.\n");
			os.exit(2);
		}
		stdout(bytes.buffer_to_string(&buf));
	}
	os.exit(0);
}