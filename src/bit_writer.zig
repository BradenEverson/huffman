//! Abstraction for writing bits to a binary target

const std = @import("std");

buffer: *std.ArrayList(u8),
byte_buf: u8,
curr_bit: u3,

const BitWriter = @This();

pub fn init(buffer: *std.ArrayList(u8)) BitWriter {
    return BitWriter{
        .buffer = buffer,
        .byte_buf = 0,
        .curr_bit = 0,
    };
}

pub fn write(self: *BitWriter, bit: u1) !void {
    if (bit == 1) {
        self.byte_buf |= @as(u8, 1) << self.curr_bit;
    }

    self.curr_bit +%= 1;
    if (self.curr_bit == 0) {
        try self.buffer.append(self.byte_buf);
        self.byte_buf = 0;
    }
}
