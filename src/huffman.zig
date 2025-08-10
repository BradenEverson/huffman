//! Huffman Encoder Struct
//! Responsible for encoding and decoding a stream and probably some other awesome stuff

const std = @import("std");
const MinHeap = @import("min_heap.zig").MinHeap;
const BitWriter = @import("bit_writer.zig");

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

fn cmpNodes(a: *HuffmanNode, b: *HuffmanNode) bool {
    return a.frequency > b.frequency;
}

fn frequencyPairsFromSlice(data: []const u8, al: *std.ArrayList(FrequencyPair)) !void {
    var frequencies = [1]u24{0} ** 256;

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

    /// An ArrayList of bits isn't the best thing ever for performance, but it is the easiest.
    /// So for now I'll keep it simple and unoptimal, and then later on we can do
    /// some of that crazy bit manipulation stuff (worst case for the huffman tree is 255 branchs, but
    /// maybe we can assume balance (or enforce it) to only need 8 max bits for an instruction).
    mappings: std.AutoHashMap(u8, std.ArrayList(u1)),

    pub fn init(alloc: std.mem.Allocator) Huffman {
        return Huffman{ .alloc = alloc, .root = null, .mappings = std.AutoHashMap(u8, std.ArrayList(u1)).init(alloc) };
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

            if (self.root) |r| {
                try self.createMappings(r, std.ArrayList(u1).init(self.alloc));
            }
        }
    }

    fn createMappings(self: *Huffman, node: *HuffmanNode, working_al: std.ArrayList(u1)) !void {
        if (node.val) |leaf| {
            try self.mappings.put(leaf, working_al);
        } else {
            defer working_al.deinit();

            if (node.left) |left| {
                var left_al = try working_al.clone();
                try left_al.append(0);

                try self.createMappings(left, left_al);
            }

            if (node.right) |right| {
                var right_al = try working_al.clone();
                try right_al.append(1);

                try self.createMappings(right, right_al);
            }
        }
    }

    pub fn encode(self: *Huffman, buf: []const u8, to: *std.ArrayList(u8)) !u32 {
        var bits: u32 = 0;
        var bit_writer = BitWriter.init(to);

        for (buf) |byte| {
            const encoding = self.mappings.get(byte).?;
            for (encoding.items) |bit| {
                try bit_writer.write(bit);
                bits += 1;
            }
        }

        try bit_writer.flush();
        return bits;
    }

    pub const DecodeError = error{ InvalidEncoding, NoRoot };

    pub fn decode(self: *Huffman, from: []const u8, to: *std.ArrayList(u8), bits: u32) !void {
        var bits_seen: u32 = 0;
        var curr_node = if (self.root) |r| r else return DecodeError.NoRoot;

        while (bits_seen < bits) {
            // Decode bit-by-bit
            const curr_byte = from[bits_seen / 8];
            const curr_bit = (curr_byte >> @truncate(bits_seen % 8)) & 0x01;

            if (curr_bit == 0) {
                // Go left
                curr_node = if (curr_node.left) |l| l else return DecodeError.InvalidEncoding;
            } else {
                // Go right
                curr_node = if (curr_node.right) |r| r else return DecodeError.InvalidEncoding;
            }

            if (curr_node.val) |v| {
                try to.append(v);
                curr_node = if (self.root) |r| r else return DecodeError.NoRoot;
            }

            bits_seen += 1;
        }
    }

    pub fn deinit(self: *Huffman) void {
        if (self.root) |root| {
            root.deinit(self.alloc);
            self.alloc.destroy(root);
        }

        var iter = self.mappings.valueIterator();
        while (iter.next()) |val| {
            val.deinit();
        }

        self.mappings.deinit();
    }
};

test "Create huffman" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const alloc = gpa.allocator();

    var huffman = Huffman.init(alloc);
    defer huffman.deinit();
}

test "Frequency map" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const alloc = gpa.allocator();

    const msg = "abcaba";

    var al = std.ArrayList(FrequencyPair).init(alloc);
    defer al.deinit();

    try frequencyPairsFromSlice(msg, &al);
    try std.testing.expectEqualSlices(FrequencyPair, &[_]FrequencyPair{ .{ .byte = 'a', .freq = 3 }, .{ .byte = 'b', .freq = 2 }, .{ .byte = 'c', .freq = 1 } }, al.items);
}

test "Build a huffman" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const alloc = gpa.allocator();

    const msg = "abcaba";

    var huffman = Huffman.init(alloc);
    defer huffman.deinit();

    try huffman.build(msg);

    const immediate_left = huffman.root.?.left.?;

    try std.testing.expectEqual('a', immediate_left.val.?);

    try std.testing.expectEqualSlices(u1, &[_]u1{0}, huffman.mappings.get('a').?.items);
    try std.testing.expectEqualSlices(u1, &[_]u1{ 1, 0 }, huffman.mappings.get('c').?.items);
    try std.testing.expectEqualSlices(u1, &[_]u1{ 1, 1 }, huffman.mappings.get('b').?.items);
}

test "More complex encoding" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const alloc = gpa.allocator();

    const msg = "The quick brown fox really likes coding in Zig because it's kinda a goated language.";

    var huffman = Huffman.init(alloc);
    defer huffman.deinit();

    try huffman.build(msg);

    try std.testing.expectEqualSlices(u1, &[_]u1{ 1, 0 }, huffman.mappings.get(' ').?.items);
    try std.testing.expectEqualSlices(u1, &[_]u1{ 0, 0, 0 }, huffman.mappings.get('a').?.items);
    try std.testing.expectEqualSlices(u1, &[_]u1{ 0, 1, 1, 1, 1 }, huffman.mappings.get('e').?.items);
    try std.testing.expectEqualSlices(u1, &[_]u1{ 0, 1, 1, 0, 1, 0 }, huffman.mappings.get('b').?.items);
    try std.testing.expectEqualSlices(u1, &[_]u1{ 0, 1, 1, 0, 1, 1 }, huffman.mappings.get('Z').?.items);
}

test "Encoding" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const alloc = gpa.allocator();

    const msg = "aabbaabbbbaabbaa";

    var huffman = Huffman.init(alloc);
    defer huffman.deinit();

    try huffman.build(msg);

    var encoded = std.ArrayList(u8).init(alloc);
    defer encoded.deinit();

    const written = try huffman.encode(msg, &encoded);

    try std.testing.expectEqualSlices(u8, &[_]u8{ 0b11001100, 0b00110011 }, encoded.items);
    try std.testing.expectEqual(16, written);
}

test "Decoding" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const alloc = gpa.allocator();

    const msg = "aabbaabbbbaabbaa";

    var huffman = Huffman.init(alloc);
    defer huffman.deinit();

    try huffman.build(msg);

    var decoded = std.ArrayList(u8).init(alloc);
    defer decoded.deinit();

    try huffman.decode(&[_]u8{ 0b11001100, 0b00110011 }, &decoded, 16);

    try std.testing.expectEqualSlices(u8, "aabbaabbbbaabbaa", decoded.items);
}
