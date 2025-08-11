# Huffman Encoding from Scratch

A simple Min-Heap, Huffman Tree and Bit Writer implementation that allows for proper encoding and decoding of binary data :)

## This repo provides:

- A min heap implementation from scratch (following https://www.digitalocean.com/community/tutorials/min-heap-binary-tree)
- A Huffman tree encoding method that supports:
    - Building a huffman tree from a message
    - Encoding data according to that tree
    - Decoding data according to that tree
- A BitWriter used when encoding instructions

## Usage:

1. Run this command:

```
zig fetch --save git+https://github.com/BradenEverson/huffman.git
```

2. Import the module into build.zig:

```zig
const huffman_dep = b.dependency("huffman", .{
    .target = target,
    .optimize = optimize,
});
exe.root_module.addImport("huffman", huffman_dep.module("huffman"));
```

3. Use it in your own projects like:

```zig
const std = @import("std");
const Huffman = @import("huffman").Huffman;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const alloc = gpa.allocator();

    const msg = "The quick brown fox really likes coding in Zig because it's kinda a goated language.";

    var huffman = Huffman.init(alloc);
    defer huffman.deinit();

    try huffman.build(msg);

    var encoded = std.ArrayList(u8).init(alloc);
    defer encoded.deinit();

    const written = try huffman.encode(msg, &encoded);

    var decoded = std.ArrayList(u8).init(alloc);
    defer decoded.deinit();

    try huffman.decode(encoded.items, &decoded, written);

    std.debug.print("{s}\n", .{decoded.items});
}
```

## Results:

- All of Moby Dick:
    - Original: 1,197,545 bytes
    - Encoded: 827,447 bytes
    - About 70% the original size :D

## Todos:

- [ ] The current implementation uses an ArrayList(u1) for simplicity when getting instructions, this can obviously be optimized
- [ ] A form of serialization for the tree itself to send to the receiver alongside the data, as you need the tree to do the decoding.
