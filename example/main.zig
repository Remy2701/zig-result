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

    const result2 = ResultType.err(ErrorPayload{
        .InvalidCharacter = 'w',
    });

    var payload: ErrorPayload = undefined;
    _ = result2.unwrapCapture(&payload) catch |err| blk: {
        std.debug.print("Error: {s} / {}\n", .{ @errorName(err), payload });
        break :blk 0; // Default value to use after
    };
}
