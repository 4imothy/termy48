// SPDX-License-Identifier: GPL-3.0

// TODO better exiting handling, error type one is not enough room to start
// TODO generalize the input stuff for all os
// TODO, error handling, might not need for space things, for when sizes are bad
// Check if defer actions are done on ctrl + c
// TODO on exit print to show the cursor
// TODO eventually read num_rows, num_cols from arguments
//* Styling *\\
//* TypeName | namespace_name | global_var | functionName | const_name *\\
const std = @import("std");
const Board = @import("Board.zig");
const out = std.io.getStdOut();
var buf = std.io.bufferedWriter(out.writer());
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

// used in Board.zig
pub const buf_wrtr = buf.writer();
pub const allocator = arena.allocator();

pub fn main() !void {
    defer arena.deinit();
    // defaults
    var num_cols: usize = 4;
    var num_rows: usize = 4;
    var piece_size: u8 = 4;
    var tty: ?std.os.fd_t = try std.os.open("/dev/tty", std.os.system.O.RDWR, 0);
    var dims: [2]usize = try getDimensions(tty);
    var screen_width = dims[0];
    var screen_height = dims[1];
    const board = try Board.init(piece_size, num_rows, num_cols);
    defer board.deinit();
    var rnd = std.rand.DefaultPrng.init(@truncate(u64, @bitCast(u128, std.time.nanoTimestamp())));
    // check if there is enough space to start the game
    const t = try board.addRandomPiece(&rnd);
    if (!t) {
        board.deinit();
        try buf_wrtr.print("Not Enough Space to Start\n", .{});
        try buf.flush();
        try std.os.exit(1);
    }
    try buf_wrtr.print("W: {d}, H: {d}\n", .{ screen_width, screen_height });
    try buf.flush();
    var orig = try std.os.tcgetattr(std.os.STDIN_FILENO);
    var new = orig;
    new.lflag &= ~(std.os.darwin.ECHO | std.os.darwin.ICANON);
    try std.os.tcsetattr(std.os.STDIN_FILENO, std.os.TCSA.FLUSH, new);
    defer std.os.tcsetattr(std.os.STDIN_FILENO, std.os.TCSA.FLUSH, orig) catch {};
    var char: u8 = undefined;
    var reader = std.io.getStdIn().reader();

    var running = true;
    while (running) {
        char = try reader.readByte();
        std.debug.print("{}\n", .{char});
        switch (char) {
            'q' => {
                std.debug.print("q pressed\n", .{});
                try std.os.exit(0);
            },
            else => {},
        }
    }
}

fn getDimensions(tty: ?std.os.fd_t) ![2]usize {
    if (tty == null) {
        return .{ 100, 100 };
    }
    var size = std.mem.zeroes(std.os.system.winsize);
    const err = std.os.system.ioctl(tty.?, std.os.system.T.IOCGWINSZ, @ptrToInt(&size));
    if (std.os.errno(err) != .SUCCESS) {
        return std.os.unexpectedErrno(@intToEnum(std.os.system.E, err));
    }
    return .{ size.ws_col, size.ws_row };
}
