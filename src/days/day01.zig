const std = @import("std");
const aoc = @import("aoc");

const WrappingResult = struct {
    value: u8,
    wraps: u32,
};

fn addWrapping(value: u8, amount: u32) WrappingResult {
    return .{
        .value = @intCast((value + amount) % 100),
        .wraps = (value + amount) / 100,
    };
}

fn subWrapping(value: u8, amount: u32) WrappingResult {
    const remainder = amount % 100;
    return .{
        .value = @intCast((value + 100 - remainder) % 100),
        .wraps = amount / 100 + @intFromBool(remainder >= value and value > 0),
    };
}

pub fn part1(input: []const u8) !i64 {
    var point: u8 = 50;
    var times: i64 = 0;
    var lines = aoc.lines(input);
    while (lines.next()) |line| {
        const direction = line[0];
        const num_slice = line[1..];
        const num = try std.fmt.parseInt(u32, num_slice, 10);
        switch (direction) {
            'L' => {
                point = subWrapping(point, num).value;
            },
            'R' => {
                point = addWrapping(point, num).value;
            },
            else => return error.InvalidInput,
        }
        if (point == 0) {
            times += 1;
        }
    }
    return times;
}

pub fn part2(input: []const u8) !i64 {
    var point: u8 = 50;
    var times: i64 = 0;
    var lines = aoc.lines(input);
    while (lines.next()) |line| {
        const direction = line[0];
        const num_slice = line[1..];
        const num = try std.fmt.parseInt(u32, num_slice, 10);
        switch (direction) {
            'L' => {
                const res = subWrapping(point, num);
                point = res.value;
                times += res.wraps;
            },
            'R' => {
                const res = addWrapping(point, num);
                point = res.value;
                times += res.wraps;
            },
            else => return error.InvalidInput,
        }
    }
    return times;
}

test "day1 part1" {
    const input =
        \\L68
        \\L30
        \\R48
        \\L5
        \\R60
        \\L55
        \\L1
        \\L99
        \\R14
        \\L82
    ;
    const result = try part1(input);
    try std.testing.expectEqual(@as(i64, 3), result);
}

test "day1 part2" {
    const input =
        \\L68
        \\L30
        \\R48
        \\L5
        \\R60
        \\L55
        \\L1
        \\L99
        \\R14
        \\L82
    ;
    const result = try part2(input);
    try std.testing.expectEqual(@as(i64, 6), result);
}
