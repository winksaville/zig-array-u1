# Sequence of commands discovering optimization error

If an exported function imports a global variable, bit_array,
the compiler assumed a function call to bit_array.b(0) in t()
could be optimized away.

Below you see the problem, in the emitted asm code for fn t()
it always returns $1234:
```
t:
	movl	$1234, %eax
	retq
```

Here is the sequence of commands which ends with executing
test.t.export.zig and it fails.

First the code for t.export.zig which exports t()
```
$ cat t.export.zig 
use @import("t.globals.zig");

export fn t() usize {
    return if (bit_array.b(0)) usize(123) else usize(1234);
}

test "t" {
    const std = @import("std");
    const assert = std.debug.assert;
    const warn = std.debug.warn;

    warn("\nt()={}\n", t());
    assert(t() == 1234);
    bit_array.w(0, 1);
    warn("t()={}\n", t());
    assert(t() == 123);
}
```

Execute the test code in t.export.zig, all is well:
```
$ zig test --release-fast t.export.zig
Test 1/6 t...
t()=1234
t()=123
OK
Test 2/6 ArrayU1.basic...OK
Test 3/6 ArrayU1.bool...OK
Test 4/6 ArrayU1.test.init.all.0...OK
Test 5/6 ArrayU1.test.walking_1...OK
Test 6/6 ArrayU1.test.random...OK
All tests passed.
```

Emit the assembler source for t.export.zig and we see that
$1234 is always being returned:
```
$ zig build-obj --release-fast --strip --emit asm t.export.zig 

$ cat zig-cache/t.export.s
	.text
	.file	"t.export"
	.globl	t
	.p2align	4, 0x90
	.type	t,@function
t:
	movl	$1234, %eax
	retq
.Lfunc_end0:
	.size	t, .Lfunc_end0-t


	.section	".note.GNU-stack","",@progbits
```

Build t.export.o
```
$ zig build-obj --release-fast t.export.zig
````

Here is the test propram that will import t.globals.zig:
```
$ cat test.t.export.zig 
const std = @import("std");
const assert = std.debug.assert;
const warn = std.debug.warn;

use @import("t.globals.zig");

extern fn t() usize;

test "optimization.bug" {
    warn("\nt()={}\n", t());
    assert(t() == 1234);
    bit_array.w(0, 1);
    warn("t()={}\n", t());
    assert(t() == 123);
}
```

And here we run it and it fails as expected:
```
$ zig test test.t.export.zig --object zig-cache/t.export.o 
Test 1/6 optimization.bug...
t()=1234
t()=1234
assertion failure
/home/wink/opt/lib/zig/std/debug/index.zig:118:13: 0x205039 in ??? (test)
            @panic("assertion failure");
            ^
/home/wink/prgs/ziglang/zig-array-u1/test.t.export.zig:14:11: 0x2050ad in ??? (test)
    assert(t() == 123);
          ^
/home/wink/opt/lib/zig/std/special/test_runner.zig:13:25: 0x22539a in ??? (test)
        if (test_fn.func()) |_| {
                        ^
/home/wink/opt/lib/zig/std/special/bootstrap.zig:96:22: 0x22514b in ??? (test)
            root.main() catch |err| {
                     ^
/home/wink/opt/lib/zig/std/special/bootstrap.zig:70:20: 0x2250c5 in ??? (test)
    return callMain();
                   ^
/home/wink/opt/lib/zig/std/special/bootstrap.zig:64:39: 0x224f28 in ??? (test)
    std.os.posix.exit(callMainWithArgs(argc, argv, envp));
                                      ^
/home/wink/opt/lib/zig/std/special/bootstrap.zig:37:5: 0x224de0 in ??? (test)
    @noInlineCall(posixCallMainAndExit);
    ^

Tests failed. Use the following command to reproduce the failure:
```
