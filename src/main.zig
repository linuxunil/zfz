//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.
const std = @import("std");
const Matrix = @import("zfz_lib").Matrix;
const Match = @import("zfz_lib").Match;
const testing = std.testing;
const Walker = std.fs.Dir.Walker;
const print = std.debug.print;

pub fn main() !void {
    // const cwd = std.fs.cwd();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const alloc = arena.allocator();

    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    const search_term = args[1];
    const search_list = args[2..];
    var scores = std.ArrayList(Match).init(alloc);
    defer scores.deinit();

    for (search_list) |term| {
        const score = try Matrix.similarity(search_term, term);
        try scores.append(.{ .term = term, .score = score });
    }

    std.mem.sort(Match, scores.items, {}, Match.compareScore);
    for (scores.items) |term| {
        std.debug.print("{s} {d}\n", .{ term.term, term.score });
    }
}
