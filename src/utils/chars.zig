const std = @import("std");

pub fn characterToUTF8(codepoint: u32, buffer: *[4]u8) []const u8 {
    const valid = std.unicode.utf8ValidCodepoint(@intCast(codepoint));
    const character: u21 = if (valid)
        @intCast(codepoint)
    else
        0xFFFD;

    const length = std.unicode.utf8Encode(character, buffer) catch unreachable;
    return buffer[0..length];
}
