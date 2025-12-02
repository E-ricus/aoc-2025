const std = @import("std");
const aoc = @import("aoc");
const registry = @import("days_registry.zig");

const Day = registry.Day;
const days = registry.days;

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: {s} <day1> [day2] [day3] ...\n", .{args[0]});
        std.debug.print("Example: {s} 1 2 3\n", .{args[0]});
        std.debug.print("\nAvailable days: ", .{});
        for (days) |day| {
            std.debug.print("{d} ", .{day.number});
        }
        std.debug.print("\n", .{});
        return;
    }

    // Run specified days
    for (args[1..]) |arg| {
        const day_num = std.fmt.parseInt(u8, arg, 10) catch {
            std.debug.print("Invalid day number: {s}\n", .{arg});
            continue;
        };

        try runDay(allocator, day_num);
    }
}

fn runDay(allocator: std.mem.Allocator, day_num: u8) !void {
    // Find the day in our days array
    var day: ?Day = null;
    for (days) |d| {
        if (d.number == day_num) {
            day = d;
            break;
        }
    }

    if (day == null) {
        std.debug.print("Day {d} not implemented yet\n", .{day_num});
        return;
    }

    const input_not_trimed = aoc.readInput(allocator, day_num) catch |err| {
        std.debug.print("Failed to read input for day {d}: {}\n", .{ day_num, err });
        return;
    };
    defer allocator.free(input_not_trimed);
    const input = std.mem.trim(u8, input_not_trimed, "\n");

    std.debug.print("\n=== Day {d} ===\n", .{day_num});

    const start1 = std.time.nanoTimestamp();
    const result1 = try day.?.part1(input);
    const end1 = std.time.nanoTimestamp();
    const time1 = @as(f64, @floatFromInt(end1 - start1)) / 1_000_000.0;

    std.debug.print("Part 1: {d} ({d:.3}ms)\n", .{ result1, time1 });

    const start2 = std.time.nanoTimestamp();
    const result2 = try day.?.part2(input);
    const end2 = std.time.nanoTimestamp();
    const time2 = @as(f64, @floatFromInt(end2 - start2)) / 1_000_000.0;

    std.debug.print("Part 2: {d} ({d:.3}ms)\n", .{ result2, time2 });
}

test "all days" {
    // Reference all day implementations to ensure their tests run
    inline for (days) |day| {
        _ = day;
    }
}
