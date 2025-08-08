const std = @import("std");
const simd = std.simd;
const testing = std.testing;

pub const ShiftSW = struct {
    seqA: []const u8,
    seqB: []const u8,
    score: ?i16 = 0,
    max_diag: usize,

    pub fn init(seqA: []const u8, seqB: []const u8) !ShiftSW {
        return ShiftSW{
            .seqA = seqA,
            .seqB = seqB,
            .max_diag = @min(seqA.len, seqB.len),
        };
    }

    pub fn scoreMatrixWithSize(self: *ShiftSW, comptime VEC_SIZE: u32) i16 {
        var prev_prev_diag: @Vector(VEC_SIZE, i16) = @splat(0);
        var prev_diag: @Vector(VEC_SIZE, i16) = @splat(0);
        var prev_up: @Vector(VEC_SIZE, i16) = @splat(0);
        var prev_left: @Vector(VEC_SIZE, i16) = @splat(0);
        var max_score: i16 = 0;

        const total_diag = self.seqA.len + self.seqB.len - 1;

        for (0..total_diag) |diag| {
            const start = if (diag < self.seqB.len) 0 else diag - self.seqB.len + 1;
            const end = @min(diag + 1, self.seqA.len);
            const len = end - start;

            var match_mask: @Vector(VEC_SIZE, bool) = @splat(false);
            match_mask = @splat(false);
            for (0..len) |k| {
                const i = start + k;
                const j = diag - i;
                match_mask[k] = (self.seqA[i] == self.seqB[j]);
            }

            const current = ShiftSW.cellScore(VEC_SIZE, prev_diag, prev_up, prev_left, match_mask);
            std.debug.print("Diag {}: len={}, current=[", .{ diag, len });
            for (0..len) |k| {
                std.debug.print("\n\t\tscore={}, pd={}, pu={},, pl={}", .{ @max(max_score, current[k]), prev_diag[k], prev_up[k], prev_left[k] });
                max_score = @max(max_score, current[k]);
            }
            std.debug.print("]\n", .{});
            prev_prev_diag = prev_up;
            prev_diag = prev_up;
            prev_up = current;
            prev_left = simd.shiftElementsRight(current, 1, 0);
        }
        self.score = max_score;
        return max_score;
    }
    fn scoreMatrix(self: *ShiftSW) i16 {
        return switch (self.max_diag) {
            1...16 => self.scoreMatrixWithSize(16),
            17...32 => self.scoreMatrixWithSize(32),
            33...64 => self.scoreMatrixWithSize(64),
            else => self.scoreMatrixWithSize(128),
            // 65...128 => self.scoreMatrixWithSize(128),
            // 129...256 => self.scoreMatrixWithSize(256),
            // else => self.scoreMatrixWithSize(512),
        };
    }

    fn cellScore(comptime VEC_SIZE: u32, prev_diag: @Vector(VEC_SIZE, i16), prev_up: @Vector(VEC_SIZE, i16), prev_left: @Vector(VEC_SIZE, i16), match_mask: @Vector(VEC_SIZE, bool)) @Vector(VEC_SIZE, i16) {
        const match_score: @Vector(VEC_SIZE, i16) = @splat(3);
        const mismatch_score: @Vector(VEC_SIZE, i16) = @splat(-1);
        const gap_penalty: @Vector(VEC_SIZE, i16) = @splat(-2);
        const zero: @Vector(VEC_SIZE, i16) = @splat(0);

        const diag_score = prev_diag + @select(i16, match_mask, match_score, mismatch_score);
        const up_score = prev_up + gap_penalty;
        const left_score = prev_left + gap_penalty;

        const max1 = @max(diag_score, up_score);
        const max2 = @max(left_score, zero);
        return @max(max1, max2);
    }
    pub fn similarity(seqA: []const u8, seqB: []const u8) !i16 {
        var matrix = try ShiftSW.init(seqA, seqB);
        const scores = matrix.scoreMatrix();
        return scores;
    }
    pub fn getScore(self: *ShiftSW) i16 {
        return self.score orelse 0;
    }
};
test "GCGATTA & GCTTAC" {
    const seqA = "GCGATTA";
    const seqB = "GCTTAC";

    const score = try ShiftSW.similarity(seqA, seqB);
    try testing.expectEqual(11, score);
}

test "CTACGCTATTTCA & CTATCTCGCTATCCA" {
    const seqB = "CTACGCTATTTCA";
    const seqA = "CTATCTCGCTATCCA";

    const score = try ShiftSW.similarity(seqA, seqB);
    try testing.expectEqual(25, score);
}
