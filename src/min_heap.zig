//! A (hopefully decent) Min Heap Implementation from scratch
//! Yes, I know there's a `PriorityQueue` in std zig, but didn't
//! you read the whole "from scratch" part of this repo?
//! I guess if I really wanted this to be from scratch it would
//! not be able to use built in allocators or any std lib stuff at
//! all but you know what I mean. We gotta draw the line somewhere,
//! and I'm drawing the line where I wanna. Cool? cool.
//! :)
const std = @import("std");

const starter_size: usize = 4;

pub fn MinHeap(comptime T: type) type {
    return struct {
        items: []T,
        size: usize,
        capacity: usize,

        /// Function that returns true if a is gt b and false if lte
        cmp_fn: *const fn (a: T, b: T) bool,

        allocator: std.mem.Allocator,

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator, cmp_fn: *const fn (a: T, b: T) bool) !Self {
            return Self{ .items = try allocator.alloc(T, starter_size), .size = 0, .capacity = starter_size, .allocator = allocator, .cmp_fn = cmp_fn };
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.items);
        }

        pub fn pop(self: *Self) ?T {
            if (self.items.len == 0) {
                return null;
            }

            const size = self.size;
            const last_elem = self.items[size - 1];

            const min = self.items[0];
            self.items[0] = last_elem;

            self.size -= 1;

            self.heapify(0);
            return min;
        }

        pub fn insert(self: *Self, elem: T) !void {
            if (self.size == self.capacity) {
                self.capacity *= 2;
                self.items = try self.allocator.realloc(self.items, self.capacity);
            }

            self.size += 1;
            self.items[self.size - 1] = elem;

            var curr = self.size - 1;

            while (curr > 0 and self.cmp_fn(self.items[parent(curr)], self.items[curr])) {
                const temp = self.items[parent(curr)];
                self.items[parent(curr)] = self.items[curr];
                self.items[curr] = temp;

                curr = parent(curr);
            }
        }

        pub fn heapify(self: *Self, idx: usize) void {
            if (self.size <= 1) {
                return;
            }

            const left = left_child(idx);
            const right = right_child(idx);

            var smallest = idx;

            if (left < self.size and self.cmp_fn(self.items[idx], self.items[left])) {
                smallest = left;
            }

            if (right < self.size and self.cmp_fn(self.items[idx], self.items[right])) {
                smallest = right;
            }

            if (smallest != idx) {
                const temp = self.items[idx];
                self.items[idx] = self.items[smallest];
                self.items[smallest] = temp;

                self.heapify(smallest);
            }
        }

        fn parent(idx: usize) usize {
            return (idx - 1) / 2;
        }

        fn left_child(idx: usize) usize {
            return ((2 * idx) + 1);
        }

        fn right_child(idx: usize) usize {
            return ((2 * idx) + 2);
        }

        pub fn get_min(self: *Self) T {
            return self.items[0];
        }
    };
}

fn cmp_u16(a: u16, b: u16) bool {
    return a > b;
}

test "initialize" {
    var heap = try MinHeap(u16).init(std.heap.page_allocator, cmp_u16);
    defer heap.deinit();
}

test "insert" {
    var heap = try MinHeap(u16).init(std.heap.page_allocator, cmp_u16);
    defer heap.deinit();
    try heap.insert(10);
    try heap.insert(5);
    try heap.insert(2);

    try std.testing.expectEqualSlices(u16, &[_]u16{ 2, 10, 5 }, heap.items[0..heap.size]);
}

test "insertion getting" {
    var heap = try MinHeap(u16).init(std.heap.page_allocator, cmp_u16);
    defer heap.deinit();
    try heap.insert(10);
    try heap.insert(5);
    try heap.insert(2);

    const min = heap.get_min();
    try std.testing.expectEqual(2, min);
}

test "wus popping" {
    var heap = try MinHeap(u16).init(std.heap.page_allocator, cmp_u16);
    defer heap.deinit();
    try heap.insert(10);
    try heap.insert(5);
    try heap.insert(2);

    var min = heap.pop();
    try std.testing.expectEqual(2, min);

    min = heap.pop();
    try std.testing.expectEqual(5, min);

    min = heap.pop();
    try std.testing.expectEqual(10, min);
    try std.testing.expectEqual(0, heap.size);
}
