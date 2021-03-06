const std = @import("std");
const debug = std.debug;
const assert = debug.assert;
const assertError = debug.assertError;
const warn = debug.warn;

/// Array of u1, typically for maximum performance min_num_bits == 2^n in size
pub fn ArrayU1(comptime min_num_bits: usize) type {
    const UsizeIdx = switch (@sizeOf(usize)) {
        4 => u5,
        8 => u6,
        else => @compileError("Currently only 4 and 8 byte usize supported for UsizeIdx\n"),
    };

    const usize_bit_count = @sizeOf(usize) * 8;
    const usize_count = (min_num_bits + (usize_bit_count - 1)) / usize_bit_count;

    return struct {
        const Self = @This();
        const Bits = [usize_count]usize;
        const num_bits = @sizeOf(Bits) * usize_bit_count;

        len: usize,
        bits: Bits,

        // Initialize the struct to 0 and return it
        pub fn init() Self {
            var ary = Self{
                .len = min_num_bits,
                .bits = undefined,
            };
            var i: usize = 0;
            while (i < ary.bits.len) : (i += 1) {
                ary.bits[i] = 0;
            }
            return ary;
        }

        /// Read a bit as bool
        pub fn b(pSelf: *Self, bit_offset: usize) bool {
            return pSelf.r(bit_offset) == 1;
        }

        /// Read a bit
        pub fn r(pSelf: *Self, bit_offset: usize) usize {
            if (bit_offset >= num_bits) return 0;
            var usize_idx = bit_offset / usize_bit_count;
            var bit_idx: UsizeIdx = @intCast(UsizeIdx, bit_offset % usize_bit_count);
            var bit = (pSelf.bits[usize_idx] & ((usize(1) << bit_idx))) != 0;
            return if (bit) usize(1) else usize(0);
        }

        /// Write a bit
        pub fn w(pSelf: *Self, bit_offset: usize, val: usize) void {
            if (bit_offset >= num_bits) return;
            var usize_idx = bit_offset / usize_bit_count;
            var bit_idx: UsizeIdx = @intCast(UsizeIdx, bit_offset % usize_bit_count);
            var bit_mask: usize = usize(1) << bit_idx;
            if (val == 0) {
                pSelf.bits[usize_idx] &= ~bit_mask;
            } else {
                pSelf.bits[usize_idx] |= bit_mask;
            }
        }
    };
}

test "ArrayU1.basic" {
    var a = ArrayU1(1).init();
    assert(a.r(0) == 0);
    a.w(0, 1);
    assert(a.r(0) == 1);
}

test "ArrayU1.bool" {
    var a = ArrayU1(1).init();
    assert(!a.b(0));
    a.w(0, 1);
    assert(a.b(0));
}

test "ArrayU1.test.init.all.0" {
    var a1 = ArrayU1(1).init();
    var bit: usize = 0;
    while (bit < a1.len) : (bit += 1) {
        assert(a1.r(bit) == 0);
    }
    var ausize_less_1 = ArrayU1((@sizeOf(usize) * 8) - 1).init();
    bit = 0;
    while (bit < ausize_less_1.len) : (bit += 1) {
        assert(ausize_less_1.r(bit) == 0);
    }
    var ausize = ArrayU1(@sizeOf(usize) * 8).init();
    bit = 0;
    while (bit < ausize.len) : (bit += 1) {
        assert(ausize.r(bit) == 0);
    }
    var ausize_usize_plus_1 = ArrayU1(@sizeOf(usize) * 8).init();
    bit = 0;
    while (bit < ausize_usize_plus_1.len) : (bit += 1) {
        assert(ausize_usize_plus_1.r(bit) == 0);
    }
}

test "ArrayU1.test.walking_1" {
    const WO = struct {
        fn walkingOne(comptime bit_count: usize) void {
            var ary = ArrayU1(bit_count).init();
            var bit: usize = 0;
            while (bit < ary.len) : (bit += 1) {
                ary.w(bit, 1);
                assert(ary.r(bit) == 1);

                // Verify one bit changed
                var b0: usize = 0;
                while (b0 < ary.len) : (b0 += 1) {
                    var b = ary.r(b0);
                    assert(b == if (b0 == bit) usize(1) else usize(0));
                }

                ary.w(bit, 0);

                // Verify all are 0
                b0 = 0;
                while (b0 < ary.len) : (b0 += 1) {
                    assert(ary.r(b0) == 0);
                }
            }
        }
    };

    WO.walkingOne(1);
    WO.walkingOne((@sizeOf(usize) * 8) - 1);
    WO.walkingOne((@sizeOf(usize) * 8));
    WO.walkingOne((@sizeOf(usize) * 8) + 1);
}

test "ArrayU1.test.random" {
    var bit0_off: usize = 0;
    var bit0_on: usize = 0;
    var bit1_off: usize = 0;
    var bit1_on: usize = 0;

    const bit_count: usize = 1024;
    const write_count: usize = 512;
    const seed: u64 = 4321;

    // Create array of bits
    var ary = ArrayU1(bit_count).init();

    // Write ones
    var prng = std.rand.DefaultPrng.init(seed);
    var count: usize = write_count;
    while (count > 0) : (count -= 1) {
        var b = prng.random.scalar(usize) & 1;
        ary.w(b, 1);
    }

    // Read them back
    prng = std.rand.DefaultPrng.init(seed);
    count = write_count;
    while (count > 0) : (count -= 1) {
        var b = prng.random.scalar(usize) & 1;
        assert(ary.r(b) == 1);
    }
}
