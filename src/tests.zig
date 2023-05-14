pub const moves = @import("tests/moves.zig");
const std = @import("std");

test {
    @import("std").testing.refAllDecls(@This());
}
