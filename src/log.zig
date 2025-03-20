const std = @import("std");

const FontStyle = @import("./font.zig").FontStyle;

const raylib = @import("raylib");
const Vector2 = raylib.Vector2;
const Font = raylib.Font;
const Color = raylib.Color;
const Rectangle = raylib.Rectangle;
const cstring = [*:0]const u8;
const string = []const u8;

const cap = 128;

pub const Log = struct {
    allocator: std.mem.Allocator,

    bounds: Rectangle,
    padding: f32,

    fontStyle: FontStyle,

    expirationTimes: [cap]f32 = undefined,
    messages: [cap]string = undefined,

    // this is where the next log message would go
    next: usize = 0,
    // this is how many live messages we have
    len: usize = 0,

    messageDuration: f32 = 5,
    elapsedTime: f32 = 0,

    pub fn init(allocator: std.mem.Allocator, bounds: Rectangle, padding: f32, fontStyle: FontStyle) Log {
        return .{
            .allocator = allocator,
            .bounds = bounds,
            .padding = padding,
            .fontStyle = fontStyle,
        };
    }

    pub fn update(self: *Log, dt: f32) void {
        self.elapsedTime += dt;

        while (self.len > 0) {
            const oldest = @mod(cap + self.next - self.len, cap);
            if (self.elapsedTime > self.expirationTimes[oldest]) {
                // this message has expired
                self.allocator.free(self.messages[oldest]);
                self.len -= 1;
            } else {
                return;
            }
        }
    }

    pub fn add(self: *Log, message: cstring) !void {
        const next = self.next;
        if (self.len == cap) {
            // we're capped out, gotta free
            self.allocator.free(self.messages[next]);
        }

        const span = std.mem.span(message);
        const len = span.len;
        const copy: []u8 = try self.allocator.alloc(u8, len + 1);
        @memcpy(copy[0..len], span[0..len]);
        copy[len] = 0;

        self.messages[next] = copy;
        self.expirationTimes[next] = self.elapsedTime + self.messageDuration;
        self.next = @mod(self.next + 1, cap);
        self.len += 1;
    }

    pub fn draw(self: Log) void {
        if (self.len == 0) {
            return;
        }

        const latest = @mod(cap + self.next - 1, cap);

        var bounds = self.bounds;

        const maxHeight = bounds.height - self.padding * 2;
        const maxWidth = bounds.width - self.padding * 2;

        var height: f32 = 0;
        {
            var y: f32 = 0;
            for (0..self.len) |offset| {
                const i = @mod(cap + latest - offset, cap);
                const message: cstring = @ptrCast(self.messages[i].ptr);

                const measure = raylib.measureTextEx(
                    self.fontStyle.font,
                    message,
                    self.fontStyle.size,
                    self.fontStyle.spacing,
                );

                y += measure.y;

                height = @max(height, y);
                if (height > maxHeight) {
                    break;
                }
            }
        }

        bounds.width = maxWidth + self.padding * 2;
        bounds.height = @min(height, maxHeight) + self.padding * 2;

        raylib.drawRectangleRec(bounds, Color.black.alpha(0.5));

        {
            const x: f32 = bounds.x + self.padding;
            var y: f32 = bounds.y + self.padding;
            const yMax = y + bounds.height - self.padding * 2;

            const scissorX: i32 = @intFromFloat(x);
            const scissorY: i32 = @intFromFloat(y);

            const scissorW: i32 = @intFromFloat(bounds.width - self.padding * 2);
            const scissorH: i32 = @intFromFloat(bounds.height - self.padding * 2);

            raylib.beginScissorMode(scissorX, scissorY, scissorW, scissorH);
            defer raylib.endScissorMode();

            for (0..self.len) |offset| {
                const i = @mod(cap + latest - offset, cap);
                const message: cstring = @ptrCast(self.messages[i].ptr);

                const measure = raylib.measureTextEx(
                    self.fontStyle.font,
                    message,
                    self.fontStyle.size,
                    self.fontStyle.spacing,
                );

                raylib.drawTextEx(
                    self.fontStyle.font,
                    message,
                    .{ .x = x, .y = y },
                    self.fontStyle.size,
                    self.fontStyle.spacing,
                    self.fontStyle.color,
                );

                y += measure.y;

                if (y > yMax) {
                    break;
                }
            }
        }
    }
};
