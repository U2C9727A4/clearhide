const std = @import("std");
const rand = std.crypto.random;
const builtin = @import("builtin");

fn xorify(allocator: std.mem.Allocator, data: []const u8, data2: []const u8) ![]u8 {
    if (data.len != data2.len) return error.IllegalLenghts;
    const buffer = try allocator.alloc(u8, data.len);
    for (0..data.len) |index| {
        buffer[index] = data[index] ^ data2[index];
    }
    return buffer;
}

fn seedToInt(seed: [std.Random.ChaCha.secret_seed_length]u8) std.meta.Int(.unsigned, (std.Random.ChaCha.secret_seed_length * 8)) {
    const seed_int: std.meta.Int(.unsigned, (std.Random.ChaCha.secret_seed_length * 8)) = @bitCast(seed);
    return seed_int;
}

fn hideFile(allocator: std.mem.Allocator, payload_file: std.fs.File, carrier_file: std.fs.File, output_file: std.fs.File) !void {
    // First, we need a secure seed. We use /dev/random for this.
    const read_only_flags = std.fs.File.OpenFlags{ .mode = .read_only};
    const random_file = try std.fs.cwd().openFile("/dev/random", read_only_flags);
    defer random_file.close();

    var seed: [std.Random.ChaCha.secret_seed_length]u8 = undefined;
    const bytes_read = try random_file.read(&seed);
    if (bytes_read != std.Random.ChaCha.secret_seed_length) return error.FailedSeedInit;
    defer std.debug.print("Seed: {d}\n", .{seedToInt(seed)});

    var csprng = std.Random.ChaCha.init(seed);
    const chacha = csprng.random();

    //const payload_metadata = try payload_file.metadata();
    const carrier_metadata = try carrier_file.metadata();
    while (true) {
        // We generate random offsets and lenght of fragments using chacha.
        const max_fragment_size = 512;
        var fragment_size = chacha.uintAtMost(u16, max_fragment_size);
        if (fragment_size == 0) fragment_size += 1;
        const offset = chacha.uintAtMost(usize, (carrier_metadata.size() - fragment_size));
        std.debug.print("offset: {d}, fragment_len: {d}\n", .{offset, fragment_size});

        var buffer: [max_fragment_size]u8 = .{0} ** max_fragment_size;
        var buffer2: [max_fragment_size]u8 = .{0} ** max_fragment_size;

        const bytes_got = try payload_file.read(buffer[0..fragment_size]);
        try carrier_file.seekTo(offset);
        _ = try carrier_file.read(buffer2[0..bytes_got]);

        const output = try xorify(allocator, buffer[0..bytes_got], buffer2[0..bytes_got]);
        defer allocator.free(output);
        const bytes_written = try output_file.write(output);
        if (bytes_written != bytes_got) return error.BadWrite;
        if (bytes_got < fragment_size) break;

    }

}

fn recoverFile(allocator: std.mem.Allocator, payload_file: std.fs.File, carrier_file: std.fs.File, output_file: std.fs.File, seed: [std.Random.ChaCha.secret_seed_length]u8) !void {
    var csprng = std.Random.ChaCha.init(seed);
    const chacha = csprng.random();

    //const payload_metadata = try payload_file.metadata();
    const carrier_metadata = try carrier_file.metadata();
    while (true) {
        // We generate random offsets and lenght of fragments using chacha.
        const max_fragment_size = 512;
        var fragment_size = chacha.uintAtMost(u16, max_fragment_size);
        if (fragment_size == 0) fragment_size += 1;
        const offset = chacha.uintAtMost(usize, (carrier_metadata.size() - fragment_size));

        var buffer: [max_fragment_size]u8 = .{0} ** max_fragment_size;
        var buffer2: [max_fragment_size]u8 = .{0} ** max_fragment_size;

        const bytes_got = try payload_file.read(buffer[0..fragment_size]);
        try carrier_file.seekTo(offset);
        _ = try carrier_file.read(buffer2[0..bytes_got]);

        const output = try xorify(allocator, buffer[0..bytes_got], buffer2[0..bytes_got]);
        defer allocator.free(output);
        const bytes_written = try output_file.write(output);
        if (bytes_written != bytes_got) return error.BadWrite;
        if (bytes_got < fragment_size) break;

    }

}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    if (args.len == 1) return;

    if (std.mem.eql(u8, args[1], "hide")) {
        const carrier_filePath = args[2];
        const payload_filePath = args[3];
        const output_filePath = args[4];
        const openflags = std.fs.File.OpenFlags{.mode = .read_only};

        const outputFlags = std.fs.File.CreateFlags{.truncate = false};
        const outputFile = try std.fs.cwd().createFile(output_filePath, outputFlags);
        defer outputFile.close();
        const carrierFile = try std.fs.cwd().openFile(carrier_filePath, openflags);
        const payloadFile = try std.fs.cwd().openFile(payload_filePath, openflags);
        defer carrierFile.close();
        defer payloadFile.close();

        try hideFile(allocator, payloadFile, carrierFile, outputFile);
    }
    if (std.mem.eql(u8, args[1], "recover")) {
        const carrier_filePath = args[2];
        const payload_filePath = args[3];
        const output_filePath = args[4];
        const seedStr = args[5];
        const seedInt = try std.fmt.parseInt(std.meta.Int(.unsigned, (std.Random.ChaCha.secret_seed_length * 8)), seedStr, 10);
        const seed: [std.Random.ChaCha.secret_seed_length]u8 = @bitCast(seedInt);
        const openflags = std.fs.File.OpenFlags{.mode = .read_only};

        const outputFlags = std.fs.File.CreateFlags{.truncate = false};
        const outputFile = try std.fs.cwd().createFile(output_filePath, outputFlags);
        defer outputFile.close();
        const carrierFile = try std.fs.cwd().openFile(carrier_filePath, openflags);
        const payloadFile = try std.fs.cwd().openFile(payload_filePath, openflags);
        defer carrierFile.close();
        defer payloadFile.close();

        try recoverFile(allocator, payloadFile, carrierFile, outputFile, seed);
    }
}
