// SPDX-License-Identifier: GPL-3.0

const main = @import("main.zig");
const std = @import("std");
const Drawer = @import("drawer.zig");
const allocator = main.allocator;
const buf_wrtr = main.buf_wrtr;

const BG_STYLING_LEN: u8 = 5;

const Board = @This();

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
            if (i != 0 and i > cap_ids[j] and elem != 0) {
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
    const floor_ids = try allocator.alloc(usize, self.num_cols);
    for (floor_ids) |*v| {
        v.* = self.num_rows - 1;
    }

    const pieces = self.pieces;
    for (pieces) |_, i| {
        var j = self.num_cols - 1;

        while (j > 0) {
            if (pieces[i][j] != 0 and j == floor_ids[j]) {
                floor_ids[j] -= 1;
            }
            j -= 1;
        }
    }
    for (pieces) |_, i| {
        var j = self.num_cols - 1;
        while (j > 0) {
            if (i != self.num_rows - 1 and pieces[i][j] != 0) {
                pieces[floor_ids[j]][j] = pieces[i][j];
                pieces[i][j] = 0;
                floor_ids[j] -= 1;
            }
            j -= 1;
        }
    }
}
pub fn slideLeft(self: Board) void {
    _ = self;
}
pub fn slideRight(self: Board) void {
    _ = self;
}

pub fn init(piece_width: u8, piece_height: u8, num_rows: usize, num_cols: usize, draw_start_x: usize, draw_start_y: usize) !Board {
    rnd = std.rand.DefaultPrng.init(@truncate(u64, @bitCast(u128, std.time.nanoTimestamp())));
    return Board{
        .pieces = try createBoard(num_rows, num_cols),
        .drawer = try Drawer.init(num_cols, piece_width, piece_height, draw_start_x, draw_start_y),
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

// TESTS
test "slide up" {
    const num_cols = 6;
    const num_rows = 4;
    var pieces = [_][num_cols]usize{
        [_]usize{ 0, 8, 2, 4, 2, 2 },
        [_]usize{ 0, 0, 2, 0, 0, 4 },
        [_]usize{ 0, 2, 2, 0, 0, 0 },
        [_]usize{ 2, 0, 2, 4, 0, 0 },
    };
    const p = &[_][]usize{ &pieces[0], &pieces[1], &pieces[2], &pieces[3] };

    const board = Board{
        .pieces = p,
        .drawer = undefined,
        .num_rows = num_rows,
        .num_cols = num_cols,
    };
    try board.slideUp();

    var after_pieces = [_][num_cols]usize{
        [_]usize{ 2, 8, 4, 8, 2, 2 },
        [_]usize{ 0, 2, 4, 0, 0, 4 },
        [_]usize{ 0, 0, 0, 0, 0, 0 },
        [_]usize{ 0, 0, 0, 0, 0, 0 },
    };
    const ap = &[_][]usize{ &after_pieces[0], &after_pieces[1], &after_pieces[2], &after_pieces[3] };
    try std.testing.expect(checkPiecesEqual(board.pieces, ap));
}

test "slide up tiny" {
    const num_cols = 1;
    const num_rows = 1;
    var pieces = [_][num_cols]usize{
        [_]usize{2},
    };
    const p = &[_][]usize{&pieces[0]};

    const board = Board{
        .pieces = p,
        .drawer = undefined,
        .num_rows = num_rows,
        .num_cols = num_cols,
    };
    try board.slideUp();

    var after_pieces = [_][num_cols]usize{
        [_]usize{2},
    };
    const ap = &[_][]usize{&after_pieces[0]};
    try std.testing.expect(checkPiecesEqual(board.pieces, ap));
}

test "slide up column" {
    const num_cols = 1;
    const num_rows = 10;
    var pieces = [_][num_cols]usize{
        [_]usize{2},
        [_]usize{2},
        [_]usize{2},
        [_]usize{2},
        [_]usize{0},
        [_]usize{2},
        [_]usize{2},
        [_]usize{8},
        [_]usize{2},
        [_]usize{2},
    };

    const p = &[_][]usize{ &pieces[0], &pieces[1], &pieces[2], &pieces[3], &pieces[4], &pieces[5], &pieces[6], &pieces[7], &pieces[8], &pieces[9] };
    const board = Board{
        .pieces = p,
        .drawer = undefined,
        .num_rows = num_rows,
        .num_cols = num_cols,
    };
    try board.slideUp();

    var after_pieces = [_][num_cols]usize{
        [_]usize{4},
        [_]usize{4},
        [_]usize{4},
        [_]usize{8},
        [_]usize{4},
        [_]usize{0},
        [_]usize{0},
        [_]usize{0},
        [_]usize{0},
        [_]usize{0},
    };
    const ap = &[_][]usize{ &after_pieces[0], &after_pieces[1], &after_pieces[2], &after_pieces[3], &after_pieces[4], &after_pieces[5], &after_pieces[6], &after_pieces[7], &after_pieces[8], &after_pieces[9] };
    try std.testing.expect(checkPiecesEqual(board.pieces, ap));
}

fn checkPiecesEqual(board_1: [][]usize, board_2: [][]usize) bool {
    if (board_1.len != board_2.len) return false;
    if (board_1[0].len != board_2[0].len) return false;

    for (board_1) |row, i| {
        for (row) |_, j| {
            if (board_1[i][j] != board_2[i][j]) {
                return false;
            }
        }
    }
    return true;
}
