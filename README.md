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

`zig fetch --save git+https://github.com/BradenEverson/huffman.git`

2. Import hte module into build.zig:

```zig
const huffman_dep = b.dependency("huffman", .{
    .target = target,
    .optimize = optimize,
})
exe.root_module.addImport("huffman", huffman_dep.module("huffman"));
```

## Todos:

- [ ] The current implementation uses an ArrayList(u1) for simplicity when getting instructions, this can obviously be optimized
- [ ] A form of serialization for the tree itself to send to the receiver alongside the data, as you need the tree to do the decoding.
