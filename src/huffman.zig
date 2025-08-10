//! Huffman Encoder Struct
//! Responsible for encoding and decoding a stream and probably some other awesome stuff

const std = @import("std");
const MinHeap = @import("min_heap.zig").MinHeap;

pub const FrequencyPair = struct {
    byte: u8,
    freq: u24,
};

fn cmp_freq(a: FrequencyPair, b: FrequencyPair) bool {
    return a.freq > b.freq;
}

pub const Huffman = struct {
    table: MinHeap(FrequencyPair),
    alloc: std.mem.Allocator,

    pub fn init(alloc: std.mem.Allocator) !Huffman {
        return Huffman{ .table = try MinHeap(FrequencyPair).init(alloc, cmp_freq), .alloc = alloc };
    }

    pub fn deinit(self: *Huffman) void {
        self.table.deinit();
    }
};

test "Create huffman" {
    var huffman = try Huffman.init(std.heap.page_allocator);
    defer huffman.deinit();
}
