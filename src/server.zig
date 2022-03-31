const std = @import("std");
const net = std.net;
const StreamServer = net.StreamServer;
const Address = net.Address;
const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const Request = @import("Request.zig");
const Response = @import("Response.zig");

pub const Handler = fn (*Request, *Response) anyerror!void;

pub const Config = struct {
    address: []const u8 = "127.0.0.1",
    port: u16 = 8080,
};

pub fn Server(comptime handler: Handler) type {
    return struct {
        allocator: std.mem.Allocator,
        clients: std.ArrayList(*Client),
        config: Config,
        const Self = @This();
        const Client = struct {
            frame: @Frame(handle),
        };
        pub fn deinit(self: *Server) void {
            self.stream_server.close();
            self.stream_server.deinit();
        }
        pub fn init(allocator: std.mem.Allocator, config: Config) Self {
            return .{ .allocator = allocator, .clients = std.ArrayList(*Client).init(allocator), .config = config };
        }
        fn handle(self: *Self, stream: net.Stream) !void {
            defer stream.close();
            var request = try Request.init(self.allocator, stream.reader());
            request.debugPrintRequest();
            var response = Response{ .version = request.version, .writer = stream.writer() };
            try handler(&request, &response);
        }

        pub fn listen(self: *Self) !void {
            var stream_server = StreamServer.init(.{});
            const address = try net.Address.resolveIp(self.config.address, self.config.port);
            try stream_server.listen(address);
            print("Listening on: {}\n", .{address});
            while (true) {
                const connection = try stream_server.accept();
                var client = try self.allocator.create(Client);
                client.* = .{
                    .frame = async self.handle(connection.stream),
                };
                try self.clients.append(client);
            }
        }
    };
}
