//! Min Heap Impl

const std = @import("std");

const Ordering = enum {
    Greater,
    Equal,
    Less,
};

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
