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

pub fn countUtf8Codepoints(text: []const u8) u64 {
    var count: u64 = 0;
    for (text) |b| {
        if ((b & 0b1100_0000) != 0b1000_0000) count += 1;
    }

    return count;
}
