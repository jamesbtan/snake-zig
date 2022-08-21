const std = @import("std");
const s = @import("snake.zig");

var prng = std.rand.DefaultPrng.init(0);
const rand = prng.random();

snake: s.Snake,
bounds: [2]u32,
food: [2]u32,

const Self = @This();

pub fn init(allocator: std.mem.Allocator, board_dim: [2]u32) !Self {
    prng.seed(blk: {
        var seed: u64 = undefined;
        try std.os.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    var board = Self{
        .snake = try s.Snake.init(
            allocator,
            randCoord(.{ board_dim[0] / 2, board_dim[1] }),
        ),
        .bounds = board_dim,
        .food = undefined,
    };
    board.placeFood();
    return board;
}

pub fn deinit(self: *Self) void {
    self.snake.deinit();
}

pub fn reset(self: *Self) !Self {
    const alloc = self.snake.pos.allocator;
    const bounds = self.bounds;
    self.deinit();
    return try Self.init(alloc, bounds);
}

fn randCoord(bounds: [2]u32) [2]u32 {
    return .{
        rand.intRangeAtMost(u32, 1, bounds[0]),
        rand.intRangeAtMost(u32, 1, bounds[1]),
    };
}

fn snakeOnFood(self: *const Self) bool {
    var i: u32 = 0;
    while (i < self.snake.pos.count) : (i += 1) {
        const curr = self.snake.pos.peekItem(i);
        if (std.mem.eql(u32, &curr, &self.food)) {
            return true;
        }
    }
    return false;
}

fn headOnFood(self: *const Self) bool {
    const head = self.snake.getHead();
    return std.mem.eql(u32, &head, &self.food);
}

fn placeFood(self: *Self) void {
    while (true) {
        self.food = randCoord(self.bounds);
        if (!self.snakeOnFood()) break;
    }
}

pub fn turn(self: *Self) !void {
    self.snake.turn();
    if (self.headOnFood()) {
        try self.snake.moveAndGrow();
        self.placeFood();
    } else {
        try self.snake.move();
    }
}
