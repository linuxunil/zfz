pub const bsw = @import("basic_sw.zig");
pub const ssw = @import("shift_sw.zig");
pub const adsw = @import("anti_diagonal_sw.zig");

const test_cases = @import("test_cases.zig");

test "all" {
    _ = @import("basic_sw.zig");
    _ = @import("shift_sw.zig");
    _ = @import("anti_diagonal_sw.zig");
}

test "matrix test cases" {
    try test_cases.runAllTestCases(bsw.Matrix);
}

test "matrix vector size test cases" {
    try test_cases.runVectorSizeTests(bsw.Matrix);
}

test "shift basic test cases" {
    try test_cases.runAllTestCases(ssw.ShiftSW);
}

test "shift vector size test cases" {
    try test_cases.runVectorSizeTests(ssw.ShiftSW);
}
test "AntiDiagonal basic test cases" {
    try test_cases.runAllTestCases(adsw.AntiDiagonalSW);
}

test "AntiDiagonal vector size test cases" {
    try test_cases.runVectorSizeTests(adsw.AntiDiagonalSW);
}
