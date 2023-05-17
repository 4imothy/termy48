// SPDX-License-Identifier: GPL-3.0

const std = @import("std");
// add 60 to make bright colors
// 3X: foreground value
// 4X: background value
// put these in a list and then take the value at that index
// find the associated index and print that
pub const reset = "\x1b[0m";
pub const bold = "\x1b[1m";
// this is bright white, change to 37 for normal
pub const white_fg = "\x1b[97m";
// pub const white_fg = "\x1b[37m";
pub const black_fg = "\x1b[30m";
pub const black_bg = "\x1b[40m";
pub const set_cursor_pos = "\x1B[{};{}H";
pub const set_cursor_x = "\x1B[{}G";
pub const set_cursor_y = "\x1B[{};H";
pub const save_cursor_position = "\x1B[s";
pub const restore_cursor_position = "\x1B[u";
pub const hide_cursor = "\x1B[?25l";
pub const show_cursor = "\x1B[?25h";
pub const clear_page = "\x1B[2J";

// TODO make this also have light backgrounds
pub const bgs = [6]*const [5:0]u8{
    "\x1b[41m", // red bg
    "\x1b[42m", // green bg
    "\x1b[43m", // yellow bg
    "\x1b[44m", // blue bg
    "\x1b[45m", // magenta bg
    "\x1b[46m", // cyan bg
};

pub fn getStyles(val: usize) *const [5:0]u8 {
    if (val == 0) {
        return black_bg;
    }
    var log_2: usize = 8 * @sizeOf(usize) - @clz(val) - 1;
    return bgs[@mod(log_2, bgs.len)];
}
