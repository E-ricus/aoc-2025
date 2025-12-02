const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create the aoc utilities module
    const aoc_mod = b.addModule("aoc", .{
        .root_source_file = b.path("src/aoc.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Generate days registry at build time
    const registry_mod = generateDaysRegistry(b, target, optimize, aoc_mod) catch |err| {
        std.debug.print("Failed to generate days registry: {}\n", .{err});
        @panic("days registry generation failed");
    };

    // Main executable for running days
    const exe = b.addExecutable(.{
        .name = "aoc_2025",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "aoc", .module = aoc_mod },
                .{ .name = "days_registry", .module = registry_mod },
            },
        }),
    });
    b.installArtifact(exe);

    // Run step - `zig build run -- 1 2 3` or all to run specific days
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run solution for specified days (e.g., zig build run -- 1 2 or zig build run all)");
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
                .{ .name = "days_registry", .module = registry_mod },
            },
        }),
    });

    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run all tests");
    test_step.dependOn(&run_tests.step);
}

const DayEntry = struct {
    num: u8,
    num_str: []const u8,
    filename: []const u8,
};

fn generateDaysRegistry(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    aoc_mod: *std.Build.Module,
) !*std.Build.Module {
    const allocator = b.allocator;

    // Collect day files
    var days_dir = b.build_root.handle.openDir("src/days", .{ .iterate = true }) catch |err| {
        if (err == error.FileNotFound) {
            return try makeRegistryModule(b, target, optimize, aoc_mod, &[_]DayEntry{});
        }
        return err;
    };
    defer days_dir.close();

    var day_entries = std.ArrayListUnmanaged(DayEntry){};
    defer {
        for (day_entries.items) |d| {
            allocator.free(d.num_str);
            allocator.free(d.filename);
        }
        day_entries.deinit(allocator);
    }

    var it = days_dir.iterate();
    while (try it.next()) |entry| {
        if (entry.kind != .file) continue;
        if (!std.mem.startsWith(u8, entry.name, "day") or !std.mem.endsWith(u8, entry.name, ".zig")) continue;

        const name_no_ext = entry.name[0 .. entry.name.len - 4];
        const num_str = name_no_ext[3..];
        const num = std.fmt.parseInt(u8, num_str, 10) catch continue;

        try day_entries.append(allocator, .{
            .num = num,
            .num_str = try allocator.dupe(u8, num_str),
            .filename = try allocator.dupe(u8, entry.name),
        });
    }

    std.mem.sort(DayEntry, day_entries.items, {}, struct {
        fn lessThan(_: void, first: DayEntry, second: DayEntry) bool {
            return first.num < second.num;
        }
    }.lessThan);

    return try makeRegistryModule(b, target, optimize, aoc_mod, day_entries.items);
}

fn makeRegistryModule(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    aoc_mod: *std.Build.Module,
    day_entries: []const DayEntry,
) !*std.Build.Module {
    var file = try b.build_root.handle.createFile("src/days_registry.zig", .{ .truncate = true });
    defer file.close();

    var buf: [4096]u8 = undefined;
    var writer = file.writer(&buf);
    const w = &writer.interface;

    try w.writeAll(
        \\// Auto-generated file - do not edit manually
        \\// Regenerated on every build
        \\
    );
    for (day_entries) |entry| {
        try w.print("const day{s} = @import(\"days/{s}\");\n", .{ entry.num_str, entry.filename });
    }
    try w.writeByte('\n');
    try w.writeAll(
        \\pub const Day = struct {
        \\    number: u8,
        \\    part1: *const fn ([]const u8) anyerror!i64,
        \\    part2: *const fn ([]const u8) anyerror!i64,
        \\};
        \\
        \\pub const days = [_]Day{
    );
    try w.writeByte('\n');
    for (day_entries) |entry| {
        try w.print(
            "    .{{ .number = {d}, .part1 = day{s}.part1, .part2 = day{s}.part2 }},\n",
            .{ entry.num, entry.num_str, entry.num_str },
        );
    }
    try w.writeAll("};\n");
    try w.flush();

    return b.addModule("days_registry", .{
        .root_source_file = b.path("src/days_registry.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{.{ .name = "aoc", .module = aoc_mod }},
    });
}
