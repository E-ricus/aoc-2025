const std = @import("std");
const aoc = @import("aoc");

pub fn part1(input: []const u8) !i64 {
    const trimmed = std.mem.trim(u8, input, "\n");
    var ranges = std.mem.splitAny(u8, trimmed, ",");
    var acc: usize = 0;
    while (ranges.next()) |range| {
        var ranged = std.mem.splitAny(u8, range, "-");
        const first_str = ranged.next() orelse return error.InvalidInput;
        const first = try std.fmt.parseInt(usize, first_str, 10);
        const second_str = ranged.next() orelse return error.InvalidInput;
        const second = try std.fmt.parseInt(usize, second_str, 10);
        for (first..second + 1) |id| {
            // max len of the biggest id
            var buf: [10]u8 = undefined;
            const id_slice = try std.fmt.bufPrint(&buf, "{d}", .{id});
            const mid = id_slice.len / 2;
            if (std.mem.eql(u8, id_slice[0..mid], id_slice[mid..])) {
                acc += id;
            }
        }
    }
    return @intCast(acc);
}

pub fn part2(input: []const u8) !i64 {
    const trimmed = std.mem.trim(u8, input, "\n");
    var ranges = std.mem.splitAny(u8, trimmed, ",");
    var acc: usize = 0;
    while (ranges.next()) |range| {
        var ranged = std.mem.splitAny(u8, range, "-");
        const first_str = ranged.next() orelse return error.InvalidInput;
        const first = try std.fmt.parseInt(usize, first_str, 10);
        const second_str = ranged.next() orelse return error.InvalidInput;
        const second = try std.fmt.parseInt(usize, second_str, 10);
        for (first..second + 1) |id| {
            // max len of the biggest id
            var buf: [10]u8 = undefined;
            const id_slice = try std.fmt.bufPrint(&buf, "{d}", .{id});
            // Will never satisfy
            if (id_slice.len == 1) {
                continue;
            }
            // Verifies if is odd
            switch (id_slice.len & 1 == 0) {
                true => {
                    const mid = id_slice.len / 2;
                    if (std.mem.eql(u8, id_slice[0..mid], id_slice[mid..])) {
                        acc += id;
                        continue;
                    }
                    // Divided by 2, all chunks are equals
                    const validator = id_slice[0..2];
                    if (chuncksRepeated(id_slice, validator)) {
                        acc += id;
                        continue;
                    }
                },
                false => {
                    // Divided by 3, all chunks are equals
                    if (chuncksRepeated(id_slice, id_slice[0..3])) {
                        acc += id;
                        continue;
                    }
                },
            }
            // Divided by 1, all values are equals
            if (chuncksRepeated(id_slice, id_slice[0..1])) {
                acc += id;
            }
        }
    }
    return @intCast(acc);
}

fn chuncksRepeated(slice: []u8, validator: []u8) bool {
    // Accounts for 2 and 3 digit numbers, only 2 digit numbers are valid and validated dividing by two
    if (std.mem.eql(u8, slice, validator)) {
        return false;
    }
    var chunks = aoc.chunks(u8, slice, validator.len);
    while (chunks.next()) |chunk| {
        if (!std.mem.eql(u8, chunk, validator)) {
            return false;
        }
    }
    return true;
}

test "day2 part1" {
    const input =
        \\11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124
    ;
    try std.testing.expectEqual(@as(i64, 1227775554), try part1(input));
}

test "day2 part2" {
    const input =
        \\11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124
    ;
    try std.testing.expectEqual(@as(i64, 4174379265), try part2(input));
}
