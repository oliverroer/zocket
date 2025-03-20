const raylib = @import("raylib");
const Font = raylib.Font;
const Color = raylib.Color;

pub const FontStyle = struct {
    font: Font,
    size: f32,
    spacing: f32,
    color: Color,
};
