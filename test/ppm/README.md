If you run `odin test . -define:WRITE_PPM_ON_FAIL=true`,
a PPM will be written here for each failing PNG file.

This is to allow you to more easily debug the issue.

It defaults to false so the test can run during CI
without producing these artifacts.