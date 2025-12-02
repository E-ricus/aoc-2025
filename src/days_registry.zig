// Auto-generated file - do not edit manually
// This file is regenerated on every build

const day01 = @import("days/day01.zig");
const day02 = @import("days/day02.zig");

pub const Day = struct {
    number: u8,
    part1: *const fn ([]const u8) anyerror!i64,
    part2: *const fn ([]const u8) anyerror!i64,
};

pub const days = [_]Day{
    .{ .number = 1, .part1 = day01.part1, .part2 = day01.part2 },
    .{ .number = 2, .part1 = day02.part1, .part2 = day02.part2 },
};

