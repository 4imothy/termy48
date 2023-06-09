// SPDX-License-Identifier: GPL-3.0

const Board = @import("../Board.zig");
const std = @import("std");

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

test "slide up column no merge" {
    const num_cols = 1;
    const num_rows = 8;
    var pieces = [_][num_cols]usize{
        [_]usize{2},
        [_]usize{4},
        [_]usize{8},
        [_]usize{16},
        [_]usize{32},
        [_]usize{64},
        [_]usize{128},
        [_]usize{256},
    };

    const p = &[_][]usize{ &pieces[0], &pieces[1], &pieces[2], &pieces[3], &pieces[4], &pieces[5], &pieces[6], &pieces[7] };
    const board = Board{
        .pieces = p,
        .drawer = undefined,
        .num_rows = num_rows,
        .num_cols = num_cols,
    };
    try board.slideUp();

    var after_pieces = [_][num_cols]usize{
        [_]usize{2},
        [_]usize{4},
        [_]usize{8},
        [_]usize{16},
        [_]usize{32},
        [_]usize{64},
        [_]usize{128},
        [_]usize{256},
    };

    const ap = &[_][]usize{ &after_pieces[0], &after_pieces[1], &after_pieces[2], &after_pieces[3], &after_pieces[4], &after_pieces[5], &after_pieces[6], &after_pieces[7] };
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

test "slide down column no merge" {
    const num_cols = 1;
    const num_rows = 8;
    var pieces = [_][num_cols]usize{
        [_]usize{2},
        [_]usize{4},
        [_]usize{8},
        [_]usize{16},
        [_]usize{32},
        [_]usize{64},
        [_]usize{128},
        [_]usize{256},
    };

    const p = &[_][]usize{ &pieces[0], &pieces[1], &pieces[2], &pieces[3], &pieces[4], &pieces[5], &pieces[6], &pieces[7] };
    const board = Board{
        .pieces = p,
        .drawer = undefined,
        .num_rows = num_rows,
        .num_cols = num_cols,
    };
    try board.slideDown();

    var after_pieces = [_][num_cols]usize{
        [_]usize{2},
        [_]usize{4},
        [_]usize{8},
        [_]usize{16},
        [_]usize{32},
        [_]usize{64},
        [_]usize{128},
        [_]usize{256},
    };

    const ap = &[_][]usize{ &after_pieces[0], &after_pieces[1], &after_pieces[2], &after_pieces[3], &after_pieces[4], &after_pieces[5], &after_pieces[6], &after_pieces[7] };
    try std.testing.expect(checkPiecesEqual(board.pieces, ap));
}

test "slide down" {
    const num_cols = 6;
    const num_rows = 4;
    var pieces = [_][num_cols]usize{
        [_]usize{ 2, 8, 2, 4, 2, 2 },
        [_]usize{ 0, 0, 2, 0, 0, 4 },
        [_]usize{ 0, 2, 2, 0, 0, 4 },
        [_]usize{ 0, 0, 2, 4, 0, 0 },
    };
    const p = &[_][]usize{ &pieces[0], &pieces[1], &pieces[2], &pieces[3] };

    const board = Board{
        .pieces = p,
        .drawer = undefined,
        .num_rows = num_rows,
        .num_cols = num_cols,
    };
    try board.slideDown();

    var after_pieces = [_][num_cols]usize{
        [_]usize{ 0, 0, 0, 0, 0, 0 },
        [_]usize{ 0, 0, 0, 0, 0, 0 },
        [_]usize{ 0, 8, 4, 0, 0, 2 },
        [_]usize{ 2, 2, 4, 8, 2, 8 },
    };
    const ap = &[_][]usize{ &after_pieces[0], &after_pieces[1], &after_pieces[2], &after_pieces[3] };
    try std.testing.expect(checkPiecesEqual(board.pieces, ap));
}

test "slide down column" {
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
    try board.slideDown();

    var after_pieces = [_][num_cols]usize{
        [_]usize{0},
        [_]usize{0},
        [_]usize{0},
        [_]usize{0},
        [_]usize{0},
        [_]usize{4},
        [_]usize{4},
        [_]usize{4},
        [_]usize{8},
        [_]usize{4},
    };
    const ap = &[_][]usize{ &after_pieces[0], &after_pieces[1], &after_pieces[2], &after_pieces[3], &after_pieces[4], &after_pieces[5], &after_pieces[6], &after_pieces[7], &after_pieces[8], &after_pieces[9] };
    try std.testing.expect(checkPiecesEqual(board.pieces, ap));
}

test "slide left" {
    const num_cols = 6;
    const num_rows = 4;
    var pieces = [_][num_cols]usize{
        [_]usize{ 2, 2, 8, 4, 4, 2 },
        [_]usize{ 2, 0, 2, 0, 0, 4 },
        [_]usize{ 0, 2, 2, 0, 8, 0 },
        [_]usize{ 2, 0, 2, 4, 0, 0 },
    };
    const p = &[_][]usize{ &pieces[0], &pieces[1], &pieces[2], &pieces[3] };

    const board = Board{
        .pieces = p,
        .drawer = undefined,
        .num_rows = num_rows,
        .num_cols = num_cols,
    };
    try board.slideLeft();

    var after_pieces = [_][num_cols]usize{
        [_]usize{ 4, 8, 8, 2, 0, 0 },
        [_]usize{ 4, 4, 0, 0, 0, 0 },
        [_]usize{ 4, 8, 0, 0, 0, 0 },
        [_]usize{ 4, 4, 0, 0, 0, 0 },
    };
    const ap = &[_][]usize{ &after_pieces[0], &after_pieces[1], &after_pieces[2], &after_pieces[3] };
    try std.testing.expect(checkPiecesEqual(board.pieces, ap));
}

test "slide left one row" {
    const num_cols = 10;
    const num_rows = 1;
    var pieces = [_][num_cols]usize{[_]usize{ 2, 2, 4, 8, 16, 16, 2, 2, 4, 4 }};

    const p = &[_][]usize{&pieces[0]};
    const board = Board{
        .pieces = p,
        .drawer = undefined,
        .num_rows = num_rows,
        .num_cols = num_cols,
    };
    try board.slideLeft();

    var after_pieces = [_][num_cols]usize{[_]usize{ 4, 4, 8, 32, 4, 8, 0, 0, 0, 0 }};
    const ap = &[_][]usize{&after_pieces[0]};
    try std.testing.expect(checkPiecesEqual(board.pieces, ap));
}

test "slide left row no merge" {
    const num_cols = 11;
    const num_rows = 1;
    var pieces = [_][num_cols]usize{[_]usize{ 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048 }};

    const p = &[_][]usize{&pieces[0]};
    const board = Board{
        .pieces = p,
        .drawer = undefined,
        .num_rows = num_rows,
        .num_cols = num_cols,
    };
    try board.slideLeft();

    var after_pieces = [_][num_cols]usize{[_]usize{ 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048 }};
    const ap = &[_][]usize{&after_pieces[0]};
    try std.testing.expect(checkPiecesEqual(board.pieces, ap));
}

test "slide right" {
    const num_cols = 6;
    const num_rows = 4;
    var pieces = [_][num_cols]usize{
        [_]usize{ 2, 2, 8, 4, 4, 2 },
        [_]usize{ 2, 0, 2, 0, 0, 4 },
        [_]usize{ 0, 2, 2, 0, 8, 0 },
        [_]usize{ 2, 0, 2, 4, 0, 0 },
    };
    const p = &[_][]usize{ &pieces[0], &pieces[1], &pieces[2], &pieces[3] };

    const board = Board{
        .pieces = p,
        .drawer = undefined,
        .num_rows = num_rows,
        .num_cols = num_cols,
    };
    try board.slideRight();

    var after_pieces = [_][num_cols]usize{
        [_]usize{ 0, 0, 4, 8, 8, 2 },
        [_]usize{ 0, 0, 0, 0, 4, 4 },
        [_]usize{ 0, 0, 0, 0, 4, 8 },
        [_]usize{ 0, 0, 0, 0, 4, 4 },
    };
    const ap = &[_][]usize{ &after_pieces[0], &after_pieces[1], &after_pieces[2], &after_pieces[3] };
    try std.testing.expect(checkPiecesEqual(board.pieces, ap));
}

test "slide right one row" {
    const num_cols = 10;
    const num_rows = 1;
    var pieces = [_][num_cols]usize{[_]usize{ 2, 2, 4, 8, 16, 16, 2, 2, 4, 4 }};

    const p = &[_][]usize{&pieces[0]};
    const board = Board{
        .pieces = p,
        .drawer = undefined,
        .num_rows = num_rows,
        .num_cols = num_cols,
    };
    try board.slideRight();

    var after_pieces = [_][num_cols]usize{[_]usize{ 0, 0, 0, 0, 4, 4, 8, 32, 4, 8 }};
    const ap = &[_][]usize{&after_pieces[0]};
    try std.testing.expect(checkPiecesEqual(board.pieces, ap));
}

test "slide left row no merge" {
    const num_cols = 11;
    const num_rows = 1;
    var pieces = [_][num_cols]usize{[_]usize{ 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048 }};

    const p = &[_][]usize{&pieces[0]};
    const board = Board{
        .pieces = p,
        .drawer = undefined,
        .num_rows = num_rows,
        .num_cols = num_cols,
    };
    try board.slideRight();

    var after_pieces = [_][num_cols]usize{[_]usize{ 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048 }};
    const ap = &[_][]usize{&after_pieces[0]};
    try std.testing.expect(checkPiecesEqual(board.pieces, ap));
}

test "tiny boards" {
    const num_cols = 1;
    const num_rows = 1;
    var pieces = [_][num_cols]usize{
        [_]usize{2},
    };
    const p = &[_][]usize{&pieces[0]};

    var after_pieces = [_][num_cols]usize{
        [_]usize{2},
    };
    const ap = &[_][]usize{&after_pieces[0]};

    const board = Board{
        .pieces = p,
        .drawer = undefined,
        .num_rows = num_rows,
        .num_cols = num_cols,
    };
    try board.slideRight();
    try std.testing.expect(checkPiecesEqual(board.pieces, ap));
    try board.slideLeft();
    try std.testing.expect(checkPiecesEqual(board.pieces, ap));
    try board.slideUp();
    try std.testing.expect(checkPiecesEqual(board.pieces, ap));
    try board.slideDown();
    try std.testing.expect(checkPiecesEqual(board.pieces, ap));
}

test "empty boards" {
    const num_rows = 0;
    const num_cols = 0;
    var pieces = [_][num_cols]usize{
        [_]usize{},
    };
    const p = &[_][]usize{&pieces[0]};

    var after_pieces = [_][num_cols]usize{
        [_]usize{},
    };
    const ap = &[_][]usize{&after_pieces[0]};

    const board = Board{
        .pieces = p,
        .drawer = undefined,
        .num_rows = num_rows,
        .num_cols = num_cols,
    };
    try board.slideRight();
    try std.testing.expect(checkPiecesEqual(board.pieces, ap));
    try board.slideLeft();
    try std.testing.expect(checkPiecesEqual(board.pieces, ap));
    try board.slideUp();
    try std.testing.expect(checkPiecesEqual(board.pieces, ap));
    try board.slideDown();
    try std.testing.expect(checkPiecesEqual(board.pieces, ap));
}
