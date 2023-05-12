// SPDX-License-Identifier: GPL-3.0

const main = @import("main.zig");
const allocator = main.allocator;
const buf_wrtr = main.buf_wrtr;
const std = @import("std");
const Drawer = @import("drawer.zig");

const BG_STYLING_LEN: u8 = 5;

const Board = @This();

pieces: [][]usize,
drawer: Drawer,
num_rows: usize,
num_cols: usize,

pub fn draw(self: Board) !void {
    try self.drawer.drawBoard(&self);
}

pub fn addRandomPiece(self: Board, rnd: *std.rand.DefaultPrng) error{OutOfMemory}!bool {
    // store the indices which have a zero
    const opens: []bool = try allocator.alloc(bool, (self.num_rows * self.num_cols));
    var num_open: usize = 0;
    for (self.pieces) |row, i| {
        for (row) |v, j| {
            var idx = (i * self.num_cols) + j;
            if (v == 0) {
                opens[idx] = true;
                num_open += 1;
            } else {
                opens[idx] = false;
            }
        }
    }
    // no open spaces after a move, lose the game
    if (num_open == 0) {
        return false;
    }
    var val: usize = 0;
    if (rnd.random().float(f32) > 0.9) {
        val = 4;
    } else {
        val = 2;
    }
    var idx: usize = @mod(rnd.random().int(usize), num_open);
    var opens_seen: usize = 0;
    var row: usize = 0;
    var col: usize = 0;
    for (opens) |is_open, i| {
        if (is_open) {
            if (opens_seen == idx) {
                // work backwards to get the 2d index from teh i
                row = @divFloor(i, self.num_cols);
                col = @mod(i, self.num_cols);
            }
            opens_seen += 1;
        }
    }
    self.pieces[row][col] = val;
    return true;
}

pub fn init(piece_size: u8, num_rows: usize, num_cols: usize) !Board {
    const piece_width: u8 = (8 * piece_size) / 3;
    return Board{
        .pieces = try createBoard(num_rows, num_cols),
        .drawer = try Drawer.init(num_cols, piece_width, piece_size),
        .num_rows = num_rows,
        .num_cols = num_cols,
    };
}

pub fn deinit(self: Board) void {
    self.drawer.deinit();
    allocator.free(self.pieces);
}

fn createBoard(num_rows: usize, num_cols: usize) error{OutOfMemory}![][]usize {
    var board: [][]usize = try allocator.alloc([]usize, num_rows);
    for (board) |*row| {
        row.* = try allocator.alloc(usize, num_cols);
        for (row.*) |*val| {
            // init to 0
            val.* = 0;
        }
    }
    return board;
}
