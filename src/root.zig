const std = @import("std");
const result = @import("result.zig");

pub const Result = result.Result;

test "root" {
    std.testing.refAllDecls(result);
}
