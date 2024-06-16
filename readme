# Zig Result
This is a library for creating and using results (similar to the ones in Rust). Those results allows you 
to give more information about an error such as a description.

**Zig Version:** 0.13.0

## Installation
You can either manually install the library, or automatically.

### Manual
You can install the library by adding it to the build.zig.zon file, either manually like so:

```zig
.{
    ...
    .dependencies = .{
        .zig-result = .{
            .url = "https://github.com/Remy2701/zig-result/archive/main.tar.gz",
            .hash = "...",
        }
    }
    ...
}
```

The hash can be found using the builtin command:
```sh
zig fetch https://github.com/Remy2701/zig-result/archive/main.tar.gz
```

### Automatic
Or you can also add it automatically like so:
```sh
zig fetch --save https://github.com/Remy2701/zig-result/archive/main.tar.gz
```

## Adding the module to your project

Then in the `build.zig`, you can add the following:
```zig
const zig_result = b.dependency("zig-result", .{
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("result", zig_result.module("zig-result"));
```

The name of the module (`result`) can be changed to whatever you want.

Finally in your code you can import the module using the following:
```zig
const result = @import("result");
```

## Example

```zig
const std = @import("std");
const Result = @import("result").Result;

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
```

More examples can be found in the tests, by navigating to the location of [`Result`](src/result.zig).

