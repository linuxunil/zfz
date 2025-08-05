//! By convention, root.zig is the root source file when making a library. If
//! you are making an executable, the convention is to delete this file and
//! start with main.zig instead.
const std = @import("std");
const testing = std.testing;

pub const Match = struct {
    term: []const u8,
    score: u8,

    pub fn compareScore(context: void, a: Match, b: Match) bool {
        _ = context;
        return a.score > b.score;
    }
};
pub const Matrix = struct {
    data: []u8,
    rows: usize,
    cols: usize,
    score: u8,
    allocator: std.mem.Allocator,

    pub fn get(self: *Matrix, row: usize, col: usize) u8 {
        return self.data[row * self.cols + col];
    }

    pub fn set(self: *Matrix, row: usize, col: usize, value: u8) void {
        self.data[row * self.cols + col] = value;
    }

    fn init(allocator: std.mem.Allocator, str1: []const u8, str2: []const u8) !Matrix {
        const rows = str2.len + 2;
        const cols = str1.len + 2;

        const data = try allocator.alloc(u8, rows * cols);
        @memset(data, 0);

        data[0 * cols + 0] = ' ';
        data[0 * cols + 1] = ' ';
        data[1 * cols + 0] = ' ';
        // Fill header row with str1 characters starting at column 1
        for (str1, 0..) |char, i| {
            data[0 * cols + (i + 2)] = char;
        }

        // Fill header column with str2 characters starting at row 1
        for (str2, 0..) |char, i| {
            data[(i + 2) * cols + 0] = char;
        }

        return Matrix{
            .data = data,
            .rows = rows,
            .cols = cols,
            .score = 0,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Matrix) void {
        self.allocator.free(self.data);
    }

    fn findMax(self: *Matrix) u8 {
        var max_score: u8 = 0;
        var max_row: usize = 0;
        var max_col: usize = 0;

        for (2..self.rows) |row| {
            for (2..self.cols) |col| {
                const score = self.get(row, col);
                if (score > max_score) {
                    max_score = score;
                    max_row = row;
                    max_col = col;
                }
            }
        }
        return max_score;
    }
    fn scoreMatrix(self: *Matrix) void {
        for (2..self.rows) |row| {
            for (2..self.cols) |col| {
                self.scoreCell(row, col);
            }
        }
        self.score = self.findMax();
    }
    pub fn getScore(self: *Matrix) u8 {
        self.scoreMatrix();
        return self.score;
    }
    fn scoreCell(self: *Matrix, row: usize, col: usize) void {
        const match_score: i32 = 16;
        const mismatch_score: i32 = -16;
        const gap_penalty: i32 = -1;

        // Check for match
        const match = (self.get(row, 0) == self.get(0, col));
        const cell = self.getNeighbors(row, col);
        // Calculate Left
        const left = @as(i32, cell.left) + gap_penalty;
        // Calculate Up
        const up = @as(i32, cell.up) + gap_penalty;
        // Calculate Diagonal (Up Left)
        const up_left = @as(i32, cell.up_left) + if (match) match_score else mismatch_score;

        const score = @max(up_left, left, up, 0);

        self.set(row, col, @intCast(score));
    }
    fn getNeighbors(self: *Matrix, row: usize, col: usize) struct { current: u8, up: u8, left: u8, up_left: u8 } {
        return .{
            .current = self.get(row, col),
            .up_left = self.get(row - 1, col - 1),
            .up = self.get(row - 1, col),
            .left = self.get(row, col - 1),
        };
    }
    pub fn print(self: *Matrix) void {
        std.debug.print("\n{s}\n", .{"--" ** 30});
        for (0..self.rows) |i| {
            for (0..self.cols) |j| {
                if ((i <= 0) or (j <= 0)) {
                    std.debug.print("{c:>5}", .{self.get(i, j)});
                } else {
                    std.debug.print("{d:>5}", .{self.get(i, j)});
                }
            }
            std.debug.print("\n", .{});
        }
        std.debug.print("\n{s}\n", .{"--" ** 30});
    }
    pub fn similarity(lhs: []const u8, rhs: []const u8) !u8 {
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        const alloc = arena.allocator();

        var matrix = try Matrix.init(alloc, lhs, rhs);
        defer matrix.deinit();
        const scores = matrix.getScore();
        // matrix.print();
        return scores;
    }
};

test "unscored matrix cat & ct" {
    const alloc = testing.allocator;
    const expected_matrix = [_]u8{
        ' ', ' ', 'c', 'a', 't', // row 0
        ' ', 0, 0, 0, 0, // row 1
        'c', 0, 0, 0, 0, // row 2
        't', 0, 0, 0, 0, // row 3
    };
    var actual = try Matrix.init(alloc, "cat", "ct");
    defer actual.deinit();
    try std.testing.expectEqualSlices(u8, &expected_matrix, actual.data);
}
test "scored matrix cat & ct" {
    const alloc = testing.allocator;
    const expected_matrix = [_]u8{
        ' ', ' ', 'c', 'a', 't', // row 0
        ' ', 0, 0, 0, 0, // row 1
        'c', 0, 16, 15, 14, // row 2
        't', 0, 15, 14, 31, // row 3
    };
    var actual = try Matrix.init(alloc, "cat", "ct");
    defer actual.deinit();
    actual.scoreMatrix();
    try std.testing.expectEqualSlices(u8, &expected_matrix, actual.data);
}

test "scores" {
    const one = try Matrix.similarity("dog", "fog");
    const two = try Matrix.similarity("test", "best");
    const three = try Matrix.similarity("abc", "def");
    const four = try Matrix.similarity("hello", "hlo");
    const five = try Matrix.similarity("run", "running");
    try testing.expectEqual(one, 32);
    try testing.expectEqual(two, 48);
    try testing.expectEqual(three, 0);
    try testing.expectEqual(four, 46);
    try testing.expectEqual(five, 48);
}
