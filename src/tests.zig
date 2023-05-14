pub const moves = @import("tests/moves.zig");

test {
    @import("std").testing.refAllDecls(@This());
}
