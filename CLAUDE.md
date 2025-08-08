# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Development Commands

### Zig Commands
- **Build library and executables**: `zig build`
- **Run tests**: `zig build test`
- **Run benchmarks**: `zig build benchmark`
- **Clean build**: `rm -rf zig-out .zig-cache`

### Python Visualization Scripts
- **Run plotting scripts**: `python scripts/<script_name>.py` (requires `uv sync` first)
- **Install Python dependencies**: `uv sync`

## Project Architecture

This is a Zig library implementing Smith-Waterman sequence alignment algorithms with Python visualization tools.

### Core Structure
- **Library module**: `src/root.zig` - Main library interface exposing Smith-Waterman implementations
- **Basic implementation**: `src/basic_sw.zig` - Standard matrix-based Smith-Waterman algorithm
- **Optimized implementation**: `src/shift_sw.zig` - Work-in-progress SIMD/vector-optimized version
- **Benchmarking**: `src/base_benchmark.zig` - Command-line tool for performance testing

### Smith-Waterman Implementation Details
The `basic_sw.zig` contains a complete Smith-Waterman implementation with:
- Matrix struct with configurable scoring parameters (match=3, mismatch=-1, gap=-2)
- Dynamic programming matrix computation with proper initialization
- Local alignment scoring (resets to 0 when negative)
- Comprehensive test suite with known sequence pairs and expected scores

### Key Data Structures
- `Matrix`: Main scoring matrix with methods for cell access, scoring, and result finding
- `Match`: Result structure for storing alignment matches with scores
- Uses `u8` for scores and matrix storage to optimize memory usage

### Development Focus
The project is exploring SIMD optimization using Zig's `@Vector` type for performance improvements in the `shift_sw.zig` implementation.