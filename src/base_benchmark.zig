const std = @import("std");
const sw = @import("root.zig");
const bsw = sw.bsw;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    if (args.len != 3) {
        std.debug.panic("Usage: {s} <seq A> <seq B>\n", .{args[0]});
        std.process.exit(1);
    }

    const seqA = args[1];
    const seqB = args[2];

    const score = try bsw.Matrix.similarity(seqA, seqB);
    std.debug.print("Score: {d}\n", .{score});
}
