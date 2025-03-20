const std = @import("std");

const raylib = @import("raylib");
const Color = raylib.Color;

const Bouncer = @import("./bouncer.zig").Bouncer;
const Log = @import("./log.zig").Log;
const UdpSender = @import("./udp/sender.zig").Sender;
const UdpReceiver = @import("./udp/receiver.zig").Receiver;

// Good ol' VGA :-)
const screenWidth = 640;
const screenHeight = 480;

const targetFPS = 60;

const quiet = true;

const message = "Hello, Zocket!";

const fontData = @embedFile("./fonts/JetBrainsMono/JetBrainsMono-Regular.ttf");

fn loadFont(fontSize: i32) !raylib.Font {
    return try raylib.loadFontFromMemory(".ttf", fontData, fontSize, null);
}

pub fn main() !void {
    std.debug.print("{s}\n", .{message});

    if (quiet) {
        raylib.setTraceLogLevel(.none);
    }

    raylib.initWindow(screenWidth, screenHeight, "Zocket");

    raylib.setTargetFPS(targetFPS);

    const bouncerPad = 40;
    const bouncerRect = raylib.Rectangle{
        .x = bouncerPad,
        .y = bouncerPad,
        .width = screenWidth - 2 * bouncerPad,
        .height = screenHeight - 2 * bouncerPad,
    };

    var bouncer = Bouncer.init(
        message,
        bouncerRect,
        .{
            .x = 180,
            .y = 120,
        },
        .{
            .color = Color.white,
            .font = try loadFont(20),
            .size = 20,
            .spacing = 0,
        },
    );

    const allocator = std.heap.page_allocator;

    var log = Log.init(
        allocator,
        bouncerRect,
        4,
        .{
            .font = try loadFont(20),
            .size = 20,
            .spacing = 0,
            .color = Color.white,
        },
    );

    const broadcast = try UdpSender.broadcast(3000);
    defer broadcast.close();

    const receiver = try UdpReceiver.nonblocking(3001);

    while (!raylib.windowShouldClose()) {
        // Update
        const dt: f32 = raylib.getFrameTime();

        bouncer.update(dt);
        log.update(dt);

        {
            var buffer = std.mem.zeroes([10 * 1024]u8);
            var address: std.net.Address = undefined;

            if (receiver.receive(buffer[0..], &address)) |read| {
                const msg = try std.fmt.allocPrintZ(allocator, "{} (len={}):\n{s}\n", .{ address, read, buffer });
                defer allocator.free(msg);
                std.debug.print("{} (len={}):\n{s}\n", .{ address, read, buffer });
                try log.add(msg);
            } else |err| switch (err) {
                error.WouldBlock => {
                    // OK
                    // std.debug.print(".", .{});
                },
                else => {
                    return err;
                },
            }
        }

        if (bouncer.hitB) {
            const msg = "bouncer hit the BOTTOM!";
            try log.add(msg);
            _ = try broadcast.send(msg ++ "\n");
        }
        if (bouncer.hitT) {
            const msg = "bouncer hit the TOP!";
            try log.add(msg);
            _ = try broadcast.send(msg ++ "\n");
        }
        if (bouncer.hitL) {
            const msg = "bouncer hit the LEFT!";
            try log.add(msg);
            _ = try broadcast.send(msg ++ "\n");
        }
        if (bouncer.hitR) {
            const msg = "bouncer hit the RIGHT!";
            try log.add(msg);
            _ = try broadcast.send(msg ++ "\n");
        }

        const pressed = raylib.getKeyPressed();
        if (pressed != .null) {
            const name = @tagName(pressed);
            try log.add(name);
        }

        // Draw
        raylib.beginDrawing();

        raylib.clearBackground(Color.black);

        raylib.drawFPS(10, 10);

        raylib.drawRectangleRec(bouncerRect, Color.gray);
        bouncer.draw();
        log.draw();

        defer raylib.endDrawing();
    }
}
