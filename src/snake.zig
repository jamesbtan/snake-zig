const std = @import("std");

const Direction = enum {
    east,
    north,
    west,
    south,
};

pub const Snake = struct {
    dir: Direction = .east,
    ndir: Direction = .east,
    pos: std.fifo.LinearFifo([2]u32, .Dynamic),

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, start_pos: [2]u32) !Self {
        _ = allocator;
        _ = start_pos;
        var al = std.fifo.LinearFifo([2]u32, .Dynamic).init(allocator);
        try al.writeItem(start_pos);
        return Self{ .pos = al };
    }

    pub fn deinit(self: *Self) void {
        self.pos.deinit();
    }

    fn getHead(self: *const Self) [2]u32 {
        return self.pos.peekItem(self.pos.count - 1);
    }

    pub fn moveAndGrow(self: *Self) !void {
        var new_head = self.getHead();
        switch (self.dir) {
            .south => new_head[1] += 1,
            .east => new_head[0] += 1,
            .north => new_head[1] -%= 1,
            .west => new_head[0] -%= 1,
        }
        try self.pos.writeItem(new_head);
    }

    pub fn move(self: *Self) !void {
        try self.moveAndGrow();
        _ = self.pos.readItem().?;
    }

    pub fn tryTurn(self: *Self, new_dir: Direction) void {
        if (@enumToInt(self.dir) % 2 != @enumToInt(new_dir) % 2) {
            self.ndir = new_dir;
        }
    }

    pub fn turn(self: *Self) void {
        self.dir = self.ndir;
    }

    fn hittingWall(self: *const Self, bounds: [2]u32) bool {
        const head = self.getHead();
        switch (self.dir) {
            .east => {
                return head[0] > bounds[0];
            },
            .north => {
                return head[1] == 0;
            },
            .west => {
                return head[0] == 0;
            },
            .south => {
                return head[1] > bounds[1];
            },
        }
    }

    fn hittingSelf(self: *const Self) bool {
        const head = self.getHead();
        {
            var i: u32 = 0;
            while (i < self.pos.count - 1) : (i += 1) {
                const curr = self.pos.peekItem(i);
                if (std.mem.eql(u32, &head, &curr)) {
                    return true;
                }
            }
        }
        return false;
    }

    pub fn dying(self: *const Self, bounds: [2]u32) bool {
        return self.hittingWall(bounds) or self.hittingSelf();
    }
};

test "snake move" {
    const start_pos = .{ 1, 3 };
    var s = try Snake.init(std.testing.allocator, start_pos);
    defer s.deinit();

    try s.move();
    try std.testing.expectEqualSlices(u32, &.{ 2, 3 }, &s.getHead());
    try s.move();
    try std.testing.expectEqualSlices(u32, &.{ 3, 3 }, &s.getHead());
    s.dir = .north;
    try s.move();
    try std.testing.expectEqualSlices(u32, &.{ 3, 2 }, &s.getHead());
    s.dir = .west;
    try s.move();
    try std.testing.expectEqualSlices(u32, &.{ 2, 2 }, &s.getHead());
    s.dir = .south;
    try s.move();
    try std.testing.expectEqualSlices(u32, &.{ 2, 3 }, &s.getHead());
}

test "snake try rotate" {
    const start_pos = .{ 0, 0 };
    var s = try Snake.init(std.testing.allocator, start_pos);
    defer s.deinit();

    s.tryTurn(.west);
    s.turn();
    try std.testing.expectEqual(Direction.east, s.dir);
    s.tryTurn(.south);
    s.turn();
    try std.testing.expectEqual(Direction.south, s.dir);
    s.tryTurn(.west);
    s.turn();
    try std.testing.expectEqual(Direction.west, s.dir);
}

test "snake will die - hit wall" {
    const start_pos = .{ 0, 0 };
    var s = try Snake.init(std.testing.allocator, start_pos);
    defer s.deinit();

    try std.testing.expect(!s.hittingWall(.{10, 10}));
    s.dir = .west;
    try std.testing.expect(s.hittingWall(.{10, 10}));
}

test "snake will die - hit self" {
    const start_pos = .{ 0, 0 };
    var s = try Snake.init(std.testing.allocator, start_pos);
    defer s.deinit();

    try std.testing.expect(!s.hittingSelf());
    try s.moveAndGrow();
    s.dir = .south;
    try s.moveAndGrow();
    s.dir = .west;
    try s.moveAndGrow();
    try std.testing.expect(!s.hittingSelf());
    s.dir = .north;
    try std.testing.expect(!s.hittingSelf());
    try s.moveAndGrow();
    try std.testing.expect(s.hittingSelf());
}
