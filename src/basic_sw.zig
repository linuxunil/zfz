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
    match_score: i32 = 3,
    mismatch_score: i32 = -1,
    gap_penalty: i32 = -2,

    pub fn get(self: *Matrix, row: usize, col: usize) u8 {
        return self.data[row * self.cols + col];
    }

    pub fn set(self: *Matrix, row: usize, col: usize, value: u8) void {
        self.data[row * self.cols + col] = value;
    }

    fn init(allocator: std.mem.Allocator, seqA: []const u8, seqB: []const u8) !Matrix {
        const rows = seqA.len + 2;
        const cols = seqB.len + 2;
        const data_size = rows * cols;

        var data = try allocator.alloc(u8, data_size);
        @memset(data, 0);

        data[0 * cols + 0] = ' ';
        data[0 * cols + 1] = ' ';
        data[1 * cols + 0] = ' ';

        // Column Header (seq b)
        for (seqB, 2..) |char, i| {
            data[0 * cols + i] = char;
        }

        // Row Header (seq a)
        for (seqA, 2..) |char, i| {
            data[i * cols + 0] = char;
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
        // Check for match
        const match = (self.get(row, 0) == self.get(0, col));
        const cell = self.getNeighbors(row, col);
        // Calculate Left
        const left = @as(i32, cell.left) + self.gap_penalty;
        // Calculate Up
        const up = @as(i32, cell.up) + self.gap_penalty;
        // Calculate Diagonal (Up Left)
        const up_left = @as(i32, cell.up_left) + if (match) self.match_score else self.mismatch_score;

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
        // Printing disabled
        _ = self;
    }
    pub fn similarity(lhs: []const u8, rhs: []const u8) !u8 {
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        const alloc = arena.allocator();

        var matrix = try Matrix.init(alloc, lhs, rhs);
        defer matrix.deinit();
        
        // Debug printing disabled
        
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
    var actual = try Matrix.init(alloc, "ct", "cat");
    defer actual.deinit();
    try std.testing.expectEqualSlices(u8, &expected_matrix, actual.data);
}
test "GCGATTA & GCTTAC" {
    const seqA = "GCGATTA";
    const seqB = "GCTTAC";
    const alloc = testing.allocator;
    const expected_matrix = [_]u8{
        ' ', ' ', 'G', 'C', 'T', 'T', 'A', 'C',
        ' ', 0,   0,   0,   0,   0,   0,   0,
        'G', 0,   3,   1,   0,   0,   0,   0,
        'C', 0,   1,   6,   4,   2,   0,   3,
        'G', 0,   3,   4,   5,   3,   1,   1,
        'A', 0,   1,   2,   3,   4,   6,   4,
        'T', 0,   0,   0,   5,   6,   4,   5,
        'T', 0,   0,   0,   3,   8,   6,   4,
        'A', 0,   0,   0,   1,   6,   11,  9,
    };

    var actual = try Matrix.init(alloc, seqA, seqB);
    defer actual.deinit();
    actual.scoreMatrix();
    try testing.expectEqualSlices(u8, &expected_matrix, actual.data);
    const score = try Matrix.similarity(seqA, seqB);
    try testing.expectEqual(score, 11);
}

test "CTACGCTATTTCA & CTATCTCGCTATCCA" {
    const seqB = "CTACGCTATTTCA";
    const seqA = "CTATCTCGCTATCCA";
    const alloc = testing.allocator;

    const expected_matrix = [_]u8{
        ' ', ' ', 'C', 'T', 'A', 'C', 'G', 'C', 'T', 'A', 'T', 'T', 'T', 'C', 'A',
        ' ', 0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
        'C', 0,   3,   1,   0,   3,   1,   3,   1,   0,   0,   0,   0,   3,   1,
        'T', 0,   1,   6,   4,   2,   2,   1,   6,   4,   3,   3,   3,   1,   2,
        'A', 0,   0,   4,   9,   7,   5,   3,   4,   9,   7,   5,   3,   2,   4,
        'T', 0,   0,   3,   7,   8,   6,   4,   6,   7,   12,  10,  8,   6,   4,
        'C', 0,   3,   1,   5,   10,  8,   9,   7,   5,   10,  11,  9,   11,  9,
        'T', 0,   1,   6,   4,   8,   9,   7,   12,  10,  8,   13,  14,  12,  10,
        'C', 0,   3,   4,   5,   7,   7,   12,  10,  11,  9,   11,  12,  17,  15,
        'G', 0,   1,   2,   3,   5,   10,  10,  11,  9,   10,  9,   10,  15,  16,
        'C', 0,   3,   1,   1,   6,   8,   13,  11,  10,  8,   9,   8,   13,  14,
        'T', 0,   1,   6,   4,   4,   6,   11,  16,  14,  13,  11,  12,  11,  12,
        'A', 0,   0,   4,   9,   7,   5,   9,   14,  19,  17,  15,  13,  11,  14,
        'T', 0,   0,   3,   7,   8,   6,   7,   12,  17,  22,  20,  18,  16,  14,
        'C', 0,   3,   1,   5,   10,  8,   9,   10,  15,  20,  21,  19,  21,  19,
        'C', 0,   3,   2,   3,   8,   9,   11,  9,   13,  18,  19,  20,  22,  20,
        'A', 0,   1,   2,   5,   6,   7,   9,   10,  12,  16,  17,  18,  20,  25,
    };
    var actual = try Matrix.init(alloc, seqA, seqB);
    defer actual.deinit();
    actual.scoreMatrix();
    try testing.expectEqualSlices(u8, &expected_matrix, actual.data);
    const score = try Matrix.similarity(seqA, seqB);
    try testing.expectEqual(score, 25);
}
