const std = @import("std");

/// Transform an union type into an error set.
fn ErrorSetFromUnion(comptime T: type) type {
    const info = @typeInfo(T);
    std.debug.assert(std.meta.activeTag(info) == .Union);

    // Transform the union fields into errors.
    comptime var errors: [info.Union.fields.len]std.builtin.Type.Error = undefined;
    inline for (info.Union.fields, 0..) |field, i| {
        errors[i] = std.builtin.Type.Error{
            .name = field.name,
        };
    }

    // Reify the type.
    return @Type(std.builtin.Type{
        .ErrorSet = &errors,
    });
}

/// Create a result type with the given [Ok] and [Error] types.
pub fn Result(comptime Ok: type, comptime Error: type) type {
    // Check the error type
    const error_info = @typeInfo(Error);
    std.debug.assert(std.meta.activeTag(error_info) == .Union);

    // Define the map type (for matching union tags to error sets)
    const ErrorTag = std.meta.Tag(Error);
    const ErrorSet_ = ErrorSetFromUnion(Error);
    const N = error_info.Union.fields.len;
    const Map = struct {
        keys: [N]ErrorTag,
        values: [N]ErrorSet_,
    };

    // Construct the map
    const map = comptime blk: {
        var map = Map{
            .keys = undefined,
            .values = undefined,
        };

        for (std.meta.tags(ErrorTag), std.meta.tags(ErrorSet_), 0..) |key, value, i| {
            map.keys[i] = key;
            map.values[i] = value;
        }

        break :blk map;
    };

    return union(enum) {
        const ErrorSet = ErrorSet_;

        ok: Ok,
        err: Error,

        /// Create a new result with the given value.
        pub fn ok(value: Ok) @This() {
            return .{
                .ok = value,
            };
        }

        /// Create a new result with the given error.
        pub fn err(value: Error) @This() {
            return .{
                .err = value,
            };
        }

        /// Check whether the result is ok.
        pub fn isOk(self: @This()) bool {
            return std.meta.activeTag(self) == .ok;
        }

        /// Check whether the result is an [err].
        pub fn isErr(self: @This()) bool {
            return std.meta.activeTag(self) == .err;
        }

        fn getErrorSet(self: @This()) ErrorSet {
            const active: ErrorTag = std.meta.activeTag(self.err);
            const idx = std.mem.indexOfScalar(ErrorTag, &map.keys, active) orelse unreachable;
            return map.values[idx];
        }

        /// Unwrap the result, returning the value or the error as an error set.
        pub fn unwrap(self: @This()) ErrorSet!Ok {
            return switch (self) {
                .ok => self.ok,
                .err => self.getErrorSet(),
            };
        }

        /// Unwrap and catpure the error, returning the value or the error as an error set.
        pub fn unwrapCapture(self: @This(), capture: *Error) ErrorSet!Ok {
            return switch (self) {
                .ok => self.ok,
                .err => blk: {
                    capture.* = self.err;
                    break :blk self.getErrorSet();
                },
            };
        }

        /// Unwrap the result, return the value or the default value given.
        pub fn unwrapOr(self: @This(), default: Ok) Ok {
            return switch (self) {
                .ok => self.ok,
                .err => default,
            };
        }

        /// Unwrap the result, return the value or null.
        pub fn unwrapOrNull(self: @This()) ?Ok {
            return switch (self) {
                .ok => self.ok,
                .err => null,
            };
        }
    };
}

test "Result.ok" {
    const ErrorPayload = union(enum) {
        InvalidCharacter: u8,
        Unknown: struct {
            message: []const u8,
        },
    };

    const ResultType = Result(i32, ErrorPayload);
    const result = ResultType.ok(42);

    try std.testing.expectEqual(42, result.unwrap());

    try std.testing.expect(result.isOk());
    try std.testing.expect(!result.isErr());

    try std.testing.expectEqual(42, result.unwrapOr(10));
    try std.testing.expectEqual(42, result.unwrapOrNull());

    var capture: ErrorPayload = undefined;
    try std.testing.expectEqual(42, result.unwrapCapture(&capture));
}

test "Result.err" {
    const ErrorPayload = union(enum) {
        InvalidCharacter: u8,
        Unknown: struct {
            message: []const u8,
        },
    };

    const ResultType = Result(i32, ErrorPayload);
    const result = ResultType.err(ErrorPayload{
        .InvalidCharacter = 'w',
    });

    try std.testing.expectEqual(ResultType.ErrorSet.InvalidCharacter, result.unwrap());
    try std.testing.expectEqual('w', result.err.InvalidCharacter);

    try std.testing.expect(!result.isOk());
    try std.testing.expect(result.isErr());

    try std.testing.expectEqual(10, result.unwrapOr(10));
    try std.testing.expectEqual(null, result.unwrapOrNull());

    var capture: ErrorPayload = undefined;
    _ = result.unwrapCapture(&capture) catch |err| {
        _ = err catch {};
        try std.testing.expectEqual(ResultType.ErrorSet.InvalidCharacter, err);
        try std.testing.expectEqual('w', capture.InvalidCharacter);
        return;
    };
}
