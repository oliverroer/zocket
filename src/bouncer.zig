const FontStyle = @import("./font.zig").FontStyle;

const raylib = @import("raylib");
const Vector2 = raylib.Vector2;
const Font = raylib.Font;
const Color = raylib.Color;
const Rectangle = raylib.Rectangle;
const String = [:0]const u8;

pub const Bouncer = struct {
    fontStyle: FontStyle,
    message: String,
    velocity: Vector2,
    rectangle: Rectangle,
    bounds: Rectangle,
    padding: f32,

    hitL: bool = false,
    hitR: bool = false,
    hitT: bool = false,
    hitB: bool = false,

    pub fn init(message: String, bounds: Rectangle, velocity: Vector2, fontStyle: FontStyle) Bouncer {
        const textMeasure = raylib.measureTextEx(fontStyle.font, message, fontStyle.size, fontStyle.spacing);

        const padding = fontStyle.size / 4;

        const width = textMeasure.x + 2 * padding;
        const height = textMeasure.y + 2 * padding;

        const x = bounds.x + (bounds.width - width) / 2;
        const y = bounds.y + (bounds.height - height) / 2;

        return .{
            .padding = padding,
            .fontStyle = fontStyle,
            .message = message,
            .velocity = velocity,
            .rectangle = .{
                .x = x,
                .y = y,
                .width = width,
                .height = height,
            },
            .bounds = bounds,
        };
    }

    pub fn update(self: *Bouncer, dt: f32) void {
        const rect = self.rectangle;
        const bounds = self.bounds;

        self.hitL = false;
        self.hitR = false;
        self.hitT = false;
        self.hitB = false;

        { // horizontal movement
            var x = rect.x + self.velocity.x * dt;
            defer self.rectangle.x = x;

            const toLeft = x - bounds.x;
            if (toLeft < 0) {
                self.velocity.x *= -1;
                x -= 2 * toLeft;
                self.hitL = true;
            } else {
                const toRight = (bounds.x + bounds.width) - (x + rect.width);
                if (toRight < 0) {
                    self.velocity.x *= -1;
                    x += toRight * 2;
                    self.hitR = true;
                }
            }
        }

        { // vertical movement
            var y = rect.y + self.velocity.y * dt;
            defer self.rectangle.y = y;

            const toTop = y - bounds.y;
            if (toTop < 0) {
                self.velocity.y *= -1;
                y -= 2 * toTop;
                self.hitT = true;
            } else {
                const toBottom = (bounds.y + bounds.height) - (y + rect.height);
                if (toBottom < 0) {
                    self.velocity.y *= -1;
                    y += toBottom * 2;
                    self.hitB = true;
                }
            }
        }
    }

    pub fn draw(self: Bouncer) void {
        raylib.drawRectangleRec(self.bounds, Color.dark_gray);
        raylib.drawRectangleRec(self.rectangle, Color.black);
        raylib.drawTextEx(
            self.fontStyle.font,
            self.message,
            .{
                .x = self.rectangle.x + self.padding,
                .y = self.rectangle.y + self.padding,
            },
            self.fontStyle.size,
            self.fontStyle.spacing,
            self.fontStyle.color,
        );
    }
};
