pub const bsw = @import("basic_sw.zig");
pub const ssw = @import("shift_sw.zig");

test "all" {
    _ = @import("basic_sw.zig");
    _ = @import("shift_sw.zig");
}
