const std = @import("std");
const aoc = @import("aoc");

pub fn part1(input: []const u8) !i64 {
    var lines = aoc.lines(input);
    var acc: u32 = 0;
    while (lines.next()) |line| {
        var first_number: u8 = 0;
        var second_number: u8 = 0;

        const highest_number = std.mem.max(u8, line);
        const highest_index = std.mem.indexOfScalar(u8, line, highest_number).?;

        if (highest_index + 1 == line.len) {
            first_number = std.mem.max(u8, line[0..highest_index]) - '0';
            second_number = highest_number - '0';
        } else {
            first_number = highest_number - '0';
            second_number = std.mem.max(u8, line[highest_index + 1 ..]) - '0';
        }
        var buf: [2]u8 = undefined;
        const val_s = try std.fmt.bufPrint(&buf, "{d}{d}", .{ first_number, second_number });

        const val = try std.fmt.parseInt(u32, val_s, 10);

        acc += val;
    }
    return @intCast(acc);
}

pub fn part2(input: []const u8) !i64 {
    _ = input;
    // TODO: Implement part 2
    return 0;
}

test "day3 part1" {
    const input =
        \\987654321111111
        \\811111111111119
        \\234234234234278
        \\818181911112111
    ;
    try std.testing.expectEqual(@as(i64, 357), try part1(input));
}

test "day3 part2" {
    const input =
        \\987654321111111
        \\811111111111119
        \\234234234234278
        \\818181911112111
    ;
    try std.testing.expectEqual(@as(i64, 0), try part2(input));
}
