const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Generate days registry at build time
    generateDaysRegistry(b) catch |err| {
        std.debug.print("Warning: Failed to generate days registry: {}\n", .{err});
    };

    // Create the aoc utilities module
    const aoc_mod = b.addModule("aoc", .{
        .root_source_file = b.path("src/aoc.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Main executable for running days
    const exe = b.addExecutable(.{
        .name = "aoc_2025",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "aoc", .module = aoc_mod },
            },
        }),
    });
    b.installArtifact(exe);

    // Run step - `zig build run -- 1 2 3` to run specific days
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run solution for specified days (e.g., zig build run -- 1 2)");
    run_step.dependOn(&run_cmd.step);

    // Input fetcher - `zig build fetch -- 5` to download input for day 5
    const fetch_exe = b.addExecutable(.{
        .name = "fetch",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tools/fetch.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    b.installArtifact(fetch_exe);

    const fetch_cmd = b.addRunArtifact(fetch_exe);
    fetch_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        fetch_cmd.addArgs(args);
    }
    const fetch_step = b.step("fetch", "Download input for a specific day (e.g., zig build fetch -- 5)");
    fetch_step.dependOn(&fetch_cmd.step);

    // New day creator - `zig build new -- 5` to create day 5 template
    const new_exe = b.addExecutable(.{
        .name = "new",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tools/new.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    b.installArtifact(new_exe);

    const new_cmd = b.addRunArtifact(new_exe);
    new_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        new_cmd.addArgs(args);
    }
    const new_step = b.step("new", "Create a new day template (e.g., zig build new -- 5)");
    new_step.dependOn(&new_cmd.step);

    // Test step
    const tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "aoc", .module = aoc_mod },
            },
        }),
    });

    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run all tests");
    test_step.dependOn(&run_tests.step);
}

fn generateDaysRegistry(b: *std.Build) !void {
    const allocator = b.allocator;

    // Check if src/days exists
    var days_dir = std.fs.cwd().openDir("src/days", .{ .iterate = true }) catch |err| {
        if (err == error.FileNotFound) {
            // Create empty registry if directory doesn't exist
            const registry_file = try std.fs.cwd().createFile("src/days_registry.zig", .{});
            defer registry_file.close();
            try registry_file.writeAll(
                \\// Auto-generated file - do not edit
                \\pub const days = [_]Day{};
                \\pub const Day = struct {
                \\    number: u8,
                \\    part1: *const fn ([]const u8) anyerror!i64,
                \\    part2: *const fn ([]const u8) anyerror!i64,
                \\};
                \\
            );
            return;
        }
        return err;
    };
    defer days_dir.close();

    // Collect all day*.zig files
    const DayEntry = struct {
        num: u8,
        num_str: []const u8,
        filename: []const u8,
    };
    var day_entries = std.ArrayList(DayEntry).initCapacity(allocator, 0) catch unreachable;
    defer day_entries.deinit(allocator);

    var iter = days_dir.iterate();
    while (try iter.next()) |entry| {
        if (entry.kind != .file) continue;
        if (!std.mem.endsWith(u8, entry.name, ".zig")) continue;
        if (!std.mem.startsWith(u8, entry.name, "day")) continue;

        // Extract day number from filename (day01.zig -> 1, day12.zig -> 12)
        const name_without_ext = entry.name[0 .. entry.name.len - 4];
        const day_num_str = name_without_ext[3..];
        const day_num = std.fmt.parseInt(u8, day_num_str, 10) catch continue;

        const entry_copy = DayEntry{
            .num = day_num,
            .num_str = try allocator.dupe(u8, day_num_str),
            .filename = try allocator.dupe(u8, entry.name),
        };
        try day_entries.append(allocator, entry_copy);
    }

    // Sort by day number
    std.mem.sort(DayEntry, day_entries.items, {}, struct {
        fn lessThan(_: void, a: DayEntry, other: DayEntry) bool {
            return a.num < other.num;
        }
    }.lessThan);

    // Generate import statements and entries
    var imports = std.ArrayList(u8).initCapacity(allocator, 0) catch unreachable;
    defer imports.deinit(allocator);

    var entries_list = std.ArrayList(u8).initCapacity(allocator, 0) catch unreachable;
    defer entries_list.deinit(allocator);

    for (day_entries.items) |day_entry| {
        try imports.writer(allocator).print("const day{s} = @import(\"days/{s}\");\n", .{ day_entry.num_str, day_entry.filename });
        try entries_list.writer(allocator).print("    .{{ .number = {d}, .part1 = day{s}.part1, .part2 = day{s}.part2 }},\n", .{ day_entry.num, day_entry.num_str, day_entry.num_str });
    }

    // Generate the registry file
    const registry_file = try std.fs.cwd().createFile("src/days_registry.zig", .{});
    defer registry_file.close();

    try registry_file.writeAll("// Auto-generated file - do not edit manually\n");
    try registry_file.writeAll("// This file is regenerated on every build\n\n");
    try registry_file.writeAll(imports.items);
    try registry_file.writeAll("\n");
    try registry_file.writeAll("pub const Day = struct {\n");
    try registry_file.writeAll("    number: u8,\n");
    try registry_file.writeAll("    part1: *const fn ([]const u8) anyerror!i64,\n");
    try registry_file.writeAll("    part2: *const fn ([]const u8) anyerror!i64,\n");
    try registry_file.writeAll("};\n\n");
    try registry_file.writeAll("pub const days = [_]Day{\n");
    try registry_file.writeAll(entries_list.items);
    try registry_file.writeAll("};\n\n");

    // Add test block to ensure all day tests are discovered
    var test_refs = std.ArrayList(u8).initCapacity(allocator, 0) catch unreachable;
    defer test_refs.deinit(allocator);

    for (day_entries.items) |day_entry| {
        try test_refs.writer(allocator).print("    _ = day{s};\n", .{day_entry.num_str});
    }

    try registry_file.writeAll("test {\n");
    try registry_file.writeAll(test_refs.items);
    try registry_file.writeAll("}\n");
}
