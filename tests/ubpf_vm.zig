const std = @import("std");
const testing = std.testing;
const ebpf = @import("zig-ebpf").ebpf;
const assembler = @import("zig-ebpf").assembler;
const interpreter = @import("zig-ebpf").interpreter;

fn vm_exec(code: []const u8, mem: []const u8) !u64 {
    var syscalls_map = std.AutoHashMap(usize, ebpf.Syscall).init(std.testing.allocator);
    defer syscalls_map.deinit();

    // Create a mutable copy of the code
    const mutable_code = try std.testing.allocator.dupe(u8, code);
    defer std.testing.allocator.free(mutable_code);

    return interpreter.execute_program(std.testing.allocator, mutable_code, mem, &[_]u8{}, &syscalls_map);
}

test "add" {
    const code = try assembler.assemble(
        \\mov32 r0, 0
        \\mov32 r1, 2
        \\add32 r0, r1
        \\exit
    );
    defer std.testing.allocator.free(code);

    const result = try vm_exec(code, &[_]u8{});
    try testing.expectEqual(@as(u64, 2), result);
}

test "add 64" {
    const code = try assembler.assemble(
        \\mov64 r0, 0
        \\mov64 r1, 2
        \\add64 r0, r1
        \\exit
    );
    defer std.testing.allocator.free(code);

    const result = try vm_exec(code, &[_]u8{});
    try testing.expectEqual(@as(u64, 2), result);
}

test "sub" {
    const code = try assembler.assemble(
        \\mov32 r0, 2
        \\mov32 r1, 1
        \\sub32 r0, r1
        \\exit
    );
    defer std.testing.allocator.free(code);

    const result = try vm_exec(code, &[_]u8{});
    try testing.expectEqual(@as(u64, 1), result);
}

test "sub 64" {
    const code = try assembler.assemble(
        \\mov64 r0, 2
        \\mov64 r1, 1
        \\sub64 r0, r1
        \\exit
    );
    defer std.testing.allocator.free(code);

    const result = try vm_exec(code, &[_]u8{});
    try testing.expectEqual(@as(u64, 1), result);
}

test "mul" {
    const code = try assembler.assemble(
        \\mov32 r0, 3
        \\mov32 r1, 4
        \\mul32 r0, r1
        \\exit
    );
    defer std.testing.allocator.free(code);

    const result = try vm_exec(code, &[_]u8{});
    try testing.expectEqual(@as(u64, 12), result);
}

test "mul 64" {
    const code = try assembler.assemble(
        \\mov64 r0, 0x100000000
        \\mov64 r1, 3
        \\mul64 r0, r1
        \\exit
    );
    defer std.testing.allocator.free(code);

    const result = try vm_exec(code, &[_]u8{});
    try testing.expectEqual(@as(u64, 0x300000000), result);
}

test "div" {
    const code = try assembler.assemble(
        \\mov32 r0, 12
        \\mov32 r1, 3
        \\div32 r0, r1
        \\exit
    );
    defer std.testing.allocator.free(code);

    const result = try vm_exec(code, &[_]u8{});
    try testing.expectEqual(@as(u64, 4), result);
}

test "div 64" {
    const code = try assembler.assemble(
        \\mov64 r0, 0x300000000
        \\mov64 r1, 3
        \\div64 r0, r1
        \\exit
    );
    defer std.testing.allocator.free(code);

    const result = try vm_exec(code, &[_]u8{});
    try testing.expectEqual(@as(u64, 0x100000000), result);
}

test "div 32 by zero" {
    const code = try assembler.assemble(
        \\mov32 r0, 1
        \\mov32 r1, 0
        \\div32 r0, r1
        \\exit
    );
    defer std.testing.allocator.free(code);

    const result = try vm_exec(code, &[_]u8{});
    try testing.expectEqual(@as(u64, 0), result);
}

test "div 64 by zero" {
    const code = try assembler.assemble(
        \\mov64 r0, 1
        \\mov64 r1, 0
        \\div64 r0, r1
        \\exit
    );
    defer std.testing.allocator.free(code);

    const result = try vm_exec(code, &[_]u8{});
    try testing.expectEqual(@as(u64, 0), result);
}
