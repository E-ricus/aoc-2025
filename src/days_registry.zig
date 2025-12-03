// Auto-generated file - do not edit manually
// Regenerated on every build
const day01 = @import("days/day01.zig");
const day02 = @import("days/day02.zig");
const day03 = @import("days/day03.zig");

pub const Day = struct {
    number: u8,
    part1: *const fn ([]const u8) anyerror!i64,
    part2: *const fn ([]const u8) anyerror!i64,
};

pub const days = [_]Day{
    .{ .number = 1, .part1 = day01.part1, .part2 = day01.part2 },
    .{ .number = 2, .part1 = day02.part1, .part2 = day02.part2 },
    .{ .number = 3, .part1 = day03.part1, .part2 = day03.part2 },
};
