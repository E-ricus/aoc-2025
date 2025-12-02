# Advent of Code 2025 - Zig

## Setup

### Option 1: Using Nix (Recommended)

If you have Nix with flakes enabled:

```bash
nix develop
# or with direnv
direnv allow
```

This provides Zig and ZLS (Zig Language Server) automatically.

### Option 2: Manual Setup

Install Zig 0.15+ manually from [ziglang.org](https://ziglang.org/download/)

## Usage

### Create a new day

```bash
zig build new -- 5
```

### Run a solution

```bash
# Run a single day
zig build run -- 5

# Run multiple days
zig build run -- 1 2 3

# Run all days
zig build run -- 1 2 3

# Run with optimizations
zig build run -Doptimize=ReleaseFast -- 5
```

### Run tests

```bash
zig build test
```

## Project Structure

```
.
├── build.zig              # Build configuration with auto-discovery
├── src/
│   ├── main.zig           # Day runner
│   ├── aoc.zig            # Shared utilities
│   ├── days_registry.zig  # Auto-generated
│   └── days/
│       ├── day01.zig      # Day 1 solution
│       ├── day02.zig      # Day 2 solution
│       └── ...
├── tools/
│   ├── fetch.zig          # Input fetcher
│   └── new.zig            # Day template creator
└── inputs/
    ├── day01.txt          # Day 1 input
    ├── day02.txt          # Day 2 input
    └── ...
```
