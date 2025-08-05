//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.
const std = @import("std");
const Matrix = @import("zfz_lib").Matrix;
const testing = std.testing;
const Walker = std.fs.Dir.Walker;
const print = std.debug.print;

pub fn main() !void {
    const cwd = std.fs.cwd();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const alloc = arena.allocator();

    var dir = try cwd.openDir(".", .{ .iterate = true });
    defer dir.close();

    var list = std.ArrayList([]const u8).init(alloc);
    defer list.deinit();

    var walk = try dir.walk(alloc);
    defer walk.deinit();

    while (try walk.next()) |w| {
        try list.append(w.basename);
    }

    var matrix = try Matrix.init(alloc, "cat", "ct");
    defer matrix.deinit();
    matrix.print();
}
