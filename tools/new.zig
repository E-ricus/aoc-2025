const std = @import("std");
const fetch = @import("./fetch.zig");

const day_template =
    \\const std = @import("std");
    \\const aoc = @import("aoc");
    \\
    \\pub fn part1(input: []const u8) !i64 {{
    \\    _ = input;
    \\    // TODO: Implement part 1
    \\    return 0;
    \\}}
    \\
    \\pub fn part2(input: []const u8) !i64 {{
    \\    _ = input;
    \\    // TODO: Implement part 2
    \\    return 0;
    \\}}
    \\
    \\test "day{} part1" {{
    \\    const input =
    \\        \\
    \\    ;
    \\    try std.testing.expectEqual(@as(i64, 0), try part1(input));
    \\}}
    \\
    \\test "day{} part2" {{
    \\    const input =
    \\        \\
    \\    ;
    \\    try std.testing.expectEqual(@as(i64, 0), try part2(input));
    \\}}
    \\
;

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: {s} <day>\n", .{args[0]});
        std.debug.print("Example: zig build new -- 5\n", .{});
        return;
    }

    const day = try std.fmt.parseInt(u8, args[1], 10);

    // Create src/days directory if it doesn't exist
    std.fs.cwd().makeDir("src/days") catch |err| {
        if (err != error.PathAlreadyExists) return err;
    };

    // Create day file
    const filename = if (day < 10)
        try std.fmt.allocPrint(allocator, "src/days/day0{d}.zig", .{day})
    else
        try std.fmt.allocPrint(allocator, "src/days/day{d}.zig", .{day});
    defer allocator.free(filename);

    // Check if file already exists
    if (std.fs.cwd().access(filename, .{})) {
        std.debug.print("Error: {s} already exists\n", .{filename});
        return error.FileExists;
    } else |_| {}

    const file = try std.fs.cwd().createFile(filename, .{});
    defer file.close();

    const content = try std.fmt.allocPrint(allocator, day_template, .{ day, day });
    defer allocator.free(content);

    try file.writeAll(content);

    std.debug.print("Created {s}\n", .{filename});
    try fetch.fetchInput(allocator, day);
    std.debug.print("\nNext steps:\n", .{});
    std.debug.print("\n1. Implement solution in {s}\n", .{filename});
    std.debug.print("\n2. Run solution:\n", .{});
    std.debug.print("   zig build run -- {d}\n", .{day});
    std.debug.print("\nNote: The day will be automatically discovered on next build!\n", .{});
}
