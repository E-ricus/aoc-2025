const std = @import("std");

/// Read the entire input file for a given day
pub fn readInput(allocator: std.mem.Allocator, day: u8) ![]const u8 {
    var path_buf: [16]u8 = undefined;
    const path = try std.fmt.bufPrint(&path_buf, "inputs/day{d:02}.txt", .{day});

    const file = std.fs.cwd().openFile(path, .{}) catch |err| {
        std.debug.print("Error: Could not open input file '{s}'\n", .{path});
        std.debug.print("Run: zig build fetch -- {d}\n", .{day});
        return err;
    };
    defer file.close();

    var buf: [4096]u8 = undefined; // temporary read buffer
    var reader: std.fs.File.Reader = file.reader(&buf);
    return reader.interface.allocRemaining(allocator, .unlimited);
}

/// Iterator for lines in input
pub const LineIterator = struct {
    buffer: []const u8,
    index: usize = 0,

    pub fn next(self: *LineIterator) ?[]const u8 {
        if (self.index >= self.buffer.len) return null;

        const start = self.index;
        const end = std.mem.indexOfScalarPos(u8, self.buffer, start, '\n') orelse self.buffer.len;

        self.index = if (end < self.buffer.len) end + 1 else self.buffer.len;

        const line = self.buffer[start..end];
        // Remove trailing \r if present (Windows line endings)
        return if (line.len > 0 and line[line.len - 1] == '\r')
            line[0 .. line.len - 1]
        else
            line;
    }

    pub fn reset(self: *LineIterator) void {
        self.index = 0;
    }
};

pub fn lines(input: []const u8) LineIterator {
    return LineIterator{ .buffer = input };
}

/// Parse an integer from a string
pub fn parseInt(comptime T: type, s: []const u8) !T {
    return std.fmt.parseInt(T, s, 10);
}

/// Split a string by delimiter
pub fn split(input: []const u8, delimiter: []const u8) std.mem.SplitIterator(u8, .sequence) {
    return std.mem.splitSequence(u8, input, delimiter);
}

/// Trim whitespace from both ends
pub fn trim(s: []const u8) []const u8 {
    return std.mem.trim(u8, s, &std.ascii.whitespace);
}

/// Common 2D grid utilities
pub fn Grid(comptime T: type) type {
    return struct {
        data: []T,
        width: usize,
        height: usize,
        allocator: std.mem.Allocator,

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator, width: usize, height: usize) !Self {
            const data = try allocator.alloc(T, width * height);
            return Self{
                .data = data,
                .width = width,
                .height = height,
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.data);
        }

        pub fn get(self: Self, x: usize, y: usize) T {
            return self.data[y * self.width + x];
        }

        pub fn set(self: *Self, x: usize, y: usize, value: T) void {
            self.data[y * self.width + x] = value;
        }

        pub fn isValid(self: Self, x: isize, y: isize) bool {
            return x >= 0 and y >= 0 and x < self.width and y < self.height;
        }
    };
}

pub fn chunks(comptime T: type, slice: []const T, chunk_size: usize) ChunkIterator(T) {
    return ChunkIterator(T){
        .slice = slice,
        .chunk_size = chunk_size,
        .index = 0,
    };
}

fn ChunkIterator(comptime T: type) type {
    return struct {
        slice: []const T,
        chunk_size: usize,
        index: usize,

        pub fn next(self: *@This()) ?[]const T {
            if (self.index >= self.slice.len) return null;

            const end = @min(self.index + self.chunk_size, self.slice.len);
            const chunk = self.slice[self.index..end];
            self.index = end;
            return chunk;
        }
    };
}

test "LineIterator" {
    const input = "line1\nline2\nline3";
    var iter = lines(input);
    try std.testing.expectEqualStrings("line1", iter.next().?);
    try std.testing.expectEqualStrings("line2", iter.next().?);
    try std.testing.expectEqualStrings("line3", iter.next().?);
    try std.testing.expect(iter.next() == null);
}

test "parseInt" {
    try std.testing.expectEqual(@as(i32, 42), try parseInt(i32, "42"));
    try std.testing.expectEqual(@as(i32, -42), try parseInt(i32, "-42"));
}
