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
