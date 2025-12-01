const std = @import("std");
const aoc = @import("aoc");

fn addWrapping(value: u8, amount: u32) u8 {
    return @intCast((value + amount) % 100);
}

fn subWrapping(value: u8, amount: u32) u8 {
    return @intCast((value + 100 - (amount % 100)) % 100);
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
                point = subWrapping(point, num);
            },
            'R' => {
                point = addWrapping(point, num);
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
    _ = input;
    // TODO: Implement part 2
    return 0;
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
    try std.testing.expectEqual(@as(i64, 6), try part2(input));
}
