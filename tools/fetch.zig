const std = @import("std");

const FetchError = error{
    HttpError,
    UnexpectedStatus,
};

fn readSessionFile(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    var file = try std.fs.cwd().openFile(path, .{ .mode = .read_only });
    defer file.close();
    var buf: [4096]u8 = undefined; // temporary read buffer
    var file_reader: std.fs.File.Reader = file.reader(&buf);
    const reader = &file_reader.interface;
    return try reader.allocRemaining(allocator, .unlimited);
}

fn fetchGet(
    allocator: std.mem.Allocator,
    url: []const u8,
) ![]u8 {
    // Load session cookie
    const session = try readSessionFile(allocator, ".session");
    defer allocator.free(session);

    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    const uri = try std.Uri.parse(url);

    const headers = [_]std.http.Header{.{ .name = "Cookie", .value = session }};

    var redirect_buffer: [8 * 1024]u8 = undefined;
    var body: std.Io.Writer.Allocating = .init(allocator);
    defer body.deinit();
    try body.ensureUnusedCapacity(64);

    const result = try client.fetch(.{
        .location = .{ .uri = uri },
        .method = .GET,
        .redirect_buffer = &redirect_buffer,
        .response_writer = &body.writer,
        .extra_headers = &headers,
    });

    if (result.status.class() != .success) {
        std.debug.print("Unexpected response: {any}\n", .{result.status.class()});
        return FetchError.UnexpectedStatus;
    }

    // Read entire body
    return try body.toOwnedSlice();
}

fn writeFile(path: []const u8, data: []const u8) !void {
    var file = try std.fs.cwd().createFile(path, .{ .truncate = true });
    defer file.close();

    try file.writeAll(data);
}

pub fn fetchInput(allocator: std.mem.Allocator, day: u8) !void {
    // Create inputs directory if it doesn't exist
    std.fs.cwd().makeDir("inputs") catch |err| {
        if (err != error.PathAlreadyExists) return err;
    };

    var path_buf: [64]u8 = undefined;
    const filename = if (day < 10) try std.fmt.bufPrint(&path_buf, "inputs/day0{d}.txt", .{day}) else try std.fmt.bufPrint(&path_buf, "inputs/day{d}.txt", .{day});

    std.debug.print("Fetching input for day {d}...\n", .{day});

    var url_buf: [64]u8 = undefined;
    const url = try std.fmt.bufPrint(&url_buf, "https://adventofcode.com/2025/day/{d}/input", .{day});
    const data = try fetchGet(allocator, url);
    defer allocator.free(data);

    try writeFile(filename, data);

    std.debug.print("Content saved to: {s}\n", .{filename});
}

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: {s} <day>\n", .{args[0]});
        std.debug.print("Example: zig build fetch -- 5\n", .{});
        return;
    }

    const day = try std.fmt.parseInt(u8, args[1], 10);
    try fetchInput(allocator, day);
}
