//! Core Huffman Encoding Struct

const EncodingTree = @import("encoding_tree.zig");
const MinHeap = @import("min_heap.zig");

/// The encoding used to go back
encoding: EncodingTree,
/// Unowned pointer to data
buf: []u8,

const Self = @This();

pub fn init(data: []u8) Self {
    const FrequencyPair = struct {
        item: u8,
        freq: u16,
    };

    _ = FrequencyPair;
    _ = data;

    @panic("Todo: Create an ArrayList of FrequencyPairs for all bytes in the data, create a min heap from this and then keep adding the min item to the end of the Huffman Tree");
}
