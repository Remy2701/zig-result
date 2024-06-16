const std = @import("std");
pub const Result = @import("result").Result;

pub fn main() !void {
    const ErrorPayload = union(enum) {
        InvalidCharacter: u8,
        Unknown: struct {
            message: []const u8,
        },
    };

    const ResultType = Result(i32, ErrorPayload);
    const result = ResultType.ok(42);

    const value = try result.unwrap();
    std.debug.print("value: {d}\n", .{value});
}
