const std = @import("std");
const SDL = @import("sdl2");
const Board = @import("board.zig");

board: Board,
win: SDL.Window,
ren: SDL.Renderer,

const Self = @This();

pub fn init(allocator: std.mem.Allocator, pix_dim: [2]u32, board_dim: [2]u32) !Self {
    try SDL.init(.{
        .video = true,
        .events = true,
    });
    errdefer SDL.quit();

    var new: Self = undefined;
    new.board = try Board.init(allocator, board_dim);
    new.win = try SDL.createWindow(
        "Snake",
        .{ .centered = {} },
        .{ .centered = {} },
        pix_dim[0],
        pix_dim[1],
        .{ .vis = .shown },
    );
    errdefer new.win.destroy();

    new.ren = try SDL.createRenderer(new.win, null, .{ .accelerated = true });
    return new;
}

pub fn deinit(self: *Self) void {
    self.ren.destroy();
    self.win.destroy();
    SDL.quit();
    self.board.deinit();
}

fn renderBoard(self: *Self) !void {
    try self.ren.setColor(SDL.Color.black);
    try self.ren.clear();

    const pix = self.win.getSize();
    const w = @intCast(u32, pix.width) / self.board.bounds[0];
    const h = @intCast(u32, pix.height) / self.board.bounds[1];

    try self.ren.setColor(SDL.Color.red);
    try self.ren.fillRect(.{
        .x = @intCast(c_int, w * (self.board.food[0] - 1)),
        .y = @intCast(c_int, h * (self.board.food[1] - 1)),
        .width = @intCast(c_int, w),
        .height = @intCast(c_int, h),
    });

    {
        try self.ren.setColor(SDL.Color.white);
        var i: u32 = 0;
        while (i < self.board.snake.pos.count) : (i += 1) {
            const curr = self.board.snake.pos.peekItem(i);
            try self.ren.fillRect(.{
                .x = @intCast(c_int, w * (curr[0] - 1)),
                .y = @intCast(c_int, h * (curr[1] - 1)),
                .width = @intCast(c_int, w),
                .height = @intCast(c_int, h),
            });
        }
    }

    self.ren.present();
}

const State = enum {
    quitting,
    dead,
    paused,
    playing,
};

fn handleInput(self: *Self) State {
    while (SDL.pollEvent()) |ev| {
        switch (ev) {
            .key_down => |kev| {
                switch (kev.keycode) {
                    .q => return .quitting,
                    .space => return .paused,
                    .d, .right => self.board.snake.tryTurn(.east),
                    .w, .up => self.board.snake.tryTurn(.north),
                    .a, .left => self.board.snake.tryTurn(.west),
                    .s, .down => self.board.snake.tryTurn(.south),
                    else => continue,
                }
            },
            else => continue,
        }
    }
    return .playing;
}

fn gameLoop(self: *Self) !State {
    try self.board.turn();
    if (self.board.snake.dying(self.board.bounds)) return .dead;
    try self.renderBoard();
    return self.handleInput();
}

fn pauseLoop(self: *Self) !State {
    const ev = try SDL.waitEvent();
    switch (ev) {
        .quit => return .quitting,
        .key_down => |kev| {
            switch (kev.keycode) {
                .space => return .playing,
                .q => return .quitting,
                .r => {
                    self.board = try self.board.reset();
                    return .playing;
                },
                else => return .paused,
            }
        },
        else => return .paused,
    }
}

pub fn mainLoop(self: *Self) !void {
    var state: State = .playing;
    while (true) {
        switch (state) {
            .quitting => break,
            .dead, .paused => {
                state = try self.pauseLoop();
            },
            .playing => {
                state = try self.gameLoop();
                SDL.delay(100);
            },
        }
    }
}
