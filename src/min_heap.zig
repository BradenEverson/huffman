//! Min Heap Impl

const std = @import("std");

pub const Ordering = enum {
    Greater,
    Equal,
    Less,
};

fn MinHeap(comptime t: type) type {
    return struct {
        const Self = @This();

        items: std.ArrayList(t),
        cmp_fn: *const fn (t, t) Ordering,

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .items = std.ArrayList(t).init(allocator),
            };
        }

        pub fn insert(self: *Self, item: t) !Self {
            var cursor = 0;
            while (self.items.items.len > cursor or self.cmp_fn(self.items.items[cursor], item) == .Less) {
                cursor += 1;
            }

            try self.items.insert(cursor, item);
        }

        pub fn deinit(self: *Self) void {
            self.items.deinit();
        }
    };
}
