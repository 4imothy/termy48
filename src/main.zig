// SPDX-License-Identifier: GPL-3.0

// TODO make work with zig 0.11.0
// TODO generalize the input stuff for all os, need windows

//* Styling *\\
//* TypeName | namespace_name | global_var | functionName | const_name *\\
const std = @import("std");
const Board = @import("Board.zig");
const f = @import("formats.zig");
const errors = @import("errors.zig");
const arg_parser = @import("arg_parser.zig");
const system = std.os.system;
const out = std.io.getStdOut();
var buf = std.io.bufferedWriter(out.writer());
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

// used in drawer.zig and arg_parser
pub const buf_wrtr = buf.writer();
pub const allocator = arena.allocator();

pub fn main() !void {
    var tty: ?std.os.fd_t = try std.os.open("/dev/tty", system.O.RDWR, 0);
    var dims: [2]usize = try getDimensions(tty);
    const screen_width = dims[0];
    const screen_height = dims[1];
    const data = try arg_parser.parseArgs(
        allocator,
        screen_width,
        screen_height,
    );
    if (!data.start_game) {
        arena.deinit();
        try buf.flush();
        std.os.exit(0);
    }
    const piece_width = data.piece_width;
    const piece_height = data.piece_height;
    const num_rows: usize = data.num_rows;
    const num_cols: usize = data.num_cols;
    // remove weird printing behavior
    // can be fixed by clearing whole page, favor this for faster
    // printing
    const game_width = num_cols * piece_width;
    const game_height = num_rows * piece_height;
    if (game_height > screen_height or game_width > screen_width) {
        try exitGameOnError(errors.insuf_space_for_board, .{});
    }
    const board = try Board.init(piece_width, piece_height, num_rows, num_cols, screen_width, screen_height, data.show_score);
    var orig = try std.os.tcgetattr(std.os.STDIN_FILENO);
    var new = orig;
    // make it it's own branch
    // ISIG: Disable vanilla CTRL-C and CTRL-Z
    // ECHO: Stop the terminal from displaying pressed keys.
    // ICANON: Allows us to read inputs byte-wise instead of line-wise.
    new.lflag &= ~(system.ECHO | system.ICANON | system.ISIG);
    try std.os.tcsetattr(std.os.STDIN_FILENO, std.os.TCSA.FLUSH, new);
    try runGame(board);
    try deinitGame(board, screen_height, orig);
    exitGame();
}

// TODO make this a bool that returns false on leave
fn runGame(board: Board) !void {
    try buf_wrtr.print(f.hide_cursor, .{});
    // TODO make this start with two pieces
    _ = try board.addRandomPiece();
    var char: u8 = undefined;
    var reader = std.io.getStdIn().reader();
    try buf.flush();
    var accepting_moves = true;
    try board.draw();
    try buf.flush();
    while (true) {
        char = try reader.readByte();
        switch (char) {
            'q' => {
                return;
            },
            'c' & '\x1F' => {
                return;
            },
            'h', 'a', 68 => { // left arrow
                if (accepting_moves) {
                    try board.slideLeft();
                    // if after you move there is no room for a piece
                    const res: bool = try board.addRandomPiece();
                    if (!res) {
                        try endGame(board);
                        accepting_moves = false;
                    } else {
                        try board.draw();
                    }
                    try buf.flush();
                }
            },
            'l', 'd', 67 => { // right arrow
                if (accepting_moves) {
                    try board.slideRight();
                    // if after you move there is no room for a piece
                    const res: bool = try board.addRandomPiece();
                    if (!res) {
                        try endGame(board);
                        accepting_moves = false;
                    } else {
                        try board.draw();
                    }
                    try buf.flush();
                }
            },
            'k', 'w', 65 => { // up arrow
                if (accepting_moves) {
                    try board.slideUp();
                    // if after you move there is no room for a piece
                    const res: bool = try board.addRandomPiece();
                    if (!res) {
                        try endGame(board);
                        accepting_moves = false;
                    } else {
                        try board.draw();
                    }
                    try buf.flush();
                }
            },
            'j', 's', 66 => { // down arrow
                if (accepting_moves) {
                    try board.slideDown();
                    // if after you move there is no room for a piece
                    const res: bool = try board.addRandomPiece();
                    if (!res) {
                        try endGame(board);
                        accepting_moves = false;
                    } else {
                        try board.draw();
                    }
                    try buf.flush();
                }
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

fn deinitGame(board: Board, screen_height: usize, orig: std.os.termios) !void {
    try buf_wrtr.print(f.show_cursor, .{});
    try buf_wrtr.print(f.set_cursor_y, .{screen_height});
    board.deinit();
    try buf.flush();
    std.os.tcsetattr(std.os.STDIN_FILENO, std.os.TCSA.FLUSH, orig) catch {};
    arena.deinit();
}

fn exitGame() void {
    std.os.exit(0);
}

pub fn exitGameOnError(comptime format: []const u8, args: anytype) !void {
    try buf_wrtr.print(format, args);
    try buf.flush();
    std.os.exit(1);
}

fn endGame(board: Board) !void {
    try board.drawEndGame();
}
