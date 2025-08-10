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

fn cmpNodes(a: *HuffmanNode, b: *HuffmanNode) bool {
    return a.frequency > b.frequency;
}

fn frequencyPairsFromSlice(data: []const u8, al: *std.ArrayList(FrequencyPair)) !void {
    var frequencies = [1]u8{0} ** 256;

    for (data) |byte| {
        frequencies[byte] += 1;
    }

    for (frequencies, 0..) |count, byte| {
        if (count > 0) {
            try al.append(.{ .byte = @truncate(byte), .freq = count });
        }
    }
}

pub const Huffman = struct {
    root: ?*HuffmanNode,
    alloc: std.mem.Allocator,

    pub fn init(alloc: std.mem.Allocator) Huffman {
        return Huffman{ .alloc = alloc, .root = null };
    }

    pub fn build(self: *Huffman, data: []const u8) !void {
        var min_heap = try MinHeap(*HuffmanNode).init(self.alloc, cmpNodes);
        defer min_heap.deinit();

        var frequencies = std.ArrayList(FrequencyPair).init(self.alloc);
        defer frequencies.deinit();

        try frequencyPairsFromSlice(data, &frequencies);

        if (frequencies.items.len == 1) {
            const node = try self.alloc.create(HuffmanNode);
            node.* = .{
                .val = frequencies.items[0].byte,
                .frequency = frequencies.items[0].freq,
                .left = null,
                .right = null,
            };

            self.root = node;
        } else {
            for (frequencies.items) |freq| {
                const node = try self.alloc.create(HuffmanNode);
                node.* = .{
                    .val = freq.byte,
                    .frequency = freq.freq,
                    .left = null,
                    .right = null,
                };
                try min_heap.insert(node);
            }

            while (min_heap.size > 1) {
                const left = min_heap.pop();
                const right = min_heap.pop();

                const left_freq: u24 = if (left) |l| l.frequency else 0;
                const right_freq: u24 = if (right) |r| r.frequency else 0;

                const parent = try self.alloc.create(HuffmanNode);

                parent.* = .{
                    .val = null,
                    .frequency = left_freq + right_freq,
                    .left = left,
                    .right = right,
                };

                try min_heap.insert(parent);
            }

            self.root = min_heap.pop();
        }
    }

    pub fn deinit(self: *Huffman) void {
        if (self.root) |root| {
            root.deinit(self.alloc);
            self.alloc.destroy(root);
        }
    }
};

test "Create huffman" {
    var huffman = Huffman.init(std.heap.page_allocator);
    defer huffman.deinit();
}

test "Frequency map" {
    const msg = "abcaba";
    var al = std.ArrayList(FrequencyPair).init(std.heap.page_allocator);
    defer al.deinit();

    try frequencyPairsFromSlice(msg, &al);
    try std.testing.expectEqualSlices(FrequencyPair, &[_]FrequencyPair{ .{ .byte = 'a', .freq = 3 }, .{ .byte = 'b', .freq = 2 }, .{ .byte = 'c', .freq = 1 } }, al.items);
}

test "Build a huffman" {
    const msg = "abcaba";

    var huffman = Huffman.init(std.heap.page_allocator);
    defer huffman.deinit();

    try huffman.build(msg);

    const immediate_left = huffman.root.?.left.?;

    try std.testing.expectEqual('a', immediate_left.val.?);
}
