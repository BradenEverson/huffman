//! Core Huffman Encoding Struct

const std = @import("std");

const EncodingTree = @import("encoding_tree.zig");
const MinHeap = @import("min_heap.zig");
const Ordering = @import("min_heap.zig").Ordering;

const FrequencyPair = struct {
    item: u8,
    freq: u16,
};

pub fn cmp_frequency_pairs(item1: FrequencyPair, item2: FrequencyPair) Ordering {
    return cmp_frequencies(item1.freq, item2.freq);
}

pub fn cmp_frequencies(item1: u16, item2: u16) Ordering {
    const signed1: i32 = @intCast(item1);
    const signed2: i32 = @intCast(item2);

    const diff: i32 = signed1 - signed2;

    if (diff == 0) {
        return .Equal;
    } else if (diff < 0) {
        return .Less;
    } else {
        return .Greater;
    }
}

/// The encoding used to go back
encoding: EncodingTree,
/// Unowned pointer to data
buf: []u8,

const Self = @This();

pub fn init(data: []u8) Self {
    const alloc = std.heap.GeneralPurposeAllocator(.{}).init();

    var encodings = std.ArrayList(FrequencyPair).init(alloc);
    defer encodings.deinit();

    _ = data;

    @panic("Todo: Create an ArrayList of FrequencyPairs for all bytes in the data, create a min heap from this and then keep adding the min item to the end of the Huffman Tree");
}
