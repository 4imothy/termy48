// SPDX-License-Identifier: GPL-3.0

const main = @import("main.zig");
const std = @import("std");
const Drawer = @import("Drawer.zig");
const allocator = main.allocator;
const buf_wrtr = main.buf_wrtr;

const BG_STYLING_LEN: u8 = 5;

pub const Board = @This();

var rnd: std.rand.DefaultPrng = undefined;

pieces: [][]usize,
drawer: Drawer,
num_rows: usize,
num_cols: usize,

pub fn draw(self: Board) !void {
    try self.drawer.drawBoard(&self);
}

pub fn addRandomPiece(self: Board) error{OutOfMemory}!bool {
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

pub fn slideUp(self: Board) !void {
    // store the ids of the lowest height
    const cap_ids = try allocator.alloc(usize, self.num_cols);
    for (cap_ids) |*v| {
        v.* = 0;
    }
    const pieces = self.pieces;
    for (pieces) |row, i| {
        for (row) |elem, j| {
            if (elem != 0 and i == cap_ids[j]) {
                cap_ids[j] += 1;
            }
        }
    }
    // to store the lowest row possible, cap as moving up,
    for (pieces) |row, i| {
        for (row) |elem, j| {
            if (i > cap_ids[j] and elem != 0) {
                pieces[cap_ids[j]][j] = elem;
                pieces[i][j] = 0;
                // now that we move a piece down the cap is one below
                cap_ids[j] += 1;
            }
        }
    }
    allocator.free(cap_ids);
    // at this point every piece has been sliden to the top as much as possible
    // so we merge
    for (pieces) |row, i| {
        for (row) |elem, j| {
            if (elem != 0 and i != self.num_rows - 1) {
                if (pieces[i][j] == pieces[i + 1][j]) {
                    pieces[i][j] *= 2;
                    var k: usize = i + 1;
                    while (k < self.num_rows - 1) {
                        pieces[k][j] = pieces[k + 1][j];
                        k += 1;
                    }
                    pieces[k][j] = 0;
                }
            }
        }
    }
}

pub fn slideDown(self: Board) !void {
    // store the ids of the highest depth
    const floor_ids = try allocator.alloc(usize, self.num_cols);
    for (floor_ids) |*v| {
        v.* = self.num_rows - 1;
    }

    const pieces = self.pieces;
    var i = self.num_rows;
    while (i > 0) {
        i -= 1;
        var j = self.num_cols;
        while (j > 0) {
            j -= 1;
            if (pieces[i][j] != 0 and i == floor_ids[j] and i > 0) {
                floor_ids[j] -= 1;
            }
        }
    }
    i = self.num_rows;
    while (i > 0) {
        i -= 1;
        var j = self.num_cols;
        while (j > 0) {
            j -= 1;
            if (i != self.num_rows - 1 and i < floor_ids[j] and pieces[i][j] != 0) {
                pieces[floor_ids[j]][j] = pieces[i][j];
                pieces[i][j] = 0;
                floor_ids[j] -= 1;
            }
        }
    }
    allocator.free(floor_ids);
    // now that every piece is as down as possible, we merge
    i = self.num_rows;
    while (i > 0) {
        i -= 1;
        var j = self.num_cols;
        while (j > 0) {
            j -= 1;
            if (pieces[i][j] != 0 and i != 0) {
                if (pieces[i][j] == pieces[i - 1][j]) {
                    pieces[i][j] *= 2;
                    var k: usize = i - 1;
                    while (k > 0) {
                        pieces[k][j] = pieces[k - 1][j];
                        k -= 1;
                    }
                    pieces[k][j] = 0;
                }
            }
        }
    }
}
pub fn slideLeft(self: Board) !void {
    const left_wall_ids = try allocator.alloc(usize, self.num_rows);
    for (left_wall_ids) |*v| {
        v.* = 0;
    }

    const pieces = self.pieces;
    for (pieces) |row, i| {
        for (row) |elem, j| {
            if (elem != 0 and j == left_wall_ids[i]) {
                left_wall_ids[i] += 1;
            }
        }
    }

    for (pieces) |row, i| {
        for (row) |elem, j| {
            // if the column is to the right of the wall and element isn't zero
            if (j > left_wall_ids[i] and elem != 0) {
                pieces[i][left_wall_ids[i]] = elem;
                pieces[i][j] = 0;
                // moved a piece ther so now wall is one thicker
                left_wall_ids[i] += 1;
            }
        }
    }
    allocator.free(left_wall_ids);

    // now we merge
    for (pieces) |row, i| {
        for (row) |elem, j| {
            if (elem != 0 and j != self.num_cols - 1) {
                if (pieces[i][j] == pieces[i][j + 1]) {
                    pieces[i][j] *= 2;
                    var k: usize = j + 1;
                    while (k < self.num_cols - 1) {
                        pieces[i][k] = pieces[i][k + 1];
                        k += 1;
                    }
                    pieces[i][k] = 0;
                }
            }
        }
    }
}
pub fn slideRight(self: Board) !void {
    // controls the max value to the right
    const right_walls = try allocator.alloc(usize, self.num_rows);
    for (right_walls) |*v| {
        v.* = self.num_cols - 1;
    }
    const pieces = self.pieces;
    var i: usize = self.num_rows;
    while (i > 0) {
        i -= 1;
        var j: usize = self.num_cols;
        while (j > 0) {
            j -= 1;
            if (pieces[i][j] != 0 and j == right_walls[i] and j != 0) {
                right_walls[i] -= 1;
            }
        }
    }
    i = self.num_rows;
    while (i > 0) {
        i -= 1;
        var j = self.num_cols;
        while (j > 0) {
            j -= 1;
            if (j < right_walls[i] and pieces[i][j] != 0) {
                pieces[i][right_walls[i]] = pieces[i][j];
                pieces[i][j] = 0;
                right_walls[i] -= 1;
            }
        }
    }
    allocator.free(right_walls);

    // now we merge
    i = self.num_rows;
    while (i > 0) {
        i -= 1;
        var j = self.num_cols;
        while (j > 0) {
            j -= 1;
            if (pieces[i][j] != 0 and j != 0) {
                if (pieces[i][j] == pieces[i][j - 1]) {
                    pieces[i][j] *= 2;
                    var k: usize = j - 1;
                    while (k > 0) {
                        pieces[i][k] = pieces[i][k - 1];
                        k -= 1;
                    }
                    pieces[i][k] = 0;
                }
            }
        }
    }
}

pub fn init(piece_width: u8, piece_height: u8, num_rows: usize, num_cols: usize, screen_width: usize, screen_height: usize) !Board {
    rnd = std.rand.DefaultPrng.init(@truncate(u64, @bitCast(u128, std.time.nanoTimestamp())));
    return Board{
        .pieces = try createBoard(num_rows, num_cols),
        .drawer = try Drawer.init(num_cols, num_rows, piece_width, piece_height, screen_width, screen_height),
        .num_rows = num_rows,
        .num_cols = num_cols,
    };
}

pub fn drawEndGame(self: Board) !void {
    try self.drawer.drawGameOver();
}

pub fn deinit(self: Board) void {
    // self.drawer.deinit();
    for (self.pieces) |row| {
        allocator.free(row);
    }
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
