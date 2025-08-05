//! By convention, root.zig is the root source file when making a library. If
//! you are making an executable, the convention is to delete this file and
//! start with main.zig instead.
const std = @import("std");
const testing = std.testing;

pub const Matrix = struct {
    data: []u8,
    rows: usize,
    cols: usize,
    allocator: std.mem.Allocator,

    pub fn get(self: *Matrix, row: usize, col: usize) u8 {
        return self.data[row * self.cols + col];
    }

    pub fn set(self: *Matrix, row: usize, col: usize, value: u8) void {
        self.data[row * self.cols + col] = value;
    }

    pub fn init(allocator: std.mem.Allocator, str1: []const u8, str2: []const u8) !Matrix {
        const rows = str2.len + 1;
        const cols = str1.len + 1;

        const data = try allocator.alloc(u8, rows * cols);
        @memset(data, ' ');

        // Fill header row with str1 characters starting at column 1
        for (str1, 0..) |char, i| {
            data[0 * cols + (i + 1)] = char;
        }

        // Fill header column with str2 characters starting at row 1
        for (str2, 0..) |char, i| {
            data[(i + 1) * cols + 0] = char;
        }

        return Matrix{
            .data = data,
            .rows = rows,
            .cols = cols,
            .allocator = allocator,
        };
    }
    pub fn deinit(self: *Matrix) void {
        self.allocator.free(self.data);
    }
    pub fn print(self: *Matrix) void {
        for (0..self.rows) |i| {
            for (0..self.cols) |j| {
                std.debug.print("{}", .{self.get(i, j)});
            }
        }
    }
};
test "matrix creation for cat and ct" {
    const allocator = testing.allocator;

    const str1 = "cat";
    const str2 = "ct";

    var matrix = try Matrix.init(allocator, str1, str2);
    defer matrix.deinit();

    const rows = str2.len + 1; // 3
    const cols = str1.len + 1; // 4

    // Test dimensions
    try testing.expect(matrix.data.len == rows * cols);
    try testing.expect(matrix.data.len == 12);

    // Test [0][0] is blank (space)
    try testing.expect(matrix.get(0, 0) == ' ');

    // Test header row (str1 = "cat")
    try testing.expect(matrix.get(0, 1) == 'c');
    try testing.expect(matrix.get(0, 2) == 'a');
    try testing.expect(matrix.get(0, 3) == 't');

    // Test header column (str2 = "ct")
    try testing.expect(matrix.get(1, 0) == 'c');
    try testing.expect(matrix.get(2, 0) == 't');

    // Test data cells are initialized to spaces
    try testing.expect(matrix.get(1, 1) == ' ');
    try testing.expect(matrix.get(1, 2) == ' ');
    try testing.expect(matrix.get(1, 3) == ' ');
    try testing.expect(matrix.get(2, 1) == ' ');
    try testing.expect(matrix.get(2, 2) == ' ');
    try testing.expect(matrix.get(2, 3) == ' ');
}

test "matrix creation for empty strings" {
    const allocator = testing.allocator;

    var matrix = try Matrix.init(allocator, "", "");
    defer matrix.deinit();

    // Should be 1x1 matrix with just the blank [0][0]
    try testing.expect(matrix.data.len == 1);
    try testing.expect(matrix.data[0] == ' ');
}

test "matrix creation for single character strings" {
    const allocator = testing.allocator;

    var matrix = try Matrix.init(allocator, "a", "b");
    defer matrix.deinit();

    // Should be 2x2 matrix
    try testing.expect(matrix.data.len == 4);

    // Test layout:
    // [ ][a]
    // [b][ ]
    try testing.expect(matrix.get(0, 0) == ' ');
    try testing.expect(matrix.get(0, 1) == 'a');
    try testing.expect(matrix.get(1, 0) == 'b');
    try testing.expect(matrix.get(1, 1) == ' ');
}
