const std = @import("std");
const simd = std.simd;
const testing = std.testing;

pub const ShiftSW = struct {
    alloc: std.mem.Allocator,
    seqA: []const u8,
    seqB: []const u8,
    score: i16 = 0,
    max_diag: usize,
    match_score: i16 = 3,
    mismatch_score: i16 = 1,
    gap_penalty: i16 = -2,

    pub fn init(alloc: std.mem.Allocator, seqA: []const u8, seqB: []const u8) !ShiftSW {
        return ShiftSW{
            .alloc = alloc,
            .seqA = seqA,
            .seqB = seqB,
            .max_diag = @min(seqA.len, seqB.len),
        };
    }

    pub fn scoreMatrixWithSize(self: *ShiftSW, comptime VEC_SIZE: u32) !void {
        var prev_row_scores = try self.alloc.alloc(i16, self.seqB.len + VEC_SIZE);
        defer self.alloc.free(prev_row_scores);
        var vertical_gap_scores = try self.alloc.alloc(i16, self.seqB.len + VEC_SIZE);
        defer self.alloc.free(vertical_gap_scores);

        @memset(prev_row_scores, 0);
        @memset(vertical_gap_scores, self.gap_penalty);

        std.debug.print("\n=== ROW-WISE SW: {} x {} ===\n", .{ self.seqA.len, self.seqB.len });
        std.debug.print("seqA (rows): \"{s}\"\n", .{self.seqA});
        std.debug.print("seqB (cols): \"{s}\"\n", .{self.seqB});

        // Process seqA.len rows (each row compares against one character of seqA)
        for (0..self.seqA.len) |row_idx| {
            var col_idx: usize = 0;
            while (col_idx < self.seqB.len) : (col_idx += VEC_SIZE) {
                self.processVectorChunk(row_idx, col_idx, VEC_SIZE, &prev_row_scores, &vertical_gap_scores);
            }

            // Print current row after processing
            std.debug.print("Row {} (seqA[{}]='{}') scores: ", .{ row_idx, row_idx, self.seqA[row_idx] });
            for (0..self.seqB.len) |j| {
                std.debug.print("{:3} ", .{prev_row_scores[j]});
            }
            std.debug.print("\n", .{});
        }
        std.debug.print("Final max score: {}\n", .{self.score});
    }
    fn processVectorChunk(
        self: *ShiftSW,
        row_index: usize,
        col_start: usize,
        comptime VEC_SIZE: u32,
        prev_row_scores: *[]i16,
        vertical_gap_scores: *[]i16,
    ) void {
        var prev_row_vector: @Vector(VEC_SIZE, i16) = undefined;
        var vertical_gap_vector: @Vector(VEC_SIZE, i16) = undefined;

        for (0..VEC_SIZE) |pos| {
            if (col_start + pos < prev_row_scores.*.len) {
                prev_row_vector[pos] = prev_row_scores.*[col_start + pos];
                vertical_gap_vector[pos] = vertical_gap_scores.*[col_start + pos];
            } else {
                prev_row_vector[pos] = 0;
                vertical_gap_vector[pos] = 0;
            }
        }

        var match_mismatch_scores: @Vector(VEC_SIZE, i16) = @splat(self.mismatch_score);
        for (0..VEC_SIZE) |pos| {
            if (col_start + pos < self.seqB.len and row_index < self.seqA.len) {
                if (self.seqA[row_index] == self.seqB[col_start + pos]) {
                    match_mismatch_scores[pos] = self.match_score;
                }
            }
        }

        // Need to process elements sequentially to handle left dependencies
        var left_neighbor_score: i16 = if (col_start == 0) 0 else self.gap_penalty; // Carry-over from previous chunk

        for (0..VEC_SIZE) |pos| {
            if (col_start + pos >= self.seqB.len) break;

            // Calculate three scores for this position
            const diagonal_score = prev_row_vector[pos] + match_mismatch_scores[pos]; // diagonal + match/mismatch
            const from_above_score = prev_row_vector[pos] + self.gap_penalty; // from above + gap
            const from_left_score = left_neighbor_score + self.gap_penalty; // from left + gap

            // Smith-Waterman max of all options including 0
            const current_cell_score = @max(@max(@max(diagonal_score, from_above_score), from_left_score), 0);

            // Update arrays
            prev_row_scores.*[col_start + pos] = current_cell_score;
            vertical_gap_scores.*[col_start + pos] = @max(from_above_score, vertical_gap_vector[pos] + self.gap_penalty); // vertical gap extension
            self.score = @max(self.score, current_cell_score);

            // Update left carry-over for next element
            left_neighbor_score = current_cell_score;
        }
    }
    fn scoreMatrix(self: *ShiftSW) !void {
        return switch (self.max_diag) {
            1...16 => try self.scoreMatrixWithSize(16),
            17...32 => try self.scoreMatrixWithSize(32),
            // 33...64 => self.scoreMatrixWithSize(64),
            else => try self.scoreMatrixWithSize(64),
            // 65...128 => self.scoreMatrixWithSize(128),
            // 129...256 => self.scoreMatrixWithSize(256),
            // else => self.scoreMatrixWithSize(512),
        };
    }
    pub fn similarity(seqA: []const u8, seqB: []const u8) !i16 {
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        const alloc = arena.allocator();
        var matrix = try ShiftSW.init(alloc, seqA, seqB);
        try matrix.scoreMatrix();
        return matrix.score;
    }
    pub fn getScore(self: *ShiftSW) i16 {
        return self.score orelse 0;
    }
};
// test "GCGATTA & GCTTAC" {
//     const seqA = "GCGATTA";
//     const seqB = "GCTTAC";
//
//     const score = try ShiftSW.similarity(seqA, seqB);
//     try testing.expectEqual(11, score);
// }
//
// test "CTACGCTATTTCA & CTATCTCGCTATCCA" {
//     const seqA = "CTACGCTATTTCA";
//     const seqB = "CTATCTCGCTATCCA";
//
//     const score = try ShiftSW.similarity(seqA, seqB);
//     try testing.expectEqual(25, score);
// }
//
// test "Matrix Orientation Verification - Small Test" {
//     const seqA = "GAT";
//     const seqB = "GCT";
//
//     std.debug.print("\n=== MATRIX ORIENTATION TEST ===\n", .{});
//
//     // Test basic implementation
//     const basic_score = try @import("basic_sw.zig").Matrix.similarity(seqA, seqB);
//     std.debug.print("Basic SW score: {}\n", .{basic_score});
//
//     // Test row-wise implementation
//     const rowwise_score = try ShiftSW.similarity(seqA, seqB);
//     std.debug.print("Row-wise SW score: {}\n", .{rowwise_score});
//
//     // They should match
//     try testing.expectEqual(basic_score, rowwise_score);
// }
