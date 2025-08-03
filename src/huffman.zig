//! Core Huffman Encoding Struct

const EncodingTree = @import("encoding_tree.zig");

/// The encoding used to go back
encoding: EncodingTree,
/// Unowned pointer to data
buf: []u8,
