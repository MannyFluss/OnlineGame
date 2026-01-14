const std = @import("std");

pub fn build(b: *std.Build) void {
    std.debug.print("Manual Fluss, your days are numbered and your testicals are MEIN :3\n", .{});

    // Optionally suppress the "Build Summary" output
    _ = b;
}
