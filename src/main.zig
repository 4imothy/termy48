// SPDX-License-Identifier: GPL-3.0

// TODO Get the cursor position
// TODO print from center of screen
// TODO error for when num rows is greater than height of the window, multiply by piece height
// TODO add the defers to the exitfunctions

// TODO generalize the input stuff for all os
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
    var num_cols: usize = 10;
    var num_rows: usize = 10;
    var piece_height: u8 = 5;
    var piece_width: u8 = 11;
    var tty: ?std.os.fd_t = try std.os.open("/dev/tty", system.O.RDWR, 0);
    var dims: [2]usize = try getDimensions(tty);
    var screen_width = dims[0];
    var screen_height = dims[1];
    // remove weird printing behavior
    // can be fixed by clearing whole page, favor this for faster
    // printing
    if (num_rows * piece_height > screen_height or num_cols * piece_width > screen_width) {
        std.debug.print("here", .{});
        try exitGameOnError(errors.insuf_space_for_board, .{});
    }
    const board = try Board.init(piece_width, piece_height, num_rows, num_cols);
    try runGame(board);

    // Change this in future to hopefully work inline
    // have to save the position as when printing below and
    // the board moves up the restored position is wrong
}

fn runGame(board: Board) !void {
    try buf_wrtr.print(f.hide_cursor, .{});
    defer board.deinit();
    var rnd = std.rand.DefaultPrng.init(@truncate(u64, @bitCast(u128, std.time.nanoTimestamp())));
    // check if there is enough space to start the game
    const t = try board.addRandomPiece(&rnd);
    if (!t) {
        try exitGameOnError(errors.insuf_space_for_numbers, .{});
    }
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
    try buf_wrtr.print(f.clear_page, .{});
    try buf_wrtr.print(f.set_cursor_pos, .{ 0, 0 });
    try buf.flush();
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
