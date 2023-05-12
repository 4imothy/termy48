// SPDX-License-Identifier: GPL-3.0

// TODO generalize the input stuff for all os
// TODO error for when num rows is greater than height of the window
// TODO eventually read num_rows, num_cols from arguments
//* Styling *\\
//* TypeName | namespace_name | global_var | functionName | const_name *\\
const std = @import("std");
const Board = @import("Board.zig");
const f = @import("formats.zig");
const errors = @import("errors.zig");
const system = std.os.system;
const out = std.io.getStdOut();
var buf = std.io.bufferedWriter(out.writer());
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

// used in Board.zig
pub const buf_wrtr = buf.writer();
pub const allocator = arena.allocator();

pub fn main() !void {
    defer arena.deinit();
    // defaults
    var num_cols: usize = 0;
    var num_rows: usize = 0;
    var piece_size: u8 = 4;
    var tty: ?std.os.fd_t = try std.os.open("/dev/tty", system.O.RDWR, 0);
    var dims: [2]usize = try getDimensions(tty);
    var screen_width = dims[0];
    var screen_height = dims[1];
    try buf_wrtr.print(f.hide_cursor, .{});

    // TODO Get the cursor position
    // Change this in future to hopefully work inline
    // have to save the position as when printing below and
    // the board moves up the restored position is wrong
    const board = try Board.init(piece_size, num_rows, num_cols);
    defer board.deinit();
    var rnd = std.rand.DefaultPrng.init(@truncate(u64, @bitCast(u128, std.time.nanoTimestamp())));
    // check if there is enough space to start the game
    const t = try board.addRandomPiece(&rnd);
    if (!t) {
        try exitGameOnError(errors.not_enough_space, .{});
    }
    try buf_wrtr.print(f.clear_page, .{});
    try buf_wrtr.print(f.set_cursor_pos, .{ 0, 0 });
    try buf_wrtr.print("W: {d}, H: {d}\n", .{ screen_width, screen_height });
    try buf.flush();
    var orig = try std.os.tcgetattr(std.os.STDIN_FILENO);
    var new = orig;
    // TODO try this on windows, don't think it will work
    // make it it's own branch
    // ISIG: Disable vanilla CTRL-C and CTRL-Z
    // ECHO: Stop the terminal from displaying pressed keys.
    // ICANON: Allows us to read inputs byte-wise instead of line-wise.
    new.lflag &= ~(system.ECHO | system.ICANON | system.ISIG);
    try std.os.tcsetattr(std.os.STDIN_FILENO, std.os.TCSA.FLUSH, new);
    defer std.os.tcsetattr(std.os.STDIN_FILENO, std.os.TCSA.FLUSH, orig) catch {};
    var char: u8 = undefined;
    var reader = std.io.getStdIn().reader();

    var running = true;
    while (running) {
        char = try reader.readByte();
        switch (char) {
            'q' => {
                try exitGame();
            },
            'c' & '\x1F' => {
                try exitGame();
            },
            'h' => {
                try board.draw();
                try buf.flush();
            },
            else => {},
        }
    }
}

fn getDimensions(tty: ?std.os.fd_t) ![2]usize {
    if (tty == null) {
        return .{ 100, 100 };
    }
    var size = std.mem.zeroes(system.winsize);
    const err = system.ioctl(tty.?, system.T.IOCGWINSZ, @ptrToInt(&size));
    if (std.os.errno(err) != .SUCCESS) {
        return std.os.unexpectedErrno(@intToEnum(system.E, err));
    }
    return .{ size.ws_col, size.ws_row };
}

fn exitGame() !void {
    try buf_wrtr.print(f.show_cursor, .{});
    try buf.flush();
    std.os.exit(0);
}

pub fn exitGameOnError(comptime format: []const u8, args: anytype) !void {
    try buf_wrtr.print(format, args);
    try buf.flush();
    std.os.exit(1);
}
