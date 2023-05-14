// SPDX-License-Identifier: GPL-3.0

// Do a first print, then restore? No.
// LOGIC: print the border, save the final position, move it the num rows up then print again
// TODO only print the border once to make printing faster
// TODO make the blanks (0) have a · in the center of it
// cant put it in the normal u8, have to make array list
// or print out as itself somehow
// TODO check if the border characters can print on windows correctly

const main = @import("main.zig");
const f = @import("formats.zig");
const allocator = main.allocator;
const std = @import("std");
const buf_wrtr = main.buf_wrtr;
const Board = @import("Board.zig");

const BG_STYLING_LEN: u8 = 5;
const Drawer = @This();

top_border: []u8,
bottom_border: []u8,
piece_width: u8,
piece_height: u8,
draw_start_x: usize,
draw_start_y: usize,
screen_width: usize,
screen_height: usize,

pub fn init(num_cols: usize, piece_width: u8, piece_height: u8, screen_width: usize, screen_height: usize, game_width: usize, game_height: usize) error{OutOfMemory}!Drawer {
    const draw_start_x: usize = (screen_width / 2) - (game_width / 2);
    const draw_start_y: usize = (screen_height / 2) - (game_height / 2);
    return Drawer{
        .piece_width = piece_width,
        .piece_height = piece_height,
        .top_border = try hBorders(true, num_cols, piece_width),
        .bottom_border = try hBorders(false, num_cols, piece_width),
        .draw_start_x = draw_start_x,
        .draw_start_y = draw_start_y,
        .screen_width = screen_width,
        .screen_height = screen_height,
    };
}

pub fn deinit(self: Drawer) void {
    allocator.free(self.top_border);
    allocator.free(self.bottom_border);
}

pub fn drawGameOver(self: Drawer) !void {
    const len: u8 = 13;
    var top = try std.ArrayList(u8).initCapacity(allocator, len);
    var mid = try std.ArrayList(u8).initCapacity(allocator, len);
    var bot = try std.ArrayList(u8).initCapacity(allocator, len);
    try top.appendSlice("┌───────────┐");
    try mid.appendSlice("│ Game Over │");
    try bot.appendSlice("└───────────┘");

    const x_index = self.screen_width / 2 - (len / 2) + 1;
    try buf_wrtr.print(f.set_cursor_pos, .{ self.screen_height / 2, x_index });
    try buf_wrtr.print("{s}\n", .{top.toOwnedSlice()});
    try buf_wrtr.print(f.set_cursor_x, .{x_index});
    try buf_wrtr.print("{s}\n", .{mid.toOwnedSlice()});
    try buf_wrtr.print(f.set_cursor_x, .{x_index});
    try buf_wrtr.print("{s}\n", .{bot.toOwnedSlice()});
    top.deinit();
    mid.deinit();
    bot.deinit();
}

pub fn drawBoard(self: Drawer, board: *const Board) !void {
    // try buf_wrtr.print(f.set_cursor_pos, .{ 10, 0 });
    // believe this is only necesarry if we don't have the not enough space for board error
    // try buf_wrtr.print(f.clear_page, .{});
    // try buf_wrtr.print(f.save_cursor_position, .{});
    const values: []usize = try allocator.alloc(usize, board.num_cols);
    try buf_wrtr.print(f.set_cursor_pos, .{ self.draw_start_y, self.draw_start_x });
    try buf_wrtr.print("{s}\n", .{self.top_border});
    const blanks: []u8 = try allocator.alloc(u8, self.piece_width);
    for (blanks) |*elem| {
        elem.* = ' ';
    }
    const styles: []*const [BG_STYLING_LEN:0]u8 = try allocator.alloc(*const [BG_STYLING_LEN:0]u8, board.num_cols);
    for (board.pieces) |row| {
        try buf_wrtr.print(f.set_cursor_x, .{self.draw_start_x});
        // one traversal to get the numbers
        // allocate num_cols * piece_width + 5, 5 for the coloring
        for (row) |elem, i| {
            values[i] = elem;
            styles[i] = f.getStyles(elem);
        }
        try self.drawBlanksTill(row, styles, blanks, self.piece_height / 2);
        if (self.piece_height > 0) {
            try buf_wrtr.print(f.set_cursor_x, .{self.draw_start_x});
            try buf_wrtr.print("│{s}{s}", .{ f.bold, f.black_fg });
            for (row) |v, i| {
                if (v != 0) {
                    const line = try replaceCenterWithNumber(v, blanks);
                    try buf_wrtr.print("{s}{s}", .{ styles[i], line });
                    allocator.free(line);
                } else {
                    // doesn't work despite no warning about the int value being too large
                    // blanks[blanks.len / 2] = '·';
                    blanks[blanks.len / 2] = '~';
                    try buf_wrtr.print("{s}{s}{s}{s}", .{ styles[i], f.white_fg, blanks, f.black_fg });
                    blanks[blanks.len / 2] = ' ';
                }
            }
            try buf_wrtr.print("{s}│\n", .{f.reset});
        }
        try self.drawBlanksTill(row, styles, blanks, self.piece_height - 1 - (self.piece_height / 2));
    }
    try buf_wrtr.print(f.set_cursor_x, .{self.draw_start_x});
    try buf_wrtr.print("{s}\n\x1b[0m", .{self.bottom_border});
    // try buf_wrtr.print(f.restore_cursor_position, .{});
    allocator.free(values);
}

fn drawBlanksTill(self: Drawer, row: []usize, styles: []*const [BG_STYLING_LEN:0]u8, blanks: []u8, limit: u8) !void {
    var idx: usize = 0;
    while (idx < limit) {
        try buf_wrtr.print(f.set_cursor_x, .{self.draw_start_x});
        try buf_wrtr.print("│{s}{s}", .{ f.bold, f.black_fg });
        for (row) |_, i| {
            // print the blank styling
            try buf_wrtr.print("{s}{s}", .{ styles[i], blanks });
        }
        try buf_wrtr.print("{s}│\n", .{f.reset});
        idx += 1;
    }
}

var holder: [@sizeOf(usize) * 8]u8 = undefined;
fn replaceCenterWithNumber(num: usize, blanks: []u8) ![]const u8 {
    // const line = allocator.alloc(u8, blanks.len);
    const line = try allocator.alloc(u8, blanks.len);
    const center = line.len / 2;
    const str_num = try std.fmt.bufPrint(&holder, "{d}", .{num});
    const start_replace = center - (str_num.len / 2);
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

// make a string of num_cols + 2 (for borders)
fn hBorders(top: bool, num_cols: usize, piece_size: usize) error{OutOfMemory}![]u8 {
    var border = std.ArrayList(u8).init(allocator);
    if (top) {
        try border.appendSlice("┌");
    } else {
        try border.appendSlice("└");
    }
    var i: usize = 0;
    while (i < num_cols * piece_size) {
        try border.appendSlice("─");
        i += 1;
    }
    if (top) {
        try border.appendSlice("┐");
    } else {
        try border.appendSlice("┘");
    }
    return border.toOwnedSlice();
}
