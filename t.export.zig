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
