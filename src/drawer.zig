// SPDX-License-Identifier: GPL-3.0

const main = @import("main.zig");
const f = @import("formats.zig");
const allocator = main.allocator;
const std = @import("std");
const buf_wrtr = main.buf_wrtr;
const Board = @import("Board.zig");

const BG_STYLING_LEN: u8 = 5;
const Drawer = @This();

piece_width: u8,
piece_height: u8,
draw_start_x: usize,
draw_start_y: usize,
screen_width: usize,
screen_height: usize,
game_height: usize,
game_width: usize,

pub fn init(num_cols: usize, num_rows: usize, piece_width: u8, piece_height: u8, screen_width: usize, screen_height: usize) !Drawer {
    const game_width = num_cols * piece_width;
    const game_height = num_rows * piece_height;
    const draw_start_x: usize = (screen_width / 2) - (game_width / 2);
    const draw_start_y: usize = (screen_height / 2) - (game_height / 2);
    try buf_wrtr.print(f.clear_page, .{});
    _ = try drawBorders(draw_start_x, draw_start_y, game_width, game_height);
    return Drawer{
        .piece_width = piece_width,
        .piece_height = piece_height,
        .draw_start_x = draw_start_x,
        .draw_start_y = draw_start_y,
        .screen_width = screen_width,
        .screen_height = screen_height,
        .game_height = game_height,
        .game_width = game_width,
    };
}

pub fn drawGameOver(self: Drawer) !void {
    try buf_wrtr.print(f.reset, .{});
    const len: u8 = 19;
    const x_index = self.screen_width / 2 - (len / 2) + 1;
    try buf_wrtr.print(f.set_cursor_pos, .{ self.screen_height / 2, x_index });
    try buf_wrtr.print("┌─────────────────┐\n", .{});
    try buf_wrtr.print(f.set_cursor_x, .{x_index});
    try buf_wrtr.print("│    Game Over    │\n", .{});
    try buf_wrtr.print(f.set_cursor_x, .{x_index});
    try buf_wrtr.print("│ Press q to quit │\n", .{});
    try buf_wrtr.print(f.set_cursor_x, .{x_index});
    try buf_wrtr.print("└─────────────────┘\n", .{});
}

pub fn drawBoard(self: Drawer, board: *const Board) !void {
    try buf_wrtr.print(f.set_cursor_pos, .{ self.draw_start_y + 1, self.draw_start_x + 1 });
    const blanks: []u8 = try allocator.alloc(u8, self.piece_width);
    for (blanks) |*elem| {
        elem.* = ' ';
    }
    for (board.pieces) |row| {
        try buf_wrtr.print(f.set_cursor_x, .{self.draw_start_x + 1});
        // one traversal to get the numbers
        // allocate num_cols * piece_width + 5, 5 for the coloring
        // this ends on a new line
        try self.drawBlanksTill(row, blanks, self.piece_height / 2);
        if (self.piece_height > 0) {
            try buf_wrtr.print(f.set_cursor_x, .{self.draw_start_x + 1});
            try buf_wrtr.print("{s}{s}", .{ f.bold, f.black_fg });
            for (row) |v| {
                if (v != 0) {
                    const line = try replaceCenterWithNumber(v, blanks);
                    try buf_wrtr.print("{s}{s}", .{ f.getStyles(v), line });
                    allocator.free(line);
                } else {
                    // doesn't work despite no warning about the int value being too large
                    // blanks[blanks.len / 2] = '·';
                    blanks[blanks.len / 2] = '~';
                    try buf_wrtr.print("{s}{s}{s}{s}", .{ f.getStyles(v), f.white_fg, blanks, f.black_fg });
                    blanks[blanks.len / 2] = ' ';
                }
            }
        }
        try buf_wrtr.print("\n", .{});
        try self.drawBlanksTill(row, blanks, self.piece_height - 1 - (self.piece_height / 2));
    }
    allocator.free(blanks);
}

fn drawBlanksTill(self: Drawer, row: []usize, blanks: []u8, limit: u8) !void {
    var idx: usize = 0;
    while (idx < limit) {
        try buf_wrtr.print(f.set_cursor_x, .{self.draw_start_x + 1});
        for (row) |v| {
            // print the blank styling
            try buf_wrtr.print("{s}{s}", .{ f.getStyles(v), blanks });
        }
        try buf_wrtr.print("\n", .{});
        idx += 1;
    }
}

var holder: [@sizeOf(usize) * 8]u8 = undefined;
fn replaceCenterWithNumber(num: usize, blanks: []u8) ![]const u8 {
    // const line = allocator.alloc(u8, blanks.len);
    const line = try allocator.alloc(u8, blanks.len);
    const center = line.len / 2;
    const str_num = try std.fmt.bufPrint(&holder, "{d}", .{num});
    // catches error of a piece is too tiny than just replace whole thing
    // rather than ending game
    const start_replace = std.math.sub(usize, center, (str_num.len / 2)) catch 0;
    const end_replace = center + ((str_num.len - 1) / 2);
    var num_idx: usize = 0;
    for (line) |_, i| {
        if (i < start_replace or i > end_replace) {
            line[i] = ' ';
        } else {
            line[i] = str_num[num_idx];
            num_idx += 1;
        }
    }
    return line;
}

fn drawBorders(draw_start_x: usize, draw_start_y: usize, game_width: usize, game_height: usize) !void {
    // set the cursor to correct position and styling
    try buf_wrtr.print(f.set_cursor_pos, .{ draw_start_y, draw_start_x });
    try buf_wrtr.print(f.reset, .{});

    // start drawing the borders
    try buf_wrtr.print("┌", .{});
    var i: usize = 0;
    while (i < game_width) {
        try buf_wrtr.print("─", .{});
        i += 1;
    }
    try buf_wrtr.print("┐", .{});
    try buf_wrtr.print("\n", .{});
    i = 0;
    while (i < game_height) {
        try buf_wrtr.print(f.set_cursor_x, .{draw_start_x});
        try buf_wrtr.print("│", .{});
        try buf_wrtr.print(f.set_cursor_x, .{draw_start_x + game_width + 1});
        try buf_wrtr.print("│\n", .{});
        i += 1;
    }
    try buf_wrtr.print(f.set_cursor_x, .{draw_start_x});
    try buf_wrtr.print("└", .{});
    i = 0;
    while (i < game_width) {
        try buf_wrtr.print("─", .{});
        i += 1;
    }
    try buf_wrtr.print("┘", .{});
}
