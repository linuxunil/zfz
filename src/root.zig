pub const bsw = @import("basic_sw.zig");
pub const ssw = @import("shift_sw.zig");
pub const adsw = @import("anti_diagonal_sw.zig");

test "all" {
    _ = @import("basic_sw.zig");
    _ = @import("shift_sw.zig");
    _ = @import("anti_diagonal_sw.zig");
}
