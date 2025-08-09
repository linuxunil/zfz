const std = @import("std");
const testing = std.testing;

pub const TestCase = struct {
    seqA: []const u8,
    seqB: []const u8,
    expected_score: i16,
    name: []const u8,
};

pub const test_cases = [_]TestCase{
    .{
        .seqA = "GCGATTA",
        .seqB = "GCTTAC",
        .expected_score = 11,
        .name = "GCGATTA & GCTTAC",
    },
    .{
        .seqA = "CTACGCTATTTCA",
        .seqB = "CTATCTCGCTATCCA",
        .expected_score = 25,
        .name = "CTACGCTATTTCA & CTATCTCGCTATCCA",
    },
};

pub const vector_size_test_cases = [_]TestCase{
    .{
        .seqA = "AAAA",
        .seqB = "AAAA", 
        .expected_score = 12,
        .name = "4-element identical sequences (match_score=3 * 4 = 12)",
    },
    .{
        .seqA = "AAAAAAAA",
        .seqB = "AAAAAAAA",
        .expected_score = 24,
        .name = "8-element identical sequences (match_score=3 * 8 = 24)",
    },
    .{
        .seqA = "AAAAAAAAAAAAAAAA",
        .seqB = "AAAAAAAAAAAAAAAA",
        .expected_score = 48,
        .name = "16-element identical sequences (match_score=3 * 16 = 48)",
    },
    .{
        .seqA = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
        .seqB = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
        .expected_score = 96,
        .name = "32-element identical sequences (match_score=3 * 32 = 96)",
    },
    .{
        .seqA = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
        .seqB = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
        .expected_score = 192,
        .name = "64-element identical sequences (match_score=3 * 64 = 192)",
    },
};

pub fn runTestCase(comptime ImplType: type, test_case: TestCase) !void {
    const score = try ImplType.similarity(test_case.seqA, test_case.seqB);
    try testing.expectEqual(test_case.expected_score, score);
}

pub fn runAllTestCases(comptime ImplType: type) !void {
    inline for (test_cases) |test_case| {
        try runTestCase(ImplType, test_case);
        try runTestCase(ImplType, .{
            .seqA = test_case.seqB,
            .seqB = test_case.seqA,
            .expected_score = test_case.expected_score,
            .name = test_case.name,
        });
    }
}

pub fn runVectorSizeTests(comptime ImplType: type) !void {
    inline for (vector_size_test_cases) |test_case| {
        try runTestCase(ImplType, test_case);
    }
}