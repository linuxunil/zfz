const std = @import("std");
const simd = std.simd;
const testing = std.testing;

pub const AntiDiagonalSW = struct {
    seqA: []const u8,
    seqB: []const u8,
    score: i16 = 0,
    max_diag: usize,
    match_score: i16 = 3,
    mismatch_score: i16 = -1,
    gap_penalty: i16 = -2,

    pub fn init(seqA: []const u8, seqB: []const u8) !AntiDiagonalSW {
        return AntiDiagonalSW{
            .seqA = seqA,
            .seqB = seqB,
            .max_diag = @min(seqA.len, seqB.len),
        };
    }
    pub fn scoreMatrix(self: *AntiDiagonalSW) void {
        return switch (self.max_diag) {
            1...16 => self.scoreMatrixWithSize(16),
            17...32 => self.scoreMatrixWithSize(32),
            33...64 => self.scoreMatrixWithSize(64),
            65...128 => self.scoreMatrixWithSize(128),
            else => self.scoreMatrixWithSize(256),
        };
    }
    fn scoreMatrixWithSize(self: *AntiDiagonalSW, comptime VEC_SIZE: u32) void {
        var prev_prev_diag: @Vector(VEC_SIZE, i16) = @splat(0); // 2 diagonals ago
        var prev_diag: @Vector(VEC_SIZE, i16) = @splat(0); // what we just scored
        const gap_score: @Vector(VEC_SIZE, i16) = @splat(self.gap_penalty);
        const match: @Vector(VEC_SIZE, i16) = @splat(self.match_score);
        const mismatch: @Vector(VEC_SIZE, i16) = @splat(self.mismatch_score);
        var match_mask: @Vector(VEC_SIZE, bool) = @splat(false); // the matches for this anti-diagonal

        const total_diag = self.seqA.len + self.seqB.len - 1;

        for (0..total_diag) |diag| {
            // Fill Match mask
            const first_cell = if (diag < self.seqB.len) 0 else diag - self.seqB.len + 1;
            const last_cell = @min(diag + 1, self.seqA.len);
            const diag_length = last_cell - first_cell;

            std.debug.print("\nDiag {}: first_cell={}, last_cell={}, diag_length={}\n", .{ diag, first_cell, last_cell, diag_length });
            match_mask = @splat(false);
            // TODO: Need to start from the middle of the vector and expand out
            // cell starts at

            //
            //
            // for (0..diag_length) |cell| {
            //     const i = first_cell + cell;
            //     const j = diag - i;
            //     std.debug.print("  k={}: i={}, j={}, seqA[{}]='{c}', seqB[{}]='{c}', match={}\n", .{ cell, i, j, i, self.seqA[i], j, self.seqB[j], self.seqA[i] == self.seqB[j] });
            //     match_mask[cell] = (self.seqA[i] == self.seqB[j]);
            // }

            //FIXME: The current implementation doesn't account for the starting position
            // We need to either setup gauds to shift the positions based on the changing
            // starting position.
            //Upscore is the previous row shifted <- one.
            const upscore = simd.shiftElementsRight(prev_diag, 1, 0) + gap_score;
            //Leftscore is the previous diag
            const leftscore = prev_diag + gap_score;
            // Matchscore is the match_mask made previously
            const matchscore = @select(i16, match_mask, match, mismatch);
            //Diagscore is previous previous shifted <- one
            const upleftscore = simd.shiftElementsRight(prev_prev_diag, 1, 0) + matchscore;
            // Reset current line
            var scores: @Vector(VEC_SIZE, i16) = @splat(0); // what we are currently scoring
            // Fine the max of each line and put it in that spot for the current diag.
            scores = @max(@max(@max(upscore, leftscore), upleftscore), scores);

            // Debug print diagonal values
            // std.debug.print("\nDiag {}: ", .{diag});
            // for (0..len) |k| {
            //     std.debug.print("{} ", .{current_diag[k]});
            // }

            // Find our highest scoring cell
            const score = @reduce(.Max, scores);
            std.debug.print("  Calcs: {}\n  matchscore= {:<2}\n  upscore=    {:<2}\n  leftscore=  {:<2}\n  upleftscore={:<2}\n  scores=     {:<2}\n  ", .{
                diag,
                matchscore,
                upscore,
                leftscore,
                upleftscore,
                scores,
            });
            // If its our highest score make it the current high_score
            if (self.score < score) {
                self.score = score;
            }
            std.debug.print("  Pre Swap: {}\n  prev_prev=  {:<2}\n  prev_diag=  {:<2}\n ", .{ diag, prev_prev_diag, prev_diag });
            prev_prev_diag = prev_diag; // using lefscore because it is the unshifted previous
            prev_diag = scores; // Current line becomes the previous line.

            std.debug.print("  After Swap: {}\n  prev_prev=  {:<2}\n  prev_diag=  {:<2}\n S/HS=       {}/{}\n", .{
                diag,  prev_prev_diag, prev_diag,
                score, self.score,
            });
            // prev_diag_match = prev_diag + @select(i16, match_mask, match_score, mismatch_score);
            // shifted_prev_diag = simd.shiftElementsRight(prev_diag, 1, 0);
            // prev_diag = prev_diag + gap_score;
            //
            // current_diag = @max(@max(@max(prev_prev_diag, prev_diag), prev_diag_match), shifted_prev_diag);
            //
            // const score = @reduce(.Max, current_diag);
            // if (score > self.score) {
            //     self.score = score;
            // }
            //
            // prev_prev_diag = shifted_prev_diag;
            // prev_diag = current_diag;
        }
    }

    pub fn similarity(seqA: []const u8, seqB: []const u8) !i16 {
        var matrix = try AntiDiagonalSW.init(seqA, seqB);
        matrix.scoreMatrix();
        return matrix.score;
    }
};
// test "AntiDiagonal basic test cases" {
//     try test_cases.runAllTestCases(AntiDiagonalSW);
// }
//
// test "AntiDiagonal vector size test cases" {
//     try test_cases.runVectorSizeTests(AntiDiagonalSW);
// }
