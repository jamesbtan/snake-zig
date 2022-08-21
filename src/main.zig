const std = @import("std");
const SDL = @import("sdl2");
const Ui = @import("ui.zig");

pub fn main() anyerror!void {
    var ui = try Ui.init(std.testing.allocator, .{ 1000, 1000 }, .{ 10, 10 });
    defer ui.deinit();

    try ui.mainLoop();
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
