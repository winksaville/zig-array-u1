# Zig Array of u1

Supports an array of bits of any size, but for maximum performance the
size should be 2^n in size. The number of bits is passed to ArrayU1 and
init will initialize the bits to zero.

Eventually this will likily replaced by being able to create
a `packed []u1` array in zig.

Two methods and variable len are implemented:
- `ArrayU1.len to return number of bits
- `ArrayU1.r(bit)` to read value is 0 or 1
- `ArrayU1.w(bit, value)` to write value 0 or 1

# Usage
```
const ArrayU1 = @import("array-u1").ArrayU1;

// Create arrays bits
var ary1024 = ArrayU1(1024).init();

// Write/read bit 123
ary1024.w(123, 0);
assert(ary1024.r(123) == 1);
```

## Test
```bash
$ zig test array-u1.zig 
Test 1/3 ArrayU1.test.init.all.0...OK
Test 2/3 ArrayU1.test.walking_1...OK
Test 3/3 ArrayU1.test.random...OK
All tests passed.
```

## Clean
Remove `zig-cache/` directory
```bash
$ rm -rf ./zig-cache/
```
