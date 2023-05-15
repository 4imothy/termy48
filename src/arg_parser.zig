const std = @import("std");
const buf_wrtr = @import("main.zig").buf_wrtr;
const errors = @import("errors.zig");

const Data = struct {
    start_game: bool,
    num_rows: usize,
    num_cols: usize,
    piece_width: u8,
    piece_height: u8,
};

const help_info =
    \\ -h: help
    \\ -r: number of rows
    \\ -c: number of columns
    \\ -w: width of pieces
    \\ -h: height of pieces
    \\ *example*: ./termy48 -r=4 -c=4 -w=11 -h=5
;

pub fn parseArgs(allocator: std.mem.Allocator) !Data {
    var data = Data{
        .start_game = true,
        .num_rows = 4,
        .num_cols = 4,
        .piece_width = 11,
        .piece_height = 5,
    };
    var args = try std.process.argsWithAllocator(allocator);
    // throw away the exe info
    _ = args.next();
    while (args.next()) |arg| {
        if (std.mem.eql(u8, "-h", arg)) {
            data.start_game = false;
            try buf_wrtr.print("{s}\n", .{help_info});
            return data;
        } else if (std.mem.startsWith(u8, arg, "-r")) {
            if (!try parseArgForValue(arg, &data.num_rows, usize)) {
                data.start_game = false;
                return data;
            }
        } else if (std.mem.startsWith(u8, arg, "-c")) {
            if (!try parseArgForValue(arg, &data.num_cols, usize)) {
                data.start_game = false;
                return data;
            }
        } else if (std.mem.startsWith(u8, arg, "-w")) {
            if (!try parseArgForValue(arg, &data.piece_width, u8)) {
                data.start_game = false;
                return data;
            }
        } else if (std.mem.startsWith(u8, arg, "-h")) {
            if (!try parseArgForValue(arg, &data.piece_height, u8)) {
                data.start_game = false;
                return data;
            }
        } else {
            try buf_wrtr.print(errors.unknown_argument, .{arg});
            data.start_game = false;
            return data;
        }
    }

    return data;
}

fn parseArgForValue(arg: []const u8, field: anytype, dest: anytype) !bool {
    if (std.mem.indexOf(u8, arg, "=")) |i| {
        field.* = std.fmt.parseInt(@TypeOf(field.*), arg[i + 1 ..], 0) catch {
            try buf_wrtr.print(errors.unable_to_parse, .{ arg[i + 1 ..], dest, arg });
            return false;
        };
    } else {
        try buf_wrtr.print(errors.no_equals_setting_arg, .{arg});
        return false;
    }
    return true;
}
