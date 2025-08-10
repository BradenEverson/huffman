//! Huffman Encoder Struct
//! Responsible for encoding and decoding a stream and probably some other awesome stuff

const std = @import("std");
const MinHeap = @import("min_heap.zig").MinHeap;

pub const FrequencyPair = struct {
    byte: u8,
    freq: u24,
};

pub const HuffmanNode = struct {
    val: ?u8,
    frequency: u24,
    left: ?*HuffmanNode,
    right: ?*HuffmanNode,

    pub fn deinit(self: *HuffmanNode, alloc: std.mem.Allocator) void {
        if (self.left) |left| {
            left.deinit(alloc);
            alloc.destroy(left);
        }

        if (self.right) |right| {
            right.deinit(alloc);
            alloc.destroy(right);
        }
    }
};

fn cmpFreq(a: FrequencyPair, b: FrequencyPair) bool {
    return a.freq > b.freq;
}

fn frequencyPairsFromSlice(data: []u8, al: *std.ArrayList(FrequencyPair)) !void {
    var frequencies = [0]u8{0} ** 256;

    for (data) |byte| {
        frequencies[byte] += 1;
    }

    for (frequencies, 0..) |count, byte| {
        if (count > 0) {
            try al.append(.{ .byte = byte, .freq = count });
        }
    }
}

pub const Huffman = struct {
    root: ?HuffmanNode,
    alloc: std.mem.Allocator,

    pub fn init(alloc: std.mem.Allocator) Huffman {
        return Huffman{ .alloc = alloc, .root = null };
    }

    pub fn build(self: *Huffman, data: []u8) !void {
        var min_heap = try MinHeap(FrequencyPair).init(self.alloc, cmpFreq);
        defer min_heap.deinit();

        var frequencies = std.ArrayList(FrequencyPair).init(self.alloc);
        defer frequencies.deinit();

        try frequencyPairsFromSlice(data, &frequencies);

        for (frequencies) |freq| {
            try min_heap.insert(freq);
        }
    }

    pub fn deinit(self: *Huffman) void {
        if (self.root) |*root| {
            root.deinit(self.alloc);
        }
    }
};

test "Create huffman" {
    var huffman = Huffman.init(std.heap.page_allocator);
    defer huffman.deinit();
}
